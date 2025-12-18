//! Lendasat API client for Flutter.
//!
//! Provides a Flutter-friendly API for the Lendasat lending platform.

use crate::lendasat::auth;
use crate::lendasat::models::*;
use crate::lendasat::storage::{self, StoredAuth};
use anyhow::{anyhow, bail, Result};
use bitcoin::Network;
use reqwest::header::{HeaderMap, HeaderName, HeaderValue, AUTHORIZATION, CONTENT_TYPE};
use serde::{Deserialize, Serialize};
use std::str::FromStr;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::OnceLock;
use tokio::sync::RwLock;

// ============================================================================
// Global State
// ============================================================================

static LENDASAT_INITIALIZED: AtomicBool = AtomicBool::new(false);

struct LendasatState {
    http_client: reqwest::Client,
    base_url: String,
    data_dir: String,
    network: Network,
    jwt_token: Option<String>,
    api_key: Option<String>,
}

static LENDASAT_STATE: OnceLock<RwLock<Option<LendasatState>>> = OnceLock::new();

fn get_state_lock() -> &'static RwLock<Option<LendasatState>> {
    LENDASAT_STATE.get_or_init(|| RwLock::new(None))
}

// ============================================================================
// Initialization
// ============================================================================

/// Initialize the Lendasat client.
///
/// - `data_dir`: Directory for storing auth data and mnemonic
/// - `api_url`: Lendasat API base URL (e.g., "https://apiborrow.lendasat.com")
/// - `network`: Bitcoin network ("bitcoin", "testnet", "signet", "regtest")
/// - `api_key`: Optional API key for authentication (alternative to JWT)
pub async fn lendasat_init(data_dir: String, api_url: String, network: String, api_key: Option<String>) -> Result<()> {
    let http_client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(30))
        .build()
        .map_err(|e| anyhow!("Failed to create HTTP client: {}", e))?;

    let network = Network::from_str(&network)
        .map_err(|e| anyhow!("Invalid network '{}': {}", network, e))?;

    // Try to load existing auth
    let jwt_token = storage::load_auth(&data_dir)?
        .filter(|auth| !auth.is_potentially_expired())
        .map(|auth| auth.jwt_token);

    let state = LendasatState {
        http_client,
        base_url: api_url,
        data_dir,
        network,
        jwt_token,
        api_key,
    };

    let lock = get_state_lock();
    let mut guard = lock.write().await;
    *guard = Some(state);

    LENDASAT_INITIALIZED.store(true, Ordering::SeqCst);
    tracing::info!("Lendasat client initialized");

    Ok(())
}

/// Check if Lendasat client is initialized.
pub fn lendasat_is_initialized() -> bool {
    LENDASAT_INITIALIZED.load(Ordering::SeqCst)
}

/// Check if user is authenticated.
pub async fn lendasat_is_authenticated() -> bool {
    let lock = get_state_lock();
    let guard = lock.read().await;
    guard.as_ref().map(|s| s.jwt_token.is_some()).unwrap_or(false)
}

// ============================================================================
// Authentication
// ============================================================================

/// Get the wallet's public key (for display/verification).
pub async fn lendasat_get_public_key() -> Result<String> {
    let lock = get_state_lock();
    let guard = lock.read().await;
    let state = guard.as_ref().ok_or_else(|| anyhow!("Lendasat not initialized"))?;
    auth::get_public_key(&state.data_dir, state.network).await
}

/// Get the wallet's derivation path.
pub fn lendasat_get_derivation_path() -> String {
    auth::get_derivation_path()
}

/// Authenticate with the Lendasat API using wallet signature.
///
/// This performs the full challenge-response authentication:
/// 1. Get public key from wallet
/// 2. Request challenge from server
/// 3. Sign challenge with wallet
/// 4. Verify signature and get JWT token
pub async fn lendasat_authenticate() -> Result<AuthResult> {
    let lock = get_state_lock();

    // Get public key from wallet
    let pubkey = {
        let guard = lock.read().await;
        let state = guard.as_ref().ok_or_else(|| anyhow!("Lendasat not initialized"))?;
        auth::get_public_key(&state.data_dir, state.network).await?
    };
    tracing::info!("Authenticating with pubkey: {}...", &pubkey[..16]);

    // Request challenge from server
    let challenge = {
        let guard = lock.read().await;
        let state = guard.as_ref().ok_or_else(|| anyhow!("Lendasat not initialized"))?;

        let url = format!("{}/api/auth/pubkey-challenge", state.base_url);
        let body = serde_json::json!({ "pubkey": pubkey });

        let response = state
            .http_client
            .post(&url)
            .header(CONTENT_TYPE, "application/json")
            .json(&body)
            .send()
            .await
            .map_err(|e| anyhow!("Failed to request challenge: {}", e))?;

        if !response.status().is_success() {
            let status = response.status();
            let text = response.text().await.unwrap_or_default();
            bail!("Challenge request failed ({}): {}", status, text);
        }

        let challenge_response: PubkeyChallengeResponse = response
            .json()
            .await
            .map_err(|e| anyhow!("Failed to parse challenge response: {}", e))?;

        challenge_response.challenge
    };

    tracing::debug!("Received challenge: {}", challenge);

    // Sign the challenge with wallet
    let signature = {
        let guard = lock.read().await;
        let state = guard.as_ref().ok_or_else(|| anyhow!("Lendasat not initialized"))?;
        auth::sign_message(&challenge, &state.data_dir, state.network).await?
    };
    tracing::debug!("Signed challenge, signature length: {}", signature.len());

    // Verify signature and get JWT
    let (token, user) = {
        let guard = lock.read().await;
        let state = guard.as_ref().ok_or_else(|| anyhow!("Lendasat not initialized"))?;

        let url = format!("{}/api/auth/pubkey-verify", state.base_url);
        let body = PubkeyVerifyRequest {
            pubkey: pubkey.clone(),
            challenge,
            signature,
        };

        let response = state
            .http_client
            .post(&url)
            .header(CONTENT_TYPE, "application/json")
            .json(&body)
            .send()
            .await
            .map_err(|e| anyhow!("Failed to verify signature: {}", e))?;

        if !response.status().is_success() {
            let status = response.status();
            let text = response.text().await.unwrap_or_default();

            // Check if user needs to register
            if status.as_u16() == 401 || text.contains("not found") || text.contains("not registered")
            {
                return Ok(AuthResult::NeedsRegistration { pubkey });
            }

            bail!("Signature verification failed ({}): {}", status, text);
        }

        let verify_response: PubkeyVerifyResponse = response
            .json()
            .await
            .map_err(|e| anyhow!("Failed to parse verify response: {}", e))?;

        (verify_response.token, verify_response.user)
    };

    // Store the token
    {
        let mut guard = lock.write().await;
        let state = guard.as_mut().ok_or_else(|| anyhow!("Lendasat not initialized"))?;

        // Save to storage
        let stored_auth = StoredAuth {
            jwt_token: token.clone(),
            user_id: user.id.clone(),
            user_name: user.name.clone(),
            user_email: user.email.clone(),
            pubkey: pubkey.clone(),
            created_at: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .map(|d| d.as_secs() as i64)
                .unwrap_or(0),
            expires_at: None, // JWT expiry is handled server-side
        };

        storage::save_auth(&state.data_dir, &stored_auth)?;
        state.jwt_token = Some(token);
    }

    tracing::info!("Authentication successful for user: {}", user.name);

    Ok(AuthResult::Success {
        user_id: user.id,
        user_name: user.name,
        user_email: user.email,
    })
}

/// Register a new user with the Lendasat platform.
pub async fn lendasat_register(email: String, name: String, invite_code: Option<String>) -> Result<String> {
    let lock = get_state_lock();

    let pubkey = {
        let guard = lock.read().await;
        let state = guard.as_ref().ok_or_else(|| anyhow!("Lendasat not initialized"))?;
        auth::get_public_key(&state.data_dir, state.network).await?
    };

    let guard = lock.read().await;
    let state = guard.as_ref().ok_or_else(|| anyhow!("Lendasat not initialized"))?;

    let url = format!("{}/api/auth/pubkey-register", state.base_url);
    let body = PubkeyRegisterRequest {
        pubkey,
        email,
        name,
        invite_code,
    };

    let response = state
        .http_client
        .post(&url)
        .header(CONTENT_TYPE, "application/json")
        .json(&body)
        .send()
        .await
        .map_err(|e| anyhow!("Failed to register: {}", e))?;

    if !response.status().is_success() {
        let status = response.status();
        let text = response.text().await.unwrap_or_default();
        bail!("Registration failed ({}): {}", status, text);
    }

    let register_response: PubkeyRegisterResponse = response
        .json()
        .await
        .map_err(|e| anyhow!("Failed to parse register response: {}", e))?;

    tracing::info!("Registration successful, user_id: {}", register_response.user_id);

    Ok(register_response.user_id)
}

/// Logout and clear stored credentials.
pub async fn lendasat_logout() -> Result<()> {
    let lock = get_state_lock();
    let mut guard = lock.write().await;
    let state = guard.as_mut().ok_or_else(|| anyhow!("Lendasat not initialized"))?;

    storage::delete_auth(&state.data_dir)?;
    state.jwt_token = None;

    tracing::info!("Logged out from Lendasat");

    Ok(())
}

// ============================================================================
// Offers
// ============================================================================

/// Get available loan offers.
pub async fn lendasat_get_offers(filters: Option<OfferFilters>) -> Result<Vec<LoanOffer>> {
    let lock = get_state_lock();
    let guard = lock.read().await;
    let state = guard.as_ref().ok_or_else(|| anyhow!("Lendasat not initialized"))?;

    let mut url = format!("{}/api/offers", state.base_url);

    // Add query parameters
    let mut params = Vec::new();
    if let Some(filters) = filters {
        if let Some(v) = filters.loan_type {
            params.push(format!("loan_type={}", v));
        }
        if let Some(v) = filters.asset_type {
            params.push(format!("asset_type={}", v));
        }
        if let Some(v) = filters.loan_assets {
            params.push(format!("loan_assets={}", v));
        }
        if let Some(v) = filters.kyc {
            params.push(format!("kyc={}", v));
        }
        if let Some(v) = filters.min_loan_amount {
            params.push(format!("min_loan_amount={}", v));
        }
        if let Some(v) = filters.max_loan_amount {
            params.push(format!("max_loan_amount={}", v));
        }
        if let Some(v) = filters.max_interest_rate {
            params.push(format!("max_interest_rate={}", v));
        }
        if let Some(v) = filters.duration_min {
            params.push(format!("duration_min={}", v));
        }
        if let Some(v) = filters.duration_max {
            params.push(format!("duration_max={}", v));
        }
        if let Some(v) = filters.collateral_asset_type {
            params.push(format!("collateral_asset_type={}", v));
        }
    }

    if !params.is_empty() {
        url = format!("{}?{}", url, params.join("&"));
    }

    // Build request with auth headers (JWT or API key)
    let mut request = state.http_client.get(&url);
    if let Some(token) = &state.jwt_token {
        request = request.header(AUTHORIZATION, format!("Bearer {}", token));
    } else if let Some(api_key) = &state.api_key {
        request = request.header("x-api-key", api_key);
    }

    let response = request
        .send()
        .await
        .map_err(|e| anyhow!("Failed to fetch offers: {}", e))?;

    if !response.status().is_success() {
        let status = response.status();
        let text = response.text().await.unwrap_or_default();
        bail!("Failed to fetch offers ({}): {}", status, text);
    }

    let offers: Vec<LoanOffer> = response
        .json()
        .await
        .map_err(|e| anyhow!("Failed to parse offers: {}", e))?;

    Ok(offers)
}

/// Get a single offer by ID.
pub async fn lendasat_get_offer(offer_id: String) -> Result<LoanOffer> {
    let offers = lendasat_get_offers(None).await?;

    offers
        .into_iter()
        .find(|o| o.id == offer_id)
        .ok_or_else(|| anyhow!("Offer not found: {}", offer_id))
}

// ============================================================================
// Contracts
// ============================================================================

/// Get authenticated headers for API requests.
/// Prioritizes JWT token over API key.
async fn get_auth_headers(state: &LendasatState) -> Result<HeaderMap> {
    let mut headers = HeaderMap::new();
    headers.insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));

    // Prefer JWT token, fall back to API key
    if let Some(token) = &state.jwt_token {
        headers.insert(
            AUTHORIZATION,
            HeaderValue::from_str(&format!("Bearer {}", token))
                .map_err(|e| anyhow!("Invalid token: {}", e))?,
        );
    } else if let Some(api_key) = &state.api_key {
        headers.insert(
            HeaderName::from_static("x-api-key"),
            HeaderValue::from_str(api_key)
                .map_err(|e| anyhow!("Invalid API key: {}", e))?,
        );
    } else {
        bail!("Not authenticated: no JWT token or API key available");
    }

    Ok(headers)
}

/// Get user's contracts.
pub async fn lendasat_get_contracts(filters: Option<ContractFilters>) -> Result<PaginatedContractsResponse> {
    let lock = get_state_lock();
    let guard = lock.read().await;
    let state = guard.as_ref().ok_or_else(|| anyhow!("Lendasat not initialized"))?;

    let headers = get_auth_headers(state).await?;

    let mut url = format!("{}/api/contracts", state.base_url);

    // Add query parameters
    let mut params = Vec::new();
    if let Some(filters) = filters {
        if let Some(v) = filters.page {
            params.push(format!("page={}", v));
        }
        if let Some(v) = filters.limit {
            params.push(format!("limit={}", v));
        }
        if let Some(v) = filters.sort_by {
            params.push(format!("sort_by={}", v));
        }
        if let Some(v) = filters.sort_order {
            params.push(format!("sort_order={}", v));
        }
        if let Some(statuses) = filters.status {
            for status in statuses {
                params.push(format!("status={:?}", status));
            }
        }
    }

    if !params.is_empty() {
        url = format!("{}?{}", url, params.join("&"));
    }

    let response = state
        .http_client
        .get(&url)
        .headers(headers)
        .send()
        .await
        .map_err(|e| anyhow!("Failed to fetch contracts: {}", e))?;

    if !response.status().is_success() {
        let status = response.status();
        let text = response.text().await.unwrap_or_default();
        bail!("Failed to fetch contracts ({}): {}", status, text);
    }

    let contracts: PaginatedContractsResponse = response
        .json()
        .await
        .map_err(|e| anyhow!("Failed to parse contracts: {}", e))?;

    Ok(contracts)
}

/// Get a single contract by ID.
pub async fn lendasat_get_contract(contract_id: String) -> Result<Contract> {
    let lock = get_state_lock();
    let guard = lock.read().await;
    let state = guard.as_ref().ok_or_else(|| anyhow!("Lendasat not initialized"))?;

    let headers = get_auth_headers(state).await?;

    let url = format!("{}/api/contracts/{}", state.base_url, contract_id);

    let response = state
        .http_client
        .get(&url)
        .headers(headers)
        .send()
        .await
        .map_err(|e| anyhow!("Failed to fetch contract: {}", e))?;

    if !response.status().is_success() {
        let status = response.status();
        let text = response.text().await.unwrap_or_default();
        bail!("Failed to fetch contract ({}): {}", status, text);
    }

    let contract: Contract = response
        .json()
        .await
        .map_err(|e| anyhow!("Failed to parse contract: {}", e))?;

    Ok(contract)
}

/// Create a new loan contract by taking an offer.
pub async fn lendasat_create_contract(
    offer_id: String,
    loan_amount: f64,
    duration_days: i32,
    borrower_loan_address: Option<String>,
) -> Result<Contract> {
    let lock = get_state_lock();

    let pubkey = {
        let guard = lock.read().await;
        let state = guard.as_ref().ok_or_else(|| anyhow!("Lendasat not initialized"))?;
        auth::get_public_key(&state.data_dir, state.network).await?
    };
    let derivation_path = auth::get_derivation_path();

    // Get Ark address for collateral
    let borrower_btc_address = get_ark_address().await?;

    let guard = lock.read().await;
    let state = guard.as_ref().ok_or_else(|| anyhow!("Lendasat not initialized"))?;

    let headers = get_auth_headers(state).await?;

    let url = format!("{}/api/contracts", state.base_url);

    let request = CreateContractRequest {
        id: offer_id,
        borrower_btc_address,
        borrower_pk: pubkey,
        borrower_derivation_path: derivation_path,
        loan_amount,
        duration_days,
        loan_type: "StableCoin".to_string(),
        borrower_loan_address,
        borrower_npub: None, // TODO: Add nostr pubkey support
        client_contract_id: None,
    };

    let response = state
        .http_client
        .post(&url)
        .headers(headers)
        .json(&request)
        .send()
        .await
        .map_err(|e| anyhow!("Failed to create contract: {}", e))?;

    if !response.status().is_success() {
        let status = response.status();
        let text = response.text().await.unwrap_or_default();
        bail!("Failed to create contract ({}): {}", status, text);
    }

    let contract: Contract = response
        .json()
        .await
        .map_err(|e| anyhow!("Failed to parse contract: {}", e))?;

    tracing::info!("Created contract: {}", contract.id);

    Ok(contract)
}

/// Cancel a requested contract.
pub async fn lendasat_cancel_contract(contract_id: String) -> Result<()> {
    let lock = get_state_lock();
    let guard = lock.read().await;
    let state = guard.as_ref().ok_or_else(|| anyhow!("Lendasat not initialized"))?;

    let headers = get_auth_headers(state).await?;

    let url = format!("{}/api/contracts/{}", state.base_url, contract_id);

    let response = state
        .http_client
        .delete(&url)
        .headers(headers)
        .send()
        .await
        .map_err(|e| anyhow!("Failed to cancel contract: {}", e))?;

    if !response.status().is_success() {
        let status = response.status();
        let text = response.text().await.unwrap_or_default();
        bail!("Failed to cancel contract ({}): {}", status, text);
    }

    tracing::info!("Cancelled contract: {}", contract_id);

    Ok(())
}

// ============================================================================
// Repayment
// ============================================================================

/// Mark an installment as paid.
pub async fn lendasat_mark_installment_paid(
    contract_id: String,
    installment_id: String,
    payment_txid: String,
) -> Result<()> {
    let lock = get_state_lock();
    let guard = lock.read().await;
    let state = guard.as_ref().ok_or_else(|| anyhow!("Lendasat not initialized"))?;

    let headers = get_auth_headers(state).await?;

    let url = format!("{}/api/contracts/{}/installment-paid", state.base_url, contract_id);

    let request = InstallmentPaidRequest {
        installment_id,
        payment_id: payment_txid,
    };

    let response = state
        .http_client
        .put(&url)
        .headers(headers)
        .json(&request)
        .send()
        .await
        .map_err(|e| anyhow!("Failed to mark installment paid: {}", e))?;

    if !response.status().is_success() {
        let status = response.status();
        let text = response.text().await.unwrap_or_default();
        bail!("Failed to mark installment paid ({}): {}", status, text);
    }

    tracing::info!("Marked installment as paid for contract: {}", contract_id);

    Ok(())
}

// ============================================================================
// Claim Collateral
// ============================================================================

/// Get the PSBT for claiming collateral (standard Bitcoin).
pub async fn lendasat_get_claim_psbt(contract_id: String, fee_rate: u32) -> Result<ClaimPsbtResponse> {
    let lock = get_state_lock();
    let guard = lock.read().await;
    let state = guard.as_ref().ok_or_else(|| anyhow!("Lendasat not initialized"))?;

    let headers = get_auth_headers(state).await?;

    let url = format!(
        "{}/api/contracts/{}/claim?fee_rate={}",
        state.base_url, contract_id, fee_rate
    );

    let response = state
        .http_client
        .get(&url)
        .headers(headers)
        .send()
        .await
        .map_err(|e| anyhow!("Failed to get claim PSBT: {}", e))?;

    if !response.status().is_success() {
        let status = response.status();
        let text = response.text().await.unwrap_or_default();
        bail!("Failed to get claim PSBT ({}): {}", status, text);
    }

    let claim_response: ClaimPsbtResponse = response
        .json()
        .await
        .map_err(|e| anyhow!("Failed to parse claim PSBT response: {}", e))?;

    Ok(claim_response)
}

/// Sign a PSBT using the Lendasat wallet keypair.
///
/// This mirrors the iframe wallet-bridge `signPsbt` behavior:
/// - Takes PSBT hex, collateral descriptor, and borrower public key
/// - Verifies borrower_pk matches our wallet's key (warns if mismatch)
/// - Signs all inputs with our keypair
/// - Returns the signed PSBT hex
pub async fn lendasat_sign_psbt(
    psbt_hex: String,
    collateral_descriptor: String,
    borrower_pk: String,
) -> Result<String> {
    let lock = get_state_lock();
    let guard = lock.read().await;
    let state = guard.as_ref().ok_or_else(|| anyhow!("Lendasat not initialized"))?;

    auth::sign_psbt(
        &psbt_hex,
        &collateral_descriptor,
        &borrower_pk,
        &state.data_dir,
        state.network,
    )
    .await
}

/// Broadcast a signed claim transaction.
pub async fn lendasat_broadcast_claim_tx(contract_id: String, signed_tx: String) -> Result<String> {
    let lock = get_state_lock();
    let guard = lock.read().await;
    let state = guard.as_ref().ok_or_else(|| anyhow!("Lendasat not initialized"))?;

    let headers = get_auth_headers(state).await?;

    let url = format!("{}/api/contracts/{}/broadcast-claim", state.base_url, contract_id);

    let request = BroadcastTxRequest { tx: signed_tx };

    let response = state
        .http_client
        .post(&url)
        .headers(headers)
        .json(&request)
        .send()
        .await
        .map_err(|e| anyhow!("Failed to broadcast claim tx: {}", e))?;

    if !response.status().is_success() {
        let status = response.status();
        let text = response.text().await.unwrap_or_default();
        bail!("Failed to broadcast claim tx ({}): {}", status, text);
    }

    let broadcast_response: BroadcastTxResponse = response
        .json()
        .await
        .map_err(|e| anyhow!("Failed to parse broadcast response: {}", e))?;

    tracing::info!("Claim tx broadcast: {}", broadcast_response.txid);

    Ok(broadcast_response.txid)
}

// ============================================================================
// Ark Claim (for Arkade collateral)
// ============================================================================

/// Get the PSBTs for claiming Ark collateral.
pub async fn lendasat_get_claim_ark_psbt(contract_id: String) -> Result<ArkClaimPsbtResponse> {
    let lock = get_state_lock();
    let guard = lock.read().await;
    let state = guard.as_ref().ok_or_else(|| anyhow!("Lendasat not initialized"))?;

    let headers = get_auth_headers(state).await?;

    let url = format!("{}/api/contracts/{}/claim-ark", state.base_url, contract_id);

    let response = state
        .http_client
        .get(&url)
        .headers(headers)
        .send()
        .await
        .map_err(|e| anyhow!("Failed to get Ark claim PSBTs: {}", e))?;

    if !response.status().is_success() {
        let status = response.status();
        let text = response.text().await.unwrap_or_default();
        bail!("Failed to get Ark claim PSBTs ({}): {}", status, text);
    }

    let claim_response: ArkClaimPsbtResponse = response
        .json()
        .await
        .map_err(|e| anyhow!("Failed to parse Ark claim response: {}", e))?;

    Ok(claim_response)
}

/// Broadcast signed Ark claim transactions.
pub async fn lendasat_broadcast_claim_ark_tx(
    contract_id: String,
    signed_ark_psbt: String,
    signed_checkpoint_psbts: Vec<String>,
) -> Result<String> {
    let lock = get_state_lock();
    let guard = lock.read().await;
    let state = guard.as_ref().ok_or_else(|| anyhow!("Lendasat not initialized"))?;

    let headers = get_auth_headers(state).await?;

    let url = format!("{}/api/contracts/{}/broadcast-claim-ark", state.base_url, contract_id);

    let request = BroadcastArkClaimRequest {
        ark_psbt: signed_ark_psbt,
        checkpoint_psbts: signed_checkpoint_psbts,
    };

    let response = state
        .http_client
        .post(&url)
        .headers(headers)
        .json(&request)
        .send()
        .await
        .map_err(|e| anyhow!("Failed to broadcast Ark claim tx: {}", e))?;

    if !response.status().is_success() {
        let status = response.status();
        let text = response.text().await.unwrap_or_default();
        bail!("Failed to broadcast Ark claim tx ({}): {}", status, text);
    }

    let broadcast_response: BroadcastTxResponse = response
        .json()
        .await
        .map_err(|e| anyhow!("Failed to parse broadcast response: {}", e))?;

    tracing::info!("Ark claim tx broadcast: {}", broadcast_response.txid);

    Ok(broadcast_response.txid)
}

// ============================================================================
// Recovery (for expired contracts)
// ============================================================================

/// Get the PSBT for recovering collateral from an expired contract.
pub async fn lendasat_get_recover_psbt(contract_id: String, fee_rate: u32) -> Result<ClaimPsbtResponse> {
    let lock = get_state_lock();
    let guard = lock.read().await;
    let state = guard.as_ref().ok_or_else(|| anyhow!("Lendasat not initialized"))?;

    let headers = get_auth_headers(state).await?;

    let url = format!(
        "{}/api/contracts/{}/recover?fee_rate={}",
        state.base_url, contract_id, fee_rate
    );

    let response = state
        .http_client
        .get(&url)
        .headers(headers)
        .send()
        .await
        .map_err(|e| anyhow!("Failed to get recover PSBT: {}", e))?;

    if !response.status().is_success() {
        let status = response.status();
        let text = response.text().await.unwrap_or_default();
        bail!("Failed to get recover PSBT ({}): {}", status, text);
    }

    let recover_response: ClaimPsbtResponse = response
        .json()
        .await
        .map_err(|e| anyhow!("Failed to parse recover PSBT response: {}", e))?;

    Ok(recover_response)
}

/// Broadcast a signed recovery transaction.
pub async fn lendasat_broadcast_recover_tx(contract_id: String, signed_tx: String) -> Result<String> {
    let lock = get_state_lock();
    let guard = lock.read().await;
    let state = guard.as_ref().ok_or_else(|| anyhow!("Lendasat not initialized"))?;

    let headers = get_auth_headers(state).await?;

    let url = format!("{}/api/contracts/{}/broadcast-recover", state.base_url, contract_id);

    let request = BroadcastTxRequest { tx: signed_tx };

    let response = state
        .http_client
        .post(&url)
        .headers(headers)
        .json(&request)
        .send()
        .await
        .map_err(|e| anyhow!("Failed to broadcast recover tx: {}", e))?;

    if !response.status().is_success() {
        let status = response.status();
        let text = response.text().await.unwrap_or_default();
        bail!("Failed to broadcast recover tx ({}): {}", status, text);
    }

    let broadcast_response: BroadcastTxResponse = response
        .json()
        .await
        .map_err(|e| anyhow!("Failed to parse broadcast response: {}", e))?;

    tracing::info!("Recovery tx broadcast: {}", broadcast_response.txid);

    Ok(broadcast_response.txid)
}

// ============================================================================
// Helpers
// ============================================================================

/// Get the Ark offchain address for collateral deposit.
async fn get_ark_address() -> Result<String> {
    use crate::state::ARK_CLIENT;
    use std::sync::Arc;

    let maybe_client = ARK_CLIENT.try_get();

    match maybe_client {
        None => bail!("Ark client not initialized"),
        Some(client) => {
            let client_arc = {
                let guard = client.read();
                Arc::clone(&*guard)
            };

            let (offchain_address, _vtxo) = client_arc
                .get_offchain_address()
                .map_err(|e| anyhow!("Could not get offchain address: {}", e))?;

            Ok(offchain_address.encode())
        }
    }
}

// ============================================================================
// Flutter-friendly types
// ============================================================================

/// Result of authentication attempt.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum AuthResult {
    Success {
        user_id: String,
        user_name: String,
        user_email: Option<String>,
    },
    NeedsRegistration {
        pubkey: String,
    },
}

/// Simplified contract info for list display.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContractSummary {
    pub id: String,
    pub status: ContractStatus,
    pub loan_amount: f64,
    pub loan_asset: LoanAsset,
    pub collateral_asset: CollateralAsset,
    pub collateral_sats: i64,
    pub interest_rate: f64,
    pub expiry: String,
    pub balance_outstanding: f64,
    pub lender_name: String,
    pub created_at: String,
}

impl From<&Contract> for ContractSummary {
    fn from(c: &Contract) -> Self {
        Self {
            id: c.id.clone(),
            status: c.status,
            loan_amount: c.loan_amount,
            loan_asset: c.loan_asset,
            collateral_asset: c.collateral_asset,
            collateral_sats: c.collateral_sats,
            interest_rate: c.interest_rate,
            expiry: c.expiry.clone(),
            balance_outstanding: c.balance_outstanding,
            lender_name: c.lender.name.clone(),
            created_at: c.created_at.clone(),
        }
    }
}

/// Simplified offer info for list display.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OfferSummary {
    pub id: String,
    pub lender_name: String,
    pub loan_asset: LoanAsset,
    pub collateral_asset: CollateralAsset,
    pub loan_amount_min: f64,
    pub loan_amount_max: f64,
    pub duration_days_min: i32,
    pub duration_days_max: i32,
    pub interest_rate: f64,
    pub min_ltv: f64,
    pub requires_kyc: bool,
}

impl From<&LoanOffer> for OfferSummary {
    fn from(o: &LoanOffer) -> Self {
        Self {
            id: o.id.clone(),
            lender_name: o.lender.name.clone(),
            loan_asset: o.loan_asset,
            collateral_asset: o.collateral_asset,
            loan_amount_min: o.loan_amount_min,
            loan_amount_max: o.loan_amount_max,
            duration_days_min: o.duration_days_min,
            duration_days_max: o.duration_days_max,
            interest_rate: o.interest_rate,
            min_ltv: o.min_ltv,
            requires_kyc: o.kyc_link.is_some(),
        }
    }
}

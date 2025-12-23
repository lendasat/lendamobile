use crate::ark::address_helper::{decode_bip21, is_ark_address, is_bip21, is_btc_address};
use crate::ark::esplora::EsploraClient;
use crate::state::{ARK_CLIENT, ArkClient, ESPLORA_URL};
use anyhow::Result;
use anyhow::{anyhow, bail};
use ark_client::Blockchain;
use ark_client::lightning_invoice::Bolt11Invoice;
use ark_client::{OffChainBalance, SwapAmount};
use ark_core::ArkAddress;
use ark_core::history::Transaction;
use ark_core::server::{Info, SubscriptionResponse};
use bitcoin::{Address, Amount, OutPoint, Txid};
use futures::StreamExt;
use rand::SeedableRng;
use rand::rngs::StdRng;
use std::str::FromStr;
use std::sync::Arc;
use std::time::Duration;

pub struct Balance {
    pub offchain: OffChainBalance,
}

pub async fn balance() -> Result<Balance> {
    let maybe_client = ARK_CLIENT.try_get();

    match maybe_client {
        None => {
            bail!("Ark client not initialized");
        }
        Some(client) => {
            // Clone the Arc<Client> so we can drop the lock guard
            let client_arc = {
                let guard = client.read();
                Arc::clone(&*guard)
            };

            // Auto-settle any confirmed boarding UTXOs before fetching balance
            // This runs silently - failures are logged but don't block balance fetch
            match auto_settle_boarding().await {
                Ok(settled) => {
                    if settled {
                        tracing::info!("Auto-settled boarding UTXOs into Ark");
                    }
                }
                Err(e) => {
                    // Don't fail balance fetch if auto-settle fails
                    tracing::debug!("Auto-settle check: {}", e);
                }
            }

            // Now we can use the cloned Arc safely across await
            let offchain_balance = client_arc
                .offchain_balance()
                .await
                .map_err(|error| anyhow!("Could not fetch balance {error}"))?;

            Ok(Balance {
                // TODO: would be good to also get the on-chain balance here
                offchain: offchain_balance,
            })
        }
    }
}

pub struct BoltzSwap {
    pub swap_id: String,
    pub amount: Amount,
    pub invoice: String,
}

pub struct Addresses {
    pub boarding: Address,
    pub offchain: ArkAddress,
    pub boltz_swap: Option<BoltzSwap>,
}

pub struct PaymentReceived {
    pub txid: Txid,
    pub amount: Amount,
}

pub async fn address(amount: Option<Amount>) -> Result<Addresses> {
    let maybe_client = ARK_CLIENT.try_get();

    match maybe_client {
        None => {
            bail!("Ark client not initialized");
        }
        Some(client) => {
            // Clone the Arc<Client> so we can drop the lock guard
            let client = {
                let guard = client.read();
                Arc::clone(&*guard)
            };
            let boarding_address = client
                .get_boarding_address()
                .map_err(|error| anyhow!("Could not get boarding address {error:#}"))?;

            let (offchain_address, _vtxo) = client
                .get_offchain_address()
                .map_err(|error| anyhow!("Could not get offchain address {error:#}"))?;

            // Try to get Lightning invoice, but don't fail if Boltz is unavailable
            let reverse_swap_result = match amount {
                None => None,
                Some(amount) => {
                    match client
                        .get_ln_invoice(SwapAmount::Invoice(amount), Some(300))
                        .await
                    {
                        Ok(swap) => Some(swap),
                        Err(e) => {
                            tracing::warn!(
                                "Failed to create Lightning invoice (Boltz may be unavailable): {e:#}"
                            );
                            None
                        }
                    }
                }
            };

            Ok(Addresses {
                boarding: boarding_address,
                offchain: offchain_address,
                boltz_swap: reverse_swap_result.map(|s| BoltzSwap {
                    swap_id: s.swap_id,
                    amount: s.amount,
                    invoice: s.invoice.to_string(),
                }),
            })
        }
    }
}

pub async fn tx_history() -> Result<Vec<Transaction>> {
    let maybe_client = ARK_CLIENT.try_get();

    match maybe_client {
        None => {
            bail!("Ark client not initialized");
        }
        Some(client) => {
            // Clone the Arc<Client> so we can drop the lock guard
            let client = {
                let guard = client.read();
                Arc::clone(&*guard)
            };

            let mut txs = client
                .transaction_history()
                .await
                .map_err(|error| anyhow!("Failed getting transaction history {error:#}"))?;

            // sort desc, i.e. newest transactions first
            txs.sort_by_key(|b| std::cmp::Reverse(b.created_at()));
            Ok(txs)
        }
    }
}

pub async fn send(address: String, amount: Amount) -> Result<Txid> {
    let maybe_client = ARK_CLIENT.try_get();

    match maybe_client {
        None => {
            bail!("Ark client not initialized");
        }
        Some(client) => {
            let client = {
                let guard = client.read();
                Arc::clone(&*guard)
            };

            if is_bip21(address.as_str()) {
                let uri = decode_bip21(address.as_str())?;
                let amount = uri.amount.unwrap_or(amount);

                if let Some(address) = uri.btc_address {
                    // TODO: there seems to be a bug sending on-chain
                    let txid = client
                        .send_on_chain(address.assume_checked(), amount)
                        .await
                        .map_err(|e| anyhow!("Failed sending onchain {e:#}"))?;
                    Ok(txid)
                } else if let Some(address) = uri.ark_address {
                    let txid = client
                        .send_vtxo(address, amount)
                        .await
                        .map_err(|e| anyhow!("Failed sending offchain {e:#}"))?;
                    Ok(txid)
                } else {
                    bail!("Unknown bip21 format. We only support bitcoin: and ark: addresses");
                }
            } else if is_ark_address(address.as_str()) {
                let address = ArkAddress::decode(address.as_str())?;
                let txid = client
                    .send_vtxo(address, amount)
                    .await
                    .map_err(|e| anyhow!("Failed sending offchain {e:#}"))?;
                Ok(txid)
            } else if is_btc_address(address.as_str()) {
                let address = Address::from_str(address.as_str())?;
                let rng = &mut StdRng::from_entropy();

                // Select VTXOs like Arkade wallet does - sorted by expiry (soonest first)
                // This ensures we use VTXOs that expire soonest, leaving fresh ones available
                let vtxo_outpoints = select_vtxos_for_amount(&client, amount).await?;

                // Use the new method with specific VTXOs
                let txid = client
                    .collaborative_redeem_with_vtxos(
                        rng,
                        &vtxo_outpoints,
                        address.assume_checked(),
                        amount,
                    )
                    .await
                    .map_err(|e| anyhow!("Failed sending onchain {e:#}"))?;
                Ok(txid)
            } else {
                bail!("Address format not supported")
            }
        }
    }
}

pub async fn settle() -> Result<()> {
    let maybe_client = ARK_CLIENT.try_get();

    match maybe_client {
        None => {
            bail!("Ark client not initialized");
        }
        Some(client) => {
            let client = {
                let guard = client.read();
                Arc::clone(&*guard)
            };
            let mut rng = StdRng::from_entropy();
            client
                .settle(&mut rng)
                .await
                .map_err(|e| anyhow!("Failed settling {e:#}"))?;
        }
    }

    Ok(())
}

/// Select VTXOs for an onchain send, sorted by expiry (soonest first).
/// This matches Arkade wallet behavior and ensures we use VTXOs expiring soonest first.
///
/// The ASP requires VTXOs to have a minimum expiry gap (typically ~30 days / 696 hours).
/// We filter out VTXOs that don't meet this requirement, then sort by expiry ascending
/// to use up VTXOs expiring soonest first (leaving fresher ones for later).
async fn select_vtxos_for_amount(client: &ArkClient, amount: Amount) -> Result<Vec<OutPoint>> {
    // Get all VTXOs
    let (vtxo_list, _) = client
        .list_vtxos()
        .await
        .map_err(|e| anyhow!("Failed to list VTXOs: {e}"))?;

    // ASP's minExpiryGap is ~696 hours (~29 days). Add a small buffer.
    // VTXOs must have at least this much time remaining to be accepted.
    const MIN_EXPIRY_GAP_SECONDS: i64 = 30 * 24 * 60 * 60; // 30 days in seconds
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map_err(|e| anyhow!("System time is before Unix epoch: {e}"))?
        .as_secs() as i64;
    let min_expiry_time = now + MIN_EXPIRY_GAP_SECONDS;

    // Get spendable VTXOs and filter to only those with enough remaining time
    let mut vtxos: Vec<_> = vtxo_list
        .spendable_offchain()
        .filter(|v| v.expires_at > min_expiry_time)
        .collect();

    let total_eligible: Amount = vtxos.iter().map(|v| v.amount).sum();

    if total_eligible < amount {
        // Not enough eligible VTXOs - check if settling would help
        let total_all: Amount = vtxo_list.spendable_offchain().map(|v| v.amount).sum();
        if total_all >= amount {
            bail!(
                "VTXOs are too close to expiry for onchain send. Please settle your balance first to refresh them. \
                 (Need {} sats, have {} eligible, {} total)",
                amount.to_sat(),
                total_eligible.to_sat(),
                total_all.to_sat()
            );
        } else {
            bail!(
                "Insufficient VTXOs for onchain send: need {}, have {}",
                amount,
                total_all
            );
        }
    }

    // Sort by expiry ascending (soonest first) - like Arkade wallet
    // This uses up older VTXOs first, preserving fresher ones
    vtxos.sort_by_key(|v| v.expires_at);

    // Select VTXOs to cover the amount
    let mut selected = Vec::new();
    let mut selected_amount = Amount::ZERO;

    for vtxo in vtxos {
        if selected_amount >= amount {
            break;
        }
        selected.push(vtxo.outpoint);
        selected_amount += vtxo.amount;

        tracing::debug!(
            outpoint = %vtxo.outpoint,
            amount = %vtxo.amount,
            expires_at = vtxo.expires_at,
            "Selected VTXO for onchain send"
        );
    }

    tracing::info!(
        vtxos_selected = selected.len(),
        total_selected = %selected_amount,
        requested = %amount,
        "Selected VTXOs for onchain send"
    );

    Ok(selected)
}

/// Represents a pending boarding UTXO (on-chain funds waiting to be settled)
pub struct BoardingUtxo {
    pub txid: String,
    pub vout: u32,
    pub amount: Amount,
    pub is_confirmed: bool,
}

/// Get pending boarding UTXOs (on-chain funds at the boarding address that haven't been settled yet)
pub async fn get_boarding_utxos() -> Result<Vec<BoardingUtxo>> {
    let maybe_client = ARK_CLIENT.try_get();

    match maybe_client {
        None => {
            bail!("Ark client not initialized");
        }
        Some(client) => {
            let client = {
                let guard = client.read();
                Arc::clone(&*guard)
            };

            // Get the stored esplora URL to create a separate esplora client
            let esplora_url = ESPLORA_URL
                .try_get()
                .ok_or_else(|| anyhow!("Esplora URL not initialized"))?
                .read()
                .clone();

            let esplora = EsploraClient::new(&esplora_url)
                .map_err(|e| anyhow!("Could not create esplora client: {e:#}"))?;

            // Get all boarding addresses
            let boarding_addresses = client
                .get_boarding_addresses()
                .map_err(|e| anyhow!("Could not get boarding addresses: {e:#}"))?;

            let mut utxos = Vec::new();

            // Query esplora for UTXOs at each boarding address
            for address in boarding_addresses {
                let address_utxos = esplora
                    .find_outpoints(&address)
                    .await
                    .map_err(|e| anyhow!("Could not find outpoints: {e:#}"))?;

                for utxo in address_utxos {
                    utxos.push(BoardingUtxo {
                        txid: utxo.outpoint.txid.to_string(),
                        vout: utxo.outpoint.vout,
                        amount: utxo.amount,
                        is_confirmed: utxo.confirmation_blocktime.is_some(),
                    });
                }
            }

            tracing::info!(
                "Found {} boarding UTXOs with total {} sats",
                utxos.len(),
                utxos.iter().map(|u| u.amount.to_sat()).sum::<u64>()
            );

            Ok(utxos)
        }
    }
}

/// Get the total pending balance (on-chain funds waiting to be settled)
pub async fn get_pending_balance() -> Result<Amount> {
    let utxos = get_boarding_utxos().await?;
    let total = utxos.iter().map(|u| u.amount).sum();
    Ok(total)
}

/// Auto-settle confirmed boarding UTXOs silently.
/// Returns Ok(true) if settled, Ok(false) if nothing to settle.
async fn auto_settle_boarding() -> Result<bool> {
    let maybe_client = ARK_CLIENT.try_get();

    match maybe_client {
        None => bail!("Ark client not initialized"),
        Some(client) => {
            let client = {
                let guard = client.read();
                Arc::clone(&*guard)
            };

            let esplora_url = ESPLORA_URL
                .try_get()
                .ok_or_else(|| anyhow!("Esplora URL not initialized"))?
                .read()
                .clone();

            let esplora = EsploraClient::new(&esplora_url)
                .map_err(|e| anyhow!("Could not create esplora client: {e:#}"))?;

            let boarding_addresses = client
                .get_boarding_addresses()
                .map_err(|e| anyhow!("Could not get boarding addresses: {e:#}"))?;

            let mut boarding_outpoints = Vec::new();

            for address in boarding_addresses {
                let address_utxos = esplora
                    .find_outpoints(&address)
                    .await
                    .map_err(|e| anyhow!("Could not find outpoints: {e:#}"))?;

                for utxo in address_utxos {
                    if utxo.confirmation_blocktime.is_some() {
                        boarding_outpoints.push(utxo.outpoint);
                    }
                }
            }

            if boarding_outpoints.is_empty() {
                return Ok(false);
            }

            tracing::info!("Auto-settling {} boarding UTXOs", boarding_outpoints.len());

            let mut rng = StdRng::from_entropy();
            client
                .settle_vtxos(&mut rng, &[], &boarding_outpoints)
                .await
                .map_err(|e| anyhow!("Failed auto-settling: {e:#}"))?;

            Ok(true)
        }
    }
}

/// Settle only boarding UTXOs (on-chain funds) into the Ark protocol.
/// This method settles ONLY the confirmed boarding UTXOs without including
/// any existing VTXOs, avoiding the minExpiryGap rejection from the server.
pub async fn settle_boarding() -> Result<()> {
    let maybe_client = ARK_CLIENT.try_get();

    match maybe_client {
        None => {
            bail!("Ark client not initialized");
        }
        Some(client) => {
            let client = {
                let guard = client.read();
                Arc::clone(&*guard)
            };

            // Get the stored esplora URL
            let esplora_url = ESPLORA_URL
                .try_get()
                .ok_or_else(|| anyhow!("Esplora URL not initialized"))?
                .read()
                .clone();

            let esplora = EsploraClient::new(&esplora_url)
                .map_err(|e| anyhow!("Could not create esplora client: {e:#}"))?;

            // Get all boarding addresses
            let boarding_addresses = client
                .get_boarding_addresses()
                .map_err(|e| anyhow!("Could not get boarding addresses: {e:#}"))?;

            let mut boarding_outpoints = Vec::new();

            // Query esplora for confirmed UTXOs at each boarding address
            for address in boarding_addresses {
                let address_utxos = esplora
                    .find_outpoints(&address)
                    .await
                    .map_err(|e| anyhow!("Could not find outpoints: {e:#}"))?;

                for utxo in address_utxos {
                    // Only include confirmed UTXOs
                    if utxo.confirmation_blocktime.is_some() {
                        boarding_outpoints.push(utxo.outpoint);
                    }
                }
            }

            if boarding_outpoints.is_empty() {
                bail!("No confirmed boarding UTXOs to settle");
            }

            tracing::info!(
                "Settling {} confirmed boarding UTXOs",
                boarding_outpoints.len()
            );

            let mut rng = StdRng::from_entropy();

            // Call settle_vtxos with empty vtxo_outpoints and the boarding outpoints
            // This ensures we only settle boarding UTXOs, not any existing VTXOs
            client
                .settle_vtxos(
                    &mut rng,
                    &[],                 // No VTXOs - this is the key!
                    &boarding_outpoints, // Only boarding UTXOs
                )
                .await
                .map_err(|e| anyhow!("Failed settling boarding UTXOs: {e:#}"))?;

            tracing::info!("Successfully settled boarding UTXOs");
        }
    }

    Ok(())
}

/// Result of paying a Lightning invoice via submarine swap
pub struct LnPaymentResult {
    pub swap_id: String,
    pub txid: Txid,
    pub amount: Amount,
}

/// Pay a Lightning invoice using Ark funds via Boltz submarine swap
pub async fn pay_ln_invoice(invoice: String) -> Result<LnPaymentResult> {
    let maybe_client = ARK_CLIENT.try_get();

    match maybe_client {
        None => {
            bail!("Ark client not initialized");
        }
        Some(client) => {
            let client = {
                let guard = client.read();
                Arc::clone(&*guard)
            };

            // Parse the BOLT11 invoice
            let bolt11: Bolt11Invoice = invoice
                .parse()
                .map_err(|e| anyhow!("Invalid BOLT11 invoice: {e}"))?;

            tracing::info!(
                "Paying Lightning invoice for {} msats",
                bolt11.amount_milli_satoshis().unwrap_or(0)
            );

            // Pay the invoice via submarine swap
            let result = client
                .pay_ln_invoice(bolt11)
                .await
                .map_err(|e| anyhow!("Failed to pay Lightning invoice: {e:#}"))?;

            tracing::info!(
                "Lightning payment successful! Swap ID: {}, TXID: {}",
                result.swap_id,
                result.txid
            );

            Ok(LnPaymentResult {
                swap_id: result.swap_id,
                txid: result.txid,
                amount: result.amount,
            })
        }
    }
}

pub(crate) async fn wait_for_payment(
    ark_address: Option<ArkAddress>,
    _boarding_address: Option<Address>,
    boltz_swap_id: Option<String>,
    timeout_seconds: u64,
) -> Result<PaymentReceived> {
    let maybe_client = ARK_CLIENT.try_get();
    match maybe_client {
        None => {
            bail!("Ark client not initialized")
        }
        Some(client) => {
            let client = {
                let guard = client.read();
                Arc::clone(&*guard)
            };

            let timeout_duration = Duration::from_secs(timeout_seconds);

            // Race between ark address subscription, lightning invoice, and timeout
            tokio::select! {
                // Monitor ark_address subscription if provided
                result = async {
                    if let Some(address) = ark_address {
                        monitor_ark_address(&client, address).await
                    } else {
                        // If no ark address, wait forever (will be cancelled by other branches)
                        futures::future::pending().await
                    }
                } => result,

                // Monitor lightning invoice payment if provided
                result = async {
                    if let Some(swap_id) = boltz_swap_id {
                        monitor_lightning_payment(&client, swap_id).await
                    } else {
                        // If no swap id, wait forever (will be cancelled by other branches)
                        futures::future::pending().await
                    }
                } => result,

                // Timeout
                _ = tokio::time::sleep(timeout_duration) => {
                    bail!("Payment waiting timed out after {} seconds", timeout_seconds)
                }
            }
        }
    }
}

async fn monitor_ark_address(
    client: &Arc<ArkClient>,
    address: ArkAddress,
) -> Result<PaymentReceived> {
    tracing::info!("Subscribing to ark address: {}", address.encode());

    // Subscribe to the address to get notifications
    let subscription_id = client
        .subscribe_to_scripts(vec![address], None)
        .await
        .map_err(|e| anyhow!("Failed to subscribe to address: {e}"))?;

    tracing::info!("Subscription ID: {subscription_id}");

    // Get the subscription stream
    let mut subscription_stream = client
        .get_subscription(subscription_id)
        .await
        .map_err(|e| anyhow!("Failed to get subscription stream: {e}"))?;

    tracing::info!("Listening for ark address notifications...");

    // Process subscription responses as they come in
    while let Some(result) = subscription_stream.next().await {
        match result {
            Ok(SubscriptionResponse::Event(e)) => {
                if let Some(psbt) = e.tx {
                    let tx = &psbt.unsigned_tx;
                    let txid = tx.compute_txid();

                    // Find the output that matches our address
                    let output = tx.output.iter().find_map(|out| {
                        if out.script_pubkey == address.to_p2tr_script_pubkey() {
                            Some(out.clone())
                        } else {
                            None
                        }
                    });

                    if let Some(output) = output {
                        tracing::info!("Payment received on ark address!");
                        tracing::info!("  TXID: {}", txid);
                        tracing::info!("  Amount: {:?}", output.value);

                        return Ok(PaymentReceived {
                            txid,
                            amount: output.value,
                        });
                    } else {
                        tracing::warn!(
                            "Received subscription response did not include our address"
                        );
                    }
                } else {
                    tracing::warn!("No tx found in subscription event");
                }
            }
            Ok(SubscriptionResponse::Heartbeat) => {
                // Ignore heartbeats
            }
            Err(e) => {
                bail!("Error receiving subscription response: {e}");
            }
        }
    }

    bail!("Subscription stream ended unexpectedly")
}

async fn monitor_lightning_payment(
    client: &Arc<ArkClient>,
    swap_id: String,
) -> Result<PaymentReceived> {
    tracing::info!("Waiting for lightning invoice payment: {}", swap_id);

    let claim_result = client
        .wait_for_vhtlc(swap_id.as_str())
        .await
        .map_err(|e| anyhow!("Failed waiting for invoice payment: {e}"))?;

    tracing::info!(
        "Lightning invoice paid and claimed! TXID: {}, Amount: {}",
        claim_result.claim_txid,
        claim_result.claim_amount
    );

    Ok(PaymentReceived {
        txid: claim_result.claim_txid,
        amount: claim_result.claim_amount,
    })
}

pub(crate) fn info() -> Result<Info> {
    let maybe_client = ARK_CLIENT.try_get();

    match maybe_client {
        None => {
            bail!("Ark client not initialized")
        }
        Some(client) => {
            let client = {
                let guard = client.read();
                Arc::clone(&*guard)
            };
            let info = client.server_info.clone();
            Ok(info)
        }
    }
}

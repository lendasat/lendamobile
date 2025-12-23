use anyhow::Result;
use bitcoin::Network;
use nostr::ToBech32;
use std::str::FromStr;

pub async fn wallet_exists(data_dir: String) -> Result<bool> {
    crate::ark::wallet_exists(data_dir).await
}

/// Setup a new wallet with a freshly generated 12-word mnemonic.
/// Returns the mnemonic words that the user MUST back up securely.
pub async fn setup_new_wallet(
    data_dir: String,
    network: String,
    esplora: String,
    server: String,
    boltz_url: String,
) -> Result<String> {
    let network = Network::from_str(network.as_str())?;
    crate::ark::setup_new_wallet(data_dir, network, esplora, server, boltz_url).await
}

pub async fn load_existing_wallet(
    data_dir: String,
    network: String,
    esplora: String,
    server: String,
    boltz_url: String,
) -> Result<String> {
    let network = Network::from_str(network.as_str())?;
    crate::ark::load_existing_wallet(data_dir, network, esplora, server, boltz_url).await
}

/// Restore a wallet from a mnemonic phrase (12 or 24 words)
pub async fn restore_wallet(
    mnemonic_words: String,
    data_dir: String,
    network: String,
    esplora: String,
    server: String,
    boltz_url: String,
) -> Result<String> {
    let network = Network::from_str(network.as_str())?;
    crate::ark::restore_wallet(
        mnemonic_words,
        data_dir,
        network,
        esplora,
        server,
        boltz_url,
    )
    .await
}

pub struct Balance {
    pub offchain: OffchainBalance,
}

pub struct OffchainBalance {
    pub pending_sats: u64,
    pub confirmed_sats: u64,
    pub total_sats: u64,
}

pub async fn balance() -> Result<Balance> {
    let balance = crate::ark::client::balance().await?;
    Ok(Balance {
        offchain: OffchainBalance {
            pending_sats: balance.offchain.pre_confirmed().to_sat(),
            confirmed_sats: balance.offchain.confirmed().to_sat(),
            total_sats: balance.offchain.total().to_sat(),
        },
    })
}

#[derive(Debug, Clone)]
pub struct Addresses {
    pub boarding: String,
    pub offchain: String,
    pub bip21: String,
    pub lightning: Option<BoltzSwap>,
}

#[derive(Debug, Clone)]
pub struct BoltzSwap {
    pub swap_id: String,
    pub amount_sats: u64,
    pub invoice: String,
}

pub async fn address(amount: Option<u64>) -> Result<Addresses> {
    let addresses = crate::ark::client::address(amount.map(bitcoin::Amount::from_sat)).await?;

    let boarding = addresses.boarding.to_string();
    let offchain = addresses.offchain.encode();
    let lightning = addresses.boltz_swap;
    // BIP21 requires amount in BTC, not satoshis
    let amount = match amount {
        None => "".to_string(),
        Some(sats) => {
            let btc = sats as f64 / 100_000_000.0;
            // Format with up to 8 decimal places, removing trailing zeros
            let btc_str = format!("{:.8}", btc)
                .trim_end_matches('0')
                .trim_end_matches('.')
                .to_string();
            format!("&amount={}", btc_str)
        }
    };

    let lightning_invoice = match &lightning {
        None => "".to_string(),
        Some(lightning) => {
            format!("&lightning={}", lightning.invoice)
        }
    };

    // Use 'ark=' for compatibility with lendasat/wallet
    let bip21 = format!("bitcoin:{boarding}?ark={offchain}{lightning_invoice}{amount}",);
    Ok(Addresses {
        boarding,
        offchain,
        lightning: lightning.map(|lightning| BoltzSwap {
            swap_id: lightning.swap_id,
            amount_sats: lightning.amount.to_sat(),
            invoice: lightning.invoice,
        }),
        bip21,
    })
}

pub enum Transaction {
    Boarding {
        txid: String,
        amount_sats: u64,
        confirmed_at: Option<i64>,
    },
    Round {
        txid: String,
        amount_sats: i64,
        created_at: i64,
    },
    Redeem {
        txid: String,
        amount_sats: i64,
        is_settled: bool,
        created_at: i64,
    },
    /// On-chain send (collaborative redeem) - funds sent from Ark to on-chain address
    Offboard {
        txid: String,
        amount_sats: i64,
        confirmed_at: Option<i64>,
    },
}

pub async fn tx_history() -> Result<Vec<Transaction>> {
    let vec = crate::ark::client::tx_history().await?;
    let txs = vec
        .into_iter()
        .map(|tx| match tx {
            ark_core::history::Transaction::Boarding {
                txid,
                amount,
                confirmed_at,
            } => {
                tracing::debug!("TX HISTORY: Boarding tx {}", txid);
                Transaction::Boarding {
                    txid: txid.to_string(),
                    amount_sats: amount.to_sat(),
                    confirmed_at,
                }
            }
            ark_core::history::Transaction::Commitment {
                txid,
                amount,
                created_at,
            } => {
                tracing::debug!("TX HISTORY: Commitment/Round tx {}", txid);
                Transaction::Round {
                    txid: txid.to_string(),
                    amount_sats: amount.to_sat(),
                    created_at,
                }
            }
            ark_core::history::Transaction::Ark {
                txid,
                amount,
                is_settled,
                created_at,
            } => {
                tracing::debug!("TX HISTORY: Ark/Redeem tx {}", txid);
                Transaction::Redeem {
                    txid: txid.to_string(),
                    amount_sats: amount.to_sat(),
                    is_settled,
                    created_at,
                }
            }
            ark_core::history::Transaction::Offboard {
                commitment_txid,
                amount,
                confirmed_at,
            } => {
                tracing::debug!("TX HISTORY: Offboard/On-chain send tx {}", commitment_txid);
                Transaction::Offboard {
                    txid: commitment_txid.to_string(),
                    // Offboard is always outgoing, so make amount negative
                    amount_sats: -(amount.to_sat() as i64),
                    confirmed_at,
                }
            }
        })
        .collect();

    Ok(txs)
}

pub async fn send(address: String, amount_sats: u64) -> Result<String> {
    let amount = bitcoin::Amount::from_sat(amount_sats);
    let txid = crate::ark::client::send(address, amount).await?;
    Ok(txid.to_string())
}

/// Result of paying a Lightning invoice
pub struct LnPaymentResult {
    pub swap_id: String,
    pub txid: String,
    pub amount_sats: u64,
}

/// Pay a BOLT11 Lightning invoice using Ark funds via Boltz submarine swap
pub async fn pay_ln_invoice(invoice: String) -> Result<LnPaymentResult> {
    let result = crate::ark::client::pay_ln_invoice(invoice).await?;
    Ok(LnPaymentResult {
        swap_id: result.swap_id,
        txid: result.txid.to_string(),
        amount_sats: result.amount.to_sat(),
    })
}

pub async fn settle() -> Result<()> {
    crate::ark::client::settle().await?;
    Ok(())
}

/// Represents a pending boarding UTXO (on-chain funds waiting to be settled)
pub struct BoardingUtxo {
    pub txid: String,
    pub vout: u32,
    pub amount_sats: u64,
    pub is_confirmed: bool,
}

/// Get pending boarding UTXOs (on-chain funds at the boarding address that haven't been settled yet)
pub async fn get_boarding_utxos() -> Result<Vec<BoardingUtxo>> {
    let utxos = crate::ark::client::get_boarding_utxos().await?;
    Ok(utxos
        .into_iter()
        .map(|u| BoardingUtxo {
            txid: u.txid,
            vout: u.vout,
            amount_sats: u.amount.to_sat(),
            is_confirmed: u.is_confirmed,
        })
        .collect())
}

/// Get the total pending balance in sats (on-chain funds waiting to be settled)
pub async fn get_pending_balance() -> Result<u64> {
    let amount = crate::ark::client::get_pending_balance().await?;
    Ok(amount.to_sat())
}

/// Settle only boarding UTXOs (on-chain funds) into the Ark protocol.
/// This method settles ONLY the confirmed boarding UTXOs without including
/// any existing VTXOs, avoiding the minExpiryGap rejection from the server.
/// Use this for completing on-chain boarding when you have existing Ark balance.
pub async fn settle_boarding() -> Result<()> {
    crate::ark::client::settle_boarding().await?;
    Ok(())
}

/// Get the Nostr secret key (nsec) derived from the wallet mnemonic
/// Note: Nostr keys are network-independent, so we use Bitcoin mainnet for derivation
pub async fn nsec(data_dir: String) -> Result<String> {
    // Nostr keys are not network-specific, but we need a network for xpriv derivation
    // Using mainnet as the standard (the derived key will be the same regardless)
    let nsec = crate::ark::nsec(data_dir, Network::Bitcoin).await?;
    Ok(nsec.to_bech32()?)
}

/// Get the Nostr public key (npub) derived from the wallet mnemonic
/// Note: Nostr keys are network-independent, so we use Bitcoin mainnet for derivation
///
/// This is the CANONICAL USER IDENTIFIER used for:
/// - PostHog analytics user identification
/// - Cross-service user correlation
/// - Any feature requiring a consistent user ID
///
/// Returns the public key in bech32 format (npub1...)
pub async fn npub(data_dir: String) -> Result<String> {
    // Nostr keys are not network-specific, but we need a network for xpriv derivation
    // Using mainnet as the standard (the derived key will be the same regardless)
    let npub = crate::ark::npub(data_dir, Network::Bitcoin).await?;
    Ok(npub.to_bech32()?)
}

/// Get the mnemonic words for backup (only available for HD wallets)
pub fn get_mnemonic(data_dir: String) -> Result<String> {
    crate::ark::get_mnemonic(data_dir)
}

pub async fn reset_wallet(data_dir: String) -> Result<()> {
    // First, reset all cached clients to ensure fresh state on next init
    // This is critical for cases where the app doesn't fully restart after reset
    crate::lendaswap::reset_client().await;
    crate::api::lendasat_api::reset_lendasat_state().await;
    tracing::info!("All client caches cleared");

    // Then delete the wallet files
    crate::ark::delete_wallet(data_dir)
}

pub struct Info {
    pub server_pk: String,
    pub network: String,
}

/// Sign a PSBT using the Ark client's identity (key provider).
///
/// This is used for signing Ark VTXO claims where the collateral is locked
/// to the Ark identity, not the Lendasat keypair.
///
/// The function extracts the required public key from the PSBT's taproot
/// internal key and uses the Ark key provider to find the matching keypair.
///
/// IMPORTANT: For this to work, the LendaSat contract must have been created
/// with the Ark identity public key as `borrower_pk`. If a different key was used
/// (e.g., Lendasat derivation path key), the tap_internal_key won't match and
/// signing will fail with "No tap_internal_key found" or "Could not find keypair".
pub async fn sign_psbt_with_ark_identity(psbt_hex: String) -> Result<String> {
    use crate::state::ARK_CLIENT;
    use bitcoin::psbt::Psbt;
    use bitcoin::secp256k1::Secp256k1;
    use bitcoin::sighash::{Prevouts, SighashCache, TapSighashType};
    use bitcoin::taproot::Signature as TapSignature;
    use std::sync::Arc;

    // Parse PSBT from hex
    let psbt_bytes =
        hex::decode(&psbt_hex).map_err(|e| anyhow::anyhow!("Invalid PSBT hex: {}", e))?;
    let mut psbt = Psbt::deserialize(&psbt_bytes)
        .map_err(|e| anyhow::anyhow!("Failed to parse PSBT: {}", e))?;

    tracing::info!(
        "Signing Ark PSBT with {} inputs using Ark identity",
        psbt.inputs.len()
    );

    // Get the Ark client
    let maybe_client = ARK_CLIENT.try_get();
    let client_arc = match maybe_client {
        None => anyhow::bail!("Ark client not initialized"),
        Some(client) => {
            let guard = client.read();
            Arc::clone(&*guard)
        }
    };

    let secp = Secp256k1::new();

    // Log our available keys for debugging
    // This helps identify if the contract was created with the right key
    if let Ok(ark_identity_pk) = crate::api::lendasat_api::get_ark_identity_pubkey().await {
        tracing::info!(
            "OUR ARK IDENTITY PUBKEY (should match contract's borrower_pk): {}",
            ark_identity_pk
        );
    }
    // Also log the Lendasat key for comparison
    if let Ok(lendasat_pk) = crate::api::lendasat_api::lendasat_get_public_key().await {
        tracing::info!(
            "OUR LENDASAT PUBKEY (old/wrong key - should NOT match): {}",
            lendasat_pk
        );
    }

    // Collect all witness UTXOs for prevouts calculation
    let prevouts: Vec<_> = psbt
        .inputs
        .iter()
        .map(|i| {
            i.witness_utxo
                .clone()
                .ok_or_else(|| anyhow::anyhow!("Missing witness UTXO"))
        })
        .collect::<Result<Vec<_>>>()?;

    let mut signed_count = 0;
    let mut failed_count = 0;

    // Sign each input using the Ark key provider
    for (idx, input) in psbt.inputs.iter_mut().enumerate() {
        // Debug: Log all available PSBT input info
        tracing::debug!(
            "Input {}: tap_internal_key={:?}, tap_key_origins={} entries, partial_sigs={} entries",
            idx,
            input.tap_internal_key,
            input.tap_key_origins.len(),
            input.partial_sigs.len()
        );

        // Log tap_key_origins for debugging (may contain the key if tap_internal_key is missing)
        if !input.tap_key_origins.is_empty() {
            for (pk, (_, derivation)) in &input.tap_key_origins {
                tracing::debug!(
                    "Input {}: tap_key_origins entry: pk={}, path={:?}",
                    idx,
                    pk,
                    derivation
                );
            }
        }

        // Try to find the taproot internal key from the PSBT input
        // First try tap_internal_key, then fall back to tap_key_origins
        let tap_key_to_use = input.tap_internal_key.or_else(|| {
            // Fallback: try to get key from tap_key_origins (first entry)
            if let Some(pk) = input.tap_key_origins.keys().next() {
                tracing::info!(
                    "Input {}: No tap_internal_key, using first tap_key_origins entry: {}",
                    idx,
                    pk
                );
                Some(*pk)
            } else {
                None
            }
        });

        if let Some(tap_internal_key) = tap_key_to_use {
            tracing::info!("Input {}: PSBT tap_internal_key: {}", idx, tap_internal_key);

            // Use the Ark key provider to get the keypair for this public key
            // The key provider will find the keypair if it was derived from our HD wallet
            match client_arc.get_keypair_for_pk(&tap_internal_key) {
                Ok(keypair) => {
                    tracing::info!("Input {}: Found matching keypair in Ark key provider", idx);

                    // Get sighash type
                    let sighash_type = input
                        .sighash_type
                        .map(|t| t.taproot_hash_ty())
                        .transpose()
                        .map_err(|e| anyhow::anyhow!("Invalid sighash type: {}", e))?
                        .unwrap_or(TapSighashType::Default);

                    // Calculate sighash
                    let mut sighash_cache = SighashCache::new(&psbt.unsigned_tx);
                    let sighash = sighash_cache
                        .taproot_key_spend_signature_hash(
                            idx,
                            &Prevouts::All(&prevouts),
                            sighash_type,
                        )
                        .map_err(|e| anyhow::anyhow!("Failed to compute sighash: {}", e))?;

                    // Sign with schnorr
                    let msg = bitcoin::secp256k1::Message::from_digest_slice(&sighash[..])
                        .map_err(|e| anyhow::anyhow!("Failed to create message: {}", e))?;
                    let signature = secp.sign_schnorr_no_aux_rand(&msg, &keypair);

                    // Store the taproot key signature
                    input.tap_key_sig = Some(TapSignature {
                        signature,
                        sighash_type,
                    });

                    tracing::info!("Input {}: Successfully signed with Ark identity", idx);
                    signed_count += 1;
                }
                Err(e) => {
                    tracing::error!(
                        "Input {}: FAILED - Could not find keypair for tap_internal_key {}: {}",
                        idx,
                        tap_internal_key,
                        e
                    );
                    tracing::error!(
                        "Input {}: This likely means the contract was created with a different borrower_pk than our Ark identity",
                        idx
                    );
                    failed_count += 1;
                }
            }
        } else {
            tracing::warn!(
                "Input {}: No tap_internal_key found in PSBT. Cannot sign this input.",
                idx
            );
            tracing::warn!(
                "Input {}: This may indicate the PSBT was created for a different key type or the server didn't set tap_internal_key",
                idx
            );
            failed_count += 1;
        }
    }

    // Summary logging
    tracing::info!(
        "Ark PSBT signing complete: {} inputs signed, {} inputs failed",
        signed_count,
        failed_count
    );

    if signed_count == 0 && !psbt.inputs.is_empty() {
        tracing::error!("FATAL: No inputs were signed! The claim transaction cannot be broadcast.");
        tracing::error!(
            "This usually means the contract's borrower_pk doesn't match our Ark identity."
        );
        tracing::error!(
            "If this is an old contract created before the key fix, it cannot be claimed from this wallet."
        );
        tracing::error!("Contact LendaSat support for assistance with old contracts.");
        anyhow::bail!(
            "Failed to sign PSBT: No inputs could be signed. \
            This contract may have been created with a different key. \
            Old contracts created before the key fix cannot be claimed. \
            Please contact LendaSat support."
        );
    }

    // Serialize the signed PSBT back to hex
    let signed_psbt_bytes = psbt.serialize();
    let signed_psbt_hex = hex::encode(signed_psbt_bytes);

    tracing::info!(
        "Ark PSBT signed successfully (signed {}/{} inputs)",
        signed_count,
        psbt.inputs.len()
    );

    Ok(signed_psbt_hex)
}

pub async fn information() -> Result<Info> {
    let info = crate::ark::client::info()?;
    Ok(Info {
        server_pk: info.signer_pk.to_string(),
        network: info.network.to_string(),
    })
}

pub struct PaymentReceived {
    pub txid: String,
    pub amount_sats: u64,
}

pub async fn wait_for_payment(
    ark_address: Option<String>,
    boarding_address: Option<String>,
    boltz_swap_id: Option<String>,
    timeout_seconds: u64,
) -> Result<PaymentReceived> {
    use ark_core::ArkAddress;
    use bitcoin::Address;
    use std::str::FromStr;

    let ark_addr = ark_address.map(|s| ArkAddress::decode(&s)).transpose()?;

    let boarding_addr = boarding_address
        .map(|s| Address::from_str(&s))
        .transpose()?
        .map(|a| a.assume_checked());

    let payment = crate::ark::client::wait_for_payment(
        ark_addr,
        boarding_addr,
        boltz_swap_id,
        timeout_seconds,
    )
    .await?;

    let txid_str = payment.txid.to_string();
    let amount_sats = payment.amount.to_sat();

    tracing::info!(
        "API: Payment received - TXID: {}, Amount: {} sats",
        txid_str,
        amount_sats
    );

    Ok(PaymentReceived {
        txid: txid_str,
        amount_sats,
    })
}

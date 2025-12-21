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
    crate::ark::restore_wallet(mnemonic_words, data_dir, network, esplora, server, boltz_url).await
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
            let btc_str = format!("{:.8}", btc).trim_end_matches('0').trim_end_matches('.').to_string();
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

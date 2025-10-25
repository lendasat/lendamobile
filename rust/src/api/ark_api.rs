use anyhow::Result;
use bitcoin::Network;
use nostr::ToBech32;
use std::str::FromStr;

pub async fn wallet_exists(data_dir: String) -> Result<bool> {
    crate::ark::wallet_exists(data_dir).await
}

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

pub async fn restore_wallet(
    nsec: String,
    data_dir: String,
    network: String,
    esplora: String,
    server: String,
    boltz_url: String,
) -> Result<String> {
    let network = Network::from_str(network.as_str())?;
    crate::ark::restore_wallet(nsec, data_dir, network, esplora, server, boltz_url).await
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
            pending_sats: balance.offchain.pending().to_sat(),
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
    let amount = match amount {
        None => "".to_string(),
        Some(a) => {
            format!("&amount={}", a.to_string())
        }
    };

    let lightning_invoice = match &lightning {
        None => "".to_string(),
        Some(lightning) => {
            format!("&lightning={}", lightning.invoice)
        }
    };

    let bip21 = format!("bitcoin:{boarding}?arkade={offchain}{lightning_invoice}{amount}",);
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
            } => Transaction::Boarding {
                txid: txid.to_string(),
                amount_sats: amount.to_sat(),
                confirmed_at,
            },
            ark_core::history::Transaction::Commitment {
                txid,
                amount,
                created_at,
            } => Transaction::Round {
                txid: txid.to_string(),
                amount_sats: amount.to_sat(),
                created_at,
            },
            ark_core::history::Transaction::Ark {
                txid,
                amount,
                is_settled,
                created_at,
            } => Transaction::Redeem {
                txid: txid.to_string(),
                amount_sats: amount.to_sat(),
                is_settled,
                created_at,
            },
        })
        .collect();

    Ok(txs)
}

pub async fn send(address: String, amount_sats: u64) -> Result<String> {
    let amount = bitcoin::Amount::from_sat(amount_sats);
    let txid = crate::ark::client::send(address, amount).await?;
    Ok(txid.to_string())
}

pub async fn settle() -> Result<()> {
    crate::ark::client::settle().await?;
    Ok(())
}

pub async fn nsec(data_dir: String) -> Result<String> {
    let nsec = crate::ark::nsec(data_dir).await?;
    Ok(nsec.to_bech32()?)
}

pub async fn reset_wallet(data_dir: String) -> Result<()> {
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

    let ark_addr = ark_address
        .map(|s| ArkAddress::decode(&s))
        .transpose()?;

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

    Ok(PaymentReceived {
        txid: payment.txid.to_string(),
        amount_sats: payment.amount.to_sat(),
    })
}

use anyhow::Result;
use ark_rs::core::ArkTransaction;
use bitcoin::Amount;

pub async fn wallet_exists(data_dir: String) -> Result<bool> {
    crate::ark::wallet_exists(data_dir).await
}

pub async fn setup_new_wallet(data_dir: String) -> Result<String> {
    crate::ark::setup_new_wallet(data_dir).await
}

pub async fn load_existing_wallet(data_dir: String) -> Result<String> {
    crate::ark::load_existing_wallet(data_dir).await
}

pub async fn restore_wallet(nsec: String, data_dir: String) -> Result<String> {
    crate::ark::restore_wallet(nsec, data_dir).await
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

pub struct Addresses {
    pub boarding: String,
    pub offchain: String,
    pub bip21: String,
}

pub fn address() -> Result<Addresses> {
    let addresses = crate::ark::client::address()?;

    let boarding = addresses.boarding.to_string();
    let offchain = addresses.offchain.encode();
    let bip21 = format!("bitcoin:{boarding}?ark={offchain}");
    Ok(Addresses {
        boarding,
        offchain,
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
            ArkTransaction::Boarding {
                txid,
                amount,
                confirmed_at,
            } => Transaction::Boarding {
                txid: txid.to_string(),
                amount_sats: amount.to_sat(),
                confirmed_at,
            },
            ArkTransaction::Round {
                txid,
                amount,
                created_at,
            } => Transaction::Round {
                txid: txid.to_string(),
                amount_sats: amount.to_sat(),
                created_at,
            },
            ArkTransaction::Redeem {
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
    let amount = Amount::from_sat(amount_sats);
    let txid = crate::ark::client::send(address, amount).await?;
    Ok(txid.to_string())
}

pub async fn settle() -> Result<()> {
    crate::ark::client::settle().await?;
    Ok(())
}

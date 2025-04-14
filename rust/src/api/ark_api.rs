use anyhow::Result;

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

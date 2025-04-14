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

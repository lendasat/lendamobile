use anyhow::Result;

pub async fn setup_new_wallet() -> Result<String> {
    crate::ark::setup_new_wallet().await
}

pub async fn restore_wallet(nsec: String) -> Result<String> {
    crate::ark::restore_wallet(nsec).await
}

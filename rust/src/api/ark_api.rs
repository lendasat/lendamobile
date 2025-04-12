use anyhow::Result;

pub async fn setup_ark_client() -> Result<String> {
    crate::ark::setup_client().await
}

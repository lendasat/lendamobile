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

pub struct Addresses {
    pub boarding: String,
    pub offchain: String,
    /// bitcoin:tb1pgfr8058rfwuxujs03yrwpwazzf9xh34az2z6nzmjyly5gy7yzk3sa4dkh8?ark=tark1lfeudey8dlajmlykr4mrej56h3eafwywlju0telljtw9t6d2257sz8qw3fu7hgf6582e68gawp950gndjlvw4r5ler9pztxp0d5srsc5welph&amount=0.00001234
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

pub enum TestEnum {
    Test,
    Test2 { test: i32 },
}

pub fn enum_fn() -> TestEnum {
    TestEnum::Test2 { test: 42 }
}

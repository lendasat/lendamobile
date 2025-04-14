use crate::state::ARK_CLIENT;
use anyhow::Result;
use anyhow::{anyhow, bail};
use ark_rs::client::OffChainBalance;
use std::sync::Arc;

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

            // Now we can use the cloned Arc safely across await
            let offchain_balance = client_arc
                .offchain_balance()
                .await
                .map_err(|error| anyhow!("Could not fetch balance {error}"))?;

            Ok(Balance {
                offchain: offchain_balance,
            })
        }
    }
}

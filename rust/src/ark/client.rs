use crate::state::ARK_CLIENT;
use anyhow::Result;
use anyhow::{anyhow, bail};
use ark_rs::client::OffChainBalance;
use ark_rs::core::ArkAddress;
use bitcoin::Address;
use parking_lot::RwLock;
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
                // TODO: woud be good to also get the on-chain balance here
                offchain: offchain_balance,
            })
        }
    }
}

pub struct Addresses {
    pub boarding: Address,
    pub offchain: ArkAddress,
}

pub fn address() -> Result<Addresses> {
    let maybe_client = ARK_CLIENT.try_get();

    match maybe_client {
        None => {
            bail!("Ark client not initialized");
        }
        Some(client) => {
            // Clone the Arc<Client> so we can drop the lock guard
            let client = {
                let guard = client.read();
                Arc::clone(&*guard)
            };
            let boarding_address = client
                .get_boarding_address()
                .map_err(|error| anyhow!("Could not get boarding address {error:#}"))?;

            let (offchain_address, vtxo) = client
                .get_offchain_address()
                .map_err(|error| anyhow!("Could not get offchain address {error:#}"))?;

            Ok(Addresses {
                boarding: boarding_address,
                offchain: offchain_address,
            })
        }
    }
}

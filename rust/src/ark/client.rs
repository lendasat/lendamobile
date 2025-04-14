use crate::ark::address_helper::{decode_bip21, is_ark_address, is_bip21, is_btc_address};
use crate::state::ARK_CLIENT;
use anyhow::Result;
use anyhow::{anyhow, bail};
use ark_rs::client::OffChainBalance;
use ark_rs::core::{ArkAddress, ArkTransaction};
use bitcoin::{Address, Amount, Txid};
use std::str::FromStr;
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

            let (offchain_address, _vtxo) = client
                .get_offchain_address()
                .map_err(|error| anyhow!("Could not get offchain address {error:#}"))?;

            Ok(Addresses {
                boarding: boarding_address,
                offchain: offchain_address,
            })
        }
    }
}

pub async fn tx_history() -> Result<Vec<ArkTransaction>> {
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

            let txs = client
                .transaction_history()
                .await
                .map_err(|error| anyhow!("Failed getting transaction history {error:#}"))?;
            Ok(txs)
        }
    }
}

pub async fn send(address: String, amount: Amount) -> Result<Txid> {
    let maybe_client = ARK_CLIENT.try_get();

    match maybe_client {
        None => {
            bail!("Ark client not initialized");
        }
        Some(client) => {
            let client = {
                let guard = client.read();
                Arc::clone(&*guard)
            };

            if is_bip21(address.as_str()) {
                let uri = decode_bip21(address.as_str())?;
                let amount = uri.amount.unwrap_or(amount);

                if let Some(address) = uri.btc_address {
                    let txid = client
                        .send_on_chain(address.assume_checked(), amount)
                        .await
                        .map_err(|e| anyhow!("Failed sending onchain {e:#}"))?;
                    Ok(txid)
                } else if let Some(address) = uri.ark_address {
                    let psbt = client
                        .send_vtxo(address, amount)
                        .await
                        .map_err(|e| anyhow!("Failed sending offchain {e:#}"))?;
                    let transaction = psbt.extract_tx()?;
                    Ok(transaction.compute_txid())
                } else {
                    bail!("Unknown bip21 format. We only support bitcoin: and ark: addresses");
                }
            } else if is_ark_address(address.as_str()) {
                let address = ArkAddress::decode(address.as_str())?;
                // TODO: why does this return a psbt?
                let psbt = client
                    .send_vtxo(address, amount)
                    .await
                    .map_err(|e| anyhow!("Failed sending offchain {e:#}"))?;
                let transaction = psbt.extract_tx()?;
                Ok(transaction.compute_txid())
            } else if is_btc_address(address.as_str()) {
                let address = Address::from_str(address.as_str())?;
                let txid = client
                    .send_on_chain(address.assume_checked(), amount)
                    .await
                    .map_err(|e| anyhow!("Failed sending onchain {e:#}"))?;
                Ok(txid)
            } else {
                bail!("Address format not supported")
            }
        }
    }
}

pub async fn settle() -> Result<()> {
    let maybe_client = ARK_CLIENT.try_get();

    match maybe_client {
        None => {
            bail!("Ark client not initialized");
        }
        Some(_client) => {
            // let client = {
            //     let guard = client.read();
            //     Arc::clone(&*guard)
            // };
            // FIXME!
            // let mut rng = rand::thread_rng();
            //
            // client
            //     .board(&mut rng)
            //     .await
            //     .map_err(|e| anyhow!("Failed settling {e:#}"))?;
        }
    }

    Ok(())
}

use crate::ark::address_helper::{decode_bip21, is_ark_address, is_bip21, is_btc_address};
use crate::ark::esplora::EsploraClient;
use crate::ark::storage::InMemoryDb;
use crate::state::ARK_CLIENT;
use anyhow::Result;
use anyhow::{anyhow, bail};
use ark_bdk_wallet::Wallet;
use ark_client::{Client, OffChainBalance, SqliteSwapStorage};
use ark_core::ArkAddress;
use ark_core::history::Transaction;
use ark_core::server::{Info, SubscriptionResponse};
use bitcoin::{Address, Amount, Txid};
use futures::StreamExt;
use rand::SeedableRng;
use rand::rngs::StdRng;
use std::str::FromStr;
use std::sync::Arc;
use std::time::Duration;

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
                // TODO: would be good to also get the on-chain balance here
                offchain: offchain_balance,
            })
        }
    }
}

pub struct BoltzSwap {
    pub swap_id: String,
    pub amount: Amount,
    pub invoice: String,
}

pub struct Addresses {
    pub boarding: Address,
    pub offchain: ArkAddress,
    pub boltz_swap: Option<BoltzSwap>,
}

pub struct PaymentReceived {
    pub txid: Txid,
    pub amount: Amount,
}

pub async fn address(amount: Option<Amount>) -> Result<Addresses> {
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

            let reverse_swap_result = match amount {
                None => None,
                Some(amount) => Some(client.get_ln_invoice(amount, Some(300)).await?),
            };

            Ok(Addresses {
                boarding: boarding_address,
                offchain: offchain_address,
                boltz_swap: reverse_swap_result.map(|s| BoltzSwap {
                    swap_id: s.swap_id,
                    amount: s.amount,
                    invoice: s.invoice.to_string(),
                }),
            })
        }
    }
}

pub async fn tx_history() -> Result<Vec<Transaction>> {
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

            let mut txs = client
                .transaction_history()
                .await
                .map_err(|error| anyhow!("Failed getting transaction history {error:#}"))?;

            // sort desc, i.e. newest transactions first
            txs.sort_by_key(|b| std::cmp::Reverse(b.created_at()));
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
                    // TODO: there seems to be a bug sending on-chain
                    let txid = client
                        .send_on_chain(address.assume_checked(), amount)
                        .await
                        .map_err(|e| anyhow!("Failed sending onchain {e:#}"))?;
                    Ok(txid)
                } else if let Some(address) = uri.ark_address {
                    let txid = client
                        .send_vtxo(address, amount)
                        .await
                        .map_err(|e| anyhow!("Failed sending offchain {e:#}"))?;
                    Ok(txid)
                } else {
                    bail!("Unknown bip21 format. We only support bitcoin: and ark: addresses");
                }
            } else if is_ark_address(address.as_str()) {
                let address = ArkAddress::decode(address.as_str())?;
                let txid = client
                    .send_vtxo(address, amount)
                    .await
                    .map_err(|e| anyhow!("Failed sending offchain {e:#}"))?;
                Ok(txid)
            } else if is_btc_address(address.as_str()) {
                let address = Address::from_str(address.as_str())?;
                let rng = &mut StdRng::from_entropy();
                let txid = client
                    .collaborative_redeem(rng, address.assume_checked(), amount, true)
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
        Some(client) => {
            let client = {
                let guard = client.read();
                Arc::clone(&*guard)
            };
            let mut rng = StdRng::from_entropy();
            client
                .settle(&mut rng, false)
                .await
                .map_err(|e| anyhow!("Failed settling {e:#}"))?;
        }
    }

    Ok(())
}

pub(crate) async fn wait_for_payment(
    ark_address: Option<ArkAddress>,
    _boarding_address: Option<Address>,
    boltz_swap_id: Option<String>,
    timeout_seconds: u64,
) -> Result<PaymentReceived> {
    let maybe_client = ARK_CLIENT.try_get();
    match maybe_client {
        None => {
            bail!("Ark client not initialized")
        }
        Some(client) => {
            let client = {
                let guard = client.read();
                Arc::clone(&*guard)
            };

            let timeout_duration = Duration::from_secs(timeout_seconds);

            // Race between ark address subscription, lightning invoice, and timeout
            tokio::select! {
                // Monitor ark_address subscription if provided
                result = async {
                    if let Some(address) = ark_address {
                        monitor_ark_address(&client, address).await
                    } else {
                        // If no ark address, wait forever (will be cancelled by other branches)
                        futures::future::pending().await
                    }
                } => result,

                // Monitor lightning invoice payment if provided
                result = async {
                    if let Some(swap_id) = boltz_swap_id {
                        monitor_lightning_payment(&client, swap_id).await
                    } else {
                        // If no swap id, wait forever (will be cancelled by other branches)
                        futures::future::pending().await
                    }
                } => result,

                // Timeout
                _ = tokio::time::sleep(timeout_duration) => {
                    bail!("Payment waiting timed out after {} seconds", timeout_seconds)
                }
            }
        }
    }
}

async fn monitor_ark_address(
    client: &Arc<Client<EsploraClient, Wallet<InMemoryDb>, SqliteSwapStorage>>,
    address: ArkAddress,
) -> Result<PaymentReceived> {
    tracing::info!("Subscribing to ark address: {}", address.encode());

    // Subscribe to the address to get notifications
    let subscription_id = client
        .subscribe_to_scripts(vec![address], None)
        .await
        .map_err(|e| anyhow!("Failed to subscribe to address: {e}"))?;

    tracing::info!("Subscription ID: {subscription_id}");

    // Get the subscription stream
    let mut subscription_stream = client
        .get_subscription(subscription_id)
        .await
        .map_err(|e| anyhow!("Failed to get subscription stream: {e}"))?;

    tracing::info!("Listening for ark address notifications...");

    // Process subscription responses as they come in
    while let Some(result) = subscription_stream.next().await {
        match result {
            Ok(SubscriptionResponse::Event(e)) => {
                if let Some(psbt) = e.tx {
                    let tx = &psbt.unsigned_tx;
                    let txid = tx.compute_txid();

                    // Find the output that matches our address
                    let output = tx.output.iter().find_map(|out| {
                        if out.script_pubkey == address.to_p2tr_script_pubkey() {
                            Some(out.clone())
                        } else {
                            None
                        }
                    });

                    if let Some(output) = output {
                        tracing::info!("Payment received on ark address!");
                        tracing::info!("  TXID: {}", txid);
                        tracing::info!("  Amount: {:?}", output.value);

                        return Ok(PaymentReceived {
                            txid,
                            amount: output.value,
                        });
                    } else {
                        tracing::warn!(
                            "Received subscription response did not include our address"
                        );
                    }
                } else {
                    tracing::warn!("No tx found in subscription event");
                }
            }
            Ok(SubscriptionResponse::Heartbeat) => {
                // Ignore heartbeats
            }
            Err(e) => {
                bail!("Error receiving subscription response: {e}");
            }
        }
    }

    bail!("Subscription stream ended unexpectedly")
}

async fn monitor_lightning_payment(
    client: &Arc<Client<EsploraClient, Wallet<InMemoryDb>, SqliteSwapStorage>>,
    swap_id: String,
) -> Result<PaymentReceived> {
    tracing::info!("Waiting for lightning invoice payment: {}", swap_id);

    client
        .wait_for_vhtlc(swap_id.as_str())
        .await
        .map_err(|e| anyhow!("Failed waiting for invoice payment: {e}"))?;

    tracing::info!("Lightning invoice paid!");

    // TODO: Get actual txid and amount from the payment
    // For now, return placeholder values - this needs to be updated when the API provides this info
    Ok(PaymentReceived {
        // TODO: this is of course not a valid txid
        txid: Txid::from_str("0000000000000000000000000000000000000000000000000000000000000000")
            .unwrap(),
        amount: Amount::ZERO,
    })
}

pub(crate) fn info() -> Result<Info> {
    let maybe_client = ARK_CLIENT.try_get();

    match maybe_client {
        None => {
            bail!("Ark client not initialized")
        }
        Some(client) => {
            let client = {
                let guard = client.read();
                Arc::clone(&*guard)
            };
            let info = client.server_info.clone();
            Ok(info)
        }
    }
}

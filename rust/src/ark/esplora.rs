use ark_client::error::IntoError;
use ark_client::{Blockchain, Error, SpendStatus, TxStatus};
use ark_core::ExplorerUtxo;
use bitcoin::OutPoint;
use bitcoin::{Address, Amount, Transaction, Txid};

pub struct EsploraClient {
    esplora_client: esplora_client::AsyncClient,
}

impl Blockchain for EsploraClient {
    async fn find_outpoints(&self, address: &Address) -> Result<Vec<ExplorerUtxo>, Error> {
        let script_pubkey = address.script_pubkey();
        let txs = self
            .esplora_client
            .scripthash_txs(&script_pubkey, None)
            .await
            .map_err(|e| format!("Could not fetch tx {e:#}").into_error())?;

        let outputs = txs
            .into_iter()
            .flat_map(|tx| {
                let txid = tx.txid;
                tx.vout
                    .iter()
                    .enumerate()
                    .filter(|(_, v)| v.scriptpubkey == script_pubkey)
                    .map(|(i, v)| ExplorerUtxo {
                        outpoint: OutPoint {
                            txid,
                            vout: i as u32,
                        },
                        amount: Amount::from_sat(v.value),
                        confirmation_blocktime: tx.status.block_time,
                        is_spent: false,
                    })
                    .collect::<Vec<_>>()
            })
            .collect::<Vec<_>>();

        let mut utxos = Vec::new();
        for output in outputs.iter() {
            let outpoint = output.outpoint;
            let status = self
                .esplora_client
                .get_output_status(&outpoint.txid, outpoint.vout as u64)
                .await
                .map_err(|e| format!("Could not get status {e:#}").into_error())?;

            match status {
                Some(esplora_client::OutputStatus { spent: false, .. }) | None => {
                    utxos.push(*output);
                }
                // Ignore spent transaction outputs
                Some(esplora_client::OutputStatus { spent: true, .. }) => {}
            }
        }

        Ok(utxos)
    }

    async fn find_tx(&self, txid: &Txid) -> Result<Option<Transaction>, Error> {
        let res = self.esplora_client.get_tx(txid).await;
        match res {
            Ok(Some(tx)) => Ok(Some(tx)),
            Ok(None) => Ok(None),
            Err(e) => {
                tracing::error!("Could not fetch transaction {e:#}");
                // TODO: I can't instantiate `Error`, hence, we don't fail here.
                // This needs some changes in the library
                Ok(None)
            }
        }
    }

    async fn get_output_status(&self, txid: &Txid, vout: u32) -> Result<SpendStatus, Error> {
        let res = self
            .esplora_client
            .get_output_status(txid, vout as u64)
            .await;

        match res {
            Ok(Some(tx)) => Ok(SpendStatus {
                spend_txid: tx.txid,
            }),
            Ok(None) => Ok(SpendStatus { spend_txid: None }),
            Err(e) => {
                tracing::error!("Could not fetch status {e:#}");
                // TODO: I can't instantiate `Error`, hence, we don't fail here.
                // This needs some changes in the library
                Err(format!("Could not fetch status {e:#}").into_error())
            }
        }
    }

    async fn broadcast(&self, tx: &Transaction) -> Result<(), Error> {
        self.esplora_client
            .broadcast(tx)
            .await
            .map_err(|err| format!("Could not broadcast tx {err:#}").into_error())?;
        Ok(())
    }

    async fn get_fee_rate(&self) -> Result<f64, Error> {
        Ok(1.0)
    }

    async fn broadcast_package(&self, txs: &[&Transaction]) -> Result<(), Error> {
        // FIXME: unfortunately esplora client does not support packages, so this is not correct
        for tx in txs {
            self.broadcast(tx).await?;
        }
        Ok(())
    }

    async fn get_tx_status(&self, txid: &Txid) -> Result<TxStatus, Error> {
        let res = self.esplora_client.get_tx_status(txid).await;

        match res {
            Ok(status) => Ok(TxStatus {
                confirmed_at: status.block_time.map(|t| t as i64),
            }),
            Err(e) => {
                tracing::error!("Could not fetch tx status {e:#}");
                Err(format!("Could not fetch tx status {e:#}").into_error())
            }
        }
    }
}

impl EsploraClient {
    pub fn new(url: &str) -> anyhow::Result<Self> {
        let builder = esplora_client::Builder::new(url);
        let esplora_client = builder.build_async()?;

        Ok(Self { esplora_client })
    }

    pub async fn check_connection(&self) -> anyhow::Result<()> {
        let height = self.esplora_client.get_height().await?;
        tracing::debug!(latest_height = height, "Fetched latest height");
        Ok(())
    }
}

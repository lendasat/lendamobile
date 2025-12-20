use crate::frb_generated::StreamSink;
use crate::models::mempool::{ProjectedBlockTransactions, ProjectedTransaction};
use anyhow::{Context, Result};
use futures_util::{SinkExt, StreamExt};
use serde_json::{self, Value};
use tokio_tungstenite::{connect_async, tungstenite::Message};

const MEMPOOL_WS_URL: &str = "wss://mempool.space/api/v1/ws";

/// Track a specific mempool block and stream its transactions
pub async fn track_mempool_block(
    block_index: u32,
    sink: StreamSink<ProjectedBlockTransactions>,
) -> Result<()> {
    tracing::info!(
        "Connecting to mempool WebSocket to track block index {}",
        block_index
    );

    let (ws_stream, _) = connect_async(MEMPOOL_WS_URL)
        .await
        .context("Failed to connect to mempool WebSocket for block tracking")?;

    tracing::info!("Connected to mempool WebSocket for block tracking");

    let (mut write, mut read) = ws_stream.split();

    // Send initialization message
    write
        .send(Message::Text(r#"{"action":"init"}"#.to_string()))
        .await
        .context("Failed to send init message")?;

    // Send track-mempool-block message
    let track_msg = format!(r#"{{"track-mempool-block":{}}}"#, block_index);
    write
        .send(Message::Text(track_msg))
        .await
        .context("Failed to send track-mempool-block message")?;

    tracing::info!("Sent track-mempool-block message for index {}", block_index);

    // Listen for projected transactions
    while let Some(msg) = read.next().await {
        match msg {
            Ok(Message::Text(text)) => {
                if let Err(e) = handle_projected_transactions(&text, block_index, &sink) {
                    tracing::warn!("Failed to handle projected transactions: {}", e);
                }
            }
            Ok(Message::Close(_)) => {
                tracing::info!("WebSocket closed by server");
                break;
            }
            Ok(Message::Ping(data)) => {
                write.send(Message::Pong(data)).await?;
            }
            Ok(_) => {
                // Ignore other message types
            }
            Err(e) => {
                tracing::error!("WebSocket error: {}", e);
                return Err(e.into());
            }
        }
    }

    Ok(())
}

fn handle_projected_transactions(
    text: &str,
    expected_index: u32,
    sink: &StreamSink<ProjectedBlockTransactions>,
) -> Result<()> {
    let value: Value = serde_json::from_str(text)?;

    if let Some(projected) = value.get("projected-block-transactions") {
        let index = projected
            .get("index")
            .and_then(|v| v.as_u64())
            .ok_or_else(|| anyhow::anyhow!("Missing or invalid index"))? as u32;

        if index == expected_index {
            let mut transactions = Vec::new();

            if let Some(block_txs_array) = projected
                .get("blockTransactions")
                .and_then(|v| v.as_array())
            {
                for tx_array in block_txs_array {
                    if let Some(arr) = tx_array.as_array() {
                        if arr.len() >= 5 {
                            let txid = arr[0]
                                .as_str()
                                .ok_or_else(|| anyhow::anyhow!("Invalid txid"))?
                                .to_string();
                            let value = arr[1].as_u64().unwrap_or(0);
                            let vsize = arr[2].as_u64().unwrap_or(0) as u32;
                            let fee_rate = arr[3].as_f64().unwrap_or(0.0);
                            let flags = arr[4].as_u64().unwrap_or(0) as u32;

                            transactions.push(ProjectedTransaction {
                                txid,
                                value,
                                vsize,
                                fee_rate,
                                flags,
                            });
                        }
                    }
                }
            }

            let tx_count = transactions.len();
            let result = ProjectedBlockTransactions {
                index,
                transactions,
            };

            sink.clone()
                .add(result)
                .expect("Failed to send projected block transactions");
            tracing::info!(
                "Emitted {} transactions for block index {}",
                tx_count,
                index
            );
        }
    }

    Ok(())
}

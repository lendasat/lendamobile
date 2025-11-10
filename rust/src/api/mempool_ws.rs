use crate::frb_generated::StreamSink;
use crate::models::mempool::MempoolWsMessage;
use anyhow::{Context, Result};
use futures_util::{SinkExt, StreamExt};
use serde_json;
use tokio::time::{interval, Duration};
use tokio_tungstenite::{connect_async, tungstenite::Message};

const MEMPOOL_WS_URL: &str = "wss://mempool.space/api/v1/ws";
const RECONNECT_DELAY: Duration = Duration::from_secs(5);
const PING_INTERVAL: Duration = Duration::from_secs(30);

/// Subscribe to real-time mempool updates via WebSocket
pub async fn subscribe_mempool_updates(sink: StreamSink<MempoolWsMessage>) -> Result<()> {
    let mut reconnect_attempts = 0;
    const MAX_RECONNECT_ATTEMPTS: u32 = 5;

    loop {
        match connect_and_listen(&sink).await {
            Ok(_) => {
                tracing::info!("Mempool WebSocket connection closed normally");
                reconnect_attempts = 0;
            }
            Err(e) => {
                reconnect_attempts += 1;
                tracing::error!(
                    "Mempool WebSocket error (attempt {}/{}): {}",
                    reconnect_attempts,
                    MAX_RECONNECT_ATTEMPTS,
                    e
                );

                if reconnect_attempts >= MAX_RECONNECT_ATTEMPTS {
                    tracing::error!("Max reconnection attempts reached, giving up");
                    return Err(e);
                }

                tracing::info!("Reconnecting in {:?}...", RECONNECT_DELAY);
                tokio::time::sleep(RECONNECT_DELAY).await;
            }
        }
    }
}

async fn connect_and_listen(sink: &StreamSink<MempoolWsMessage>) -> Result<()> {
    tracing::info!("Connecting to mempool WebSocket: {}", MEMPOOL_WS_URL);

    let (ws_stream, _) = connect_async(MEMPOOL_WS_URL)
        .await
        .context("Failed to connect to mempool WebSocket")?;

    tracing::info!("Connected to mempool WebSocket");

    let (mut write, mut read) = ws_stream.split();

    // Send initialization messages
    write
        .send(Message::Text(r#"{"action":"init"}"#.to_string()))
        .await
        .context("Failed to send init message")?;

    write
        .send(Message::Text(
            r#"{"action":"want","data":["blocks","stats","mempool-blocks","live-2h-chart"]}"#
                .to_string(),
        ))
        .await
        .context("Failed to send want message")?;

    write
        .send(Message::Text(r#"{"track-rbf-summary":true}"#.to_string()))
        .await
        .context("Failed to send track-rbf-summary message")?;

    tracing::info!("Sent initialization messages to mempool WebSocket");

    let mut ping_interval = interval(PING_INTERVAL);

    loop {
        tokio::select! {
            msg = read.next() => {
                match msg {
                    Some(Ok(Message::Text(text))) => {
                        if let Err(e) = handle_message(&text, sink) {
                            tracing::warn!("Failed to handle WebSocket message: {}", e);
                        }
                    }
                    Some(Ok(Message::Close(_))) => {
                        tracing::info!("WebSocket closed by server");
                        break;
                    }
                    Some(Ok(Message::Ping(data))) => {
                        write.send(Message::Pong(data)).await?;
                    }
                    Some(Ok(_)) => {
                        // Ignore other message types
                    }
                    Some(Err(e)) => {
                        tracing::error!("WebSocket error: {}", e);
                        return Err(e.into());
                    }
                    None => {
                        tracing::info!("WebSocket stream ended");
                        break;
                    }
                }
            }

            _ = ping_interval.tick() => {
                if let Err(e) = write.send(Message::Ping(vec![])).await {
                    tracing::error!("Failed to send ping: {}", e);
                    return Err(e.into());
                }
            }
        }
    }

    Ok(())
}

fn handle_message(text: &str, sink: &StreamSink<MempoolWsMessage>) -> Result<()> {
    match serde_json::from_str::<MempoolWsMessage>(text) {
        Ok(msg) => {
            // Only emit messages that contain relevant data
            if msg.mempool_blocks.is_some()
                || msg.blocks.is_some()
                || msg.conversions.is_some()
                || msg.fees.is_some()
                || msg.da.is_some()
            {
                sink.clone()
                    .add(msg)
                    .expect("Failed to send mempool WebSocket message");
            }
            Ok(())
        }
        Err(e) => {
            tracing::debug!("Couldn't parse message as MempoolWsMessage: {}", e);
            Ok(())
        }
    }
}

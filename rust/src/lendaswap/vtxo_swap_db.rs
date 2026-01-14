//! SQLite-based storage for VTXO swaps in LendaSwap.
//!
//! This module provides a SQLite storage implementation for `ExtendedVtxoSwapStorageData`
//! using proper columnar storage for better queryability and migration support.

use anyhow::Result;
use lendaswap_core::ExtendedVtxoSwapStorageData;
use lendaswap_core::api::VtxoSwapStatus;
use lendaswap_core::storage::{StorageFuture, VtxoSwapStorage};
use std::path::Path;
use std::str::FromStr;

/// SQLite-based storage for VtxoSwaps in LendaSwap.
///
/// Stores swap data in a SQLite database with proper columnar storage
/// for better queryability and migration support.
pub struct VtxoSwapDb {
    pool: sqlx::SqlitePool,
}

/// Database row representation for VTXO swap storage.
/// This maps to the SQLite table schema.
#[derive(Debug, Clone, sqlx::FromRow)]
struct VtxoSwapRow {
    // Primary key
    swap_id: String,

    // VtxoSwapResponse fields
    status: String,
    created_at: String,

    // Client VHTLC params
    client_vhtlc_address: String,
    client_fund_amount_sats: i64,
    client_pk: String,
    client_locktime: i64,
    client_unilateral_claim_delay: i64,
    client_unilateral_refund_delay: i64,
    client_unilateral_refund_without_receiver_delay: i64,

    // Server VHTLC params
    server_vhtlc_address: String,
    server_fund_amount_sats: i64,
    server_pk: String,
    server_locktime: i64,
    server_unilateral_claim_delay: i64,
    server_unilateral_refund_delay: i64,
    server_unilateral_refund_without_receiver_delay: i64,

    // Common params
    arkade_server_pk: String,
    preimage_hash_response: String,
    fee_sats: i64,
    network: String,

    // SwapParams fields (sensitive - stored as hex)
    secret_key: String,
    public_key: String,
    preimage: String,
    preimage_hash_params: String,
    user_id: String,
    key_index: i64,
}

impl VtxoSwapDb {
    /// Create a new VtxoSwapDb with the given data directory.
    /// The SQLite database will be created at `{data_dir}/lendaswap_vtxo_swaps.sqlite`.
    pub async fn new(data_dir: String) -> Result<Self> {
        let db_path = Path::new(&data_dir).join("lendaswap_vtxo_swaps.sqlite");
        let db_url = format!("sqlite:{}?mode=rwc", db_path.display());

        let pool = sqlx::SqlitePool::connect(&db_url)
            .await
            .map_err(|e| anyhow::anyhow!("Failed to connect to SQLite database: {}", e))?;

        // Run migrations to create tables
        Self::run_migrations(&pool).await?;

        let count: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM vtxo_swaps")
            .fetch_one(&pool)
            .await
            .unwrap_or((0,));

        tracing::info!(
            swap_count = count.0,
            "Loaded existing swaps from SQLite storage"
        );

        Ok(Self { pool })
    }

    /// Run database migrations to create/update tables.
    async fn run_migrations(pool: &sqlx::SqlitePool) -> Result<()> {
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS vtxo_swaps (
                -- Primary key
                swap_id TEXT PRIMARY KEY NOT NULL,

                -- VtxoSwapResponse fields
                status TEXT NOT NULL,
                created_at TEXT NOT NULL,

                -- Client VHTLC params
                client_vhtlc_address TEXT NOT NULL,
                client_fund_amount_sats INTEGER NOT NULL,
                client_pk TEXT NOT NULL,
                client_locktime INTEGER NOT NULL,
                client_unilateral_claim_delay INTEGER NOT NULL,
                client_unilateral_refund_delay INTEGER NOT NULL,
                client_unilateral_refund_without_receiver_delay INTEGER NOT NULL,

                -- Server VHTLC params
                server_vhtlc_address TEXT NOT NULL,
                server_fund_amount_sats INTEGER NOT NULL,
                server_pk TEXT NOT NULL,
                server_locktime INTEGER NOT NULL,
                server_unilateral_claim_delay INTEGER NOT NULL,
                server_unilateral_refund_delay INTEGER NOT NULL,
                server_unilateral_refund_without_receiver_delay INTEGER NOT NULL,

                -- Common params
                arkade_server_pk TEXT NOT NULL,
                preimage_hash_response TEXT NOT NULL,
                fee_sats INTEGER NOT NULL,
                network TEXT NOT NULL,

                -- SwapParams fields (stored as hex)
                secret_key TEXT NOT NULL,
                public_key TEXT NOT NULL,
                preimage TEXT NOT NULL,
                preimage_hash_params TEXT NOT NULL,
                user_id TEXT NOT NULL,
                key_index INTEGER NOT NULL
            )
            "#,
        )
        .execute(pool)
        .await
        .map_err(|e| anyhow::anyhow!("Failed to create vtxo_swaps table: {}", e))?;

        // Create indexes for common queries
        sqlx::query("CREATE INDEX IF NOT EXISTS idx_vtxo_swaps_status ON vtxo_swaps(status)")
            .execute(pool)
            .await
            .ok();

        sqlx::query(
            "CREATE INDEX IF NOT EXISTS idx_vtxo_swaps_created_at ON vtxo_swaps(created_at)",
        )
        .execute(pool)
        .await
        .ok();

        Ok(())
    }

    /// Convert a database row to ExtendedVtxoSwapStorageData.
    fn row_to_data(row: VtxoSwapRow) -> Result<ExtendedVtxoSwapStorageData, lendaswap_core::Error> {
        use lendaswap_core::api::VtxoSwapResponse;
        use lendaswap_core::types::SwapParams;

        // Parse status
        let status = parse_vtxo_swap_status(&row.status)?;

        // Parse created_at timestamp
        let created_at = time::OffsetDateTime::parse(
            &row.created_at,
            &time::format_description::well_known::Rfc3339,
        )
        .map_err(|e| lendaswap_core::Error::Other(format!("Failed to parse created_at: {}", e)))?;

        // Parse swap_id as UUID
        let id = uuid::Uuid::from_str(&row.swap_id)
            .map_err(|e| lendaswap_core::Error::Other(format!("Failed to parse swap_id: {}", e)))?;

        // Build VtxoSwapResponse
        let response = VtxoSwapResponse {
            id,
            status,
            created_at,
            client_vhtlc_address: row.client_vhtlc_address,
            client_fund_amount_sats: row.client_fund_amount_sats,
            client_pk: row.client_pk,
            client_locktime: row.client_locktime as u64,
            client_unilateral_claim_delay: row.client_unilateral_claim_delay,
            client_unilateral_refund_delay: row.client_unilateral_refund_delay,
            client_unilateral_refund_without_receiver_delay: row
                .client_unilateral_refund_without_receiver_delay,
            server_vhtlc_address: row.server_vhtlc_address,
            server_fund_amount_sats: row.server_fund_amount_sats,
            server_pk: row.server_pk,
            server_locktime: row.server_locktime as u64,
            server_unilateral_claim_delay: row.server_unilateral_claim_delay,
            server_unilateral_refund_delay: row.server_unilateral_refund_delay,
            server_unilateral_refund_without_receiver_delay: row
                .server_unilateral_refund_without_receiver_delay,
            arkade_server_pk: row.arkade_server_pk,
            preimage_hash: row.preimage_hash_response,
            fee_sats: row.fee_sats,
            network: row.network,
        };

        // Parse SwapParams
        let secret_key_bytes = hex::decode(&row.secret_key).map_err(|e| {
            lendaswap_core::Error::Other(format!("Failed to decode secret_key: {}", e))
        })?;
        let secret_key =
            bitcoin::secp256k1::SecretKey::from_slice(&secret_key_bytes).map_err(|e| {
                lendaswap_core::Error::Other(format!("Failed to parse secret_key: {}", e))
            })?;

        let public_key_bytes = hex::decode(&row.public_key).map_err(|e| {
            lendaswap_core::Error::Other(format!("Failed to decode public_key: {}", e))
        })?;
        let public_key =
            bitcoin::secp256k1::PublicKey::from_slice(&public_key_bytes).map_err(|e| {
                lendaswap_core::Error::Other(format!("Failed to parse public_key: {}", e))
            })?;

        let preimage_bytes = hex::decode(&row.preimage).map_err(|e| {
            lendaswap_core::Error::Other(format!("Failed to decode preimage: {}", e))
        })?;
        let preimage: [u8; 32] = preimage_bytes
            .try_into()
            .map_err(|_| lendaswap_core::Error::Other("Invalid preimage length".to_string()))?;

        let preimage_hash_bytes = hex::decode(&row.preimage_hash_params).map_err(|e| {
            lendaswap_core::Error::Other(format!("Failed to decode preimage_hash: {}", e))
        })?;
        let preimage_hash: [u8; 32] = preimage_hash_bytes.try_into().map_err(|_| {
            lendaswap_core::Error::Other("Invalid preimage_hash length".to_string())
        })?;

        let user_id_bytes = hex::decode(&row.user_id).map_err(|e| {
            lendaswap_core::Error::Other(format!("Failed to decode user_id: {}", e))
        })?;
        let user_id = bitcoin::secp256k1::PublicKey::from_slice(&user_id_bytes)
            .map_err(|e| lendaswap_core::Error::Other(format!("Failed to parse user_id: {}", e)))?;

        let swap_params = SwapParams {
            secret_key,
            public_key,
            preimage,
            preimage_hash,
            user_id,
            key_index: row.key_index as u32,
        };

        Ok(ExtendedVtxoSwapStorageData {
            response,
            swap_params,
        })
    }

    /// Convert ExtendedVtxoSwapStorageData to database row values.
    fn data_to_row(swap_id: &str, data: &ExtendedVtxoSwapStorageData) -> VtxoSwapRow {
        let response = &data.response;
        let params = &data.swap_params;

        VtxoSwapRow {
            swap_id: swap_id.to_string(),
            status: format!("{:?}", response.status),
            created_at: response
                .created_at
                .format(&time::format_description::well_known::Rfc3339)
                .unwrap_or_default(),
            client_vhtlc_address: response.client_vhtlc_address.clone(),
            client_fund_amount_sats: response.client_fund_amount_sats,
            client_pk: response.client_pk.clone(),
            client_locktime: response.client_locktime as i64,
            client_unilateral_claim_delay: response.client_unilateral_claim_delay,
            client_unilateral_refund_delay: response.client_unilateral_refund_delay,
            client_unilateral_refund_without_receiver_delay: response
                .client_unilateral_refund_without_receiver_delay,
            server_vhtlc_address: response.server_vhtlc_address.clone(),
            server_fund_amount_sats: response.server_fund_amount_sats,
            server_pk: response.server_pk.clone(),
            server_locktime: response.server_locktime as i64,
            server_unilateral_claim_delay: response.server_unilateral_claim_delay,
            server_unilateral_refund_delay: response.server_unilateral_refund_delay,
            server_unilateral_refund_without_receiver_delay: response
                .server_unilateral_refund_without_receiver_delay,
            arkade_server_pk: response.arkade_server_pk.clone(),
            preimage_hash_response: response.preimage_hash.clone(),
            fee_sats: response.fee_sats,
            network: response.network.clone(),
            secret_key: hex::encode(params.secret_key.secret_bytes()),
            public_key: hex::encode(params.public_key.serialize()),
            preimage: hex::encode(params.preimage),
            preimage_hash_params: hex::encode(params.preimage_hash),
            user_id: hex::encode(params.user_id.serialize()),
            key_index: params.key_index as i64,
        }
    }
}

/// Parse VtxoSwapStatus from string.
fn parse_vtxo_swap_status(s: &str) -> Result<VtxoSwapStatus, lendaswap_core::Error> {
    match s {
        "Pending" => Ok(VtxoSwapStatus::Pending),
        "ClientFunded" => Ok(VtxoSwapStatus::ClientFunded),
        "ServerFunded" => Ok(VtxoSwapStatus::ServerFunded),
        "ClientRedeemed" => Ok(VtxoSwapStatus::ClientRedeemed),
        "ServerRedeemed" => Ok(VtxoSwapStatus::ServerRedeemed),
        "ClientRefunded" => Ok(VtxoSwapStatus::ClientRefunded),
        "ClientFundedServerRefunded" => Ok(VtxoSwapStatus::ClientFundedServerRefunded),
        "Expired" => Ok(VtxoSwapStatus::Expired),
        _ => Err(lendaswap_core::Error::Other(format!(
            "Unknown VtxoSwapStatus: {}",
            s
        ))),
    }
}

impl VtxoSwapStorage for VtxoSwapDb {
    fn get(&self, swap_id: &str) -> StorageFuture<'_, Option<ExtendedVtxoSwapStorageData>> {
        let swap_id = swap_id.to_string();
        Box::pin(async move {
            let result: Option<VtxoSwapRow> = sqlx::query_as(
                r#"
                SELECT
                    swap_id, status, created_at,
                    client_vhtlc_address, client_fund_amount_sats, client_pk,
                    client_locktime, client_unilateral_claim_delay,
                    client_unilateral_refund_delay, client_unilateral_refund_without_receiver_delay,
                    server_vhtlc_address, server_fund_amount_sats, server_pk,
                    server_locktime, server_unilateral_claim_delay,
                    server_unilateral_refund_delay, server_unilateral_refund_without_receiver_delay,
                    arkade_server_pk, preimage_hash_response, fee_sats, network,
                    secret_key, public_key, preimage, preimage_hash_params, user_id, key_index
                FROM vtxo_swaps WHERE swap_id = ?
                "#,
            )
            .bind(&swap_id)
            .fetch_optional(&self.pool)
            .await
            .map_err(|e| lendaswap_core::Error::Other(format!("Failed to get swap: {}", e)))?;

            match result {
                Some(row) => Ok(Some(Self::row_to_data(row)?)),
                None => Ok(None),
            }
        })
    }

    fn store(&self, swap_id: &str, data: &ExtendedVtxoSwapStorageData) -> StorageFuture<'_, ()> {
        let swap_id = swap_id.to_string();
        let row = Self::data_to_row(&swap_id, data);
        Box::pin(async move {
            sqlx::query(
                r#"
                INSERT INTO vtxo_swaps (
                    swap_id, status, created_at,
                    client_vhtlc_address, client_fund_amount_sats, client_pk,
                    client_locktime, client_unilateral_claim_delay,
                    client_unilateral_refund_delay, client_unilateral_refund_without_receiver_delay,
                    server_vhtlc_address, server_fund_amount_sats, server_pk,
                    server_locktime, server_unilateral_claim_delay,
                    server_unilateral_refund_delay, server_unilateral_refund_without_receiver_delay,
                    arkade_server_pk, preimage_hash_response, fee_sats, network,
                    secret_key, public_key, preimage, preimage_hash_params, user_id, key_index
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(swap_id) DO UPDATE SET
                    status = excluded.status,
                    created_at = excluded.created_at,
                    client_vhtlc_address = excluded.client_vhtlc_address,
                    client_fund_amount_sats = excluded.client_fund_amount_sats,
                    client_pk = excluded.client_pk,
                    client_locktime = excluded.client_locktime,
                    client_unilateral_claim_delay = excluded.client_unilateral_claim_delay,
                    client_unilateral_refund_delay = excluded.client_unilateral_refund_delay,
                    client_unilateral_refund_without_receiver_delay = excluded.client_unilateral_refund_without_receiver_delay,
                    server_vhtlc_address = excluded.server_vhtlc_address,
                    server_fund_amount_sats = excluded.server_fund_amount_sats,
                    server_pk = excluded.server_pk,
                    server_locktime = excluded.server_locktime,
                    server_unilateral_claim_delay = excluded.server_unilateral_claim_delay,
                    server_unilateral_refund_delay = excluded.server_unilateral_refund_delay,
                    server_unilateral_refund_without_receiver_delay = excluded.server_unilateral_refund_without_receiver_delay,
                    arkade_server_pk = excluded.arkade_server_pk,
                    preimage_hash_response = excluded.preimage_hash_response,
                    fee_sats = excluded.fee_sats,
                    network = excluded.network,
                    secret_key = excluded.secret_key,
                    public_key = excluded.public_key,
                    preimage = excluded.preimage,
                    preimage_hash_params = excluded.preimage_hash_params,
                    user_id = excluded.user_id,
                    key_index = excluded.key_index
                "#,
            )
            .bind(&row.swap_id)
            .bind(&row.status)
            .bind(&row.created_at)
            .bind(&row.client_vhtlc_address)
            .bind(row.client_fund_amount_sats)
            .bind(&row.client_pk)
            .bind(row.client_locktime)
            .bind(row.client_unilateral_claim_delay)
            .bind(row.client_unilateral_refund_delay)
            .bind(row.client_unilateral_refund_without_receiver_delay)
            .bind(&row.server_vhtlc_address)
            .bind(row.server_fund_amount_sats)
            .bind(&row.server_pk)
            .bind(row.server_locktime)
            .bind(row.server_unilateral_claim_delay)
            .bind(row.server_unilateral_refund_delay)
            .bind(row.server_unilateral_refund_without_receiver_delay)
            .bind(&row.arkade_server_pk)
            .bind(&row.preimage_hash_response)
            .bind(row.fee_sats)
            .bind(&row.network)
            .bind(&row.secret_key)
            .bind(&row.public_key)
            .bind(&row.preimage)
            .bind(&row.preimage_hash_params)
            .bind(&row.user_id)
            .bind(row.key_index)
            .execute(&self.pool)
            .await
            .map_err(|e| lendaswap_core::Error::Other(format!("Failed to store swap: {}", e)))?;

            tracing::debug!(swap_id = %swap_id, "Stored vtxo swap to SQLite");
            Ok(())
        })
    }

    fn delete(&self, swap_id: &str) -> StorageFuture<'_, ()> {
        let swap_id = swap_id.to_string();
        Box::pin(async move {
            sqlx::query("DELETE FROM vtxo_swaps WHERE swap_id = ?")
                .bind(&swap_id)
                .execute(&self.pool)
                .await
                .map_err(|e| {
                    lendaswap_core::Error::Other(format!("Failed to delete swap: {}", e))
                })?;

            tracing::debug!(swap_id = %swap_id, "Deleted vtxo swap from SQLite");
            Ok(())
        })
    }

    fn list(&self) -> StorageFuture<'_, Vec<String>> {
        Box::pin(async move {
            let rows: Vec<(String,)> = sqlx::query_as("SELECT swap_id FROM vtxo_swaps")
                .fetch_all(&self.pool)
                .await
                .map_err(|e| {
                    lendaswap_core::Error::Other(format!("Failed to list swaps: {}", e))
                })?;

            Ok(rows.into_iter().map(|(id,)| id).collect())
        })
    }

    fn get_all(&self) -> StorageFuture<'_, Vec<ExtendedVtxoSwapStorageData>> {
        Box::pin(async move {
            let rows: Vec<VtxoSwapRow> = sqlx::query_as(
                r#"
                SELECT
                    swap_id, status, created_at,
                    client_vhtlc_address, client_fund_amount_sats, client_pk,
                    client_locktime, client_unilateral_claim_delay,
                    client_unilateral_refund_delay, client_unilateral_refund_without_receiver_delay,
                    server_vhtlc_address, server_fund_amount_sats, server_pk,
                    server_locktime, server_unilateral_claim_delay,
                    server_unilateral_refund_delay, server_unilateral_refund_without_receiver_delay,
                    arkade_server_pk, preimage_hash_response, fee_sats, network,
                    secret_key, public_key, preimage, preimage_hash_params, user_id, key_index
                FROM vtxo_swaps
                "#,
            )
            .fetch_all(&self.pool)
            .await
            .map_err(|e| lendaswap_core::Error::Other(format!("Failed to get all swaps: {}", e)))?;

            let mut swaps = Vec::with_capacity(rows.len());
            for row in rows {
                match Self::row_to_data(row) {
                    Ok(data) => swaps.push(data),
                    Err(e) => {
                        tracing::warn!("Failed to convert swap row to data: {}", e);
                    }
                }
            }

            Ok(swaps)
        })
    }
}

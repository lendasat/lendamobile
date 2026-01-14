//! SQLite-based storage for swaps in LendaSwap.
//!
//! This module provides a SQLite storage implementation for `ExtendedSwapStorageData`
//! using three separate tables for each swap type (BtcToEvm, EvmToBtc, BtcToArkade).

use anyhow::Result;
use lendaswap_core::api::{
    BtcToArkadeSwapResponse, BtcToEvmSwapResponse, EvmToBtcSwapResponse, GetSwapResponse,
    SwapCommonFields, SwapStatus, TokenId,
};
use lendaswap_core::client::ExtendedSwapStorageData;
use lendaswap_core::storage::{StorageFuture, SwapStorage};
use lendaswap_core::types::SwapParams;
use std::fs;
use std::path::Path;
use std::str::FromStr;
use time::OffsetDateTime;
use uuid::Uuid;

/// Parse a TokenId from string.
/// TODO: Replace with TokenId::from_str once it's implemented in lendaswap-core.
fn parse_token_id(s: &str) -> TokenId {
    match s {
        "BtcLightning" => TokenId::BtcLightning,
        "BtcArkade" => TokenId::BtcArkade,
        other => TokenId::Coin(other.to_string()),
    }
}

/// SQLite-based storage for Swaps in LendaSwap.
///
/// Uses three separate tables for proper normalization:
/// - `btc_to_evm_swaps`: BTC → EVM swaps
/// - `evm_to_btc_swaps`: EVM → BTC swaps
/// - `btc_to_arkade_swaps`: BTC → Arkade swaps
pub struct SwapDb {
    pool: sqlx::SqlitePool,
}

/// Swap type discriminator.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum SwapType {
    BtcToEvm,
    EvmToBtc,
    BtcToArkade,
}

impl SwapType {
    fn as_str(&self) -> &'static str {
        match self {
            SwapType::BtcToEvm => "BtcToEvm",
            SwapType::EvmToBtc => "EvmToBtc",
            SwapType::BtcToArkade => "BtcToArkade",
        }
    }

    fn from_str(s: &str) -> Option<Self> {
        match s {
            "BtcToEvm" => Some(SwapType::BtcToEvm),
            "EvmToBtc" => Some(SwapType::EvmToBtc),
            "BtcToArkade" => Some(SwapType::BtcToArkade),
            _ => None,
        }
    }
}

// ============================================================================
// Database row types for each swap type
// ============================================================================

#[derive(Debug, Clone, sqlx::FromRow)]
struct BtcToEvmRow {
    // Primary key
    swap_id: String,
    // Common fields
    status: String,
    hash_lock: String,
    fee_sats: i64,
    asset_amount: f64,
    sender_pk: String,
    receiver_pk: String,
    server_pk: String,
    evm_refund_locktime: i64,
    vhtlc_refund_locktime: i64,
    unilateral_claim_delay: i64,
    unilateral_refund_delay: i64,
    unilateral_refund_without_receiver_delay: i64,
    network: String,
    created_at: String,
    // BtcToEvm specific
    htlc_address_evm: String,
    htlc_address_arkade: String,
    user_address_evm: String,
    ln_invoice: String,
    sats_receive: i64,
    source_token: String,
    target_token: String,
    bitcoin_htlc_claim_txid: Option<String>,
    bitcoin_htlc_fund_txid: Option<String>,
    evm_htlc_claim_txid: Option<String>,
    evm_htlc_fund_txid: Option<String>,
    // SwapParams
    secret_key: String,
    public_key: String,
    preimage: String,
    preimage_hash: String,
    user_id: String,
    key_index: i64,
}

#[derive(Debug, Clone, sqlx::FromRow)]
struct EvmToBtcRow {
    // Primary key
    swap_id: String,
    // Common fields
    status: String,
    hash_lock: String,
    fee_sats: i64,
    asset_amount: f64,
    sender_pk: String,
    receiver_pk: String,
    server_pk: String,
    evm_refund_locktime: i64,
    vhtlc_refund_locktime: i64,
    unilateral_claim_delay: i64,
    unilateral_refund_delay: i64,
    unilateral_refund_without_receiver_delay: i64,
    network: String,
    created_at: String,
    // EvmToBtc specific
    htlc_address_evm: String,
    htlc_address_arkade: String,
    user_address_evm: String,
    user_address_arkade: Option<String>,
    ln_invoice: String,
    source_token: String,
    target_token: String,
    sats_receive: i64,
    bitcoin_htlc_fund_txid: Option<String>,
    bitcoin_htlc_claim_txid: Option<String>,
    evm_htlc_claim_txid: Option<String>,
    evm_htlc_fund_txid: Option<String>,
    create_swap_tx: Option<String>,
    approve_tx: Option<String>,
    gelato_forwarder_address: Option<String>,
    gelato_user_nonce: Option<String>,
    gelato_user_deadline: Option<String>,
    source_token_address: String,
    // SwapParams
    secret_key: String,
    public_key: String,
    preimage: String,
    preimage_hash: String,
    user_id: String,
    key_index: i64,
}

#[derive(Debug, Clone, sqlx::FromRow)]
struct BtcToArkadeRow {
    // Primary key
    swap_id: String,
    // BtcToArkade fields
    status: String,
    btc_htlc_address: String,
    asset_amount: i64,
    sats_receive: i64,
    fee_sats: i64,
    hash_lock: String,
    btc_refund_locktime: i64,
    arkade_vhtlc_address: String,
    target_arkade_address: String,
    btc_fund_txid: Option<String>,
    btc_claim_txid: Option<String>,
    arkade_fund_txid: Option<String>,
    arkade_claim_txid: Option<String>,
    network: String,
    created_at: String,
    // VHTLC parameters
    server_vhtlc_pk: String,
    arkade_server_pk: String,
    vhtlc_refund_locktime: i64,
    unilateral_claim_delay: i64,
    unilateral_refund_delay: i64,
    unilateral_refund_without_receiver_delay: i64,
    source_token: String,
    target_token: String,
    // SwapParams
    secret_key: String,
    public_key: String,
    preimage: String,
    preimage_hash: String,
    user_id: String,
    key_index: i64,
}

impl SwapDb {
    /// Create a new SwapDb with the given data directory.
    pub async fn new(data_dir: String) -> Result<Self> {
        let db_path = Path::new(&data_dir).join("lendaswap_swaps.sqlite");
        let db_url = format!("sqlite:{}?mode=rwc", db_path.display());

        let pool = sqlx::SqlitePool::connect(&db_url)
            .await
            .map_err(|e| anyhow::anyhow!("Failed to connect to SQLite database: {}", e))?;

        Self::run_migrations(&pool).await?;

        // Migrate existing JSON files (best-effort, don't fail if migration has issues)
        let json_dir = Path::new(&data_dir).join("lendaswap_swaps");
        if let Err(e) = Self::migrate_json_files(&pool, &json_dir).await {
            tracing::error!(
                "Failed to migrate JSON swap files: {}. Continuing anyway.",
                e
            );
        }

        let count = Self::count_all_swaps(&pool).await;
        tracing::info!(
            swap_count = count,
            "Loaded existing swaps from SQLite storage"
        );

        Ok(Self { pool })
    }

    async fn count_all_swaps(pool: &sqlx::SqlitePool) -> i64 {
        let btc_to_evm: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM btc_to_evm_swaps")
            .fetch_one(pool)
            .await
            .unwrap_or((0,));
        let evm_to_btc: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM evm_to_btc_swaps")
            .fetch_one(pool)
            .await
            .unwrap_or((0,));
        let btc_to_arkade: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM btc_to_arkade_swaps")
            .fetch_one(pool)
            .await
            .unwrap_or((0,));
        btc_to_evm.0 + evm_to_btc.0 + btc_to_arkade.0
    }

    async fn run_migrations(pool: &sqlx::SqlitePool) -> Result<()> {
        // Registry table to track which table contains each swap
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS swap_registry (
                swap_id TEXT PRIMARY KEY NOT NULL,
                swap_type TEXT NOT NULL
            )
            "#,
        )
        .execute(pool)
        .await
        .map_err(|e| anyhow::anyhow!("Failed to create swap_registry table: {}", e))?;

        // BTC → EVM swaps table
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS btc_to_evm_swaps (
                swap_id TEXT PRIMARY KEY NOT NULL,
                -- Common fields
                status TEXT NOT NULL,
                hash_lock TEXT NOT NULL,
                fee_sats INTEGER NOT NULL,
                asset_amount REAL NOT NULL,
                sender_pk TEXT NOT NULL,
                receiver_pk TEXT NOT NULL,
                server_pk TEXT NOT NULL,
                evm_refund_locktime INTEGER NOT NULL,
                vhtlc_refund_locktime INTEGER NOT NULL,
                unilateral_claim_delay INTEGER NOT NULL,
                unilateral_refund_delay INTEGER NOT NULL,
                unilateral_refund_without_receiver_delay INTEGER NOT NULL,
                network TEXT NOT NULL,
                created_at TEXT NOT NULL,
                -- BtcToEvm specific
                htlc_address_evm TEXT NOT NULL,
                htlc_address_arkade TEXT NOT NULL,
                user_address_evm TEXT NOT NULL,
                ln_invoice TEXT NOT NULL,
                sats_receive INTEGER NOT NULL,
                source_token TEXT NOT NULL,
                target_token TEXT NOT NULL,
                bitcoin_htlc_claim_txid TEXT,
                bitcoin_htlc_fund_txid TEXT,
                evm_htlc_claim_txid TEXT,
                evm_htlc_fund_txid TEXT,
                -- SwapParams
                secret_key TEXT NOT NULL,
                public_key TEXT NOT NULL,
                preimage TEXT NOT NULL,
                preimage_hash TEXT NOT NULL,
                user_id TEXT NOT NULL,
                key_index INTEGER NOT NULL
            )
            "#,
        )
        .execute(pool)
        .await
        .map_err(|e| anyhow::anyhow!("Failed to create btc_to_evm_swaps table: {}", e))?;

        // EVM → BTC swaps table
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS evm_to_btc_swaps (
                swap_id TEXT PRIMARY KEY NOT NULL,
                -- Common fields
                status TEXT NOT NULL,
                hash_lock TEXT NOT NULL,
                fee_sats INTEGER NOT NULL,
                asset_amount REAL NOT NULL,
                sender_pk TEXT NOT NULL,
                receiver_pk TEXT NOT NULL,
                server_pk TEXT NOT NULL,
                evm_refund_locktime INTEGER NOT NULL,
                vhtlc_refund_locktime INTEGER NOT NULL,
                unilateral_claim_delay INTEGER NOT NULL,
                unilateral_refund_delay INTEGER NOT NULL,
                unilateral_refund_without_receiver_delay INTEGER NOT NULL,
                network TEXT NOT NULL,
                created_at TEXT NOT NULL,
                -- EvmToBtc specific
                htlc_address_evm TEXT NOT NULL,
                htlc_address_arkade TEXT NOT NULL,
                user_address_evm TEXT NOT NULL,
                user_address_arkade TEXT,
                ln_invoice TEXT NOT NULL,
                source_token TEXT NOT NULL,
                target_token TEXT NOT NULL,
                sats_receive INTEGER NOT NULL,
                bitcoin_htlc_fund_txid TEXT,
                bitcoin_htlc_claim_txid TEXT,
                evm_htlc_claim_txid TEXT,
                evm_htlc_fund_txid TEXT,
                create_swap_tx TEXT,
                approve_tx TEXT,
                gelato_forwarder_address TEXT,
                gelato_user_nonce TEXT,
                gelato_user_deadline TEXT,
                source_token_address TEXT NOT NULL,
                -- SwapParams
                secret_key TEXT NOT NULL,
                public_key TEXT NOT NULL,
                preimage TEXT NOT NULL,
                preimage_hash TEXT NOT NULL,
                user_id TEXT NOT NULL,
                key_index INTEGER NOT NULL
            )
            "#,
        )
        .execute(pool)
        .await
        .map_err(|e| anyhow::anyhow!("Failed to create evm_to_btc_swaps table: {}", e))?;

        // BTC → Arkade swaps table
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS btc_to_arkade_swaps (
                swap_id TEXT PRIMARY KEY NOT NULL,
                status TEXT NOT NULL,
                btc_htlc_address TEXT NOT NULL,
                asset_amount INTEGER NOT NULL,
                sats_receive INTEGER NOT NULL,
                fee_sats INTEGER NOT NULL,
                hash_lock TEXT NOT NULL,
                btc_refund_locktime INTEGER NOT NULL,
                arkade_vhtlc_address TEXT NOT NULL,
                target_arkade_address TEXT NOT NULL,
                btc_fund_txid TEXT,
                btc_claim_txid TEXT,
                arkade_fund_txid TEXT,
                arkade_claim_txid TEXT,
                network TEXT NOT NULL,
                created_at TEXT NOT NULL,
                -- VHTLC parameters
                server_vhtlc_pk TEXT NOT NULL,
                arkade_server_pk TEXT NOT NULL,
                vhtlc_refund_locktime INTEGER NOT NULL,
                unilateral_claim_delay INTEGER NOT NULL,
                unilateral_refund_delay INTEGER NOT NULL,
                unilateral_refund_without_receiver_delay INTEGER NOT NULL,
                source_token TEXT NOT NULL,
                target_token TEXT NOT NULL,
                -- SwapParams
                secret_key TEXT NOT NULL,
                public_key TEXT NOT NULL,
                preimage TEXT NOT NULL,
                preimage_hash TEXT NOT NULL,
                user_id TEXT NOT NULL,
                key_index INTEGER NOT NULL
            )
            "#,
        )
        .execute(pool)
        .await
        .map_err(|e| anyhow::anyhow!("Failed to create btc_to_arkade_swaps table: {}", e))?;

        // Create indexes
        for table in &[
            "btc_to_evm_swaps",
            "evm_to_btc_swaps",
            "btc_to_arkade_swaps",
        ] {
            sqlx::query(&format!(
                "CREATE INDEX IF NOT EXISTS idx_{}_status ON {}(status)",
                table, table
            ))
            .execute(pool)
            .await
            .ok();
        }

        Ok(())
    }

    async fn migrate_json_files(pool: &sqlx::SqlitePool, json_dir: &Path) -> Result<()> {
        if !json_dir.exists() {
            return Ok(());
        }

        let entries = match fs::read_dir(json_dir) {
            Ok(entries) => entries,
            Err(_) => return Ok(()),
        };

        let mut migrated_count = 0;
        let mut failed_count = 0;

        for entry in entries.flatten() {
            let path = entry.path();
            if let Some(filename) = path.file_name().and_then(|n| n.to_str()) {
                if !filename.ends_with(".json") {
                    continue;
                }

                let swap_id = filename.trim_end_matches(".json");

                // Check if already in registry
                let exists: Option<(String,)> =
                    sqlx::query_as("SELECT swap_type FROM swap_registry WHERE swap_id = ?")
                        .bind(swap_id)
                        .fetch_optional(pool)
                        .await
                        .ok()
                        .flatten();

                if exists.is_some() {
                    continue;
                }

                match fs::read_to_string(&path) {
                    Ok(content) => {
                        match serde_json::from_str::<ExtendedSwapStorageData>(&content) {
                            Ok(data) => {
                                if Self::store_internal(pool, swap_id, &data).await.is_ok() {
                                    migrated_count += 1;
                                    // Delete the migrated JSON file
                                    if let Err(e) = fs::remove_file(&path) {
                                        tracing::warn!(
                                            "Failed to delete migrated JSON file {}: {}",
                                            filename,
                                            e
                                        );
                                    }
                                } else {
                                    failed_count += 1;
                                }
                            }
                            Err(e) => {
                                tracing::warn!("Failed to parse JSON file {}: {}", filename, e);
                                failed_count += 1;
                            }
                        }
                    }
                    Err(e) => {
                        tracing::warn!("Failed to read JSON file {}: {}", filename, e);
                        failed_count += 1;
                    }
                }
            }
        }

        if migrated_count > 0 || failed_count > 0 {
            tracing::info!(
                migrated = migrated_count,
                failed = failed_count,
                "Migrated JSON swap files to SQLite"
            );
        }

        Ok(())
    }

    async fn store_internal(
        pool: &sqlx::SqlitePool,
        swap_id: &str,
        data: &ExtendedSwapStorageData,
    ) -> Result<(), lendaswap_core::Error> {
        let swap_type = match &data.response {
            GetSwapResponse::BtcToEvm(_) => SwapType::BtcToEvm,
            GetSwapResponse::EvmToBtc(_) => SwapType::EvmToBtc,
            GetSwapResponse::BtcToArkade(_) => SwapType::BtcToArkade,
        };

        // Update registry
        sqlx::query(
            "INSERT INTO swap_registry (swap_id, swap_type) VALUES (?, ?)
             ON CONFLICT(swap_id) DO UPDATE SET swap_type = excluded.swap_type",
        )
        .bind(swap_id)
        .bind(swap_type.as_str())
        .execute(pool)
        .await
        .map_err(|e| lendaswap_core::Error::Other(format!("Failed to update registry: {}", e)))?;

        // Store in appropriate table
        match &data.response {
            GetSwapResponse::BtcToEvm(r) => {
                Self::store_btc_to_evm(pool, swap_id, r, &data.swap_params).await
            }
            GetSwapResponse::EvmToBtc(r) => {
                Self::store_evm_to_btc(pool, swap_id, r, &data.swap_params).await
            }
            GetSwapResponse::BtcToArkade(r) => {
                Self::store_btc_to_arkade(pool, swap_id, r, &data.swap_params).await
            }
        }
    }

    async fn store_btc_to_evm(
        pool: &sqlx::SqlitePool,
        swap_id: &str,
        r: &BtcToEvmSwapResponse,
        params: &SwapParams,
    ) -> Result<(), lendaswap_core::Error> {
        let created_at = r
            .common
            .created_at
            .format(&time::format_description::well_known::Rfc3339)
            .unwrap_or_default();

        sqlx::query(
            r#"
            INSERT INTO btc_to_evm_swaps (
                swap_id, status, hash_lock, fee_sats, asset_amount, sender_pk, receiver_pk, server_pk,
                evm_refund_locktime, vhtlc_refund_locktime, unilateral_claim_delay, unilateral_refund_delay,
                unilateral_refund_without_receiver_delay, network, created_at,
                htlc_address_evm, htlc_address_arkade, user_address_evm, ln_invoice, sats_receive,
                source_token, target_token, bitcoin_htlc_claim_txid, bitcoin_htlc_fund_txid,
                evm_htlc_claim_txid, evm_htlc_fund_txid,
                secret_key, public_key, preimage, preimage_hash, user_id, key_index
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(swap_id) DO UPDATE SET
                status = excluded.status, hash_lock = excluded.hash_lock, fee_sats = excluded.fee_sats,
                asset_amount = excluded.asset_amount, sender_pk = excluded.sender_pk, receiver_pk = excluded.receiver_pk,
                server_pk = excluded.server_pk, evm_refund_locktime = excluded.evm_refund_locktime,
                vhtlc_refund_locktime = excluded.vhtlc_refund_locktime, unilateral_claim_delay = excluded.unilateral_claim_delay,
                unilateral_refund_delay = excluded.unilateral_refund_delay,
                unilateral_refund_without_receiver_delay = excluded.unilateral_refund_without_receiver_delay,
                network = excluded.network, created_at = excluded.created_at,
                htlc_address_evm = excluded.htlc_address_evm, htlc_address_arkade = excluded.htlc_address_arkade,
                user_address_evm = excluded.user_address_evm, ln_invoice = excluded.ln_invoice,
                sats_receive = excluded.sats_receive, source_token = excluded.source_token, target_token = excluded.target_token,
                bitcoin_htlc_claim_txid = excluded.bitcoin_htlc_claim_txid, bitcoin_htlc_fund_txid = excluded.bitcoin_htlc_fund_txid,
                evm_htlc_claim_txid = excluded.evm_htlc_claim_txid, evm_htlc_fund_txid = excluded.evm_htlc_fund_txid,
                secret_key = excluded.secret_key, public_key = excluded.public_key, preimage = excluded.preimage,
                preimage_hash = excluded.preimage_hash, user_id = excluded.user_id, key_index = excluded.key_index
            "#,
        )
        .bind(swap_id)
        .bind(format!("{:?}", r.common.status))
        .bind(&r.common.hash_lock)
        .bind(r.common.fee_sats)
        .bind(r.common.asset_amount)
        .bind(&r.common.sender_pk)
        .bind(&r.common.receiver_pk)
        .bind(&r.common.server_pk)
        .bind(r.common.evm_refund_locktime as i64)
        .bind(r.common.vhtlc_refund_locktime as i64)
        .bind(r.common.unilateral_claim_delay)
        .bind(r.common.unilateral_refund_delay)
        .bind(r.common.unilateral_refund_without_receiver_delay)
        .bind(&r.common.network)
        .bind(&created_at)
        .bind(&r.htlc_address_evm)
        .bind(&r.htlc_address_arkade)
        .bind(&r.user_address_evm)
        .bind(&r.ln_invoice)
        .bind(r.sats_receive)
        .bind(r.source_token.as_str())
        .bind(r.target_token.as_str())
        .bind(&r.bitcoin_htlc_claim_txid)
        .bind(&r.bitcoin_htlc_fund_txid)
        .bind(&r.evm_htlc_claim_txid)
        .bind(&r.evm_htlc_fund_txid)
        .bind(hex::encode(params.secret_key.secret_bytes()))
        .bind(hex::encode(params.public_key.serialize()))
        .bind(hex::encode(params.preimage))
        .bind(hex::encode(params.preimage_hash))
        .bind(hex::encode(params.user_id.serialize()))
        .bind(params.key_index as i64)
        .execute(pool)
        .await
        .map_err(|e| lendaswap_core::Error::Other(format!("Failed to store BtcToEvm swap: {}", e)))?;

        Ok(())
    }

    async fn store_evm_to_btc(
        pool: &sqlx::SqlitePool,
        swap_id: &str,
        r: &EvmToBtcSwapResponse,
        params: &SwapParams,
    ) -> Result<(), lendaswap_core::Error> {
        let created_at = r
            .common
            .created_at
            .format(&time::format_description::well_known::Rfc3339)
            .unwrap_or_default();

        sqlx::query(
            r#"
            INSERT INTO evm_to_btc_swaps (
                swap_id, status, hash_lock, fee_sats, asset_amount, sender_pk, receiver_pk, server_pk,
                evm_refund_locktime, vhtlc_refund_locktime, unilateral_claim_delay, unilateral_refund_delay,
                unilateral_refund_without_receiver_delay, network, created_at,
                htlc_address_evm, htlc_address_arkade, user_address_evm, user_address_arkade, ln_invoice,
                source_token, target_token, sats_receive, bitcoin_htlc_fund_txid, bitcoin_htlc_claim_txid,
                evm_htlc_claim_txid, evm_htlc_fund_txid, create_swap_tx, approve_tx,
                gelato_forwarder_address, gelato_user_nonce, gelato_user_deadline, source_token_address,
                secret_key, public_key, preimage, preimage_hash, user_id, key_index
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(swap_id) DO UPDATE SET
                status = excluded.status, hash_lock = excluded.hash_lock, fee_sats = excluded.fee_sats,
                asset_amount = excluded.asset_amount, sender_pk = excluded.sender_pk, receiver_pk = excluded.receiver_pk,
                server_pk = excluded.server_pk, evm_refund_locktime = excluded.evm_refund_locktime,
                vhtlc_refund_locktime = excluded.vhtlc_refund_locktime, unilateral_claim_delay = excluded.unilateral_claim_delay,
                unilateral_refund_delay = excluded.unilateral_refund_delay,
                unilateral_refund_without_receiver_delay = excluded.unilateral_refund_without_receiver_delay,
                network = excluded.network, created_at = excluded.created_at,
                htlc_address_evm = excluded.htlc_address_evm, htlc_address_arkade = excluded.htlc_address_arkade,
                user_address_evm = excluded.user_address_evm, user_address_arkade = excluded.user_address_arkade,
                ln_invoice = excluded.ln_invoice, source_token = excluded.source_token, target_token = excluded.target_token,
                sats_receive = excluded.sats_receive, bitcoin_htlc_fund_txid = excluded.bitcoin_htlc_fund_txid,
                bitcoin_htlc_claim_txid = excluded.bitcoin_htlc_claim_txid, evm_htlc_claim_txid = excluded.evm_htlc_claim_txid,
                evm_htlc_fund_txid = excluded.evm_htlc_fund_txid, create_swap_tx = excluded.create_swap_tx,
                approve_tx = excluded.approve_tx, gelato_forwarder_address = excluded.gelato_forwarder_address,
                gelato_user_nonce = excluded.gelato_user_nonce, gelato_user_deadline = excluded.gelato_user_deadline,
                source_token_address = excluded.source_token_address,
                secret_key = excluded.secret_key, public_key = excluded.public_key, preimage = excluded.preimage,
                preimage_hash = excluded.preimage_hash, user_id = excluded.user_id, key_index = excluded.key_index
            "#,
        )
        .bind(swap_id)
        .bind(format!("{:?}", r.common.status))
        .bind(&r.common.hash_lock)
        .bind(r.common.fee_sats)
        .bind(r.common.asset_amount)
        .bind(&r.common.sender_pk)
        .bind(&r.common.receiver_pk)
        .bind(&r.common.server_pk)
        .bind(r.common.evm_refund_locktime as i64)
        .bind(r.common.vhtlc_refund_locktime as i64)
        .bind(r.common.unilateral_claim_delay)
        .bind(r.common.unilateral_refund_delay)
        .bind(r.common.unilateral_refund_without_receiver_delay)
        .bind(&r.common.network)
        .bind(&created_at)
        .bind(&r.htlc_address_evm)
        .bind(&r.htlc_address_arkade)
        .bind(&r.user_address_evm)
        .bind(&r.user_address_arkade)
        .bind(&r.ln_invoice)
        .bind(r.source_token.as_str())
        .bind(r.target_token.as_str())
        .bind(r.sats_receive)
        .bind(&r.bitcoin_htlc_fund_txid)
        .bind(&r.bitcoin_htlc_claim_txid)
        .bind(&r.evm_htlc_claim_txid)
        .bind(&r.evm_htlc_fund_txid)
        .bind(&r.create_swap_tx)
        .bind(&r.approve_tx)
        .bind(&r.gelato_forwarder_address)
        .bind(&r.gelato_user_nonce)
        .bind(&r.gelato_user_deadline)
        .bind(&r.source_token_address)
        .bind(hex::encode(params.secret_key.secret_bytes()))
        .bind(hex::encode(params.public_key.serialize()))
        .bind(hex::encode(params.preimage))
        .bind(hex::encode(params.preimage_hash))
        .bind(hex::encode(params.user_id.serialize()))
        .bind(params.key_index as i64)
        .execute(pool)
        .await
        .map_err(|e| lendaswap_core::Error::Other(format!("Failed to store EvmToBtc swap: {}", e)))?;

        Ok(())
    }

    async fn store_btc_to_arkade(
        pool: &sqlx::SqlitePool,
        swap_id: &str,
        r: &BtcToArkadeSwapResponse,
        params: &SwapParams,
    ) -> Result<(), lendaswap_core::Error> {
        let created_at = r
            .created_at
            .format(&time::format_description::well_known::Rfc3339)
            .unwrap_or_default();

        sqlx::query(
            r#"
            INSERT INTO btc_to_arkade_swaps (
                swap_id, status, btc_htlc_address, asset_amount, sats_receive, fee_sats, hash_lock,
                btc_refund_locktime, arkade_vhtlc_address, target_arkade_address,
                btc_fund_txid, btc_claim_txid, arkade_fund_txid, arkade_claim_txid, network, created_at,
                server_vhtlc_pk, arkade_server_pk, vhtlc_refund_locktime,
                unilateral_claim_delay, unilateral_refund_delay, unilateral_refund_without_receiver_delay,
                source_token, target_token,
                secret_key, public_key, preimage, preimage_hash, user_id, key_index
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(swap_id) DO UPDATE SET
                status = excluded.status, btc_htlc_address = excluded.btc_htlc_address,
                asset_amount = excluded.asset_amount, sats_receive = excluded.sats_receive,
                fee_sats = excluded.fee_sats, hash_lock = excluded.hash_lock,
                btc_refund_locktime = excluded.btc_refund_locktime, arkade_vhtlc_address = excluded.arkade_vhtlc_address,
                target_arkade_address = excluded.target_arkade_address,
                btc_fund_txid = excluded.btc_fund_txid, btc_claim_txid = excluded.btc_claim_txid,
                arkade_fund_txid = excluded.arkade_fund_txid, arkade_claim_txid = excluded.arkade_claim_txid,
                network = excluded.network, created_at = excluded.created_at,
                server_vhtlc_pk = excluded.server_vhtlc_pk, arkade_server_pk = excluded.arkade_server_pk,
                vhtlc_refund_locktime = excluded.vhtlc_refund_locktime,
                unilateral_claim_delay = excluded.unilateral_claim_delay,
                unilateral_refund_delay = excluded.unilateral_refund_delay,
                unilateral_refund_without_receiver_delay = excluded.unilateral_refund_without_receiver_delay,
                source_token = excluded.source_token, target_token = excluded.target_token,
                secret_key = excluded.secret_key, public_key = excluded.public_key, preimage = excluded.preimage,
                preimage_hash = excluded.preimage_hash, user_id = excluded.user_id, key_index = excluded.key_index
            "#,
        )
        .bind(swap_id)
        .bind(format!("{:?}", r.status))
        .bind(&r.btc_htlc_address)
        .bind(r.asset_amount)
        .bind(r.sats_receive)
        .bind(r.fee_sats)
        .bind(&r.hash_lock)
        .bind(r.btc_refund_locktime)
        .bind(&r.arkade_vhtlc_address)
        .bind(&r.target_arkade_address)
        .bind(&r.btc_fund_txid)
        .bind(&r.btc_claim_txid)
        .bind(&r.arkade_fund_txid)
        .bind(&r.arkade_claim_txid)
        .bind(&r.network)
        .bind(&created_at)
        .bind(&r.server_vhtlc_pk)
        .bind(&r.arkade_server_pk)
        .bind(r.vhtlc_refund_locktime)
        .bind(r.unilateral_claim_delay)
        .bind(r.unilateral_refund_delay)
        .bind(r.unilateral_refund_without_receiver_delay)
        .bind(r.source_token.as_str())
        .bind(r.target_token.as_str())
        .bind(hex::encode(params.secret_key.secret_bytes()))
        .bind(hex::encode(params.public_key.serialize()))
        .bind(hex::encode(params.preimage))
        .bind(hex::encode(params.preimage_hash))
        .bind(hex::encode(params.user_id.serialize()))
        .bind(params.key_index as i64)
        .execute(pool)
        .await
        .map_err(|e| lendaswap_core::Error::Other(format!("Failed to store BtcToArkade swap: {}", e)))?;

        Ok(())
    }

    fn parse_swap_params(
        secret_key: &str,
        public_key: &str,
        preimage: &str,
        preimage_hash: &str,
        user_id: &str,
        key_index: i64,
    ) -> Result<SwapParams, lendaswap_core::Error> {
        let secret_key_bytes = hex::decode(secret_key).map_err(|e| {
            lendaswap_core::Error::Other(format!("Failed to decode secret_key: {}", e))
        })?;
        let secret_key =
            bitcoin::secp256k1::SecretKey::from_slice(&secret_key_bytes).map_err(|e| {
                lendaswap_core::Error::Other(format!("Failed to parse secret_key: {}", e))
            })?;

        let public_key_bytes = hex::decode(public_key).map_err(|e| {
            lendaswap_core::Error::Other(format!("Failed to decode public_key: {}", e))
        })?;
        let public_key =
            bitcoin::secp256k1::PublicKey::from_slice(&public_key_bytes).map_err(|e| {
                lendaswap_core::Error::Other(format!("Failed to parse public_key: {}", e))
            })?;

        let preimage_bytes = hex::decode(preimage).map_err(|e| {
            lendaswap_core::Error::Other(format!("Failed to decode preimage: {}", e))
        })?;
        let preimage: [u8; 32] = preimage_bytes
            .try_into()
            .map_err(|_| lendaswap_core::Error::Other("Invalid preimage length".to_string()))?;

        let preimage_hash_bytes = hex::decode(preimage_hash).map_err(|e| {
            lendaswap_core::Error::Other(format!("Failed to decode preimage_hash: {}", e))
        })?;
        let preimage_hash: [u8; 32] = preimage_hash_bytes.try_into().map_err(|_| {
            lendaswap_core::Error::Other("Invalid preimage_hash length".to_string())
        })?;

        let user_id_bytes = hex::decode(user_id).map_err(|e| {
            lendaswap_core::Error::Other(format!("Failed to decode user_id: {}", e))
        })?;
        let user_id = bitcoin::secp256k1::PublicKey::from_slice(&user_id_bytes)
            .map_err(|e| lendaswap_core::Error::Other(format!("Failed to parse user_id: {}", e)))?;

        Ok(SwapParams {
            secret_key,
            public_key,
            preimage,
            preimage_hash,
            user_id,
            key_index: key_index as u32,
        })
    }

    fn row_to_btc_to_evm(
        row: BtcToEvmRow,
    ) -> Result<ExtendedSwapStorageData, lendaswap_core::Error> {
        let swap_params = Self::parse_swap_params(
            &row.secret_key,
            &row.public_key,
            &row.preimage,
            &row.preimage_hash,
            &row.user_id,
            row.key_index,
        )?;

        let id = Uuid::from_str(&row.swap_id)
            .map_err(|e| lendaswap_core::Error::Other(format!("Failed to parse swap_id: {}", e)))?;
        let status = parse_swap_status(&row.status)?;
        let created_at = OffsetDateTime::parse(
            &row.created_at,
            &time::format_description::well_known::Rfc3339,
        )
        .map_err(|e| lendaswap_core::Error::Other(format!("Failed to parse created_at: {}", e)))?;

        let common = SwapCommonFields {
            id,
            status,
            hash_lock: row.hash_lock,
            fee_sats: row.fee_sats,
            asset_amount: row.asset_amount,
            sender_pk: row.sender_pk,
            receiver_pk: row.receiver_pk,
            server_pk: row.server_pk,
            evm_refund_locktime: row.evm_refund_locktime as u32,
            vhtlc_refund_locktime: row.vhtlc_refund_locktime as u32,
            unilateral_claim_delay: row.unilateral_claim_delay,
            unilateral_refund_delay: row.unilateral_refund_delay,
            unilateral_refund_without_receiver_delay: row.unilateral_refund_without_receiver_delay,
            network: row.network,
            created_at,
        };

        let response = BtcToEvmSwapResponse {
            common,
            htlc_address_evm: row.htlc_address_evm,
            htlc_address_arkade: row.htlc_address_arkade,
            user_address_evm: row.user_address_evm,
            ln_invoice: row.ln_invoice,
            sats_receive: row.sats_receive,
            source_token: parse_token_id(&row.source_token),
            target_token: parse_token_id(&row.target_token),
            bitcoin_htlc_claim_txid: row.bitcoin_htlc_claim_txid,
            bitcoin_htlc_fund_txid: row.bitcoin_htlc_fund_txid,
            evm_htlc_claim_txid: row.evm_htlc_claim_txid,
            evm_htlc_fund_txid: row.evm_htlc_fund_txid,
        };

        Ok(ExtendedSwapStorageData {
            response: GetSwapResponse::BtcToEvm(response),
            swap_params,
        })
    }

    fn row_to_evm_to_btc(
        row: EvmToBtcRow,
    ) -> Result<ExtendedSwapStorageData, lendaswap_core::Error> {
        let swap_params = Self::parse_swap_params(
            &row.secret_key,
            &row.public_key,
            &row.preimage,
            &row.preimage_hash,
            &row.user_id,
            row.key_index,
        )?;

        let id = Uuid::from_str(&row.swap_id)
            .map_err(|e| lendaswap_core::Error::Other(format!("Failed to parse swap_id: {}", e)))?;
        let status = parse_swap_status(&row.status)?;
        let created_at = OffsetDateTime::parse(
            &row.created_at,
            &time::format_description::well_known::Rfc3339,
        )
        .map_err(|e| lendaswap_core::Error::Other(format!("Failed to parse created_at: {}", e)))?;

        let common = SwapCommonFields {
            id,
            status,
            hash_lock: row.hash_lock,
            fee_sats: row.fee_sats,
            asset_amount: row.asset_amount,
            sender_pk: row.sender_pk,
            receiver_pk: row.receiver_pk,
            server_pk: row.server_pk,
            evm_refund_locktime: row.evm_refund_locktime as u32,
            vhtlc_refund_locktime: row.vhtlc_refund_locktime as u32,
            unilateral_claim_delay: row.unilateral_claim_delay,
            unilateral_refund_delay: row.unilateral_refund_delay,
            unilateral_refund_without_receiver_delay: row.unilateral_refund_without_receiver_delay,
            network: row.network,
            created_at,
        };

        let response = EvmToBtcSwapResponse {
            common,
            htlc_address_evm: row.htlc_address_evm,
            htlc_address_arkade: row.htlc_address_arkade,
            user_address_evm: row.user_address_evm,
            user_address_arkade: row.user_address_arkade,
            ln_invoice: row.ln_invoice,
            source_token: parse_token_id(&row.source_token),
            target_token: parse_token_id(&row.target_token),
            sats_receive: row.sats_receive,
            bitcoin_htlc_fund_txid: row.bitcoin_htlc_fund_txid,
            bitcoin_htlc_claim_txid: row.bitcoin_htlc_claim_txid,
            evm_htlc_claim_txid: row.evm_htlc_claim_txid,
            evm_htlc_fund_txid: row.evm_htlc_fund_txid,
            create_swap_tx: row.create_swap_tx,
            approve_tx: row.approve_tx,
            gelato_forwarder_address: row.gelato_forwarder_address,
            gelato_user_nonce: row.gelato_user_nonce,
            gelato_user_deadline: row.gelato_user_deadline,
            source_token_address: row.source_token_address,
        };

        Ok(ExtendedSwapStorageData {
            response: GetSwapResponse::EvmToBtc(response),
            swap_params,
        })
    }

    fn row_to_btc_to_arkade(
        row: BtcToArkadeRow,
    ) -> Result<ExtendedSwapStorageData, lendaswap_core::Error> {
        let swap_params = Self::parse_swap_params(
            &row.secret_key,
            &row.public_key,
            &row.preimage,
            &row.preimage_hash,
            &row.user_id,
            row.key_index,
        )?;

        let id = Uuid::from_str(&row.swap_id)
            .map_err(|e| lendaswap_core::Error::Other(format!("Failed to parse swap_id: {}", e)))?;
        let status = parse_swap_status(&row.status)?;
        let created_at = OffsetDateTime::parse(
            &row.created_at,
            &time::format_description::well_known::Rfc3339,
        )
        .map_err(|e| lendaswap_core::Error::Other(format!("Failed to parse created_at: {}", e)))?;

        let response = BtcToArkadeSwapResponse {
            id,
            status,
            btc_htlc_address: row.btc_htlc_address,
            asset_amount: row.asset_amount,
            sats_receive: row.sats_receive,
            fee_sats: row.fee_sats,
            hash_lock: row.hash_lock,
            btc_refund_locktime: row.btc_refund_locktime,
            arkade_vhtlc_address: row.arkade_vhtlc_address,
            target_arkade_address: row.target_arkade_address,
            btc_fund_txid: row.btc_fund_txid,
            btc_claim_txid: row.btc_claim_txid,
            arkade_fund_txid: row.arkade_fund_txid,
            arkade_claim_txid: row.arkade_claim_txid,
            network: row.network,
            created_at,
            server_vhtlc_pk: row.server_vhtlc_pk,
            arkade_server_pk: row.arkade_server_pk,
            vhtlc_refund_locktime: row.vhtlc_refund_locktime,
            unilateral_claim_delay: row.unilateral_claim_delay,
            unilateral_refund_delay: row.unilateral_refund_delay,
            unilateral_refund_without_receiver_delay: row.unilateral_refund_without_receiver_delay,
            source_token: parse_token_id(&row.source_token),
            target_token: parse_token_id(&row.target_token),
        };

        Ok(ExtendedSwapStorageData {
            response: GetSwapResponse::BtcToArkade(response),
            swap_params,
        })
    }
}

/// Parse SwapStatus from string.
fn parse_swap_status(s: &str) -> Result<SwapStatus, lendaswap_core::Error> {
    match s {
        "Pending" => Ok(SwapStatus::Pending),
        "ClientFundingSeen" => Ok(SwapStatus::ClientFundingSeen),
        "ClientFunded" => Ok(SwapStatus::ClientFunded),
        "ServerFunded" => Ok(SwapStatus::ServerFunded),
        "ClientRedeeming" => Ok(SwapStatus::ClientRedeeming),
        "ClientRedeemed" => Ok(SwapStatus::ClientRedeemed),
        "ServerRedeemed" => Ok(SwapStatus::ServerRedeemed),
        "Expired" => Ok(SwapStatus::Expired),
        "ClientRefunded" => Ok(SwapStatus::ClientRefunded),
        "ClientFundedServerRefunded" => Ok(SwapStatus::ClientFundedServerRefunded),
        "ClientRefundedServerFunded" => Ok(SwapStatus::ClientRefundedServerFunded),
        "ClientRefundedServerRefunded" => Ok(SwapStatus::ClientRefundedServerRefunded),
        "ClientInvalidFunded" => Ok(SwapStatus::ClientInvalidFunded),
        "ClientFundedTooLate" => Ok(SwapStatus::ClientFundedTooLate),
        "ClientRedeemedAndClientRefunded" => Ok(SwapStatus::ClientRedeemedAndClientRefunded),
        _ => Err(lendaswap_core::Error::Other(format!(
            "Unknown SwapStatus: {}",
            s
        ))),
    }
}

impl SwapStorage for SwapDb {
    fn get(&self, swap_id: &str) -> StorageFuture<'_, Option<ExtendedSwapStorageData>> {
        let swap_id = swap_id.to_string();
        Box::pin(async move {
            // Look up swap type in registry
            let registry: Option<(String,)> =
                sqlx::query_as("SELECT swap_type FROM swap_registry WHERE swap_id = ?")
                    .bind(&swap_id)
                    .fetch_optional(&self.pool)
                    .await
                    .map_err(|e| {
                        lendaswap_core::Error::Other(format!("Failed to query registry: {}", e))
                    })?;

            let swap_type = match registry {
                Some((t,)) => match SwapType::from_str(&t) {
                    Some(st) => st,
                    None => return Ok(None),
                },
                None => return Ok(None),
            };

            match swap_type {
                SwapType::BtcToEvm => {
                    let row: Option<BtcToEvmRow> =
                        sqlx::query_as("SELECT * FROM btc_to_evm_swaps WHERE swap_id = ?")
                            .bind(&swap_id)
                            .fetch_optional(&self.pool)
                            .await
                            .map_err(|e| {
                                lendaswap_core::Error::Other(format!("Failed to get swap: {}", e))
                            })?;

                    match row {
                        Some(r) => Ok(Some(Self::row_to_btc_to_evm(r)?)),
                        None => Ok(None),
                    }
                }
                SwapType::EvmToBtc => {
                    let row: Option<EvmToBtcRow> =
                        sqlx::query_as("SELECT * FROM evm_to_btc_swaps WHERE swap_id = ?")
                            .bind(&swap_id)
                            .fetch_optional(&self.pool)
                            .await
                            .map_err(|e| {
                                lendaswap_core::Error::Other(format!("Failed to get swap: {}", e))
                            })?;

                    match row {
                        Some(r) => Ok(Some(Self::row_to_evm_to_btc(r)?)),
                        None => Ok(None),
                    }
                }
                SwapType::BtcToArkade => {
                    let row: Option<BtcToArkadeRow> =
                        sqlx::query_as("SELECT * FROM btc_to_arkade_swaps WHERE swap_id = ?")
                            .bind(&swap_id)
                            .fetch_optional(&self.pool)
                            .await
                            .map_err(|e| {
                                lendaswap_core::Error::Other(format!("Failed to get swap: {}", e))
                            })?;

                    match row {
                        Some(r) => Ok(Some(Self::row_to_btc_to_arkade(r)?)),
                        None => Ok(None),
                    }
                }
            }
        })
    }

    fn store(&self, swap_id: &str, data: &ExtendedSwapStorageData) -> StorageFuture<'_, ()> {
        let swap_id = swap_id.to_string();
        let data = data.clone();
        Box::pin(async move {
            Self::store_internal(&self.pool, &swap_id, &data).await?;
            tracing::debug!(swap_id = %swap_id, "Stored swap to SQLite");
            Ok(())
        })
    }

    fn delete(&self, swap_id: &str) -> StorageFuture<'_, ()> {
        let swap_id = swap_id.to_string();
        Box::pin(async move {
            // Look up swap type first
            let registry: Option<(String,)> =
                sqlx::query_as("SELECT swap_type FROM swap_registry WHERE swap_id = ?")
                    .bind(&swap_id)
                    .fetch_optional(&self.pool)
                    .await
                    .map_err(|e| {
                        lendaswap_core::Error::Other(format!("Failed to query registry: {}", e))
                    })?;

            if let Some((swap_type,)) = registry {
                let table = match swap_type.as_str() {
                    "BtcToEvm" => "btc_to_evm_swaps",
                    "EvmToBtc" => "evm_to_btc_swaps",
                    "BtcToArkade" => "btc_to_arkade_swaps",
                    _ => return Ok(()),
                };

                sqlx::query(&format!("DELETE FROM {} WHERE swap_id = ?", table))
                    .bind(&swap_id)
                    .execute(&self.pool)
                    .await
                    .map_err(|e| {
                        lendaswap_core::Error::Other(format!("Failed to delete swap: {}", e))
                    })?;
            }

            // Delete from registry
            sqlx::query("DELETE FROM swap_registry WHERE swap_id = ?")
                .bind(&swap_id)
                .execute(&self.pool)
                .await
                .map_err(|e| {
                    lendaswap_core::Error::Other(format!("Failed to delete from registry: {}", e))
                })?;

            tracing::debug!(swap_id = %swap_id, "Deleted swap from SQLite");
            Ok(())
        })
    }

    fn list(&self) -> StorageFuture<'_, Vec<String>> {
        Box::pin(async move {
            let rows: Vec<(String,)> = sqlx::query_as("SELECT swap_id FROM swap_registry")
                .fetch_all(&self.pool)
                .await
                .map_err(|e| {
                    lendaswap_core::Error::Other(format!("Failed to list swaps: {}", e))
                })?;

            Ok(rows.into_iter().map(|(id,)| id).collect())
        })
    }

    fn get_all(&self) -> StorageFuture<'_, Vec<ExtendedSwapStorageData>> {
        Box::pin(async move {
            let mut swaps = Vec::new();

            // Get all BtcToEvm swaps
            let btc_to_evm_rows: Vec<BtcToEvmRow> =
                sqlx::query_as("SELECT * FROM btc_to_evm_swaps")
                    .fetch_all(&self.pool)
                    .await
                    .map_err(|e| {
                        lendaswap_core::Error::Other(format!("Failed to get swaps: {}", e))
                    })?;

            for row in btc_to_evm_rows {
                match Self::row_to_btc_to_evm(row) {
                    Ok(data) => swaps.push(data),
                    Err(e) => tracing::warn!("Failed to convert BtcToEvm row: {}", e),
                }
            }

            // Get all EvmToBtc swaps
            let evm_to_btc_rows: Vec<EvmToBtcRow> =
                sqlx::query_as("SELECT * FROM evm_to_btc_swaps")
                    .fetch_all(&self.pool)
                    .await
                    .map_err(|e| {
                        lendaswap_core::Error::Other(format!("Failed to get swaps: {}", e))
                    })?;

            for row in evm_to_btc_rows {
                match Self::row_to_evm_to_btc(row) {
                    Ok(data) => swaps.push(data),
                    Err(e) => tracing::warn!("Failed to convert EvmToBtc row: {}", e),
                }
            }

            // Get all BtcToArkade swaps
            let btc_to_arkade_rows: Vec<BtcToArkadeRow> =
                sqlx::query_as("SELECT * FROM btc_to_arkade_swaps")
                    .fetch_all(&self.pool)
                    .await
                    .map_err(|e| {
                        lendaswap_core::Error::Other(format!("Failed to get swaps: {}", e))
                    })?;

            for row in btc_to_arkade_rows {
                match Self::row_to_btc_to_arkade(row) {
                    Ok(data) => swaps.push(data),
                    Err(e) => tracing::warn!("Failed to convert BtcToArkade row: {}", e),
                }
            }

            Ok(swaps)
        })
    }
}

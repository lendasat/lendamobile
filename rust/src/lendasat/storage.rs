//! Lendasat local storage module.
//!
//! Handles persistent storage of JWT tokens and user data.

use anyhow::{anyhow, Result};
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::Path;

const LENDASAT_AUTH_FILE: &str = "lendasat_auth.json";

/// Stored authentication data
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StoredAuth {
    pub jwt_token: String,
    pub user_id: String,
    pub user_name: String,
    pub user_email: Option<String>,
    pub pubkey: String,
    pub created_at: i64,
    pub expires_at: Option<i64>,
}

impl StoredAuth {
    /// Check if the token is potentially expired
    /// (actual validation happens on the server)
    pub fn is_potentially_expired(&self) -> bool {
        if let Some(expires_at) = self.expires_at {
            let now = std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .map(|d| d.as_secs() as i64)
                .unwrap_or(0);
            now >= expires_at
        } else {
            // If no expiry set, assume token is valid for 24 hours
            let now = std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .map(|d| d.as_secs() as i64)
                .unwrap_or(0);
            let one_day = 24 * 60 * 60;
            now >= self.created_at + one_day
        }
    }
}

/// Load stored authentication from disk
pub fn load_auth(data_dir: &str) -> Result<Option<StoredAuth>> {
    let path = Path::new(data_dir).join(LENDASAT_AUTH_FILE);

    if !path.exists() {
        return Ok(None);
    }

    let content =
        fs::read_to_string(&path).map_err(|e| anyhow!("Failed to read auth file: {}", e))?;

    let auth: StoredAuth =
        serde_json::from_str(&content).map_err(|e| anyhow!("Failed to parse auth file: {}", e))?;

    Ok(Some(auth))
}

/// Save authentication to disk
pub fn save_auth(data_dir: &str, auth: &StoredAuth) -> Result<()> {
    let path = Path::new(data_dir).join(LENDASAT_AUTH_FILE);

    let content =
        serde_json::to_string_pretty(auth).map_err(|e| anyhow!("Failed to serialize auth: {}", e))?;

    fs::write(&path, content).map_err(|e| anyhow!("Failed to write auth file: {}", e))?;

    Ok(())
}

/// Delete stored authentication
pub fn delete_auth(data_dir: &str) -> Result<()> {
    let path = Path::new(data_dir).join(LENDASAT_AUTH_FILE);

    if path.exists() {
        fs::remove_file(&path).map_err(|e| anyhow!("Failed to delete auth file: {}", e))?;
    }

    Ok(())
}

/// Check if authentication exists
pub fn has_auth(data_dir: &str) -> bool {
    let path = Path::new(data_dir).join(LENDASAT_AUTH_FILE);
    path.exists()
}

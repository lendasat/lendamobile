use anyhow::{Result, anyhow};
use ark_core::ArkAddress;
use bitcoin::address::NetworkUnchecked;
use bitcoin::{Address, Amount};
use std::collections::HashMap;
use std::str::FromStr;
use url::form_urlencoded;

pub struct DecodedUri {
    pub btc_address: Option<Address<NetworkUnchecked>>,
    pub ark_address: Option<ArkAddress>,
    pub amount: Option<Amount>,
}

pub fn decode_bip21(uri: &str) -> Result<DecodedUri> {
    if !is_bip21(uri) {
        return Err(anyhow!("Invalid BIP21 URI: {}", uri));
    }

    let parts: Vec<&str> = uri.splitn(2, ':').collect();
    let scheme = parts[0].to_string();
    let rest = parts[1];

    let mut destination = rest.to_string();
    let mut query = None;

    if let Some(_query_idx) = rest.find('?') {
        let split: Vec<&str> = rest.splitn(2, '?').collect();
        destination = split[0].to_string();
        query = Some(split[1].to_string());
    }

    let mut options: Option<HashMap<String, String>> = None;
    let mut amount: Option<Amount> = None;

    if let Some(q) = query {
        let mut map = HashMap::new();
        for (key, value) in form_urlencoded::parse(q.as_bytes()) {
            map.insert(key.to_string(), value.to_string());
        }

        if let Some(amount_str) = map.get("amount") {
            match amount_str.parse::<f64>() {
                Ok(btc_amount) => {
                    let sats = Amount::from_btc(btc_amount)?;

                    amount = Some(sats);
                }
                Err(_) => return Err(anyhow!("Invalid amount")),
            }
        }

        options = Some(map);
    }

    // Check for ark address in scheme or query params (supports both 'ark' and legacy 'arkade')
    let ark_address = if scheme.starts_with("ark") {
        let address = ArkAddress::decode(destination.as_str())?;
        Some(address)
    } else if let Some(address) = options
        .as_ref()
        .and_then(|o| o.get("ark").or_else(|| o.get("arkade")).cloned())
    {
        let address = ArkAddress::decode(address.as_str())?;
        Some(address)
    } else {
        None
    };

    let btc_address = if scheme.starts_with("bitcoin") {
        let address = Address::from_str(destination.as_str())?;
        Some(address)
    } else if let Some(address) = options.as_ref().and_then(|o| o.get("bitcoin").cloned()) {
        let address = Address::from_str(address.as_str())?;
        Some(address)
    } else {
        None
    };

    Ok(DecodedUri {
        btc_address,
        ark_address,
        amount,
    })
}

pub fn is_bip21(data: &str) -> bool {
    data.starts_with("bitcoin:") || data.starts_with("ark:")
}

pub fn is_ark_address(data: &str) -> bool {
    data.starts_with("ark1") || data.starts_with("tark1")
}

pub fn is_btc_address(data: &str) -> bool {
    data.starts_with("bc1") || data.starts_with("tb1") || data.starts_with("bcrt1")
}

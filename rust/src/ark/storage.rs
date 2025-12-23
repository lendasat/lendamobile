use ark_client::Error;
use ark_client::error::IntoError;
use ark_client::wallet::Persistence;
use ark_core::BoardingOutput;
use bitcoin::XOnlyPublicKey;
use bitcoin::secp256k1::SecretKey;
use std::collections::HashMap;
use std::sync::RwLock;

#[derive(Default)]
pub struct InMemoryDb {
    boarding_outputs: RwLock<HashMap<BoardingOutput, SecretKey>>,
}

impl Persistence for InMemoryDb {
    fn save_boarding_output(
        &self,
        sk: SecretKey,
        boarding_output: BoardingOutput,
    ) -> Result<(), Error> {
        let mut guard = self.boarding_outputs.write().map_err(|e| {
            format!("Failed to acquire write lock for boarding outputs: {e}").into_error()
        })?;
        guard.insert(boarding_output, sk);

        Ok(())
    }

    fn load_boarding_outputs(&self) -> Result<Vec<BoardingOutput>, Error> {
        let guard = self.boarding_outputs.read().map_err(|e| {
            format!("Failed to acquire read lock for boarding outputs: {e}").into_error()
        })?;
        Ok(guard.clone().into_keys().collect())
    }

    fn sk_for_pk(&self, pk: &XOnlyPublicKey) -> Result<SecretKey, Error> {
        let guard = self.boarding_outputs.read().map_err(|e| {
            format!("Failed to acquire read lock for boarding outputs: {e}").into_error()
        })?;
        let secret_key = guard
            .iter()
            .find_map(|(b, sk)| if b.owner_pk() == *pk { Some(*sk) } else { None })
            .ok_or_else(|| format!("No secret key found for public key: {pk}").into_error())?;
        Ok(secret_key)
    }
}

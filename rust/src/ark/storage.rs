use ark_rs::client::wallet::Persistence;
use ark_rs::client::Error;
use ark_rs::core::BoardingOutput;
use bitcoin::secp256k1::SecretKey;
use bitcoin::XOnlyPublicKey;
use std::sync::RwLock;

#[derive(Default)]
pub struct InMemoryDb {
    boarding_outputs: RwLock<Vec<(SecretKey, BoardingOutput)>>,
}

impl Persistence for InMemoryDb {
    fn save_boarding_output(
        &self,
        sk: SecretKey,
        boarding_output: BoardingOutput,
    ) -> Result<(), Error> {
        self.boarding_outputs
            .write()
            .unwrap()
            .push((sk, boarding_output));

        Ok(())
    }

    fn load_boarding_outputs(&self) -> Result<Vec<BoardingOutput>, Error> {
        Ok(self
            .boarding_outputs
            .read()
            .unwrap()
            .clone()
            .into_iter()
            .map(|(_, b)| b)
            .collect())
    }

    fn sk_for_pk(&self, pk: &XOnlyPublicKey) -> Result<SecretKey, Error> {
        let maybe_sk = self
            .boarding_outputs
            .read()
            .unwrap()
            .iter()
            .find_map(|(sk, b)| if b.owner_pk() == *pk { Some(*sk) } else { None });
        let secret_key = maybe_sk.unwrap();
        Ok(secret_key)
    }
}

import gleeunit
import lumina_server/data

// Imported to test
import lumina_server/async_crypto

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn async_crypto_1_test() {
  let keys = async_crypto.generate_keypair()

  let signature =
    async_crypto.sign(
      message: <<"Hello, Joe!":utf8>>,
      private_key: keys.private_key,
    )
  // Correct contents
  assert async_crypto.verify(
    message: <<"Hello, Joe!":utf8>>,
    signature:,
    pub_key: keys.public_key,
  )
  // Forged contents
  assert !async_crypto.verify(
    message: <<"Bye, Joe?":utf8>>,
    signature:,
    pub_key: keys.public_key,
  )
}

/// Parses the did found in https://w3c-ccg.github.io/did-key-spec/#example-a-simple-ed25519-did-key-value
/// and matches it against what in my belief should be the original public key.
pub fn did_key_ref_decode_test() {
  let ref = "did:key:z6MkhaXgBZDvotDkL5257faiztiGiC2QtKLGpbnnEGta2doK"
  assert data.pk_ldid_decode(ref)
    == Ok(<<
      46,
      111,
      204,
      227,
      103,
      1,
      220,
      121,
      20,
      136,
      224,
      208,
      177,
      116,
      92,
      193,
      227,
      58,
      76,
      28,
      159,
      204,
      65,
      198,
      59,
      211,
      67,
      219,
      190,
      9,
      112,
      230,
    >>)
}

pub fn did_key_did_lumina_match_test() {
  let pubkey = async_crypto.generate_keypair().public_key

  let keydid = data.pk_ldid_key_encode(pubkey)

  let lumdid = data.pk_ldid_encode(pubkey)
  let assert #(Ok(decoded_lum), Ok(decoded_key)) = #(
    data.pk_ldid_decode(lumdid),
    data.pk_ldid_decode(keydid),
  )
  assert decoded_lum == decoded_key
}

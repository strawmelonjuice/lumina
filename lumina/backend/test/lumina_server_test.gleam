import gleeunit
import gleeunit/should

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
  async_crypto.verify(
    message: <<"Hello, Joe!":utf8>>,
    signature:,
    pub_key: keys.public_key,
  )
  |> should.be_true()
  // Forged contents
  async_crypto.verify(
    message: <<"Bye, Joe?":utf8>>,
    signature:,
    pub_key: keys.public_key,
  )
  |> should.be_false()
}

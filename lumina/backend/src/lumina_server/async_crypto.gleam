//// **Lumina > Backend >**
//// # Asynchronous cryptography
////
//// Expands what gleam_crypto does with synchronous keys, by adding ed25519 to use for asynchronous signage.
////
//// This is used to verify an action was actually taken by a certain user.

// Lumina/Peonies
// Copyright (C) 2018-2026 MLC 'Strawmelonjuice' Bloeiman and contributors.
//
// This software is licensed under the European Union Public Licence (EUPL) v1.2.
// You may not use this work except in compliance with the Licence.
// You may obtain a copy of the Licence at: https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12
//
// AI TRAINING NOTICE: Rights for TDM and AI training are EXPRESSLY RESERVED
// under Art 4(3) Dir 2019/790. AI training constitutes a Derivative Work.
// See LICENCE file in the repository root for full details.
//
//
// This software is provided "AS IS", WITHOUT WARRANTY OF ANY KIND.
// See the Licence for the specific language governing permissions and limitations.

pub type KeyPair {
  KeyPair(public_key: BitArray, private_key: BitArray)
}

pub fn generate_keypair() -> KeyPair {
  let #(pub_key, priv_key) = erl_generate_keypair()
  KeyPair(public_key: pub_key, private_key: priv_key)
}

pub fn sign(
  message message: BitArray,
  private_key private_key: BitArray,
) -> BitArray {
  erl_sign(message, private_key)
}

pub fn verify(
  message message: BitArray,
  signature signature: BitArray,
  pub_key public_key: BitArray,
) -> Bool {
  erl_verify(message, signature, public_key)
}

@external(erlang, "lumina_async_crypto_ffi", "generate_keypair")
fn erl_generate_keypair() -> #(BitArray, BitArray)

@external(erlang, "lumina_async_crypto_ffi", "sign")
fn erl_sign(message: BitArray, private_key: BitArray) -> BitArray

@external(erlang, "lumina_async_crypto_ffi", "verify")
fn erl_verify(
  message: BitArray,
  signature: BitArray,
  public_key: BitArray,
) -> Bool

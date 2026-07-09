-module(lumina_async_crypto_ffi).
-export([generate_keypair/0, sign/2, verify/3]).

generate_keypair() ->
    crypto:generate_key(eddsa, ed25519).

sign(Message, PrivateKey) ->
    crypto:sign(eddsa, none, Message, [PrivateKey, ed25519]).

verify(Message, Signature, PublicKey) ->
    crypto:verify(eddsa, none, Message, Signature, [PublicKey, ed25519]).

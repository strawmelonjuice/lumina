%% **Lumina > Backend > Erlang Native Implementations >**
%% # Asynchronous cryptography
%%


-module(lumina_async_crypto_ffi).

-export([generate_keypair/0, sign/2, verify/3]).

%% Generates an ed25519 keypair, used for the identification and signing of a Lumina user!
generate_keypair() ->
    crypto:generate_key(eddsa, ed25519).

%% Sign a message using ed25519.
sign(Message, PrivateKey) ->
    crypto:sign(eddsa, none, Message, [PrivateKey, ed25519]).

%% Verify a signature on a ed25519 signed message.
verify(Message, Signature, PublicKey) ->
    crypto:verify(eddsa, none, Message, Signature, [PublicKey, ed25519]).

[![CircleCI](https://circleci.com/gh/GrappigPanda/paseto_plug/tree/master.svg?style=svg)](https://circleci.com/gh/GrappigPanda/paseto_plug/tree/master)
[![Hex.pm](https://img.shields.io/hexpm/v/paseto_plug.svg)](https://hex.pm/packages/paseto_plug)
[HexDocs](https://hexdocs.pm/paseto_plug/api-reference.html)

# paseto_plug

A Phoenix authentication plug that validates Paseto (Platform Agnostic Security Tokens).

## Installation

This package can be installed by adding `paseto_plug` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:paseto_plug, "~> 0.1.0"}
  ]
end
```

## Considerations for using this library

There are a few library/binary requirements required in order for the Paseto 
library to work on any computer:
1. Erlang version >= 20.1
    * This is required because this was the first Erlang version to introduce
      crypto:sign/5.
2. libsodium >= 1.0.13 
    * This is required for cryptography used in Paseto.
    * This can be found at https://github.com/jedisct1/libsodium
3. openssl >= 1.1 
    * This is needed for XChaCha-Poly1305 used for V2.Local Paseto

## Using the plug

This plug, solely, handles taking a Paseto and validating it was issued by your key(-pair).
Should you need more information on generating a Paseto, take a look at my other project over here:
https://github.com/GrappigPanda/paseto

So, in order to use the plug, you will need to include the following in your `router.ex` file.

```elixir
plug PasetoPlug, key_provider: &KeyProvider.get_key/0
```

Moreover, you will need to write a key provider module + function. This can be as simple as the following:

```elixir
defmodule KeyProvider do
  def get_key() do
    "safe_key"
  end
end
```

Now, whenever a request goes through, the requester will either face a 401 (if they have an invalid paseto) or your `conn` will have a new `:claims` key in the `assigns` map.

```elixir
# You can grab it by using
conn.assigns.claims
```

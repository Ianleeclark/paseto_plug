defmodule PasetoPlugTest.V2 do
  use ExUnit.Case
  use Plug.Test

  alias KeyProvider

  doctest PasetoPlug

  defmodule KeyProvider do
    @public_key Salty.Sign.Ed25519.keypair()

    def public_key_provider do
      {:ok, pk, sk} = @public_key
      {pk, sk}
    end

    def public_key_provider_pk do
      {:ok, pk, _sk} = @public_key
      pk
    end

    def public_key_provider_sk do
      {:ok, _pk, sk} = @public_key
      sk
    end

    def local_key_provider do
      <<56, 165, 237, 250, 173, 90, 82, 73, 227, 45, 166, 36, 121, 213, 122, 227, 188, 168, 248, 190, 39, 11, 243, 40, 236, 206, 123, 237, 189, 43, 220, 66>>
    end
  end

  defmodule TestRouterPublic do
    import Plug.Conn
    use Plug.Router

    alias KeyProvider

    plug PasetoPlug, key_provider: &KeyProvider.public_key_provider/0

    get "/" do
      send_resp(conn, 200, "Paseto verified")
    end
  end

  defmodule TestRouterPublicInvalid do
    import Plug.Conn
    use Plug.Router

    plug PasetoPlug, key_provider: fn -> :crypto.generate_key(:rsa, {2048, 65_637}) end

    get "/" do
      send_resp(conn, 200, "Paseto verified")
    end
  end

  defmodule TestRouterLocal do
    import Plug.Conn
    use Plug.Router

    alias KeyProvider

    plug PasetoPlug, key_provider: &KeyProvider.local_key_provider/0

    get "/" do
      send_resp(conn, 200, "Paseto verified")
    end
  end

  defmodule TestRouterLocalInvalid do
    import Plug.Conn
    use Plug.Router

    plug PasetoPlug, key_provider: fn -> "invalid_key" end

    get "/" do
      send_resp(conn, 200, "Paseto verified")
    end
  end

  describe "V2 Plug Tests" do
    test "Invalid V2 local token" do
      conn =
        conn(:get, "/")
        |> put_req_header("authorization", "Bearer v2.local.VGhpcyBpcyBhIHRlc3QgbWVzc2FnZSe-sJyD2x_fCDGEUKDcvjU9y3jRHxD4iEJ8iQwwfMUq5jUR47J15uPbgyOmBkQCxNDydR0yV1iBR-GPpyE-NQw")

      assert TestRouterLocalInvalid.call(conn, []).status == 401
    end

    test "Valid V2 local token" do
      key = KeyProvider.local_key_provider()
      paseto = Paseto.V2.encrypt("test data", key)
      {:ok, paseto_token} = Paseto.parse_token(paseto, key)

      conn =
        conn(:get, "/")
        |> put_req_header("authorization", "Bearer #{paseto}")

      retval = TestRouterLocal.call(conn, [])
      assert retval.assigns.claims == paseto_token
    end

    test "Invalid V2 public token" do
      conn =
        conn(:get, "/")
        |> put_req_header("authorization", "Bearer v2.public.VGhpcyBpcyBhIHRlc3QgbWVzc2FnZSe-sJyD2x_fCDGEUKDcvjU9y3jRHxD4iEJ8iQwwfMUq5jUR47J15uPbgyOmBkQCxNDydR0yV1iBR-GPpyE-NQw")

      assert TestRouterPublicInvalid.call(conn, []).status == 401
    end

    test "Valid V2 public token" do
      key = KeyProvider.public_key_provider()
      secret_key = KeyProvider.public_key_provider_sk()
      paseto = Paseto.V2.sign("test data", secret_key)
      {:ok, paseto_token} = Paseto.parse_token(paseto, key)

      conn =
        conn(:get, "/")
        |> put_req_header("authorization", "Bearer #{paseto}")

      retval = TestRouterPublic.call(conn, [])
      assert retval.assigns.claims == paseto_token
    end
  end
end

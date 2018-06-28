defmodule PasetoPlugTest.V1 do
  use ExUnit.Case
  use Plug.Test

  alias KeyProvider

  doctest PasetoPlug

  defmodule KeyProvider do
    @public_exponent 65_537
    @public_key :crypto.generate_key(:rsa, {2048, @public_exponent})
    @local_key "test_local_key"

    def public_key_provider do
      @public_key
    end

    def public_key_provider_pk do
      {pk, _sk} = @public_key
      pk
    end

    def public_key_provider_sk do
      {_pk, sk} = @public_key
      sk
    end

    def local_key_provider do
      @local_key
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

  describe "V1 Plug Tests" do
    # test "Invalid V1 local token" do
    #   conn =
    #     conn(:get, "/")
    #     |> put_req_header("authorization", "Bearer v1.local.VGhpcyBpcyBhIHRlc3QgbWVzc2FnZSe-sJyD2x_fCDGEUKDcvjU9y3jRHxD4iEJ8iQwwfMUq5jUR47J15uPbgyOmBkQCxNDydR0yV1iBR-GPpyE-NQw")

    #   assert TestRouterLocalInvalid.call(conn, []).status == 401
    # end

    test "Valid V1 local token" do
      local_key = KeyProvider.local_key_provider()
      paseto = Paseto.V1.encrypt("test data", local_key)
      {:ok, paseto_token} = Paseto.parse_token(paseto, local_key)

      conn =
        conn(:get, "/")
        |> put_req_header("authorization", "Bearer #{paseto}")

      retval = TestRouterLocal.call(conn, [])
      assert retval.assigns.claims == paseto_token
    end

    test "Invalid V1 public token" do
      conn =
        conn(:get, "/")
        |> put_req_header("authorization", "Bearer v1.public.dGVzdCBkYXRhecLVdIi75R6KdGB9wQkKIvB3G1St3flaBgmGefpCW6ujItt8Zfe3vKGnvjIu17NYTsQtAxZzwfT4_SqMCPVuyBwv_DXVmtvLD-edR4-ZiqflP7GOqxILTfGQftsHnWs9brZzz0hOh1_jyPbsZdBrwnR4E0kgHFEKfaOYzekdLdiOs8sbA9ylFdk6_Ma21F-fvFDxWpqkZmcey3CRjR_sdswgvNiCD1SfcPEv3eEHWFrO_7IJkaQDOlDZuv6gh5K4Khj9cfaDn05OaWlAO5esEbBYnaUGy9yyomekwCy4afqhLM-OaZ6EmINkLL47a2H3BcbqbdwVt9-BGnzY0togaw")

      assert TestRouterPublicInvalid.call(conn, []).status == 401
    end

    test "Valid V1 public token" do
      key = KeyProvider.public_key_provider()
      secret_key = KeyProvider.public_key_provider_sk()
      paseto = Paseto.V1.sign("test data", secret_key)
      {:ok, paseto_token} = Paseto.parse_token(paseto, key)

      conn =
        conn(:get, "/")
        |> put_req_header("authorization", "Bearer #{paseto}")

      retval = TestRouterPublic.call(conn, [])
      assert retval.assigns.claims == paseto_token
    end
  end
end

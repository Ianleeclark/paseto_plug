defmodule PasetoPlugTest do
  use ExUnit.Case
  use Plug.Test

  doctest PasetoPlug

  defmodule KeyProvider do
    @public_exponent 65_537
    @public_key :crypto.generate_key(:rsa, {2048, @public_exponent})
    @local_key "test_local_key"

    def public_key_provider do
      @public_key
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

  defmodule TestRouterPrivate do
    import Plug.Conn
    use Plug.Router

    alias KeyProvider

    plug PasetoPlug, key_provider: &KeyProvider.local_key_provider/0

    get "/" do
      send_resp(conn, 200, "Paseto verified")
    end
  end

  describe "V2 Plug Tests" do
    test "Invalid V2 local token" do
      conn =
        conn(:get, "/")
        |> put_req_header("authorization", "Bearer v2.local.VGhpcyBpcyBhIHRlc3QgbWVzc2FnZSe-sJyD2x_fCDGEUKDcvjU9y3jRHxD4iEJ8iQwwfMUq5jUR47J15uPbgyOmBkQCxNDydR0yV1iBR-GPpyE-NQw")

      assert TestRouterPublic.call(conn, []).status == 401
    end
  end
end

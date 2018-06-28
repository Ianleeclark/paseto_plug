defmodule PasetoPlug do
  @moduledoc """
  Documentation for PasetoPlug.
  """

  require Logger

  import Plug.Conn

  @type paseto_key :: {binary(), binary()} | binary()

  @spec init(%{key_provider: (() -> paseto_key)}) :: paseto_key
  def init(key_provider: key_provider) do
    key_provider.()
  end

  def call(conn, key) when is_binary(key) do
    do_call(conn, key)
  end
  def call(conn, public_key) do
    do_call(conn, public_key)
  end

  defp do_call(conn, key) do
    conn
    |> get_auth_token()
    |> case do
      {:ok, token} ->
        validate_token(token, key)
      error ->
        error
    end
    |> (&create_auth_response(conn, &1)).()
  end

  @spec get_auth_token(%Plug.Conn{}) :: {:ok, String.t()} | {:error, String.t()}
  defp get_auth_token(%Plug.Conn{} = conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        {:ok, String.trim(token)}

      error ->
        Logger.debug("Failed to grab `authorization` header from conn. Got #{inspect(error)}")
        {:error, "Invalid Authorization Header. Expected `Authorization: Bearer <token>`"}
    end
  end

  @spec validate_token(String.t(), paseto_key) :: {:ok, %Paseto.Token{}} | {:error, String.t()}
  defp validate_token(token, key) do
    token
    |> Paseto.parse_token(key)
  end

  @spec create_auth_response(
          %Plug.Conn{},
          {:ok, %Paseto.V1{} | %Paseto.V2{}} | {:error, String.t()}
        ) :: any()
  defp create_auth_response(%Plug.Conn{} = conn, token_validation) do
    case token_validation do
      {:ok, token} ->
        assign(conn, :claims, token)

      {:error, reason} ->
        conn
        |> send_resp(401, reason)
        |> halt()
    end
  end
end

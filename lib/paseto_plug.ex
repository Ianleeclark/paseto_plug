defmodule PasetoPlug do
  @moduledoc """
  Documentation for PasetoPlug.
  """

  require Logger

  import Plug.Conn

  def init(opts) do
  end

  def call(conn, config) do
    conn
    |> get_auth_token()
    |> case do
      {:ok, token} ->
        token
        |> validate_token()
        |> (&create_auth_response(conn, &1)).()

      error ->
        error
    end
  end

  @spec get_auth_token(%Plug.Conn{}) :: {:ok, String.t()} | {:error, String.t()}
  defp get_auth_token(%Plug.Conn{} = conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        {:ok, token}

      error ->
        Logger.debug("Failed to grab `authorization` header from conn. Got #{inspect(error)}")
        {:error, "Invalid Authorization Header. Expected `Authorization: Bearer <token>`"}
    end
  end

  @spec validate_token(String.t()) :: :ok | {:error, String.t()}
  defp validate_token(token) do
    token
    # TODO(ian): Need to get the key loaded
    |> Paseto.parse_token(key)
  end

  @spec create_auth_response(
          %Plug.Conn{},
          {:ok, %Paseto.V1{} | %Paseto.V2{}} | {:error, String.t()}
        ) :: any()
  defp create_auth_response(%Plug.Conn{} = conn, token_validation) do
    case token_validation do
      {:ok, token} ->
        assign(conn, :claims, token.payload)

      {:error, reason} ->
        conn
        |> send_resp(401, reason)
        |> halt()
    end
  end
end

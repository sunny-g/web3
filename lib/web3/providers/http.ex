defmodule Web3.Providers.HTTP do
  @moduledoc """
  An interface for querying an Ethereum node via the HTTP JSON-RPC API

  TODO: handle message sending concurrently
  """

  @behaviour Web3.Providers.Base

  require OK
  require HTTPoison
  require Poison
  import OK, only: ["~>>": 2]
  use GenServer

  @type env         :: %{
    required(:url)      => bitstring,
    optional(:id)       => non_neg_integer,
  }
  @type payload     :: %{
    required(:method)   => bitstring,
    optional(:params)   => [any],
  }

  @default_env      %{id: 0}
  @default_payload  %{jsonrpc: "2.0", params: []}
  @default_headers  [{"Content-Type", "application/json"}]

  #-------------------------------------------------------------------------#
  # PUBLIC API
  #-------------------------------------------------------------------------#

  @doc """
  Starts an RPC client process
  """
  @spec start_link(env, GenServer.options) :: GenServer.on_start
  def start_link(env, opts \\ []) when is_map(env) do
    GenServer.start_link(__MODULE__, env, opts)
  end

  @doc """
  Sends a JSON object to the Ethereum node, returns a response
  """
  @spec send_rpc(GenServer.name, payload) :: any
  def send_rpc(name, payload) do
    GenServer.call(name, {:send, payload})
  end

  #-------------------------------------------------------------------------#
  # SERVER
  #-------------------------------------------------------------------------#

  @spec init(env) :: {:ok, env}
  def init(env) do
    # TODO: validate `env`, return {:error, error} if invalid
    {:ok, extend_env(env)}
  end

  @spec handle_call({:send, payload}, GenServer.from, env) :: {:reply, any, env}
  def handle_call({:send, payload}, _from, %{id: id, url: url} = env) do
    response = handle_send(payload, id, url)

    {:reply, response, %{env | id: id + 1}}
  end

  #-------------------------------------------------------------------------#
  # CALLBACK IMPLEMENTATIONS
  #-------------------------------------------------------------------------#

  @spec handle_send(payload, non_neg_integer, bitstring) :: any
  defp handle_send(payload, id, url)
      when is_map(payload) and is_integer(id) and is_bitstring(url) do
    {:ok, body} = create_payload(payload, id)

    HTTPoison.post(url, body, @default_headers)
    |> handle_response
  end

  #-------------------------------------------------------------------------#
  # HELPERS
  #-------------------------------------------------------------------------#

  @doc false
  @spec extend_env(map) :: map
  defp extend_env(env), do: Map.merge(@default_env, env)

  @spec create_payload(payload, integer) :: bitstring
  defp create_payload(payload, id) when is_map(payload) and is_integer(id) do
    @default_payload
    |> Map.merge(%{id: id})
    |> Map.merge(payload)
    |> Poison.encode
  end

  # TODO: parse response for status code, handle accordingly
  @spec handle_response({:error, HTTPoison.Error}) :: {:error, any}
  defp handle_response({:error, %HTTPoison.Error{reason: reason}}) do
    IO.puts("received error: #{reason}")
    OK.failure(reason)
  end
  @spec handle_response({:ok, HTTPoison.Response}) :: {:ok, any} | {:error, any}
  defp handle_response({:ok, %HTTPoison.Response{body: body}}) do
    {:ok, body} = Poison.decode(body)

    case Map.fetch(body, "result") do
      OK.success(response) -> OK.success(response)
      :error ->
        Map.fetch(body, "error")
        ~>> OK.failure
    end
  end
end

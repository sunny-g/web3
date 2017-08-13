defmodule Web3.Providers.Base do
  @moduledoc """
  Base module for maintaining a connection with an Ethereum node
  """

  @doc """
  Starts the provider, or just returns :ok
  """
  @callback start_link(any) :: GenServer.on_start | :ok

  @doc """
  Sends a message to the Ethereum node, returns the successful/erroneous
  response, or confirmation of message delivery
  """
  @callback send_rpc(GenServer.name, map) :: {:ok, response :: any} | {:error, reason :: any}
end

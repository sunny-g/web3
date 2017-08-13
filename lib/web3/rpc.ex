defmodule Web3.RPC do
  @moduledoc """
  Ethereum client module for calling Ethereum RPC methods

  Example usage:


  """

  ## Example ##

  # spawns a new provider
  # {:ok, eth_rpc_pid} = Web3.RPC.start([
  #   provider: Web3.Provider.HTTP,
  #   url: url,
  #   timeout: timeout,
  # ])

  # rpc methods
  # Web3.RPC...

  # filters
  # :ok = Web3.RPC.new_filter(eth_rpc_pid, filter_args)
  # Web3.Filter...

  # contract
  # :ok = Web3.RPC.new_contract(eth_rpc_pid, [:abi, :bytecode, :default_tx_object])
  # Web3.Contract...

  defmacro __using__(provider: provider) do
    quote location: :keep do
      use Supervisor
      use Web3.Query

      # use Web3.Filter
      # use Web3.Contract

      @provider   unquote(provider)

      #-------------------------------------------------------------------------#
      # PUBLIC/API
      #-------------------------------------------------------------------------#

      @spec start_link(unquote(provider).env) :: any
      def start_link(provider_env) do
        Supervisor.start_link(__MODULE__, provider_env)
      end

      def send(payload) do
        # IO.inspect("calling send")
        @provider.send_rpc(__MODULE__, payload)
      end

      @doc """
      Spawns a Filter process, using `send` to poll for changes
      Should be provided a `pid` to cast events to
      ? returns a `pid`?
      """
      def new_filter() do
        """
        steps:
        - spawn a new filter process
        - it needs
        """

        # @filter.new
      end

      @doc """
      Spanws a Contract process, using `sendTransaction` to attempt to create a
      new contract on the blockchain
      ? polls to determine deployment success...?

      If txn fails, process shuts itself down and sends a failure message
      If txn succeeds, it establishes a filter

      Once created, exposes a call method to make requests to the blockchain
      uses `call` or `sendTransaction` to make requests
      """
      def new_contract() do
        # Contract.new(@filter.send, @filter.receive...)
      end

      @doc """
      """
      def contract_at() do
        # Contract.new(@filter.send, @filter.receive...)
      end

      #-------------------------------------------------------------------------#
      # SERVER
      #-------------------------------------------------------------------------#

      # @spec init(map) ::
      def init(provider_env) do
        children = [
          worker(@provider, [provider_env, [name: __MODULE__]])
        ]

        supervise(children, strategy: :one_for_one)
      end

      defoverridable [start_link: 1, send: 1]
    end
  end
end

defmodule Web3.TestRPC do
  use Web3.RPC, provider: Web3.Providers.HTTP

  @testrpc_url  "http://localhost:8545"

  def start_link() do
    start_link(%{url: @testrpc_url})
  end
end

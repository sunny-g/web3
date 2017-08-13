defmodule Web3.Query.Macros do
  @moduledoc """
  Module for the Query module macros
  """

  alias Web3.Schema

  @doc_url  "https://github.com/ethereum/wiki/wiki/JSON-RPC#"

  defp gen_doc(method_name) do
    quote do
      @doc """
      Sends a `#{unquote(method_name)}` request to the Ethereum JSON-RPC server

      See the JSON-RPC [documentation](#{unquote(@doc_url)}#{String.downcase(unquote(method_name))}) for more details
      """
    end
  end

  defp gen_spec(method_atom) do
    quote location: :keep do
      @spec unquote(method_atom)(any) :: any
    end
  end

  defp gen_func(method_name, method_description) do
    method_atom = :"#{method_name}"

    quote location: :keep do
      def unquote(method_atom)(params \\ []) do
        # fill out spec inputs, required and optional
        # fill out fn inputs, required and optional
        # map each input into a formatter, then into the params list
        # ... send
        # unformat the result

        # ... in other words...

        # validate inputs against Schema
        # format inputs according to Format
        # ... send
        # format outputs according to Format
        # validate outputs against Schema

        send(%{method: unquote(method_name), params: params})
      end
    end
  end

  def gen_method(method_name, method_description) do
    method_atom = :"#{method_name}"

    quote location: :keep do
      unquote(gen_doc(method_name))
      unquote(gen_spec(method_atom))
      unquote(gen_func(method_name, method_description))
    end
  end
end

defmodule Web3.Query do
  @moduledoc """
  Loads the Ethereum RPC schema and generates the equivalent methods

  Each method will:
    - take in native types as params
    - for each param, format it for the RPC method
    - call RPC's `send` method with a map of the `method` and `params`
    - decode and unformat the response into the native types
  """

  require Web3.Query.Macros
  alias Web3.Schema
  # alias Web3.Format

  defmacro __using__(_) do
    Schema.Spec.get_methods()
    |> Map.to_list
    |> Enum.map(fn {name, description} ->
      Web3.Query.Macros.gen_method(name, description)
    end)
  end
end

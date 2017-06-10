defmodule Web3.Schema do
  @moduledoc """
  Loads the schema file, makes it available via getter methods on module
  attributes

  Exports a `validate/2` function for validating a value against RPC types and
  an `is_valid?/2` function for determining if a value is a valid RPC
  input or output
  """

  # require OK
  alias Web3.Schema.Primitive
  alias Web3.Schema.Complex

  @doc false
  @spec validate(any, bitstring | [bitstring]) :: {:ok, boolean} | {:error, any}
  def validate(val, type) when is_bitstring(type) or is_list(type) do
    is_primitive = Primitive.validate(val, type)

    case is_primitive do
      {:ok, true} -> {:ok, true}
      _ -> Complex.validate(val, type)
    end
  end

  @doc false
  @spec is_valid?(any, bitstring | [bitstring]) :: boolean
  def is_valid?(val, type) when is_bitstring(type) or is_list(type) do
    Primitive.is_valid?(val, type) or Complex.is_valid?(val, type)
  end
end

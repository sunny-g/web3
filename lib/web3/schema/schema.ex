defmodule Web3.Schema do
  @moduledoc """
  Loads the schema file, makes it available via getter methods on module
  attributes

  Exports a `validate/2` function for validating a value against RPC types and
  an `is_valid?/2` function for determining if a value is a valid RPC
  input or output
  """

  require OK
  alias Web3.Schema.Primitive
  alias Web3.Schema.Complex

  @doc """
  Validate a value against all known JSON-RPC primitive and complex types
  """
  @spec validate(any, bitstring | [bitstring]) :: {:ok, boolean} | {:error, reason :: any}
  def validate(val, type) when is_bitstring(type) or is_list(type) do
    case Complex.validate(val, type) do
      OK.success(true) -> OK.success(true)
      _ -> Primitive.validate(val, type)
    end
  end

  @doc """
  Determine if a value is a known JSON-RPC primitive and complex type
  """
  @spec is_valid?(any, bitstring | [bitstring]) :: boolean
  def is_valid?(val, type) when is_bitstring(type) or is_list(type) do
    Complex.is_valid?(val, type) or Primitive.is_valid?(val, type)
  end
end

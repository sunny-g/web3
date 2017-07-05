defmodule Web3.Schema.Primitive do
  @moduledoc """
  Performs validation according to the RPC primitive types
  """

  require OK
  alias Web3.Schema.Spec
  alias Web3.Util.Hex

  @type b       :: boolean
  @type s       :: bitstring
  @type q       :: integer
  @type t       :: bitstring
  @type d       :: binary
  @type d8      :: <<_::8>>
  @type d20     :: <<_::20>>
  @type d32     :: <<_::32>>
  @type d60     :: <<_::60>>
  @type d256    :: <<_::256>>
  @type array_d :: d | [d, ...]

  @doc """
  Attempt to validate a value as an RPC primitive type
  """
  @spec validate(any, bitstring) :: {:ok, boolean} | {:error, any}
  def validate(val, type) do
    try do
      is_valid(val, type) |> OK.success
    rescue
      err -> OK.failure(err)
    end
  end

  @doc """
  Determine if value is a valid RPC primitive type
  """
  @spec is_valid?(any, bitstring) :: boolean
  def is_valid?(val, type) do
    try do
      is_valid(val, type)
    rescue
      _ -> false
    end
  end

  defp is_valid(val, "B"), do: is_boolean(val)
  defp is_valid(val, "S"), do: is_bitstring(val)
  defp is_valid(val, "Q"), do: is_integer(val)
  defp is_valid(val, "T"), do: val in Spec.get_block_tags
  defp is_valid(val, "D"), do: Hex.is_hex?(val)
  defp is_valid(val, "D" <> byte_length) do
    byte_length = String.to_integer(byte_length)
    Hex.is_hex?(val, byte_length)
  end
  defp is_valid(val, "Array|D") when not is_list(val), do: is_valid(val, "D")
  defp is_valid(val, "Array|D") when is_list(val), do: Enum.all?(val, &is_valid(&1, "D"))
end

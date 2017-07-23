defmodule Web3.Schema.Primitive do
  @moduledoc """
  Performs validation according to the RPC primitive types
  """

  require OK
  alias Web3.Schema.Spec
  alias Web3.Hex

  @type quantity  :: integer
  @type tag       :: bitstring
  @type d         :: binary
  @type d8        :: <<_::8>>
  @type d20       :: <<_::20>>
  @type d32       :: <<_::32>>
  @type d60       :: <<_::60>>
  @type d256      :: <<_::256>>
  @type array_d   :: d | [d, ...]
  @type t         :: boolean | bitstring | quantity | tag | d | d8 | d20 | d32 | d60 | d256 | array_d

  @doc """
  Attempt to validate a value as an RPC primitive type
  """
  @spec validate(t, bitstring) :: {:ok, boolean} | {:error, any}
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
  @spec is_valid?(t, bitstring) :: boolean
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
  defp is_valid(val, "D8"), do: Hex.is_hex?(val, 8)
  defp is_valid(val, "D20"), do: Hex.is_hex?(val, 20)
  defp is_valid(val, "D32"), do: Hex.is_hex?(val, 32)
  defp is_valid(val, "D60"), do: Hex.is_hex?(val, 60)
  defp is_valid(val, "D256"), do: Hex.is_hex?(val, 256)
  defp is_valid(val, "Array|D") when is_list(val), do: Enum.all?(val, &is_valid(&1, "D"))
  defp is_valid(val, "Array|D"), do: is_valid(val, "D")
  defp is_valid(_val, _type), do: false
end

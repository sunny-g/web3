defmodule Web3.Hex do
  @moduledoc """
  Base-16 hexadecimal bitstring utility functions
  """

  require OK
  import OK, only: ["~>>": 2]

  @regex              ~r/^0x[0-9A-Fa-f]+$/
  @prefix             "0x"
  @prefix_byte_size   2
  # TODO: look at https://github.com/tallakt/codepagex/blob/master/lib/codepagex/error.ex for modelling errors, possibly move all errors to another module
  @invalid_hex_error  :"invalid hexadecimal bitstring"

  @typedoc """
  Placeholder type for a hexadecimal string
  Considered a valid hex string if it is:
    1. a bitstring
    2. prefixed with "0x"
    3. only contains ASCII characters 0-9, A-F, and/or a-f
  """
  @type t :: bitstring

  #-------------------------------------------------------------------------#
  # MAIN HEX UTILS
  #-------------------------------------------------------------------------#

  @doc """
  Determines if bitstring is a valid hex string
  Optionally, you can specify the `byte_length` that the hex string should conform to

  ## Example
    iex> Web3.Hex.is_hex?("0xAff")
    true

    iex> Web3.Hex.is_hex?("0xaf", 1)
    true

    iex> Web3.Hex.is_hex?("0xAf", 1)
    true

    iex> Web3.Hex.is_hex?("0xAf", 2)
    false

    iex> Web3.Hex.is_hex?("0xAff", 1)
    false

    iex> Web3.Hex.is_hex?("0x0Aff", 2)
    true

    iex> Web3.Hex.is_hex?("0xAfFa", 2)
    true

    iex> Web3.Hex.is_hex?("0x", 0)
    false

    iex> Web3.Hex.is_hex?("af", 0)
    false

    iex> Web3.Hex.is_hex?("0xafg", 1)
    false

    iex> Web3.Hex.is_hex?("0xaffg", 2)
    false

    iex> Web3.Hex.is_hex?("0xaf", 2)
    false
  """
  @spec is_hex?(bitstring) :: boolean
  @spec is_hex?(t, non_neg_integer) :: boolean
  def is_hex?(str) when is_bitstring(str), do: Regex.match?(@regex, str)
  def is_hex?(str, len)
      when is_bitstring(str) and is_integer(len) and len >= 0 do
    if byte_size(str) === (2 + (2 * len)), do: is_hex?(str), else: false
  end

  @doc """
  Determines if bitstring begins with "0x"

  ## Example
    iex> Web3.Hex.has_prefix?("0xaf")
    true

    iex> Web3.Hex.has_prefix?("0xAfxyz")
    true

    iex> Web3.Hex.has_prefix?("0x")
    true

    iex> Web3.Hex.has_prefix?("0")
    false

    iex> Web3.Hex.has_prefix?("0a")
    false
  """
  @spec has_prefix?(bitstring) :: boolean
  def has_prefix?(str) when is_bitstring(str) and byte_size(str) < @prefix_byte_size, do: false
  def has_prefix?(str) when is_bitstring(str) do
    @prefix === binary_part(str, 0, @prefix_byte_size)
  end

  @doc """
  Adds "0x" to a bitstring, unless it already has the prefix

  ## Example
    iex> Web3.Hex.add_prefix("af")
    { :ok, "0xaf" }

    iex> Web3.Hex.add_prefix("0xaf")
    { :ok, "0xaf" }

    iex> Web3.Hex.add_prefix("Afxyz")
    { :ok, "0xAfxyz" }

    iex> Web3.Hex.add_prefix("0xAfxyz")
    { :ok, "0xAfxyz" }
  """
  @spec add_prefix(bitstring) :: {:ok, t} | {:error, reason :: atom}
  def add_prefix(str) when is_bitstring(str) do
    if has_prefix?(str) do
      OK.success(str)
    else
      str
      |> pad_left(@prefix)
      |> OK.success
    end
  end

  @doc """
  Removes leading "0x" from a bitstring, unless it is already missing the prefix

  ## Example
    iex> Web3.Hex.remove_prefix("0xaf")
    { :ok, "af" }

    iex> Web3.Hex.remove_prefix("0xAfxyz")
    { :ok, "Afxyz" }

    iex> Web3.Hex.remove_prefix("0x")
    { :ok, "" }

    iex> Web3.Hex.remove_prefix("Afxyz")
    { :error, :"invalid hexadecimal bitstring" }

    iex> Web3.Hex.remove_prefix("0")
    { :error, :"invalid hexadecimal bitstring" }
  """
  @spec remove_prefix(t) :: {:ok, bitstring} | {:error, reason :: atom}
  def remove_prefix(str) when is_bitstring(str) do
    if has_prefix?(str) do
      str
      |> String.trim_leading(@prefix)
      |> OK.success
    else
      OK.failure(@invalid_hex_error)
    end
  end

  @doc """
  Adds leading "0"s to the hex bitstring to pad it to desired length
  If the input bitstring has the "0x" prefix, it will be preserved

  ## Example
    iex> Web3.Hex.pad_to_byte_length("0x0", 1)
    { :ok, "0x00" }

    iex> Web3.Hex.pad_to_byte_length("0xaf", 2)
    { :ok, "0x00af" }

    iex> Web3.Hex.pad_to_byte_length("0x", 1)
    { :error, :"invalid hexadecimal bitstring" }

    iex> Web3.Hex.pad_to_byte_length("0xAfxy", 3)
    { :error, :"invalid hexadecimal bitstring" }
  """
  @spec pad_to_byte_length(t, non_neg_integer) :: {:ok, t} | {:error, reason :: atom}
  def pad_to_byte_length(hex, len)
      when is_bitstring(hex) and is_integer(len) and len >= 0 do
    unless is_hex?(hex) do
      OK.failure(@invalid_hex_error)
    else
      hex
      |> String.trim_leading(@prefix)
      |> String.pad_leading(len * 2, "0")
      |> add_prefix
    end
  end

  @doc """
  Adds a leading "0" to the hex bitstring to make it an even-length hex bitstring
  If the input bitstring has the "0x" prefix, it will be preserved

  ## Example
    iex> Web3.Hex.pad_to_even_length("0x0")
    { :ok, "0x00" }

    iex> Web3.Hex.pad_to_even_length("0x0af")
    { :ok, "0x00af" }

    iex> Web3.Hex.pad_to_even_length("0x")
    { :error, :"invalid hexadecimal bitstring" }

    iex> Web3.Hex.pad_to_even_length("")
    { :error, :"invalid hexadecimal bitstring" }

    iex> Web3.Hex.pad_to_even_length("0")
    { :error, :"invalid hexadecimal bitstring" }

    iex> Web3.Hex.pad_to_even_length("0af")
    { :error, :"invalid hexadecimal bitstring" }
  """
  @spec pad_to_even_length(t) :: {:ok, t} | {:error, reason :: atom}
  def pad_to_even_length(hex) when is_bitstring(hex) do
    cond do
      not is_hex?(hex) ->
        OK.failure(@invalid_hex_error)
      rem(byte_size(hex), 2) === 0 ->
        OK.success(hex)
      true ->
        hex
        |> String.trim_leading(@prefix)
        |> pad_left("0")
        |> add_prefix
    end
  end

  #-------------------------------------------------------------------------#
  # CONVERSION
  #-------------------------------------------------------------------------#

  @doc """
  Converts an integer to a hex string

  ## Example
    iex> Web3.Hex.from_int(0)
    { :ok, "0x0" }

    iex> Web3.Hex.from_int(1)
    { :ok, "0x1" }

    iex> Web3.Hex.from_int(255)
    { :ok, "0xff" }

    iex> Web3.Hex.from_int(256)
    { :ok, "0x100" }
  """
  @spec from_int(non_neg_integer) :: {:ok, t}
  def from_int(int) when is_integer(int) do
    str = int
    |> :binary.encode_unsigned
    |> Base.encode16(case: :lower)

    str = if String.first(str) === "0" do
      str |> trim_left(1)
    else
      str
    end

    add_prefix(str)
  end

  @doc """
  ## Example
    iex> Web3.Hex.to_int("0x0")
    { :ok, 0 }

    iex> Web3.Hex.to_int("0x1")
    { :ok, 1 }

    iex> Web3.Hex.to_int("0xFF")
    { :ok, 255 }

    iex> Web3.Hex.to_int("0xAf")
    { :ok, 175 }

    iex> Web3.Hex.to_int("0x0af")
    { :ok, 175 }

    iex> Web3.Hex.to_int("0xAfxyz")
    { :error, :"invalid hexadecimal bitstring" }
  """
  @spec to_int(t | bitstring) :: {:ok, non_neg_integer} | {:error, reason :: atom}
  def to_int(hex) when is_bitstring(hex) do
    unless is_hex?(hex) do
      OK.failure(@invalid_hex_error)
    else
      # TODO: fix issues with dialyzer here
      hex
      |> pad_to_even_length
      ~>> remove_prefix
      ~>> Base.decode16(case: :mixed)
      ~>> :binary.decode_unsigned
      |> OK.success
    end
  end

  #-------------------------------------------------------------------------#
  # HELPERS
  #-------------------------------------------------------------------------#

  defp trim_left(str, len) when is_bitstring(str) and is_integer(len) do
    binary_part(str, len, byte_size(str) - len)
  end

  defp pad_left(str, prefix) when is_bitstring(str) and is_bitstring(prefix) do
    prefix <> str
  end
end

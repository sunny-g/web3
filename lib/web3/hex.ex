defmodule Web3.Hex do
  @moduledoc """
  Base-16 hexadecimal bitstring utility functions
  """

  require OK

  @prefix             "0x"
  @prefix_byte_size   2
  @invalid_hex_error  "Invalid hexadecimal bitstring"

  @typedoc """
  Placeholder type for a hexadecimal string
  Considered a valid hex string if it is:
    1. a bitstring
    2. prefixed with "0x"
    3. only contains ASCII characters 0-9, A-F, and/or a-f
  """
  @type hex_string :: bitstring

  @doc """
  Determines if bitstring is a valid hex string
  Optionally, you can also specify the byte_length that the hex string should be

  ## Example
    iex> Web3.Hex.is_hex?("0xaf", 1)
    true

    iex> Web3.Hex.is_hex?("0xAf", 1)
    true

    iex> Web3.Hex.is_hex?("0xAf", 2)
    false

    iex> Web3.Hex.is_hex?("0xAff", 1)
    false

    iex> Web3.Hex.is_hex?("0xAff")
    true

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
  @spec is_hex?(bitstring, non_neg_integer) :: boolean
  def is_hex?(str, byte_length) when is_bitstring(str) do
    if byte_size(str) !== ((2 * byte_length) + 2), do: false, else: is_hex?(str)
  end
  @spec is_hex?(bitstring) :: boolean
  def is_hex?(str) when is_bitstring(str), do: Regex.match?(~r/^0x[0-9A-Fa-f]+$/, str)

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
  def has_prefix?(str) when is_bitstring(str) do
    if byte_size(str) < @prefix_byte_size do
      false
    else
      @prefix === binary_part(str, 0, @prefix_byte_size)
    end
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
  @spec add_prefix(bitstring) :: { :ok, hex_string }
  def add_prefix(str) when is_bitstring(str) do
    if has_prefix?(str) do
      { :ok, str }
    else
      new = pad_left(str, @prefix)
      { :ok, new }
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
    { :error, "Invalid hexadecimal bitstring" }

    iex> Web3.Hex.remove_prefix("0")
    { :error, "Invalid hexadecimal bitstring" }
  """
  @spec remove_prefix(hex_string) :: { :ok, bitstring }
  def remove_prefix(str) when is_bitstring(str) do
    if !has_prefix?(str) do
      { :error, @invalid_hex_error }
    else
      trim_left(str, @prefix_byte_size)
      |> OK.success
    end
  end

  @doc """
  Adds a leading "0" to the hex bitstring to make it an even-length bitstring
  Optionally, the input hex can have the "0x" prefix which will be preserved

  ## Example
    iex> Web3.Hex.pad_to_even_length("")
    ""

    iex> Web3.Hex.pad_to_even_length("0")
    "00"

    iex> Web3.Hex.pad_to_even_length("0af")
    "00af"

    iex> Web3.Hex.pad_to_even_length("0x0")
    "0x00"

    iex> Web3.Hex.pad_to_even_length("0x0af")
    "0x00af"
  """
  @spec pad_to_even_length(bitstring) :: bitstring
  def pad_to_even_length(hex) when is_bitstring(hex) and rem(byte_size(hex), 2) === 0, do: hex
  def pad_to_even_length(hex) when is_bitstring(hex) do
    if has_prefix?(hex) do
      hex
      |> trim_left(@prefix_byte_size)
      |> pad_left("0")
      |> add_prefix
      |> elem(1)
    else
      hex
      |> pad_left("0")
    end
  end

  @doc """
  Converts an integer to a hex string

  ## Example
    iex> Web3.Hex.from_int(0)
    { :ok, "0x00" }

    iex> Web3.Hex.from_int(1)
    { :ok, "0x01" }

    iex> Web3.Hex.from_int(255)
    { :ok, "0xff" }

    iex> Web3.Hex.from_int(256)
    { :ok, "0x0100" }
  """
  @spec from_int(non_neg_integer) :: { :ok, bitstring }
  def from_int(int) when is_integer(int) do
    :binary.encode_unsigned(int)
    |> Base.encode16(case: :lower)
    |> add_prefix
  end

  @doc ~s"""
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
    { :error, "Invalid hexadecimal bitstring" }
  """
  @spec to_int(bitstring) :: { :ok, non_neg_integer }
  def to_int(hex) when is_bitstring(hex) do
    if !is_hex?(hex) do
      { :error, @invalid_hex_error }
    else
      OK.with do
        hex <- remove_prefix(hex)
        bin <- hex
          |> pad_to_even_length
          |> Base.decode16(case: :mixed)
        :binary.decode_unsigned(bin)
        |> OK.success
      end
    end
  end

  #################### HELPERS ####################

  defp trim_left(str, len) when is_bitstring(str) and is_integer(len) do
    binary_part(str, len, byte_size(str) - len)
  end

  defp pad_left(str, prefix) when is_bitstring(str) and is_bitstring(prefix) do
    prefix <> str
  end
end

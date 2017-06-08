defmodule Web3.Schema.Loader do
  @moduledoc false

  @derive [Poison.Encoder]
  defstruct [:methods, :objects, :tags]

  require OK
  import OK, only: ["~>>": 2]

  @type methods_spec    :: %{bitstring => [[bitstring] | bitstring | non_neg_integer]}
  @type objects_spec    :: %{bitstring => %{bitstring => [bitstring] | bitstring}}
  @type t :: %{
    required(:methods)    => methods_spec,
    required(:objects)    => objects_spec,
    required(:tags)       => [bitstring],
    optional(:primitives) => [bitstring],
  }

  @external_resource  Path.join([__DIR__, "../../", "schema.json"])
  @schema_load_error  "Must run `mix run schema` to clone the schema.json first"

  defmacro __using__(_) do
    quote do
      import Web3.Hex
      import unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :block_tags,   accumulate: true)
      Module.register_attribute(__MODULE__, :methods,      accumulate: true)
      Module.register_attribute(__MODULE__, :object_types, accumulate: true)

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_) do
    quote do
      {:ok, schema} = unquote(__MODULE__).load

      Module.put_attribute(__MODULE__, :block_tags,   Map.get(schema, :tags))
      Module.put_attribute(__MODULE__, :methods,      Map.get(schema, :methods))
      Module.put_attribute(__MODULE__, :object_types, Map.get(schema, :objects))

      @doc """
      Retrieves the block tags
      """
      @spec get_block_tags :: [bitstring]
      def get_block_tags, do: hd(@block_tags)

      @doc """
      Retrieves the RPC method names and their type signatures
      """
      @spec get_methods :: unquote(__MODULE__).methods_spec
      def get_methods, do: hd(@methods)

      @doc """
      Retrieves the RPC object types and their type signatures
      """
      @spec get_object_types :: unquote(__MODULE__).objects_spec
      def get_object_types, do: hd(@object_types)
    end
  end

  @doc """
  Loads and decodes the local schema.json file into a Map
  """
  @spec load :: {:ok, __MODULE__.t} | {:error, bitstring}
  def load do
    OK.with do
      {:ok, @external_resource}
      ~>> File.read
      ~>> Poison.decode(as: %__MODULE__{})
    else
      :enoent -> {:error, @schema_load_error}
    end
  end
end

defmodule Web3.Schema.Primitives do
  @moduledoc false

  use Web3.Schema.Loader
  alias Web3.Hex

  @type primitives_spec :: %{bitstring => bitstring}

  @primitive_validator_names  %{
    "D"           => "hex",
    "D8"          => "hex8",
    "D20"         => "hex20",
    "D32"         => "hex32",
    "D60"         => "hex60",
    "D256"        => "hex256",
    "B"           => "boolean",
    "S"           => "bitstring",
    "Array|DATA"  => "data_or_array",
    "Q"           => "integer",
    "Q|T"         => "integer_or_tag"
  }

  @doc """
  Retrieves the RPC primitive types and their respective validator names
  """
  @spec get_primitive_validator_names :: unquote(__MODULE__).primitives_spec
  def get_primitive_validator_names, do: @primitive_validator_names

  #-----------------------------------------------------------------------#
  #---------------------- PRIMITIVE TYPE VALIDATION ----------------------#
  #   - if a native type, use the Kernel module's validation function
  #   - if a data type, validate that its a hex bitstring of the appropriate length
  #   - otherwise, use the other custom type
  #-----------------------------------------------------------------------#

  def is_boolean(val), do: Kernel.is_boolean(val)
  def is_bitstring(val), do: Kernel.is_bitstring(val)
  def is_integer(val), do: Kernel.is_integer(val)

  @doc """
  Checks if input is a valid hex string
  """
  @spec is_hex(bitstring) :: boolean
  def is_hex(val), do: Hex.is_hex?(val)

  @doc """
  Checks if input is a valid arbitrary-length hex string or a list of valid
  arbitrary-length hex strings
  """
  @spec is_data_or_array(bitstring | [bitstring]) :: boolean
  def is_data_or_array(val) do
    is_hex(val) or Enum.all?(val, &__MODULE__.is_hex/1)
  end

  @doc """
  Checks if input is an integer quantity or a valid block tag
  """
  @spec is_integer_or_tag(non_neg_integer | bitstring) :: boolean
  def is_integer_or_tag(val) do
    Kernel.is_integer(val) or (val in __MODULE__.get_block_tags)
  end

  for byte_length <- [ 8, 20, 32, 60, 256 ] do
    method_name = String.to_atom("is_hex#{byte_length}")

    @doc """
    Checks if input is a valid hex string and of length #{byte_length} bytes
    """
    @spec unquote(method_name)(bitstring) :: boolean
    def unquote(method_name)(val), do: Hex.is_hex?(val, unquote(byte_length))
  end

  @doc """
  Creates the method name of a primitive type validator method in the Primitives module
  """
  @spec validator_name_from_type(bitstring) :: atom
  def validator_name_from_type(type) when Kernel.is_bitstring(type) do
    String.to_atom("is_#{Map.get(@primitive_validator_names, type)}")
  end
end

defmodule Web3.Schema.Collections do
  @moduledoc false

  use Web3.Schema.Loader
  alias Web3.Schema.Primitives

  # @type objects_spec :: %{bitstring => bitstring}

  # @object_validator_names Web3.Schema.Loader.get_object_types
  #   |> Enum.reduce(%{}, fn ({type, _}, acc) ->
  #     Map.put(acc, type, "is_#{Macro.underscore(type)}")
  #   end)

  # @doc """
  # Retrieves the RPC object types and their respective validator names
  # """
  # @spec get_object_validator_names :: unquote(__MODULE__).objects_spec
  # def get_object_validator_names, do: @object_validator_names

  #-----------------------------------------------------------------------#
  #----------------------- RPC LIST TYPE VALIDATION ----------------------#
  #-----------------------------------------------------------------------#

  @doc """
  Checks is input is an array of a given type
  """
  # @spec is_array_of_type(any, bitstring) :: boolean
  def is_array_of_type(val, type) do
    # if type is in primitive types, create the method name and use it's validator fn
    # if type is in object types, create the method name and use it's validator fn
    # else return false
    primitive_validator_names = Primitives.get_primitive_validator_names
    object_types = get_object_types()

    {module, validator_name} = cond do
      Map.has_key?(primitive_validator_names, type) ->
        validator_name = Primitives.validator_name_from_type(type)
        {Primitives, validator_name}
      Map.has_key?(object_types, type) ->
        validator_name = __MODULE__.validator_name_from_type(type)
        {__MODULE__, validator_name}
      true -> {Kernel, :"raise/1"}
    end

    is_list(val) and module !== Kernel and Enum.all?(val, &apply(module, validator_name, &1))
  end

  # @doc false
  # @spec is_data_or_transaction_array([bitstring | %{}]) :: boolean
  def is_data_or_transaction_array do
  end

  #-----------------------------------------------------------------------#
  #---------------------- RPC OBJECT TYPE VALIDATION ---------------------#
  #-----------------------------------------------------------------------#

  # Enum.each(__MODULE__.get_object_types, fn {name, spec} -> end)

  @doc """
  Creates the method name of an object type validator method in the Collections module
  """
  @spec validator_name_from_type(bitstring) :: atom
  def validator_name_from_type(type) when is_bitstring(type) do
    String.to_atom("is_#{Macro.underscore(type)}")
  end
end

defmodule Web3.Schema do
  @moduledoc """
  Loads the schema file, makes it available via getter methods

  Exports a `validate/2` function for validating API inputs and outputs
  (before formatting them for the API, and after parsing them from API)
  """

  use Web3.Schema.Loader
  alias Web3.Schema.Primitives
  alias Web3.Schema.Collections

  # @doc """
  # For a given data type, attempt to validate it against the appropriate method
  # in the Kernel or Web3.Schema module
  # """
  # @spec validate(any, bitstring) :: boolean
  # def validate(val, type) do
  #   primitive_types = Primitives.get_primitive_validator_names()
  #   validator_name = String.to_atom("is_#{Map.get(primitive_types, type)}")

  #   cond do
  #     Keyword.has_key?(Primitives.__info__(:functions), validator_name) ->
  #       apply(Primitives, validator_name, [val])
  #     Keyword.has_key?(Collections.__info__(:functions), validator_name) ->
  #       apply(Lists, validator_name, [val])
  #     Keyword.has_key?(Kernel.__info__(:functions), validator_name) ->
  #       apply(Kernel, validator_name, [val])
  #     true -> :error
  #   end
  # end
end

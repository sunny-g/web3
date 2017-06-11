defmodule Web3.Schema.Loader do
  @moduledoc false

  @derive [Poison.Encoder]
  defstruct [:primitives, :combinations, :tags, :methods, :objects]

  import OK, only: ["~>>": 2]

  @type primitives_spec   :: [bitstring]
  @type combinations_spec :: [bitstring]
  @type block_tags_spec   :: [bitstring]
  @type methods_spec      :: %{
    bitstring => [[bitstring] | bitstring | non_neg_integer]
  }
  @type objects_spec      :: %{
    bitstring => %{bitstring => [bitstring] | bitstring}
  }
  @type t :: %{
    required(:primitives)   => [bitstring],
    required(:combinations) => [bitstring],
    required(:tags)         => [bitstring],
    required(:methods)      => methods_spec,
    required(:objects)      => objects_spec,
  }

  @external_resource  Path.join([__DIR__, "../../../", "schema.json"])
  @schema_load_error  "Must run `mix do schema` to clone the schema.json first"

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :primitives,    accumulate: true)
      Module.register_attribute(__MODULE__, :combinations,  accumulate: true)
      Module.register_attribute(__MODULE__, :block_tags,    accumulate: true)
      Module.register_attribute(__MODULE__, :methods,       accumulate: true)
      Module.register_attribute(__MODULE__, :object_types,  accumulate: true)

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_) do
    quote do
      {:ok, schema} = unquote(__MODULE__).load

      Module.put_attribute(__MODULE__, :primitives,   Map.get(schema, :primitives))
      Module.put_attribute(__MODULE__, :combinations, Map.get(schema, :combinations))
      Module.put_attribute(__MODULE__, :block_tags,   Map.get(schema, :tags))
      Module.put_attribute(__MODULE__, :methods,      Map.get(schema, :methods))
      Module.put_attribute(__MODULE__, :object_types, Map.get(schema, :objects))

      @doc """
      Retrieves the primitive types
      """
      @spec get_primitive_types :: unquote(__MODULE__).primitives_spec
      def get_primitive_types, do: hd(@primitives)

      @doc """
      Retrieves the primitive types
      """
      @spec get_combination_types :: unquote(__MODULE__).combinations_spec
      def get_combination_types, do: hd(@combinations)

      @doc """
      Retrieves the block tags
      """
      @spec get_block_tags :: unquote(__MODULE__).block_tags_spec
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

defmodule Web3.Schema.Schema do
  @moduledoc """
  Loads the local schema.json into module attributes for compilation
  """

  use Web3.Schema.Loader
end

defmodule Web3.Schema.Loader do
  @moduledoc false

  @derive [Poison.Encoder]
  defstruct [:methods, :objects, :tags]

  require OK
  import OK, only: ["~>>": 2]

  @type primitives_spec :: %{bitstring => bitstring}
  @type methods_spec    :: %{bitstring => [[bitstring] | bitstring | non_neg_integer]}
  @type objects_spec    :: %{bitstring => %{bitstring => [bitstring] | bitstring}}
  @type t :: %{
    required(:methods)  => methods_spec,
    required(:objects)  => objects_spec,
    required(:tags)     => [bitstring],
  }

  @external_resource  Path.join([__DIR__, "../../", "schema.json"])
  @schema_load_error  "Must run `mix run schema` to clone the schema.json first"
  @primitive_types    %{
    "D"           => "binary",
    "D8"          => "binary8",
    "D20"         => "binary20",
    "D32"         => "binary32",
    "D60"         => "binary60",
    "D256"        => "binary256",
    "B"           => "boolean",
    "S"           => "bitstring",
    "Array|DATA"  => "array_or_data",
    "Q"           => "integer",
    "Q|T"         => "integer_or_tag"
  }

  defmacro __using__(_) do
    quote do
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

      @doc """
      Retrieves the RPC primitive types
      """
      @spec get_primitive_types :: unquote(__MODULE__).primitives_spec
      def get_primitive_types, do: @primitive_types
    end
  end

  @doc """
  Loads and decodes the local schema.json file into a Map
  """
  @spec load :: {:ok, __MODULE__.t} | {:error, bitstring}
  def load do
    OK.with do
      {:ok, unquote(@external_resource)}
      ~>> File.read
      ~>> Poison.decode(as: %__MODULE__{})
    else
      :enoent -> {:error, unquote(@schema_load_error)}
    end
  end
end

defmodule Web3.Schema do
  @moduledoc """
  Loads the schema file, makes it available via getter methods
  """

  use Web3.Schema.Loader
end

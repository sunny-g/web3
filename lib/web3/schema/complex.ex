defmodule Web3.Schema.Complex.Combination do
  @moduledoc """
  Determine if value is a valid RPC combination type
  """

  alias Web3.Schema.Schema
  alias Web3.Schema.Primitive

  defmacro __using__(_) do
    for type <- Schema.get_combination_types do
      quote [
        location: :keep,
        bind_quoted: [type: type],
      ] do
        defp is_valid(val, unquote(type)) do
          [ type1, type2 ] = String.split(unquote(type), "|")

          not is_nil(val) and (
            Primitive.is_valid?(val, type1) or
            Primitive.is_valid?(val, type2) or
            __MODULE__.is_valid?(val, type1) or
            __MODULE__.is_valid?(val, type2)
          )
        end
      end
    end
  end
end

defmodule Web3.Schema.Complex.List do
  @moduledoc """
  Determine if value is a valid RPC list type
  """

  defmacro __using__(_) do
    quote location: :keep do
      defp is_valid(val, [type]) when is_list(val) do
        Enum.all?(val, &__MODULE__.is_valid?(&1, type))
      end
    end
  end
end

defmodule Web3.Schema.Complex.Object do
  @moduledoc """
  Determine if value is a valid RPC object type
  """

  alias Web3.Schema.Schema
  alias Web3.Schema.Primitive

  defmacro __using__(_) do
    for {type, full_schema} <- Schema.get_object_types do
      { required, object_schema } = Map.pop(full_schema, "__required")
      optional = object_schema
      |> Map.drop(required)
      |> Map.keys

      schema = Macro.escape(object_schema)

      quote [
        location: :keep,
        unquote: true,
        bind_quoted: [
          required:  required,
          optional:  optional,
        ]
      ] do
        unquote(generate_validator(type, schema, required, optional))
      end
    end
  end

  defp generate_validator(type, schema, required, optional) do
    quote location: :keep do
      # TODO: define a map type for each object type
      @spec is_valid(map, bitstring) :: boolean
      defp is_valid(object, _) when not is_map(object), do: false
      defp is_valid(object, unquote(type)) when is_map(object) do
        has_all_valid_required_props = Enum.all?(unquote(required), fn prop_name ->
          type = Map.get(unquote(schema), prop_name)
          val = Map.get(object, prop_name)

          not is_nil(val) and (
            Primitive.is_valid?(val, type) or
            __MODULE__.is_valid?(val, type)
          )
        end)

        # unless the object contains all required props, return false...
        unless has_all_valid_required_props do
          false
        else
          # ... if it does, guarantee that it contains no other props...
          Map.take(object, unquote(optional)) === %{} or
          # ... but if it does...
          Enum.all?(unquote(optional), fn prop_name ->
            type = Map.get(unquote(schema), prop_name)
            val = Map.get(object, prop_name)

            # ... guarantee that they are either nil or valid RPC types
            is_nil(val) or (
              Primitive.is_valid?(val, type) or
              __MODULE__.is_valid?(val, type)
            )
          end)
        end
      end
    end
  end
end

defmodule Web3.Schema.Complex do
  @moduledoc false

  use Web3.Schema.Complex.Combination
  use Web3.Schema.Complex.List
  use Web3.Schema.Complex.Object

  @doc """
  Attempt to validate a value as an RPC combination, list of object type
  """
  @spec validate(any, bitstring) :: {:ok, boolean} | {:error, any}
  def validate(val, type) do
    try do
      {:ok, is_valid(val, type)}
    rescue
      err -> {:error, err}
    end
  end

  @doc """
  Determine if value is a valid RPC combination, list or object type
  """
  @spec is_valid?(any, bitstring) :: boolean
  def is_valid?(val, type) do
    try do
      is_valid(val, type)
    rescue
      _ -> false
    end
  end
end

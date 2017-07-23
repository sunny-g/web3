defmodule Web3.Schema.Complex.Combination do
  @moduledoc """
  Determine if value is a valid RPC combination type
  """

  alias Web3.Schema.Spec
  alias Web3.Schema.Primitive

  defmacro __using__(_) do
    for type <- Spec.get_combination_types do
      quote location: :keep do
        @spec is_valid(any, bitstring) :: boolean
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

  alias Web3.Schema.Primitive

  defmacro __using__(_) do
    quote location: :keep do
      @spec is_valid(list, [bitstring]) :: boolean
      defp is_valid(val, [type]) when is_list(val) do
        Enum.all?(val, fn elem ->
          Primitive.is_valid?(elem, type) or __MODULE__.is_valid?(elem, type)
        end)
      end
    end
  end
end

defmodule Web3.Schema.Complex.Object do
  @moduledoc """
  Determine if value is a valid RPC object type
  """

  alias Web3.Schema.Spec
  alias Web3.Schema.Primitive

  defmacro __using__(_) do
    quote location: :keep do
      @spec is_valid(map, bitstring) :: boolean
      defp is_valid(object, _) when not is_map(object), do: false

      unquote(generate_all_validators())

      defp has_all_valid_props?(schema, object, is_strict) do
        Enum.all?(Map.keys(schema), fn prop_name ->
          has_schema_prop = Map.has_key?(object, prop_name)
          type = Map.get(schema, prop_name)
          val = Map.get(object, prop_name)

          if is_strict do
            # verify that the value isn't nil and is a valid Primitive or Complex type
            not is_nil(val) and (
              Primitive.is_valid?(val, type) or
              __MODULE__.is_valid?(val, type)
            )
          else
            # verify that the key doesn't exist in object,
            # but if it does, verify that it's a valid Primitive or Complex type
            not has_schema_prop or (
              Primitive.is_valid?(val, type) or
              __MODULE__.is_valid?(val, type)
            )
          end
        end)
      end
    end
  end

  defp generate_all_validators() do
    for {type, full_schema} <- Spec.get_object_types do
      { required_keys, object_schema } = Map.pop(full_schema, "__required")

      required_schema = Map.take(object_schema, required_keys) |> Macro.escape
      optional_schema = Map.drop(object_schema, required_keys) |> Macro.escape

      quote [
        location: :keep,
        unquote: true,
        bind_quoted: [
          required_schema:  required_schema,
          optional_schema:  optional_schema,
        ]
      ] do
        unquote(generate_validator(type, required_schema, optional_schema))
      end
    end
  end

  defp generate_validator(type, required_schema, optional_schema) do
    quote location: :keep do
      # TODO: define a map type for each object type
      defp is_valid(object, unquote(type)) when is_map(object) do
        has_all_valid_required_props = has_all_valid_props?(unquote(required_schema), object, true)

        # if it lacks all required props OR they are invalid, return false
        unless has_all_valid_required_props do
          false
        else
          required_keys = Map.keys(unquote(required_schema))
          optional_keys = Map.keys(unquote(optional_schema))

          # verify that any extra props are defined as optional and are valid
          has_no_extra_props = Map.drop(object, required_keys ++ optional_keys) === %{}

          # verify that there aren't props that arent defined as optional or required
          has_valid_optional_props = has_all_valid_props?(unquote(optional_schema), object, false)

          has_no_extra_props and has_valid_optional_props
        end
      end
    end
  end
end

defmodule Web3.Schema.Complex do
  @moduledoc false

  require OK
  use Web3.Schema.Complex.Combination
  use Web3.Schema.Complex.List
  use Web3.Schema.Complex.Object

  @doc """
  Attempt to validate a value as an RPC combination, list of object type
  """
  @spec validate(any, bitstring) :: {:ok, boolean} | {:error, reason :: any}
  def validate(val, type) do
    try do
      is_valid(val, type) |> OK.success
    rescue
      err -> OK.failure(err)
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

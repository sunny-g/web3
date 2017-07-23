defmodule Web3.Schema.Test do
  use ExUnit.Case
  alias Web3.Schema

  describe "Primitive types" do
    test "boolean (B)" do
    end

    test "string (S)" do
    end

    test "quantity (Q)" do
    end

    test "tag (T)" do
    end

    test "data (D)" do
    end

    test "data (D8)" do
    end

    test "data (D20)" do
    end

    test "data (D32)" do
    end

    test "data (D60)" do
    end

    test "data (D256)" do
    end

    test "array of/or data (Array|D)" do
    end
  end

  describe "Combination types" do
    test "B|EthSyncing" do
      assert Web3.Schema.is_valid?(true, "B|EthSyncing") == true
      assert Web3.Schema.is_valid?(%{}, "B|EthSyncing") == true
      assert Web3.Schema.is_valid?(%{"startingBlock" => 123}, "B|EthSyncing") == true

      assert Web3.Schema.is_valid?("true", "B|EthSyncing") == false
      assert Web3.Schema.is_valid?(%{"startingBlock" => "123"}, "B|EthSyncing") == false
    end

    test "D32|Transaction" do
      d32 = "0x0000000000000000000000000000000000000000000000000000000000000000"
      assert Web3.Schema.is_valid?(d32, "D32|Transaction") == true
      assert Web3.Schema.is_valid?(%{}, "D32|Transaction") == true
      assert Web3.Schema.is_valid?(%{"nonce" => 123}, "D32|Transaction") == true

      assert Web3.Schema.is_valid?(d32 <> "0", "D32|Transaction") == false
      assert Web3.Schema.is_valid?(%{"nonce" => "123"}, "D32|Transaction") == false
      assert Web3.Schema.is_valid?(%{"once" => 123}, "D32|Transaction") == false
    end

    test "Q|T" do
      assert Web3.Schema.is_valid?(123, "Q|T") == true
      assert Web3.Schema.is_valid?("latest", "Q|T") == true
      assert Web3.Schema.is_valid?("earliest", "Q|T") == true
      assert Web3.Schema.is_valid?("pending", "Q|T") == true

      assert Web3.Schema.is_valid?(123.123, "Q|T") == false
      assert Web3.Schema.is_valid?("123", "Q|T") == false
    end
  end

  describe "List types" do
    test "of primitives" do
      assert Web3.Schema.is_valid?([123], ["Q"]) == true
      assert Web3.Schema.is_valid?(["latest"], ["T"]) == true

      assert Web3.Schema.is_valid?([123], ["T"]) == false
      assert Web3.Schema.is_valid?(["latest"], ["Q"]) == false
    end

    test "of combinations" do

    end

    test "of objects" do
    end
  end

  describe "Object types: containing required properties" do
    test "objects with no required properties" do
      assert Web3.Schema.is_valid?(%{}, "EthSyncing") == true

      # contains valid properties
      assert Web3.Schema.is_valid?(%{"startingBlock" => 123}, "EthSyncing") == true
      assert Web3.Schema.is_valid?(%{"startingBlock" => 123, "currentBlock" => 123}, "EthSyncing") == true

      # contains one valid property with invalid value
      assert Web3.Schema.is_valid?(%{"startingBlock" => "123"}, "EthSyncing") == false

      # contains invalid property
      assert Web3.Schema.is_valid?(%{"endingBlock" => 123}, "EthSyncing") == false
    end

    test "objects with required properties" do
      len60 = "000000000000000000000000000000000000000000000000000000000000"
      d60 = "0x" <> len60 <> len60
      d = "0x00"
      shhpost = %{"topics" => [d], "payload" => d, "priority" => 123, "ttl" => 123}

      # contains only the required properties
      assert Web3.Schema.is_valid?(%{"topics" => [d60]}, "SHHFilter") == true
      assert Web3.Schema.is_valid?(%{"topics" => [d60, d60]}, "SHHFilter") == true
      assert Web3.Schema.is_valid?(%{"topics" => [[d60, d60]]}, "SHHFilter") == true
      assert Web3.Schema.is_valid?(%{"topics" => [d60, [d60]]}, "SHHFilter") == true
      assert Web3.Schema.is_valid?(shhpost, "SHHPost") == true

      # contains all required and optional properties
      assert Web3.Schema.is_valid?(%{"topics" => [d60], "to" => d60}, "SHHFilter") == true
      assert Web3.Schema.is_valid?(%{"topics" => [d60, d60], "to" => d60}, "SHHFilter") == true
      assert Web3.Schema.is_valid?(%{"topics" => [[d60, d60]], "to" => d60}, "SHHFilter") == true
      assert Web3.Schema.is_valid?(%{"topics" => [d60, [d60]], "to" => d60}, "SHHFilter") == true

      new_shhpost = Map.merge(%{"to" => d60, "from" => d60}, shhpost)
      assert Web3.Schema.is_valid?(new_shhpost, "SHHPost") == true

      # contains all required and only some optional properties
      new_shhpost = Map.merge(%{"to" => d60}, shhpost)
      assert Web3.Schema.is_valid?(new_shhpost, "SHHPost") == true

      # contains an invalid optional property
      assert Web3.Schema.is_valid?(%{"topics" => [d60], "toe" => d60}, "SHHFilter") == false

      # contains only optional properties
      assert Web3.Schema.is_valid?(%{"to" => d60}, "SHHFilter") == false
    end
  end

  describe "Object types: containing specific types" do
    test "only primitive types" do
    end

    test "only primitive, combination and/or list types" do
    end

    test "some object types" do
    end
  end
end

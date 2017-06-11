defmodule Mix.Tasks.Schema do
  @moduledoc """
  Fetches the latest Ethereum RPC schema.json from github.com/sunny-g/ethjs-schema
  """

  use Mix.Task
  @dir        System.tmp_dir
  @schema_dir "#{@dir}ethjs-schema"

  def run(_) do
    try do
      System.cmd("git", ["clone", "https://github.com/sunny-g/ethjs-schema", @schema_dir])
      System.cmd("mv", ["#{@schema_dir}/src/schema.json", System.cwd])
    after
      System.cmd("rm", ["-rf", @schema_dir])
    end
  end
end

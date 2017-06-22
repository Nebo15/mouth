defmodule Mouth.TestAdapter do
  @moduledoc """
  Implimentation of Test Adapter for Mouth
  """
  @behaviour Mouth.Adapter
  def deliver(message, _) do
    IO.puts message.body
  end

  def status(_, config) do
    IO.puts inspect config
  end

  def handle_config(config) do
    config
  end
end

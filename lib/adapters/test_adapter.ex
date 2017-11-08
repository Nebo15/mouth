defmodule Mouth.TestAdapter do
  @moduledoc """
  Implimentation of Test Adapter for Mouth
  """
  @behaviour Mouth.Adapter

  def deliver(%Mouth.Message{body: "exception"}, config) do
    Mouth.raise_api_error(config.gateway_url, "There was a problem sending the message", "response body")
  end

  def deliver(message, _) do
    IO.puts message.body
    {:ok, [status: "Accepted", id: "test"]}
  end

  def status(_, config) do
    IO.puts inspect config
    {:ok, [status: "Accepted", id: "test"]}
  end

  def handle_config(config) do
    config
  end
end

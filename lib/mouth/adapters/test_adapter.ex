defmodule Mouth.TestAdapter do
  @moduledoc """
  Implementation of Test Adapter for Mouth
  """

  @behaviour Mouth.Adapter

  def deliver(%Mouth.Message{body: "exception"}, config) do
    Mouth.raise_api_error(
      config.gateway_url,
      "There was a problem sending the message",
      "response body"
    )
  end

  def deliver(message, _) do
    send(self(), {:sms, message})
    {:ok, [status: "Accepted", id: "test", datetime: to_string(DateTime.utc_now())]}
  end

  def status(_, config) do
    send(self(), {:config, config})
    {:ok, [status: "Accepted", id: "test", datetime: to_string(DateTime.utc_now())]}
  end

  def handle_config(config) do
    config
  end
end

defmodule Mouth.LocalAdapter do
  @moduledoc """
  Delivers messages locally to an in-memory store.
  """

  @behaviour Mouth.Adapter

  def deliver(message, config) do
    driver = storage_driver(config)
    message = driver.push(message)
    {:ok, [status: "Accepted", id: message.meta[:id], datetime: to_string(DateTime.utc_now())]}
  end

  def status(id, _config) do
    {:ok, [status: "Accepted", id: id, datetime: to_string(DateTime.utc_now())]}
  end

  def handle_config(config) do
    config
  end

  defp storage_driver(config) do
    config[:storage_driver] || Mouth.LocalAdapter.Storage.Memory
  end
end

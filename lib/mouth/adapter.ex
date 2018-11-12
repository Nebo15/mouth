defmodule Mouth.Adapter do
  @moduledoc ~S"""
  """

  @callback deliver(%Mouth.Message{}, %{}) :: any
  @callback status(String.t(), %{}) :: any
  @callback handle_config(map) :: map

  def hackney_options(config, options) do
    Keyword.merge(Map.get(config, :hackney_options, Keyword.new()), options)
  end
end

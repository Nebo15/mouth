defmodule Mouth.Adapter do
  @moduledoc ~S"""
  """

  @callback deliver(%Mouth.Message{}, %{}) :: any
  @callback status(String.t, %{}) :: any
  @callback handle_config(map) :: map
end

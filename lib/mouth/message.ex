defmodule Mouth.Message do
  @moduledoc """
  Message struct for Mouth
  """
  @type phone_number :: String.t()
  @type phone_number_list :: nil | phone_number | [phone_number]

  @type t :: %__MODULE__{
          to: phone_number,
          body: String.t(),
          meta: map
        }

  defstruct to: nil,
            body: nil,
            meta: %{}

  @spec new_message(Enum.t()) :: __MODULE__.t()
  def new_message(attrs \\ []) do
    struct!(%__MODULE__{}, attrs)
  end

  @spec to(__MODULE__.t(), String.t()) :: __MODULE__.t()
  def to(message, param) do
    Map.put(message, :to, param)
  end

  @spec body(__MODULE__.t(), String.t()) :: __MODULE__.t()
  def body(message, param) do
    Map.put(message, :body, param)
  end
end

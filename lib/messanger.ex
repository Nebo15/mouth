defmodule Mouth.Messanger do
  @moduledoc """
  """

  @cannot_call_directly_error """
  cannot call Mouth.Messanger directly. Instead implement your own Messanger module
  with: use Mouth.Messanger, otp_app: :my_app
  """

  require Logger

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do

      @spec deliver(Mouth.Message.t) :: Mouth.Message.t
      def deliver(message) do
        config = build_config()
        Mouth.Messanger.deliver(config.adapter, message, config)
      end

      def status(id) do
        config = build_config()
        Mouth.Messanger.status(config.adapter, id, config)
      end

      otp_app = Keyword.fetch!(opts, :otp_app)

      defp build_config, do: Mouth.Messanger.build_config(__MODULE__, unquote(otp_app))
    end
  end

  @doc false
  def deliver(_message) do
    raise @cannot_call_directly_error
  end

  def status(_) do
    raise @cannot_call_directly_error
  end

  @doc false
  def deliver(adapter, message, config) do
    message = validate_and_normalize(message, adapter)

    result =
      if message.to == [] do
        debug_unsent(message)
        {:error, "Empty recipient"}
      else
        debug_sent(message, adapter)
        adapter.deliver(message, config)
      end
    result
  end

  @doc false
  def status(adapter, id, config) do
    adapter.status(id, config)
  end

  defp debug_sent(message, adapter) do
    Logger.debug """
    Sending message with #{inspect adapter}:

    #{inspect message, limit: :infinity}
    """
  end

  defp debug_unsent(message) do
    Logger.debug """
    Message was not sent because recipient is empty.

    Full message - #{inspect message, limit: :infinity}
    """
  end

  defp validate_and_normalize(message, adapter) do
    validate(message, adapter)
  end

  defp validate(message, _adapter) do
    validate_recipients(message)
  end

  defp validate_recipients(%Mouth.Message{} = message) do
    if Enum.all?(
      Enum.map([:to], &Map.get(message, &1)),
      &nil_recipient?/1
    ) do
      raise Mouth.NilRecipientsError, message
    else
      message
    end
  end

  defp nil_recipient?(nil), do: true
  defp nil_recipient?([]), do: false
  defp nil_recipient?([_] = recipients) do
    Enum.all?(recipients, &nil_recipient?/1)
  end
  defp nil_recipient?(_), do: false

  def build_config(messanger, otp_app) do
    otp_app
    |> Application.fetch_env!(messanger)
    |> Map.new
    |> handle_adapter_config
  end

  defp handle_adapter_config(base_config = %{adapter: adapter}) do
    adapter.handle_config(base_config)
  end
end

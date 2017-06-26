defmodule Mouth.Messenger do
  @moduledoc """
  """

  @cannot_call_directly_error """
  cannot call Mouth.Messenger directly. Instead implement your own Messenger module
  with: use Mouth.Messenger, otp_app: :my_app
  """
  require Logger

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour Mouth.Messenger

      @spec deliver(Mouth.Message.t) :: Mouth.Message.t
      def deliver(message) do
        config = build_config()
        Mouth.Messenger.deliver(message, config)
      end

      def status(id) do
        config = build_config()
        Mouth.Messenger.status(id, config)
      end

      otp_app = Keyword.fetch!(opts, :otp_app)

      defp build_config, do: Mouth.Messenger.build_config(__MODULE__, unquote(otp_app))
    end
  end

  @optional_callbacks init: 0
  @callback init() :: {:ok, Keyword.t} | :ignore

  @doc false
  def deliver(_message) do
    raise @cannot_call_directly_error
  end

  def status(_) do
    raise @cannot_call_directly_error
  end

  @doc false
  def deliver(message, config) do
    message = validate_and_normalize(message, config.adapter)

    result =
      if message.to == [] do
        debug_unsent(message)
        {:error, "Empty recipient"}
      else
        debug_sent(message, config.adapter)
        config.adapter.deliver(message, config)
      end
    result
  end

  @doc false
  def status(id, config) do
    config.adapter.status(id, config)
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

  def build_config(messenger, otp_app) do
    otp_app
    |> get_application_config(messenger)
    |> Map.new
    |> handle_adapter_config
  end

  defp handle_adapter_config(base_config = %{adapter: adapter}) do
    adapter.handle_config(base_config)
  end

  defp get_application_config(otp_app, messenger) do
    {:ok, config} =
      if Code.ensure_loaded?(messenger) and function_exported?(messenger, :init, 0) do
        messenger.init
      else
        {:ok, Application.get_env(otp_app, messenger)}
      end
    config
  end
end

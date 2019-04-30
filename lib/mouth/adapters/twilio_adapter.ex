defmodule Mouth.TwilioAdapter do
  @moduledoc false

  import Mouth.Adapter, only: [hackney_options: 2]

  @behaviour Mouth.Adapter

  @positive_statuses ~w(
    accepted
    queued
    sending
    sent
    delivered
    received
  )

  @negative_statuses ~w(failed undelivered)

  @spec deliver(Mouth.Message.t(), %{}) :: {}
  def deliver(%Mouth.Message{to: to, from: from, body: body} = _, config) do
    process_request(to, from, body, config)
  end

  @spec status(String.t(), %{}) :: {}
  def status(id, config) do
    url = "#{config.host}/2010-04-01/Accounts/#{config.account_sid}/Messages/#{id}.json"

    call = :hackney.get(url, headers(config), [], hackney_options(config, with_body: true))

    url
    |> http_call(call, "")
    |> parse_resp(url)
  end

  defp process_request(to, from, body, config) do
    url = "#{config.host}/2010-04-01/Accounts/#{config.account_sid}/Messages.json"
    request =
      cond do
        from ->
          [Body: body, To: to, From: from]
        config[:messaging_service_sid] ->
          [Body: body, To: to, MessagingServiceSid: config.messaging_service_sid]
        true ->
          [Body: body, To: to, From: config.source_number]
      end

    send(self(), {:twilio_call, request})

    call = :hackney.post(url, headers(config), {:form, request}, hackney_options(config, with_body: true))

    url
    |> http_call(call, request)
    |> parse_resp(url)
  end

  defp http_call(url, call, body) do
    case call do
      {:ok, status, _headers, response} when status > 299 ->
        Mouth.raise_api_error(url, response, body)

      {:ok, status, headers, response} ->
        %{status_code: status, headers: headers, body: response}

      {:error, reason} ->
        Mouth.raise_api_error(url, reason, body)
    end
  end

  defp parse_resp(%{status_code: _, headers: _, body: body}, url) do
    response =
      case Jason.decode(body) do
        {:ok, body} ->
          [status: to_string(body["status"]), id: to_string(body["sid"]), datetime: to_string(body["date_created"])]

        {:error, reason} ->
          Mouth.raise_api_error(url, body, reason: reason)
      end

    case response[:status] do
      status when status in @positive_statuses ->
        {:ok, response}

      status when status in @negative_statuses ->
        {:error, response}

      _ ->
        {:error, response}
    end
  end

  def handle_config(config) do
    unless config[:host] do
      Mouth.raise_config_error(config, :host)
    end

    unless config[:source_number] do
      Mouth.raise_config_error(config, :source_number)
    end

    unless config[:account_sid] do
      Mouth.raise_config_error(config, :account_sid)
    end

    unless config[:auth_token] do
      Mouth.raise_config_error(config, :auth_token)
    end

    config
  end

  defp headers(config) do
    [
      {"Content-Type", "application/json"},
      {"Authorization", "Basic #{auth_token(config)}"}
    ]
  end

  defp auth_token(config) do
    [config.account_sid, config.auth_token]
    |> Enum.join(":")
    |> Base.encode64()
  end
end

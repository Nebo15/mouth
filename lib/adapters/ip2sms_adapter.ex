defmodule Mouth.IP2SMSAdapter do
  @moduledoc """
  Implimentation of IP2SMS Adapter for Mouth
  """
  @behaviour Mouth.Adapter

  @positive_statuses [
    "Accepted",
    "Enroute",
    "Delivered",
    "waiting",
    "sending",
    "sent",
    "waiting",
    "completed"
  ]
  @negative_statuses ["Expired", "Deleted", "Undeliverable", "Rejected", "Unknown", "canceled"]

  @spec deliver(Mouth.Message.t(), %{}) :: {}
  def deliver(%Mouth.Message{to: to, body: body} = _, config) do
    process_request(config.gateway_url, compile_send_xml(to, body, config), config)
  end

  @spec status(String.t(), %{}) :: {}
  def status(id, config) do
    process_request(config.gateway_status_url, compile_status_xml(id, config), config)
  end

  defp process_request(url, xml, config) do
    response =
      url
      |> http_call(xml, config)
      |> parse_resp()

    case response[:status] do
      status when status in @positive_statuses ->
        {:ok, response}

      status when status in @negative_statuses ->
        {:error, response}

      _ ->
        {:error, response}
    end
  end

  defp http_call(url, body, config) do
    case :hackney.post(url, headers(config), body, [:with_body]) do
      {:ok, status, _headers, response} when status > 299 ->
        Mouth.raise_api_error(config.gateway_url, response, body)

      {:ok, status, headers, response} ->
        %{status_code: status, headers: headers, body: response}

      {:error, reason} ->
        Mouth.raise_api_error(config.gateway_url, reason, body)
    end
  end

  defp parse_resp(%{status_code: _, headers: _, body: response}) do
    {doc, _} = response |> :binary.bin_to_list() |> :xmerl_scan.string()
    {:xmlObj, :string, status} = :xmerl_xpath.string('string(/status/state)', doc)
    {:xmlObj, :string, id} = :xmerl_xpath.string('string(/status/@id)', doc)
    {:xmlObj, :string, datetime} = :xmerl_xpath.string('string(/status/@date)', doc)
    [status: to_string(status), id: to_string(id), datetime: to_string(datetime)]
  end

  def handle_config(config) do
    unless config[:source_number] do
      Mouth.raise_config_error(config, :source_number)
    end

    unless config[:gateway_url] do
      Mouth.raise_config_error(config, :gateway_url)
    end

    unless config[:gateway_status_url] do
      Mouth.raise_config_error(config, :gateway_status_url)
    end

    unless config[:login] do
      Mouth.raise_config_error(config, :login)
    end

    unless config[:password] do
      Mouth.raise_config_error(config, :password)
    end

    config
  end

  defp headers(config) do
    [
      {"Content-Type", "text/xml"},
      {"Authorization", "Basic #{auth_token(config)}"}
    ]
  end

  defp auth_token(config) do
    [config.login, config.password]
    |> Enum.join(":")
    |> Base.encode64()
  end

  defp compile_send_xml(to, body, config) do
    """
    <message>
    <service id="#{service_type(to)}" source="#{config.source_number}"/>
    #{to_line_xml(to)}
    <body content-type="text/plain">#{body}</body>
    </message>
    """
  end

  defp compile_status_xml(id, _) do
    "<request id=\"#{id}\">status</request>"
  end

  defp to_line_xml(number) when is_list(number) do
    number
    |> Enum.map(&to_line_xml/1)
    |> Enum.join()
  end

  defp to_line_xml(number), do: "<to>#{number}</to>"

  defp service_type(to) when is_list(to), do: "bulk"
  defp service_type(_), do: "single"
end

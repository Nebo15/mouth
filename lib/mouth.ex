defmodule Mouth do
  @moduledoc """
  Documentation for Mouth.
  """
  # use Application

  # def start(_type, _args) do
  #   init = Application.get_env(:mouth, :init)
  #   case init do
  #     nil -> {:ok, self()}
  #     init_fun ->
  #       require IEx
  #       IEx.pry
  #       {:ok, config} = apply(init_fun, [])
  #       Map.keys(config)
  #       |> Enum.map(fn key -> Application.put_env(:mouth, key, config[key]) end)
  #       {:ok, self()}
  #   end
  # end
  defmodule NilRecipientsError do
    @moduledoc false
    defexception [:message]

    def exception(message) do
      message = """
      All recipients were set to nil. Must specify at least one recipient.
      Full message - #{inspect message, limit: :infinity}
      """
      %NilRecipientsError{message: message}
    end
  end

  defmodule ConfigError do
    @moduledoc false
    defexception [:message]

    def exception({config, field}) do
      message = """
      There was no #{field} set for the #{config.adapter} adapter.
      * Here are the config options that were passed in:
      #{inspect config}
      """
      %ConfigError{message: message}
    end
  end

  def raise_config_error(config, field) do
    raise ConfigError, {config, field}
  end

  defmodule ApiError do
    @moduledoc false
    defexception [:message]

    def exception({service_name, response, params}) do
      message = """
      There was a problem sending the message through the #{service_name} API.
      Here is the response:
      #{inspect response, limit: :infinity}
      Here are the params we sent:
      #{inspect params, limit: :infinity}
      """
      %ApiError{message: message}
    end
  end
  def raise_api_error(service_name, response, params) do
    raise ApiError, {service_name, response, params}
  end
end

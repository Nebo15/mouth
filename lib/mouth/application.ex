defmodule Mouth.Application do
  @moduledoc false

  use Application

  import Supervisor.Spec, warn: false

  require Logger

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Mouth.Supervisor]
    Supervisor.start_link(children(), opts)
  end

  @doc false
  def children do
    base = [
      worker(Mouth.LocalAdapter.Storage.Memory, [])
    ]

    if Application.get_env(:mouth, :serve_inbox) do
      cowboy = Application.ensure_all_started(:cowboy)
      plug = Application.ensure_all_started(:plug)
      port = Application.get_env(:mouth, :preview_port, 4000)

      case {cowboy, plug} do
        {{:ok, _}, {:ok, _}} ->
          Logger.info("Running Mouth inbox preview server with Cowboy using http on port #{port}")
          [Plug.Cowboy.child_spec(scheme: :http, plug: Plug.Mouth.InboxPreview, options: [port: port]) | base]

        _ ->
          Logger.warn(
            "Could not start preview server on port #{port}. Please ensure plug and cowboy" <>
              " are in your dependency list."
          )

          []
      end
    else
      base
    end
  end
end

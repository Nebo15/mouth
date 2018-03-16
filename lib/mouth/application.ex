defmodule Mouth.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Mouth.LocalAdapter.Storage.Memory, [])
    ]

    opts = [strategy: :one_for_one, name: Mouth.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

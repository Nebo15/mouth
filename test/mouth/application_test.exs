defmodule Mouth.ApplicationTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  import Supervisor.Spec

  test "starts preview web server" do
    Application.put_env(:mouth, :serve_inbox, true)

    output =
      capture_log(fn ->
        Mouth.Application.children()
      end)

    assert output =~ "Running Mouth inbox preview server with Cowboy using http on port 1423"
    assert Mouth.Application.children() == [
      Plug.Adapters.Cowboy.child_spec(:http, Plug.Mouth.InboxPreview, [], port: 1423),
      worker(Mouth.LocalAdapter.Storage.Memory, [])
    ]

    Application.delete_env(:mouth, :serve_inbox)
  end
end

defmodule Mix.Tasks.Mouth.Inbox.ServerTest do
  use ExUnit.Case

  test "starts a preview webserver" do
    refute Application.get_env(:mouth, :serve_inbox)

    # Prevent server from running with --no-halt
    Application.put_env(:mouth, :halt_server, true)
    Mix.Task.run("mouth.inbox.server", [])

    assert Application.get_env(:mouth, :serve_inbox) == true
    Application.delete_env(:mouth, :serve_inbox)
  end
end

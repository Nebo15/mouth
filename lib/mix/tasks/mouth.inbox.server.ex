defmodule Mix.Tasks.Mouth.Inbox.Server do
  @moduledoc """
  Starts the inbox preview server.

  ## Command line options

  This task accepts the same command-line arguments as `run`.
  For additional information, refer to the documentation for `Mix.Tasks.Run`.

  For example, to run `swoosh.mailbox.server` without checking dependencies:

      mix mouth.inbox.server --no-deps-check

  The `--no-halt` flag is automatically added.
  """

  use Mix.Task

  @shortdoc "Starts the inbox preview server"

  def run(args) do
    Application.put_env(:mouth, :serve_inbox, true)
    Mix.Task.run("run", run_args() ++ args)
  end

  defp run_args do
    if iex_running?() || halt?(), do: [], else: ["--no-halt"]
  end

  defp iex_running? do
    Code.ensure_loaded?(IEx) && IEx.started?()
  end

  defp halt? do
    Application.get_env(:mouth, :halt_server)
  end
end

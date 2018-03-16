defmodule Mouth.LocalAdapter.Storage.Memory do
  @moduledoc ~S"""
  In-memory storage driver used by the `Mouth.Adapters.Local` adapter.

  The messages in this mailbox are stored in memory and won't persist once your
  application is stopped.
  """

  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def stop() do
    GenServer.stop(__MODULE__)
  end

  def push(message) do
    GenServer.call(__MODULE__, {:push, message})
  end

  def pop() do
    GenServer.call(__MODULE__, :pop)
  end

  def get(id) do
    GenServer.call(__MODULE__, {:get, id})
  end

  def all() do
    GenServer.call(__MODULE__, :all)
  end

  def delete_all() do
    GenServer.call(__MODULE__, :delete_all)
  end

  # Callbacks

  def init(_args) do
    {:ok, []}
  end

  def handle_call({:push, message}, _from, messages) do
    id = :crypto.strong_rand_bytes(16) |> Base.encode16() |> String.downcase()
    message = %{message | meta: %{id: id}}
    {:reply, message, [message | messages]}
  end

  def handle_call(:pop, _from, [h | t]) do
    {:reply, h, t}
  end

  def handle_call({:get, id}, _from, messages) do
    message = Enum.find(messages, fn message -> message.meta.id == id end)
    {:reply, message, messages}
  end

  def handle_call(:all, _from, messages) do
    {:reply, messages, messages}
  end

  def handle_call(:delete_all, _from, _messages) do
    {:reply, :ok, []}
  end
end

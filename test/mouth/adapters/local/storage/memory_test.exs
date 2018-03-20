defmodule Mouth.LocalAdapter.Storage.MemoryTest do
  use ExUnit.Case

  alias Mouth.LocalAdapter.Storage.Memory

  setup do
    Memory.delete_all()
    :ok
  end

  test "start_link/0 starts with an empty mailbox" do
    {:ok, pid} = GenServer.start_link(Memory, [])
    count = GenServer.call(pid, :all) |> Enum.count()
    assert count == 0
  end

  test "push a message into the mailbox" do
    Memory.push(%Mouth.Message{})
    assert Memory.all() |> Enum.count() == 1
  end

  test "get a message from the mailbox" do
    Memory.push(%Mouth.Message{})
    %Mouth.Message{meta: %{id: id}} = Memory.push(%Mouth.Message{body: "Hello, world!"})
    Memory.push(%Mouth.Message{})
    assert %Mouth.Message{body: "Hello, world!"} = Memory.get(id)
  end

  test "pop a message from the mailbox" do
    Memory.push(%Mouth.Message{body: "Test 1"})
    Memory.push(%Mouth.Message{body: "Test 2"})
    assert Memory.all() |> Enum.count() == 2

    message = Memory.pop()
    assert message.body == "Test 2"
    assert Memory.all() |> Enum.count() == 1

    message = Memory.pop()
    assert message.body == "Test 1"
    assert Memory.all() |> Enum.count() == 0
  end

  test "delete all the messages in the mailbox" do
    Memory.push(%Mouth.Message{})
    Memory.push(%Mouth.Message{})
    assert Memory.all() |> Enum.count() == 2

    Memory.delete_all()
    assert Memory.all() |> Enum.count() == 0
  end
end

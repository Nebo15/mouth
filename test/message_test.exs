defmodule Mouth.MessageTest do
  use ExUnit.Case
  alias Mouth.Message
  import Mouth.Message

  @default_attrs [to: "+380501234567", body: "test"]

  test "Message.new_message/1 returns proper message struct" do
    assert %Message{to: "+380501234567", body: "test"} == Message.new_message(@default_attrs)
  end

  test "Message.new_message/1 returns clear struct" do
    assert %Message{to: nil, body: nil} == Message.new_message()
  end

  test "TestSender.send/1 works with to list" do
    assert %Message{to: ["+380501234567", "+380501234568"], body: "test"} ==
      Message.new_message(to: ["+380501234567", "+380501234568"], body: "test")
  end

  test "helper function to" do
    assert %Message{to: "+380501234567", body: nil} ==
      Message.new_message() |> to("+380501234567")
  end

  test "helper function body" do
    assert %Message{to: nil, body: "test"} ==
      Message.new_message() |> body("test")
  end
end

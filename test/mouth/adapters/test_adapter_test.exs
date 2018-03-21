defmodule Mouth.TestAdapterTest do
  use ExUnit.Case
  alias Mouth.Message

  @default_attrs [to: "+380501234567", body: "test"]

  defmodule TestSender do
    use Mouth.Messenger, otp_app: :mouth

    def init() do
      config = Confex.get_map(:mouth, TestSender)
      {:ok, config}
    end
  end

  Application.put_env(
    :mouth,
    __MODULE__.TestSender,
    adapter: Mouth.TestAdapter,
    gateway_url: {:system, "GATEWAY_URL", "defaulturl.com:4000"}
  )

  test "TestSender.deliver/1 works as expected" do
    msg = Message.new_message(@default_attrs)
    {:ok, _} = TestSender.deliver(msg)

    assert_receive {:sms, message}
    assert message.body == "test"
  end

  test "TestSender.deliver/1 raises when data is invalid" do
    msg = Message.new_message()

    assert catch_error(TestSender.deliver(msg)) == %Mouth.NilRecipientsError{
             message: """
             All recipients were set to nil. Must specify at least one recipient.
             Full message - %Mouth.Message{body: nil, meta: %{}, to: nil}
             """
           }
  end

  test "TestSender.deliver/1 raises api error" do
    msg = Message.new_message(body: "exception", to: "+380501234567")

    assert_raise Mouth.ApiError, fn ->
      TestSender.deliver(msg)
    end
  end

  test "confex integration" do
    msg = Message.new_message(@default_attrs)
    System.put_env("GATEWAY_URL", "systemurl.com:4000")

    on_exit(fn ->
      System.delete_env("GATEWAY_URL")
    end)

    {:ok, _} = TestSender.status(msg)
    assert_receive {:config, %{adapter: Mouth.TestAdapter, gateway_url: "systemurl.com:4000"}}
  end
end

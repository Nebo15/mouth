defmodule Mouth.TestAdapterTest do
  use ExUnit.Case
  alias Mouth.Message

  import ExUnit.CaptureIO

  @default_attrs [to: "+380501234567", body: "test"]

  Application.put_env(
    :mouth,
    __MODULE__.TestSender,
    adapter: Mouth.TestAdapter
  )

  defmodule TestSender do
    use Mouth.Messanger, otp_app: :mouth
  end

  test "TestSender.deliver/1 works as expected" do
    msg = Message.new_message(@default_attrs)
    assert capture_io(fn ->
      TestSender.deliver(msg)
    end) == "test\n"
  end

  test "TestSender.deliver/1 raises when data is invalid" do
    msg = Message.new_message()
    assert catch_error(TestSender.deliver(msg)) == %Mouth.NilRecipientsError{message:
    """
    All recipients were set to nil. Must specify at least one recipient.
    Full message - %Mouth.Message{body: nil, to: nil}
    """
    }
  end
end

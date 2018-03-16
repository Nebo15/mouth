defmodule Mouth.Adapters.LocalTest do
  use ExUnit.Case

  alias Mouth.Message
  alias Mouth.LocalAdapter.Storage.Memory

  defmodule LocalSender do
    use Mouth.Messenger, otp_app: :mouth

    def init do
      config = Confex.get_map(:mouth, LocalSender)
      {:ok, config}
    end
  end

  Application.put_env(
    :mouth,
    __MODULE__.LocalSender,
    adapter: Mouth.LocalAdapter
  )

  setup do
    Memory.delete_all()
    :ok
  end

  test "LocalSender.deliver/1 works as expected" do
    msg = Message.new_message(to: "+380501234567", body: "test")
    {:ok, _} = LocalSender.deliver(msg)

    assert [%Message{body: "test"}] = Memory.all()
  end
end

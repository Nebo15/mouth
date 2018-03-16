defmodule Plug.Mouth.InboxPreviewTest do
  use ExUnit.Case
  use Plug.Test

  alias Plug.Mouth.InboxPreview
  alias Mouth.LocalAdapter.Storage.Memory
  alias Mouth.Message

  @default_opts [
    base_path: "",
    storage_driver: Memory
  ]

  setup do
    messages = [
      Memory.push(%Message{to: "+13602223333", body: "my first message"}),
      Memory.push(%Message{to: "+15034445555", body: "my second message"})
    ]

    {:ok, messages: messages}
  end

  describe "/" do
    test "renders list of messages", %{messages: messages} do
      {200, _headers, response} =
        :get
        |> conn("/")
        |> InboxPreview.call(@default_opts)
        |> sent_resp()

      for msg <- messages do
        assert response =~ "To: #{msg.to}"
        refute response =~ msg.body
        assert response =~ ~s{href="/#{msg.meta.id}"}
      end

      assert response =~ "Select a message to preview it"
    end
  end

  describe "/:id" do
    test "renders particular message", %{messages: [msg | _]} do
      {200, _headers, response} =
        :get
        |> conn("/#{msg.meta.id}")
        |> InboxPreview.call(@default_opts)
        |> sent_resp()

      assert response =~ "To: +13602223333"
      assert response =~ "my first message"
      refute response =~ "Select a message to preview it"
    end
  end

  test "renders 404" do
    {404, _headers, response} =
      :get
      |> conn("/does/not/exist")
      |> InboxPreview.call(@default_opts)
      |> sent_resp()

    assert response == "not found"
  end
end

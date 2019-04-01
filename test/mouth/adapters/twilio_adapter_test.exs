defmodule Mouth.TwilioAdapterTest do
  use ExUnit.Case
  alias Mouth.Message

  @default_attrs [to: "+380931234567", body: "test"]

  defmodule TestTwilioSender do
    use Mouth.Messenger, otp_app: :mouth
  end

  setup_all do
    {:ok, _} = Plug.Adapters.Cowboy.http(__MODULE__.TwilioMockServer, [], port: 4001)
    :ok
  end

  setup do
    Application.put_env(
      :mouth,
      __MODULE__.TestTwilioSender,
      adapter: Mouth.TwilioAdapter,
      host: "localhost:4001",
      source_number: "TEST_NUMBER",
      account_sid: "test_sid",
      auth_token: "token"
    )
  end

  describe "TestSender.deliver against mock server" do
    defmodule TwilioMockServer do
      @moduledoc false

      use Plug.Router

      plug(:match)
      plug(:dispatch)

      get "/2010-04-01/Accounts/test_sid/Messages/SM1da5893f540a4e86a8a0b6dd549de34a.json" do
        test_resp =
          Jason.encode!(%{
            sid: "SM79ab955c7cf74ffc972adae826cfd6ce",
            date_created: "Fri, 16 Feb 2018 11:58:04 +0000",
            date_updated: "Fri, 16 Feb 2018 11:58:07 +0000",
            date_sent: "Fri, 16 Feb 2018 11:58:04 +0000",
            account_sid: "test_sid",
            to: "+380931234567",
            from: "ehealth-dev",
            messaging_service_sid: nil,
            body: "test",
            status: "delivered",
            num_segments: "1",
            num_media: "0",
            direction: "outbound-api",
            api_version: "2010-04-01",
            price: "-0.08700",
            price_unit: "USD",
            error_code: nil,
            error_message: nil,
            uri: "/2010-04-01/Accounts/test_sid/Messages/SM1da5893f540a4e86a8a0b6dd549de34a.json",
            subresource_uris: %{
              media: "/2010-04-01/Accounts/test_sid/Messages/SM1da5893f540a4e86a8a0b6dd549de34a/Media.json"
            }
          })

        conn
        |> put_resp_header("Content-Type", "application/json")
        |> send_resp(200, test_resp)
      end

      post "/2010-04-01/Accounts/test_sid/Messages.json" do
        test_resp =
          Jason.encode!(%{
            sid: "SM1da5893f540a4e86a8a0b6dd549de34a",
            date_created: "Fri, 16 Feb 2018 11:11:24 +0000",
            date_updated: "Fri, 16 Feb 2018 11:11:24 +0000",
            date_sent: nil,
            account_sid: "test_sid",
            to: "+380931234567",
            from: "ehealth-dev",
            messaging_service_sid: nil,
            body: "test",
            status: "queued",
            num_segments: "1",
            num_media: "0",
            direction: "outbound-api",
            api_version: "2010-04-01",
            price: nil,
            price_unit: "USD",
            error_code: nil,
            error_message: nil,
            uri: "/2010-04-01/Accounts/test_sid/Messages/SM1da5893f540a4e86a8a0b6dd549de34a.json",
            subresource_uris: %{
              media: "/2010-04-01/Accounts/test_sid/Messages/SM1da5893f540a4e86a8a0b6dd549de34a/Media.json"
            }
          })

        conn
        |> put_resp_header("Content-Type", "application/json")
        |> send_resp(200, test_resp)
      end

      post "/error/2010-04-01/Accounts/test_sid/Messages.json" do
        send_resp(conn, 502, "Application Error")
      end
    end

    test "TestSender.deliver/1 works as expected" do
      msg = Message.new_message(@default_attrs)

      assert TestTwilioSender.deliver(msg) ==
               {:ok,
                [
                  status: "queued",
                  id: "SM1da5893f540a4e86a8a0b6dd549de34a",
                  datetime: "Fri, 16 Feb 2018 11:11:24 +0000"
                ]}
    end

    test "TestSender.deliver/1 works as expected with overridden from" do
      msg = Message.new_message(@default_attrs ++ [from: "someotherfrom"])

      assert TestTwilioSender.deliver(msg) ==
               {:ok,
                [
                  status: "queued",
                  id: "SM1da5893f540a4e86a8a0b6dd549de34a",
                  datetime: "Fri, 16 Feb 2018 11:11:24 +0000"
                ]}
    end

    test "TestSender.deliver/1 works as expected with multiple numbers" do
      msg = Message.new_message(to: ["+380931234567", "+380931230987"], body: "test")

      assert TestTwilioSender.deliver(msg) ==
               {:ok,
                [
                  status: "queued",
                  id: "SM1da5893f540a4e86a8a0b6dd549de34a",
                  datetime: "Fri, 16 Feb 2018 11:11:24 +0000"
                ]}
    end

    test "TestSender.status/1 works as expected" do
      assert TestTwilioSender.status("SM1da5893f540a4e86a8a0b6dd549de34a") ==
               {:ok,
                [
                  status: "delivered",
                  id: "SM79ab955c7cf74ffc972adae826cfd6ce",
                  datetime: "Fri, 16 Feb 2018 11:58:04 +0000"
                ]}
    end
  end

  test "TestTwilioSender.deliver/1 raises when server returns error" do
    Application.put_env(
      :mouth,
      __MODULE__.TestTwilioSender,
      adapter: Mouth.TwilioAdapter,
      source_number: "TEST_NUMBER",
      host: "localhost:4001/error",
      account_sid: "test_sid",
      auth_token: "token"
    )

    msg = Message.new_message(@default_attrs)

    assert catch_error(TestTwilioSender.deliver(msg)) == %Mouth.ApiError{
             message: """
             There was a problem sending the message through the localhost:4001/error/2010-04-01/Accounts/test_sid/Messages.json API.
             Here is the response:
             \"Application Error\"
             Here are the params we sent:
             [Body: \"test\", To: \"+380931234567\", From: \"TEST_NUMBER\"]
             """
           }
  end

  test "TestTwilioSender.deliver/1 raises when server is unavaible" do
    Application.put_env(
      :mouth,
      __MODULE__.TestTwilioSender,
      adapter: Mouth.TwilioAdapter,
      source_number: "TEST_NUMBER",
      host: "superunavaibledoma.in",
      account_sid: "test_sid",
      auth_token: "token"
    )

    msg = Message.new_message(@default_attrs)

    assert catch_error(TestTwilioSender.deliver(msg)) == %Mouth.ApiError{
             message: """
             There was a problem sending the message through the superunavaibledoma.in/2010-04-01/Accounts/test_sid/Messages.json API.
             Here is the response:
             :nxdomain
             Here are the params we sent:
             [Body: \"test\", To: \"+380931234567\", From: \"TEST_NUMBER\"]
             """
           }
  end

  test "TestTwilioSender.deliver/1 raises when config is invalid" do
    Application.put_env(
      :mouth,
      __MODULE__.TestTwilioSender,
      adapter: Mouth.TwilioAdapter,
      host: "localhost:4001",
      account_sid: "test_sid",
      auth_token: "token"
    )

    msg = Message.new_message(@default_attrs)

    assert catch_error(TestTwilioSender.deliver(msg)) == %Mouth.ConfigError{
             message: """
             There was no source_number set for the Elixir.Mouth.TwilioAdapter adapter.
             * Here are the config options that were passed in:
             %{account_sid: \"test_sid\", adapter: Mouth.TwilioAdapter, auth_token: \"token\", host: \"localhost:4001\"}
             """
           }

    Application.put_env(
      :mouth,
      __MODULE__.TestTwilioSender,
      adapter: Mouth.TwilioAdapter,
      host: "localhost:4001",
      source_number: "TEST_NUMBER",
      account_sid: "test_sid"
    )

    msg = Message.new_message(@default_attrs)

    assert catch_error(TestTwilioSender.deliver(msg)) == %Mouth.ConfigError{
             message: """
             There was no auth_token set for the Elixir.Mouth.TwilioAdapter adapter.
             * Here are the config options that were passed in:
             %{account_sid: \"test_sid\", adapter: Mouth.TwilioAdapter, host: \"localhost:4001\", source_number: \"TEST_NUMBER\"}
             """
           }

    Application.put_env(
      :mouth,
      __MODULE__.TestTwilioSender,
      adapter: Mouth.TwilioAdapter,
      host: "localhost:4001",
      source_number: "TEST_NUMBER",
      auth_token: "token"
    )

    msg = Message.new_message(@default_attrs)

    assert catch_error(TestTwilioSender.deliver(msg)) == %Mouth.ConfigError{
             message: """
             There was no account_sid set for the Elixir.Mouth.TwilioAdapter adapter.
             * Here are the config options that were passed in:
             %{adapter: Mouth.TwilioAdapter, auth_token: \"token\", host: \"localhost:4001\", source_number: \"TEST_NUMBER\"}
             """
           }
  end

  test "TestTwilioSender.deliver/1 raises when data is invalid" do
    msg = Message.new_message()

    assert catch_error(TestTwilioSender.deliver(msg)) == %Mouth.NilRecipientsError{
             message: """
             All recipients were set to nil. Must specify at least one recipient.
             Full message - %Mouth.Message{body: nil, from: nil, meta: %{}, to: nil}
             """
           }
  end
end

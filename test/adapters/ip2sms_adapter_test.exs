defmodule Mouth.IP2SMSAdapterTest do
  use ExUnit.Case
  alias Mouth.Message

  @default_attrs [to: "+380931234567", body: "test"]

  defmodule TestSMS2IPSender do
    use Mouth.Messenger, otp_app: :mouth
  end

  setup_all do
    {:ok, _} = Plug.Adapters.Cowboy.http __MODULE__.IP2SMSMockServer, [], port: 4000
    :ok
  end

  setup do
    Application.put_env(
      :mouth,
      __MODULE__.TestSMS2IPSender,
      adapter: Mouth.IP2SMSAdapter,
      source_number: "TEST_NUMBER",
      gateway_url: "localhost:4000",
      login: "test",
      password: "password"
    )
  end

  describe "TestSender.deliver against mock server" do
    defmodule IP2SMSMockServer do
      use Plug.Router
      plug :match
      plug :dispatch

      post "/" do
        test_resp = """
        <status id="3806712345671174984921384" date="Wed, 28 Mar 2007 12:35:00 +0300">
        <state>Accepted</state>
        </status>
        """
        conn
        |> put_resp_header("Content-Type", "text/xml")
        |> send_resp(200, test_resp)
      end

      post "/error" do
        send_resp(conn, 502, "Application Error")
      end
    end

    test "TestSender.deliver/1 works as expected" do
      msg = Message.new_message(@default_attrs)
      assert TestSMS2IPSender.deliver(msg) == {:ok, [status: "Accepted", id: "3806712345671174984921384"]}
    end

    test "TestSender.deliver/1 works as expected with multiple numbers" do
      msg = Message.new_message(to: ["+380931234567", "+380931230987"], body: "test")
      assert TestSMS2IPSender.deliver(msg) == {:ok, [status: "Accepted", id: "3806712345671174984921384"]}
    end

    test "TestSender.status/1 works as expected" do
      assert TestSMS2IPSender.status("3806712345671174984921384") ==
        {:ok, [status: "Accepted", id: "3806712345671174984921384"]}
    end

    test "TestSMS2IPSender.deliver/1 raises when server returns error" do
      Application.put_env(
        :mouth,
        __MODULE__.TestSMS2IPSender,
        adapter: Mouth.IP2SMSAdapter,
        source_number: "TEST_NUMBER",
        gateway_url: "localhost:4000/error",
        login: "test",
        password: "password"
      )
      msg = Message.new_message(@default_attrs)
      assert catch_error(TestSMS2IPSender.deliver(msg)) ==  %Mouth.ApiError{message:
      """
      There was a problem sending the message through the localhost:4000/error API.
      Here is the response:
      \"Application Error\"
      Here are the params we sent:
      \"<message>\\n<service id=\\\"single\\\" source=\\\"TEST_NUMBER\\\"/>\\n<to>+380931234567</to>\\n<body content-type=\\\"text/plain\\\">test</body>\\n</message>\\n\"
      """
      }
    end

    test "TestSMS2IPSender.deliver/1 raises when server is unavaible" do
      Application.put_env(
        :mouth,
        __MODULE__.TestSMS2IPSender,
        adapter: Mouth.IP2SMSAdapter,
        source_number: "TEST_NUMBER",
        gateway_url: "superunavaibledoma.in",
        login: "test",
        password: "password"
      )
      msg = Message.new_message(@default_attrs)
      assert catch_error(TestSMS2IPSender.deliver(msg)) ==  %Mouth.ApiError{message:
      """
      There was a problem sending the message through the superunavaibledoma.in API.
      Here is the response:
      :nxdomain
      Here are the params we sent:
      \"<message>\\n<service id=\\\"single\\\" source=\\\"TEST_NUMBER\\\"/>\\n<to>+380931234567</to>\\n<body content-type=\\\"text/plain\\\">test</body>\\n</message>\\n\"
      """
      }
    end
  end

  test "TestSMS2IPSender.deliver/1 raises when config is invalid" do
    Application.put_env(
      :mouth,
      __MODULE__.TestSMS2IPSender,
      adapter: Mouth.IP2SMSAdapter,
      gateway_url: "localhost:4000",
      login: "test",
      password: "password"
    )
    msg = Message.new_message(@default_attrs)
    assert catch_error(TestSMS2IPSender.deliver(msg)) ==  %Mouth.ConfigError{message:
    """
    There was no source_number set for the Elixir.Mouth.IP2SMSAdapter adapter.
    * Here are the config options that were passed in:
    %{adapter: Mouth.IP2SMSAdapter, gateway_url: \"localhost:4000\", login: \"test\", password: \"password\"}
    """
    }
    Application.put_env(
      :mouth,
      __MODULE__.TestSMS2IPSender,
      adapter: Mouth.IP2SMSAdapter,
      source_number: "TEST_NUMBER",
      login: "test",
      password: "password"
    )
    msg = Message.new_message(@default_attrs)
    assert catch_error(TestSMS2IPSender.deliver(msg)) ==  %Mouth.ConfigError{message:
    """
    There was no gateway_url set for the Elixir.Mouth.IP2SMSAdapter adapter.
    * Here are the config options that were passed in:
    %{adapter: Mouth.IP2SMSAdapter, login: \"test\", password: \"password\", source_number: \"TEST_NUMBER\"}
    """
    }
    Application.put_env(
      :mouth,
      __MODULE__.TestSMS2IPSender,
      adapter: Mouth.IP2SMSAdapter,
      gateway_url: "localhost:4000",
      source_number: "TEST_NUMBER",
      password: "password"
    )
    msg = Message.new_message(@default_attrs)
    assert catch_error(TestSMS2IPSender.deliver(msg)) ==  %Mouth.ConfigError{message:
    """
    There was no login set for the Elixir.Mouth.IP2SMSAdapter adapter.
    * Here are the config options that were passed in:
    %{adapter: Mouth.IP2SMSAdapter, gateway_url: \"localhost:4000\", password: \"password\", source_number: \"TEST_NUMBER\"}
    """
    }
    Application.put_env(
      :mouth,
      __MODULE__.TestSMS2IPSender,
      adapter: Mouth.IP2SMSAdapter,
      gateway_url: "localhost:4000",
      source_number: "TEST_NUMBER",
      login: "test"
    )
    msg = Message.new_message(@default_attrs)
    assert catch_error(TestSMS2IPSender.deliver(msg)) ==  %Mouth.ConfigError{message:
    """
    There was no password set for the Elixir.Mouth.IP2SMSAdapter adapter.
    * Here are the config options that were passed in:
    %{adapter: Mouth.IP2SMSAdapter, gateway_url: \"localhost:4000\", login: \"test\", source_number: \"TEST_NUMBER\"}
    """
    }
  end
  test "TestSMS2IPSender.deliver/1 raises when data is invalid" do
    msg = Message.new_message()
    assert catch_error(TestSMS2IPSender.deliver(msg)) == %Mouth.NilRecipientsError{message:
    """
    All recipients were set to nil. Must specify at least one recipient.
    Full message - %Mouth.Message{body: nil, to: nil}
    """
    }
  end
end

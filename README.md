# Mouth
![logo](https://68.media.tumblr.com/avatar_21e0adf52036_128.png "Logo")

Simple adapter based SMS sending library

## Installation
This package can be installed
by adding `mouth` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:mouth, "~> 0.1.0"}]
end
```

## Adapters
* `Mouth.SMS2IPAdapter` - Simple SMS2IP adapter
* `Mouth.TestAdapter` - Adapter for test environment

## Getting Started
```elixir
# In your config/config.exs file
#
# There may be other adapter specific configuration you need to add.
config :my_app, MyApp.Messanger,
  adapter: Mouth.SMS2IPAdapter,
  source_number: "TEST_NUMBER",
  gateway_url: "localhost:4000",
  login: "test",
  password: "password"

# Somewhere in your application
defmodule MyApp.Messanger do
  use Mouth.Messanger, otp_app: :my_app
end

# Define your messages
defmodule MyApp.Message do
  import Mouth.Message

  def send_password do
    new_message(
      to: "+380931234567",
      body: "12345"
    )

    # or pipe using Mouth.Message functions
    new_message
    |> to("+380931234567")
    |> body("12345")
  end
end

# In a controller or some other module
Message.send_password |> Messanger.deliver
```

## Contributing

Before opening a pull request, please open an issue first.

Once we've decided how to move forward with a pull request:

    $ git clone https://github.com/nebo15/mouth.git
    $ cd mouth
    $ mix deps.get
    $ mix test

Once you've made your additions and `mix test` passes, go ahead and open a PR!

## Thanks!
Thanks to cool guys from [Bamboo](https://github.com/thoughtbot/bamboo) for inspiration

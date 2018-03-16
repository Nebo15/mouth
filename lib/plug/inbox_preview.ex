if Code.ensure_loaded?(Plug) do
  defmodule Plug.Mouth.InboxPreview do
    @moduledoc """
    Plug that serves pages useful for previewing messages in development.

    It takes one option at initialization:

      * `base_path` - sets the base URL path where this module is plugged. Defaults
        to `/`.

    ## Examples

        # in a Phoenix router
        defmodule Sample.Router do
          scope "/dev" do
            pipe_through [:browser]
            forward "/inbox", Plug.Mouth.InboxPreview, [base_path: "/dev/inbox"]
          end
        end
    """

    use Plug.Router
    use Plug.ErrorHandler

    alias Mouth.LocalAdapter.Storage.Memory

    require EEx
    EEx.function_from_file(:defp, :template, "lib/plug/templates/inbox_preview/index.html.eex", [:assigns])

    def call(conn, opts) do
      conn =
        conn
        |> assign(:base_path, opts[:base_path] || "")
        |> assign(:storage_driver, opts[:storage_driver] || Memory)

      super(conn, opts)
    end

    plug(:match)
    plug(:dispatch)

    get "/" do
      messages = conn.assigns.storage_driver.all()

      conn
      |> put_resp_content_type("text/html")
      |> send_resp(200, template(messages: messages, message: nil, conn: conn))
    end

    get "/:id" do
      messages = conn.assigns.storage_driver.all()
      message = conn.assigns.storage_driver.get(id)

      conn
      |> put_resp_content_type("text/html")
      |> send_resp(200, template(messages: messages, message: message, conn: conn))
    end

    match _ do
      send_resp(conn, 404, "not found")
    end

    defp to_absolute_url(conn, path) do
      URI.parse("#{conn.assigns.base_path}/#{path}").path
    end
  end
end

defmodule MockMe.ResponsePlug do
  @moduledoc """
  Used to handle the toggling of the responses based on the route flag.
  """
  import Plug.Conn
  require Logger
  require Jason
  alias Plug.Conn
  alias MockMe.{State, Response, Route, ResponseNotSetError}

  def init(options), do: options

  def call(
        %{assigns: %{route: %Route{} = route}} = conn,
        _opts
      ) do
    conn = put_resp_header(conn, "content-type", route.content_type)

    route.name
    |> State.current_route_flag()
    |> do_call(conn)
  end

  def call(conn, _opts) do
    message =
      "the route #{conn.method} `#{conn.request_path}` has not been defined in your configuration"

    Logger.error(message)

    send_resp(conn, 404, message)
  end

  defp do_call(%ResponseNotSetError{} = error, conn) do
    send_resp(conn, 500, Jason.encode!(%{error: Map.from_struct(error)}))
  end

  defp do_call({:timeout, milliseconds}, conn) do
    :timer.sleep(milliseconds)
    do_call(:timeout, conn)
  end

  defp do_call(
         flag,
         %Conn{assigns: %{route: %Route{name: name}}} = conn
       )
       when is_atom(flag) do
    State.routes()
    |> Map.fetch!(name)
    |> Map.fetch!(:responses)
    |> Map.fetch(flag)
    |> case do
      :error ->
        Logger.error("No mock for test_case [:#{name}, :#{flag}]")

        send_resp(
          conn,
          500,
          Jason.encode!(%{
            data: %{message: "Mock not found", route_name: name, flag: flag}
          })
        )

      {:ok, %Response{} = response} ->
        conn
        |> set_response_headers(response)
        |> set_response_cookies(response)
        |> send_resp(
          response.status_code,
          response.body
        )
    end
  end

  def set_response_headers(conn, %{headers: []}), do: conn

  def set_response_headers(conn, %{headers: headers}) do
    Enum.reduce(headers, conn, fn {header, value}, conn ->
      put_resp_header(conn, header, value)
    end)
  end

  def set_response_cookies(conn, %{cookies: []}), do: conn

  def set_response_cookies(conn, %{cookies: cookies}) do
    conn = %{conn | secret_key_base: "some_key"}

    Enum.reduce(cookies, conn, fn {name, attrs, options}, conn ->
      put_resp_cookie(conn, name, attrs, options)
    end)
  end
end

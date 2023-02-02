defmodule MockMeTest do
  @moduledoc false
  use ExUnit.Case
  alias MockMe.{Response, State}
  doctest MockMe

  @moduletag :capture_log

  defp base_url do
    port = Application.get_env(:mock_me, :port, MockMe.default_port())
    "http://localhost:#{port}"
  end

  defp route_url(route_name) do
    path = get_route_path(route_name)
    base_url() |> Path.join(path)
  end

  defp get_route_path(route_name) do
    State.get_state()
    |> Map.fetch!(:routes)
    |> Map.fetch!(route_name)
    |> Map.fetch!(:path)
  end

  setup do
    State.reset_routes()
    MockMe.TestRoutes.routes() |> MockMe.add_routes()
  end

  describe "state agent" do
    test "has started" do
      assert %State{} = MockMe.get_state()
    end

    test "set_response/2 works if flag exists" do
      assert MockMe.set_response(:test_me, :failure)

      assert MockMe.current_route_flag(:test_me) == :failure
    end

    test "set_response/2 throws if route is not defined" do
      assert_raise(
        MockMe.RouteNotDefinedError,
        fn -> MockMe.set_response(:not_defined, :not_defined) end
      )
    end

    test "set_response/2 throws if flag has not been defined" do
      assert_raise(
        MockMe.ResponseNotDefinedError,
        fn -> MockMe.set_response(:test_me, :bogus) end
      )
    end

    test "reset_flags/0" do
      assert MockMe.set_response(:test_me, :failure)

      assert MockMe.current_route_flag(:test_me) == :failure

      assert MockMe.reset_flags()

      assert %MockMe.ResponseNotSetError{} = MockMe.current_route_flag(:test_me)
    end

    test "add_response/2" do
      response = %Response{flag: :timeout, body: ""}
      %{test_me: %{responses: responses}} = State.routes()
      assert Map.get(responses, :timeout) === nil
      MockMe.add_response(:test_me, response)
      assert %{test_me: %{responses: responses}} = State.routes()
      assert Map.get(responses, :timeout) === response
    end

    test "remove_response/2" do
      assert %{
               test_me: %{
                 responses: %{success: %Response{}}
               }
             } = State.routes()

      assert MockMe.remove_response(:test_me, :success) == :ok
      assert %{test_me: %{responses: responses}} = State.routes()
      assert Map.get(responses, :success) === nil
    end
  end

  describe "integrations with test endpoints" do
    test "getting a success repsonse" do
      assert MockMe.set_response(:test_me, :success)

      assert {:ok, %HTTPoison.Response{status_code: 200, body: resp_body}} =
               :test_me
               |> route_url()
               |> HTTPoison.get()

      assert "test-body" == resp_body
    end

    test "toggling the response" do
      assert MockMe.set_response(:test_me, :failure)

      assert {:ok, %HTTPoison.Response{status_code: 422, body: resp_body}} =
               :test_me
               |> route_url()
               |> HTTPoison.get()

      assert "test-failure-body" == resp_body
    end

    test "timeout" do
      assert MockMe.set_response(:test_me, {:timeout, 1000})

      assert {:error, %HTTPoison.Error{reason: :timeout}} =
               :test_me
               |> route_url()
               |> HTTPoison.get([], recv_timeout: 800)
    end

    test "timeout - will still return 200 if response is defined" do
      response = %Response{flag: :timeout, body: "This is the expected timeout response"}
      assert MockMe.add_response(:test_me, response) == :ok

      assert State.routes()
             |> Map.get(:test_me)
             |> Map.get(:responses)
             |> Map.get(:timeout) == response

      assert MockMe.set_response(:test_me, {:timeout, 500}) == :ok

      assert {:ok, %HTTPoison.Response{status_code: 200, body: body}} =
               :test_me
               |> route_url()
               |> HTTPoison.get()

      assert body === response.body
    end

    test "not defined route" do
      assert {:ok, %HTTPoison.Response{status_code: 404, body: resp_body}} =
               base_url()
               |> Path.join("not-defined")
               |> HTTPoison.get()

      assert resp_body =~ "has not been defined"
    end

    test "response not set" do
      MockMe.reset_flags()
      assert State.get_state() |> Map.fetch!(:flags) == %{}

      assert {:ok,
              %HTTPoison.Response{
                status_code: 500,
                body: resp_body
              }} =
               :test_me
               |> route_url()
               |> HTTPoison.get()

      assert resp_body =~ "No response has been set for route: :test_me"
    end

    test "sets passed in headers" do
      assert MockMe.set_response(:test_headers, :success)

      assert {:ok, %HTTPoison.Response{status_code: 200, headers: headers}} =
               :test_headers
               |> route_url()
               |> HTTPoison.get()

      assert Enum.any?(headers, fn item -> {"content-type", "application/xml"} == item end)
    end

    test "sets passed in cookies" do
      assert MockMe.set_response(:test_cookies, :success)

      assert {:ok, %HTTPoison.Response{status_code: 200, headers: headers}} =
               :test_cookies
               |> route_url()
               |> HTTPoison.get()

      assert Enum.any?(headers, fn item ->
               case item do
                 {"set-cookie", "my-cookie=" <> cookie} -> !is_nil(cookie)
                 _ -> false
               end
             end)
    end
  end
end

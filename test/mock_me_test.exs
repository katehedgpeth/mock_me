defmodule MockMeTest do
  @moduledoc false
  use ExUnit.Case
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
    MockMe.State.get_state()
    |> Map.fetch!(:routes)
    |> Map.fetch!(route_name)
    |> Map.fetch!(:path)
  end

  describe "state agent" do
    test "has started" do
      assert MockMe.set_response(:jwt, :failure)
      assert MockMe.current_route_flag(:jwt) == :failure
    end

    test "set_response/2" do
      assert MockMe.set_response(:test_me, :failure)

      assert MockMe.current_route_flag(:test_me) == :failure
    end

    test "set_response/2 ignores unset flags" do
      assert MockMe.set_response(:no_flag, :bogus)

      assert MockMe.current_route_flag(:no_flag) == :bogus
    end

    test "reset_flags/0" do
      assert MockMe.set_response(:test_me, :wipe_me)

      assert MockMe.current_route_flag(:test_me) == :wipe_me

      assert MockMe.reset_flags()

      assert %MockMe.ResponseNotSetError{} = MockMe.current_route_flag(:test_me)
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

    test "invalid flag" do
      assert MockMe.set_response(:test_me, :invalid_flag)

      assert {:ok, %HTTPoison.Response{status_code: 500, body: resp_body}} =
               :test_me
               |> route_url()
               |> HTTPoison.get()

      body = Jason.decode!(resp_body)
      assert body["data"] != nil
    end

    test "not defined route" do
      assert MockMe.set_response(:test_me, :invalid_flag)

      assert {:ok, %HTTPoison.Response{status_code: 404, body: resp_body}} =
               base_url()
               |> Path.join("not-defined")
               |> HTTPoison.get()

      assert resp_body =~ "has not been defined"
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

defmodule MockMe.TestRoutes do
  @routes [
    %MockMe.Route{
      name: :test_me,
      path: "/test-path",
      responses: [
        %MockMe.Response{flag: :success, body: "test-body"},
        %MockMe.Response{flag: :failure, body: "test-failure-body", status_code: 422}
      ]
    },
    %MockMe.Route{
      name: :test_headers,
      path: "/test-headers",
      responses: [
        %MockMe.Response{
          flag: :success,
          body: "test-body",
          headers: [{"content-type", "application/xml"}, {"connection", "Keep-Alive"}]
        },
        %MockMe.Response{flag: :failure, body: "test-failure-body", status_code: 422}
      ]
    },
    %MockMe.Route{
      name: :test_cookies,
      path: "/test-cookies",
      responses: [
        %MockMe.Response{
          flag: :success,
          body: "test-body",
          cookies: [{"my-cookie", %{user_id: 1}, [sign: true]}]
        },
        %MockMe.Response{flag: :failure, body: "test-failure-body", status_code: 422}
      ]
    }
  ]

  def routes, do: @routes
end

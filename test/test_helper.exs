ExUnit.start()
MockMe.start()

Application.ensure_all_started(:hackney)

MockMe.TestRoutes.routes() |> MockMe.add_routes()
MockMe.start_server()

MockMe.reset_flags()

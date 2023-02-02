defmodule MockMe.ResponseNotSetError do
  @type t :: %__MODULE__{
          message: String.t()
        }
  defexception [:message]

  def exception(route_name: route_name) do
    %__MODULE__{
      message: """
      No response has been set for route: :#{route_name}.
      Be sure to call `MockMe.set_response(route_name, flag)`
      before attempting to call the mock server.
      """
    }
  end
end

defmodule MockMe.RouteNotDefinedError do
  defexception [:message, :route_name]

  def exeception(route_name: route_name) do
    route_names =
      MockMe.State.routes()
      |> Map.keys()
      |> Enum.map(&("- :" <> &1))
      |> Enum.join("\n")

    %__MODULE__{
      message: """
      Cannot find a route named :#{route_name}.
      Known route names:
      #{route_names}
      """
    }
  end
end

defmodule MockMe.ResponseNotDefinedError do
  defexception [:message]

  def exception(route_name: route_name, flag: flag) do
    %MockMe.Route{responses: responses} = MockMe.State.routes() |> Map.fetch!(route_name)

    known_keys =
      responses
      |> Map.keys()
      |> Enum.map(&"- :#{&1}")
      |> Enum.join("\n")

    %__MODULE__{
      message: """
      No response with flag :#{flag} defined for route :#{route_name}.
      Known flags for :#{route_name}:
      #{known_keys}
      """
    }
  end
end

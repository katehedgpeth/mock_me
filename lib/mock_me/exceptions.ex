defmodule MockMe.ResponseNotSetError do
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

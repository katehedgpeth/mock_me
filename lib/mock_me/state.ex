defmodule MockMe.State do
  @moduledoc """
  Used to keep track of state for mocks in tests.
  Holds a map of route names and response flags which the server uses to determine which response to serve.

  ## Example

  ```
  %{
    routes: [
      %MockMe.Route{
        name: :test_me,
        path: "/test-path",
        responses: [
          %MockMe.Response{flag: :success, body: "test-body"},
          %MockMe.Response{flag: :failure, body: "test-failure-body"}
        ]
      }
    ],
    cases: %{
      test_me: :success
    }
  }
  ```
  These values are populated from `MockMe.add_routes/1` and then toggled using `MockMe.set_response(:route_name, :route_flag)`.
  """
  use Agent, shutdown: 5000

  alias MockMe.ResponseNotDefinedError
  alias MockMe.RouteNotDefinedError
  alias MockMe.{Route, Response}

  @type t() :: %__MODULE__{
          routes: %{
            atom() => Route.t()
          },
          flags: %{
            atom() => Response.t()
          }
        }

  defstruct routes: %{},
            flags: %{}

  def start_link(_) do
    Agent.start_link(fn -> %__MODULE__{} end, name: __MODULE__)
  end

  def routes do
    Agent.get(__MODULE__, fn %__MODULE__{routes: routes} -> routes end)
  end

  @doc """
  Called inside each endoint to determine which response to return.
  You should never need to call this in your code except in the case of troubleshooting.
  """
  @spec current_route_flag(atom()) :: atom() | ResponseNotSetError.t()
  def current_route_flag(route_name) do
    Agent.get(__MODULE__, &do_current_route_flag(&1, route_name))
  end

  def reset_flags do
    Agent.update(__MODULE__, &do_reset_flags/1)
  end

  def set_route_flag(route_name, flag) do
    :ok = verify_route_flag_exists(route_name, flag)

    Agent.update(__MODULE__, &do_set_route_flag(&1, route_name, flag))
  end

  def get_state do
    Agent.get(__MODULE__, & &1)
  end

  def add_routes(routes) do
    Enum.each(routes, &add_route/1)
  end

  def reset_routes() do
    Agent.update(__MODULE__, &do_reset_routes/1)
  end

  def add_route(%Route{} = route) do
    Agent.update(__MODULE__, &do_add_route(&1, route))
  end

  def add_route_response(route_name, %Response{} = response) do
    Agent.update(__MODULE__, &do_add_route_response(&1, route_name, response))
  end

  def remove_route_response(route_name, response_name) do
    Agent.update(__MODULE__, &do_remove_route_response(&1, route_name, response_name))
  end

  defp do_reset_routes(%__MODULE__{} = state) do
    %{state | routes: %{}}
  end

  defp do_add_route(%__MODULE__{routes: routes} = state, %Route{} = route) do
    responses =
      route
      |> Map.fetch!(:responses)
      |> Enum.map(&{&1.flag, &1})
      |> Enum.into(%{})

    %{
      state
      | routes: Map.put(routes, route.name, %{route | responses: responses})
    }
  end

  defp do_current_route_flag(
         %__MODULE__{flags: flags},
         route_name
       ) do
    case Map.fetch(flags, route_name) do
      {:ok, flag} ->
        flag

      :error ->
        MockMe.ResponseNotSetError.exception(route_name: route_name)
    end
  end

  defp do_set_route_flag(
         %__MODULE__{flags: flags} = state,
         route_name,
         flag
       ) do
    %{state | flags: Map.put(flags, route_name, flag)}
  end

  defp do_reset_flags(%__MODULE__{} = state) do
    %{state | flags: %{}}
  end

  defp do_add_route_response(%__MODULE__{} = state, route_name, response) do
    routes =
      Map.update!(
        state.routes,
        route_name,
        &add_response_to_route(&1, response)
      )

    %{state | routes: routes}
  end

  defp add_response_to_route(%Route{} = route, response) do
    %{route | responses: Map.put(route.responses, response.flag, response)}
  end

  defp do_remove_route_response(%__MODULE__{} = state, route_name, response_name) do
    routes = Map.update!(state.routes, route_name, &remove_response_from_route(&1, response_name))
    %{state | routes: routes}
  end

  defp remove_response_from_route(%Route{} = route, response_name) do
    %{route | responses: Map.delete(route.responses, response_name)}
  end

  defp verify_route_flag_exists(_, {:timeout, milliseconds}) when is_integer(milliseconds) do
    :ok
  end

  defp verify_route_flag_exists(route_name, flag) do
    # raise if route or response has not been defined
    case routes() |> Map.fetch(route_name) do
      :error ->
        raise RouteNotDefinedError, route_name: route_name

      {:ok, %Route{responses: responses}} ->
        if Map.fetch(responses, flag) === :error do
          raise ResponseNotDefinedError, route_name: route_name, flag: flag
        end
    end

    :ok
  end
end

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

  # def child_spec([]) do
  #   %{
  #     id: __MODULE__,
  #     start:
  #       {__MODULE__, :start_link,
  #        [
  #          %__MODULE__{}
  #        ]},
  #     restart: :permanent,
  #     shutdown: 5000,
  #     type: :worker
  #   }
  # end

  def start_link(%__MODULE__{} = initial_state) do
    Agent.start_link(fn -> initial_state end, name: __MODULE__)
  end

  def routes do
    Agent.get(__MODULE__, fn %__MODULE__{routes: routes} -> routes end)
  end

  @doc """
  Called inside each endoint to determine which response to return.
  You should never need to call this in your code except in the case of troubleshooting.
  """
  @spec current_route_flag(atom()) :: atom()
  def current_route_flag(route_name) do
    Agent.get(__MODULE__, &do_current_route_flag(&1, route_name))
  end

  def reset_flags do
    Agent.update(__MODULE__, &do_reset_flags/1)
  end

  def set_route_flag(route_name, flag) do
    Agent.update(__MODULE__, &do_set_route_flag(&1, route_name, flag))
  end

  def get_state do
    Agent.get(__MODULE__, & &1)
  end

  def add_routes(routes) do
    Enum.each(routes, &add_route/1)
  end

  def add_route(%Route{} = route) do
    Agent.update(__MODULE__, &do_add_route(&1, route))
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
end

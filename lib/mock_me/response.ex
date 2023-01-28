defmodule MockMe.Response do
  @moduledoc """
  Used to define how the mocked endpoint should respond.

  ## Example

    ```
    %Response{
      flag: :success,               #required
      body: "some-serialized-body", #required
      status_code: 200,             #default
      headers: [],                  #default
      cookies: [],                  #default
    }
    ```

    `headers` is an array of tuples with the header and value: `{"content-type", "application/json"}`
    `cookies` is an array of tuples with the name, value and options which follow the signature of `Plug.Conn.set_resp_cookie`
    `{"my-cookie", %{user_id: user.id}, sign: true}`
  """

  @type t :: %__MODULE__{
          flag: atom(),
          body: String.t(),
          headers: List.t({String.t(), String.t()}),
          cookies: List.t({String.t(), Map.t(), Keyword.t()}),
          status_code: integer()
        }

  @type flag() :: atom() | {:timeout, integer()}

  @enforce_keys [:flag, :body]
  defstruct [
    :flag,
    :body,
    headers: [],
    cookies: [],
    status_code: 200
  ]
end

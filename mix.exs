defmodule MockMe.MixProject do
  @moduledoc false
  use Mix.Project

  def project do
    [
      app: :mock_me,
      version: "0.2.0",
      elixir: "~> 1.10",
      elixirc_paths: Mix.env() |> elixirc_paths(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "MockMe",
      description: description(),
      package: package(),
      source_url: "https://github.com/katehedgpeth/mock_me"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MockMe.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["test/fixtures"] ++ elixirc_paths(:prod)
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.0.0", [only: [:dev, :test], runtime: false]},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false},
      {:httpoison, "~> 1.7", [only: [:dev, :test], runtime: false]},
      {:plug, "~> 1.14"},
      {:plug_cowboy, "~> 2.0"},
      {:jason, "~> 1.4"}
    ]
  end

  defp description() do
    """
    MockMe is a simple mock server used to mock out your third party services in your tests. Unlike many mocking
    solutions, MockMe starts a real HTTP server and serves real static responses which may be toggled easily using
    the `MockMe.set_response(:test, :result)` function in your tests.
    """
  end

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/nbriar/mock_me",
        "ExampleApp" => "https://github.com/nbriar/mock_me_phoenix_example"
      }
    ]
  end
end

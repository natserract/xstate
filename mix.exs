defmodule Xstate.MixProject do
  use Mix.Project

  def project do
    [
      app: :xstate,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "State machine library for Elixir",
      source_url: "https://github.com/natserract/xstate",
      homepage_url: "https://github.com/natserract/xstate",
      package: [
        maintainers: ["Alfin Surya"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/natserract/xstate"}
      ],
      docs: [
        extras: ["README.md"],
        main: "readme"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:type_struct, "~> 0.1.0"}
    ]
  end
end

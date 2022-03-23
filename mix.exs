defmodule Recode.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/hrzndhrn/recode"

  def project do
    [
      app: :recode,
      version: "0.1.0",
      elixir: "~> 1.11",
      name: "Recode",
      description: description(),
      docs: docs(),
      source_url: @source_url,
      start_permanent: Mix.env() == :prod,
      dialyzer: dialyzer(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env(),
      deps: deps(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :mix, :ex_unit, :crypto],
      mod: {Recode.Application, []}
    ]
  end

  defp description do
    "A linter with autocorrection and a refactoring tool."
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      formatters: ["html"],
      groups_for_modules: [
        "Linter tasks": [
          Recode.Task.AliasExpansion,
          Recode.Task.PipeFunOne,
          Recode.Task.SinglePipe,
          Recode.Task.Specs
        ],
        "Refactoring tasks": [
          Recode.Task.Rename
        ]
      ]
    ]
  end

  def preferred_cli_env do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test,
      "coveralls.github": :test
    ]
  end

  defp dialyzer do
    [
      plt_file: {:no_warn, "test/support/plts/dialyzer.plt"},
      flags: [:unmatched_returns]
    ]
  end

  defp deps do
    [
      {:beam_file, "~> 0.3"},
      {:bunt, "~> 0.2.0"},
      {:sourceror, "~> 0.10"},
      # dev/test
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.25", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:mox, "~> 1.0", only: :test}
    ]
  end

  defp package do
    [
      maintainers: ["Marcus Kruse"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end

defmodule PasetoPlug.MixProject do
  use Mix.Project

  def project do
    [
      app: :paseto_plug,
      version: "0.4.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      description: description(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:paseto, "~> 1.3"},
      {:plug, "~> 1.0"},
      # Non-core dependencies, but nice-to-have
      {:credo, "~> 0.9.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      testall: ["credo", "test"]
    ]
  end

  defp description do
    "A plug for validating issued Paseto (Platform Agnostic Security Tokens)."
  end

  defp package do
    [
      name: "paseto_plug",
      files: ["lib", "mix.exs", "LICENSE"],
      maintainers: ["Ian Lee Clark"],
      licenses: ["BSD 3-clause"],
      links: %{"Github" => "https://github.com/GrappigPanda/paseto_plug"}
    ]
  end
end

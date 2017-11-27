defmodule Mouth.Mixfile do
  use Mix.Project

  def project do
    [app: :mouth,
     version: "0.3.3",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [tool: ExCoveralls],
     description: description(),
     package: package(),
     deps: deps()]
  end

  def application do
    [external_applications: [:logger, :hackney, :xmerl]]
  end

  defp deps do
    [
      {:hackney, "~> 1.8.6"},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:dogma, "~> 0.1", only: :test},
      {:excoveralls, "~> 0.6", only: :test},
      {:cowboy, "~> 1.0.0", only: :test},
      {:plug, "~> 1.0", only: :test},
      {:confex, ">= 0.0.0", only: :test}
    ]
  end

  defp description do
    """
    Simple adapter based SMS sending library
    """
  end

  defp package do
    [
      name: :mouth,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Alex Troush"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/nebo15/mouth"}
    ]
  end
end

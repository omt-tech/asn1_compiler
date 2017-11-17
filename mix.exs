defmodule Asn1Compiler.MixProject do
  use Mix.Project

  def project do
    [
      app: :asn1_compiler,
      version: "0.1.0",
      elixir: "~> 1.4",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp deps do
    [
    ]
  end
end

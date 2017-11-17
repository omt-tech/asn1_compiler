defmodule Asn1Compiler.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project() do
    [
      app: :asn1_compiler,
      version: @version,
      elixir: "~> 1.4",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: """
      A mix compiler for the ASN.1 format leveraging Erlang's `:asn1_ct`.
      """,
      package: package(),
      docs: docs()
    ]
  end

  def application() do
    [
      extra_applications: []
    ]
  end

  defp deps() do
    [
      {:ex_doc, "~> 0.14", only: :dev}
    ]
  end

  defp package() do
    [
      licenses: ["MIT"],
      maintainers: ["Michał Muskała"],
      links: %{"GitHub" => "https://github.com/omt-tech/asn1_compiler"}
    ]
  end

  defp docs() do
    [
      main: "Mix.Tasks.Compile.Asn1",
      source_ref: "v#{@version}",
      source_url: "https://github.com/omt-tech/asn1_compiler"
    ]
  end
end

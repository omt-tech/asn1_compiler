# Asn1Compiler

A mix compiler for the ASN.1 format leveraging Erlang's `:asn1_ct`.

## Installation

The package can be installed by adding `asn1_compiler` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:asn1_compiler, "~> 0.1.0", runtime: false}
  ]
end
```

Please notice the `runtime: false` option - the compiler is not needed at runtime and should
not be included in releases.

## Usage

Once installed, the compiler can be enabled by changing project configuration in `mix.exs`:

```elixir
def project() do
  [
    # ...
    compilers: [:asn1] ++ Mix.compilers(),
    asn1_options: [:maps]
  ]
end
```

Then, you can place your `.asn1` files in the `asn1` folder. The files will be compiled to `src`
as Erlang modules that will be picked up by the Erlang compiler.

The `:asn1_ct` compiler accepts many options that are described in the
[documentation](http://erlang.org/doc/man/asn1ct.html#compile-1) - they can be passed using the
`asn1_options` project configuration (in the same place where the `compilers` configuration lives).
It is recommended to at least set the options to `[:maps]` so that the decoding and encoding
passes use maps rather than records.

Further documentation can found at
[https://hexdocs.pm/asn1_compiler](https://hexdocs.pm/asn1_compiler).

defmodule Mix.Tasks.Compile.Asn1 do
  @moduledoc """
  A mix compiler for the ASN.1 format leveraging Erlang's `:asn1_ct`.

  Once installed, the compiler can be enabled by changing project configuration in `mix.exs`:

      def project() do
        [
          # ...
          compilers: [:asn1] ++ Mix.compilers(),
          asn1_options: [:maps]
        ]
      end

  Then, you can place your `.asn1` files in the `asn1` folder. The files will be compiled to `src`
  as Erlang modules that will be picked up by the Erlang compiler.

  The `:asn1_ct` compiler accepts many options that are described in the
  [documentation](http://erlang.org/doc/man/asn1ct.html#compile-1) - they can be passed using the
  `asn1_options` project configuration (in the same place where the `compilers` configuration
  lives). It is recommended to at least set the options to `[:maps]` so that the decoding
  and encoding passes use maps rather than records.

  ## Command line options

    * `--force` - forces compilation regardless of modification times
    * `--verbose` - inform about each compiled file

  ## Configuration

    * `:asn1_paths` - directories to find source files. Defaults to `["asn1"]`.
    * `:erlc_paths` - directories to store generated source files. Defaults to `["src"]` (also
      used by the erlang compiler).
    * `:asn1_options` - compilation options that apply to ASN.1's compiler.
      All available options are descrived in the
      [documentation](http://erlang.org/doc/man/asn1ct.html#compile-2).
  """

  # Support Elixir <= 1.6
  if Code.ensure_loaded?(Mix.Task.Compiler) do
    use Mix.Task.Compiler
  else
    use Mix.Task
  end

  @recursive true
  @manifest ".compile.asn1"
  @manifest_vsn 1

  @min_mtime {{1970, 1, 1}, {0, 0, 0}}

  @switches [force: :boolean, verbose: :boolean, warnings_as_errors: :boolean]

  @doc """
  Runs this task.
  """
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: @switches)

    project = Mix.Project.config()
    source_paths = Keyword.get(project, :asn1_paths, ["asn1"])
    dest_path = List.first(Keyword.fetch!(project, :erlc_paths))
    verbose? = Keyword.get(opts, :verbose, false)

    # TODO: warnings_as_errors
    options = Keyword.get(project, :asn1_options, [])

    File.mkdir_p!(dest_path)

    targets = extract_targets(source_paths, dest_path, Keyword.get(opts, :force, false))

    compile(manifest(), targets, verbose?, fn input, output ->
      options = options ++ [:noobj, outdir: to_charlist(Path.dirname(output))]
      :asn1ct.compile(to_charlist(input), options)
    end)
  end

  @doc """
  Returns manifests used by this compiler.
  """
  def manifests(), do: [manifest()]
  defp manifest(), do: Path.join(Mix.Project.manifest_path(), @manifest)

  @doc """
  Cleans up compilation artifacts.
  """
  def clean() do
    remove_files(read_manifest(manifest()))

    File.rm(manifest())
  end

  defp module_files(dir, module) do
    [
      Path.join(dir, "#{module}.erl"),
      Path.join(dir, "#{module}.hrl"),
      Path.join(dir, "#{module}.asn1db")
    ]
  end

  defp extract_targets(source_paths, dest_path, force?) do
    for source <- extract_files(List.wrap(source_paths), ["asn1", "asn", "py"]) do
      module = module_name(source)

      if force? or stale?(source, module_files(dest_path, module)) do
        {:stale, source, Path.join(dest_path, "#{module}.erl")}
      else
        {:ok, source, Path.join(dest_path, "#{module}.erl")}
      end
    end
  end

  defp module_name(file) do
    file |> Path.basename() |> Path.rootname()
  end

  defp extract_files(paths, exts) when is_list(exts) do
    extract_files(paths, "*.{#{Enum.join(exts, ",")}}")
  end

  defp extract_files(paths, pattern) do
    Enum.flat_map(paths, fn path ->
      case File.stat(path) do
        {:ok, %{type: :directory}} -> Path.wildcard("#{path}/**/#{pattern}")
        {:ok, %{type: :regular}} -> [path]
        _ -> []
      end
    end)
    |> Enum.uniq()
  end

  defp stale?(source, targets) do
    modified_target =
      targets
      |> Enum.map(&last_modified/1)
      |> Enum.reject(&(&1 == @min_mtime))
      |> Enum.min(fn -> @min_mtime end)

    last_modified(source) > modified_target
  end

  defp last_modified(file) do
    case File.stat(file) do
      {:ok, %{mtime: mtime}} -> mtime
      {:error, _} -> @min_mtime
    end
  end

  defp compile(manifest, targets, verbose?, callback) do
    stale = for {:stale, src, dest} <- targets, do: {src, dest}

    previous = read_manifest(manifest)

    removed = Enum.reject(previous, fn dest -> Enum.any?(targets, &match?({_, _, ^dest}, &1)) end)

    entries =
      Enum.reject(previous, fn dest ->
        dest in removed || Enum.any?(stale, &match?({_, ^dest}, &1))
      end)

    if stale == [] and removed == [] do
      :noop
    else
      remove_files(removed)
      compiling_n(length(stale), "asn1")

      {status, new_entries} = compile(stale, callback, verbose?)

      write_manifest(manifest, entries ++ new_entries)
      status
    end
  end

  defp compile(stale, callback, verbose?) do
    stale
    |> Enum.map(fn {input, output} ->
         case callback.(input, output) do
           :ok ->
             verbose? && Mix.shell().info("Compiled #{input}")
             {:ok, [output]}

           {:error, _errors} ->
             {:error, []}
         end
       end)
    |> Enum.reduce({:ok, []}, fn {status1, entries1}, {status2, entries2} ->
         status = if status1 == :error or status2 == :error, do: :error, else: :ok
         {status, entries1 ++ entries2}
       end)
  end

  defp compiling_n(1, ext), do: Mix.shell().info("Compiling 1 file (.#{ext})")
  defp compiling_n(n, ext), do: Mix.shell().info("Compiling #{n} files (.#{ext})")

  defp remove_files(to_remove) do
    to_remove
    |> Enum.flat_map(&module_files(Path.dirname(&1), module_name(&1)))
    |> Enum.each(&File.rm/1)
  end

  defp read_manifest(file) do
    try do
      file |> File.read!() |> :erlang.binary_to_term()
    rescue
      _ -> []
    else
      {@manifest_vsn, data} when is_list(data) -> data
      _ -> []
    end
  end

  defp write_manifest(file, entries) do
    Path.dirname(file) |> File.mkdir_p!()
    File.write!(file, :erlang.term_to_binary({@manifest_vsn, entries}))
  end
end

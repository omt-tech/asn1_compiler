defmodule Mix.Tasks.Compile.Asn1Test do
  use Asn1Compiler.Case

  import ExUnit.CaptureIO

  setup _config do
    Mix.Project.push(Asn1Compiler.Sample)
    :ok
  end

  test "compiles test.asn1" do
    in_fixture "compile_asn1", fn ->
      assert Mix.Tasks.Compile.Asn1.run(["--verbose"]) == :ok
      assert_received {:mix_shell, :info, ["Compiled asn1/test.asn1"]}
      assert File.regular?("src/test.erl")
      assert File.regular?("src/test.asn1db")
      assert File.regular?("src/test.hrl")

      assert Mix.Tasks.Compile.Asn1.run(["--verbose"]) == :noop
      refute_received {:mix_shell, :info, ["Compiled asn1/test.asn1"]}

      assert Mix.Tasks.Compile.Asn1.run(["--force", "--verbose"]) == :ok
      assert_received {:mix_shell, :info, ["Compiled asn1/test.asn1"]}
    end
  end

  test "compilation continues if one file fails to compile" do
    in_fixture "compile_asn1", fn ->
      file = Path.absname("asn1/zzz.asn1")

      File.write!(file, """
      LDAP-V3 DEFINITIONS
              BEGIN

              MessageID ::= INVALID

              END
      """)

      capture_io(fn ->
        assert :error = Mix.Tasks.Compile.Asn1.run([])
      end)

      assert File.regular?("src/test.erl")
      assert File.regular?("src/test.asn1db")
      assert File.regular?("src/test.hrl")
      refute File.regular?("src/zzz.erl")
      refute File.regular?("src/zzz.asn1db")
      refute File.regular?("src/zzz.hrl")
    end
  end

  test "removes old artifact files" do
    in_fixture "compile_asn1", fn ->
      assert Mix.Tasks.Compile.Asn1.run([]) == :ok
      assert File.regular?("src/test.erl")

      File.rm!("asn1/test.asn1")
      assert Mix.Tasks.Compile.Asn1.run([]) == :ok
      refute File.regular?("src/test.erl")
      refute File.regular?("src/test.asn1db")
      refute File.regular?("src/test.hrl")
    end
end
end

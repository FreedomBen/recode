defmodule Mix.Tasks.Recode do
  @moduledoc """
  TODO: add moduledoc
  """

  @shortdoc "TODO: add shortdoc"

  use Mix.Task

  alias Recode.DotFormatter
  alias Recode.Task.AliasExpansion
  alias Recode.Task.PipeFunOne
  alias Recode.Task.SinglePipe

  @inputs "{lib,test}/**/*.{ex,exs}"
  @tasks [alias_expansion: AliasExpansion, pipe_fun_one: PipeFunOne, single_pipe: SinglePipe]

  @opts strict: [pipe_fun_one: :boolean, alias_expansion: :boolean, single_pipe: :boolean]

  @impl Mix.Task
  def run(opts) do
    tasks =
      opts
      |> OptionParser.parse!(@opts)
      |> elem(0)
      |> tasks(@tasks)

    @inputs
    |> Path.wildcard()
    |> read!()
    |> recode(tasks, locals_without_parens: DotFormatter.locals_without_parens())
    |> write!()
  end

  defp write!(outputs) when is_list(outputs) do
    Enum.map(outputs, &write!/1)
  end

  defp write!({path, old, new}) do
    unless old == new do
      File.write!(path, new)
      Mix.Shell.IO.info([IO.ANSI.green(), "* update: ", IO.ANSI.reset(), path])
    end
  end

  defp read!(paths) do
    Enum.map(paths, fn path -> {path, File.read!(path)} end)
  end

  defp recode(inputs, tasks, opts) when is_list(inputs) do
    Enum.map(inputs, fn input -> recode(input, tasks, opts) end)
  end

  defp recode({path, code}, tasks, opts) do
    {path, code, recode(code, tasks, opts)}
  end

  defp recode(code, tasks, opts) do
    Enum.reduce(tasks, code, fn task, code ->
      code
      |> Sourceror.parse_string!()
      |> task.run()
      |> Sourceror.to_string(opts)
      |> newline()
    end)
  end

  defp tasks([], tasks), do: Keyword.values(tasks)

  defp tasks(opts, tasks) do
    opts
    |> Keyword.values()
    |> Enum.any?()
    |> case do
      true -> tasks(opts, tasks, :include)
      false -> tasks(opts, tasks, :exclude)
    end
  end

  defp tasks(opts, tasks, :include) do
    opts
    |> Enum.reduce([], fn {key, true}, acc ->
      [Keyword.get(tasks, key) | acc]
    end)
    |> Enum.reverse()
  end

  defp tasks(opts, tasks, :exclude) do
    tasks
    |> Enum.reduce([], fn {key, task}, acc ->
      case Keyword.get(opts, key, true) do
        false -> acc
        true -> [task | acc]
      end
    end)
    |> Enum.reverse()
  end

  defp newline(string), do: string <> "\n"
end

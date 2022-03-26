defmodule Recode.Task.PipeFunOne do
  @moduledoc """
  Add parentheses to one-arity functions.

      # preferred
      some_string |> String.downcase() |> String.trim()

      # not preferred
      some_string |> String.downcase |> String.trim

  This task rewrites the code when `mix recode` runs with `autocorrect: true`.
  """

  use Recode.Task, correct: true, check: true

  alias Recode.Issue
  alias Recode.Project
  alias Recode.Source
  alias Recode.Task.PipeFunOne
  alias Sourceror.Zipper

  def run(project, opts) do
    Project.map(project, fn source ->
      {zipper, issues} =
        source
        |> Source.zipper!()
        |> Zipper.traverse([], fn zipper, issues ->
          pipe_fun_one(zipper, issues, opts[:autocorrect])
        end)

      source =
        source
        |> Source.update(PipeFunOne, code: zipper)
        |> Source.add_issues(issues)

      {:ok, source}
    end)
  end

  defp pipe_fun_one(~z/{:|>, _meta, _tree}/ = zipper, issues, true) do
    {Zipper.update(zipper, &update/1), issues}
  end

  defp pipe_fun_one(~z/{:|>, meta, _tree} = ast/ = zipper, issues, false) do
    case issue?(ast) do
      true ->
        issue = Issue.new(PipeFunOne, "Use parentheses for one-arity functions in pipes.", meta)

        {zipper, [issue | issues]}

      false ->
        {zipper, issues}
    end
  end

  defp pipe_fun_one(zipper, issues, _autocorrect), do: {zipper, issues}

  defp issue?({:|>, _meta1, [_a, {_name, _meta2, args}]}), do: args == nil

  defp update({:|>, meta, [a, b]}) do
    {:|>, meta, [a, update(b)]}
  end

  defp update({name, meta, nil}) do
    {name, meta, []}
  end

  defp update(tree), do: tree
end

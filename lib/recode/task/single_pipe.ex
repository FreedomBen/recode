defmodule Recode.Task.SinglePipe do
  @moduledoc """
  Pipes (`|>`) should only be used when piping data through multiple calls.

      # preferred
      some_string |> String.downcase() |> String.trim()
      Enum.reverse(some_enum)

      # not preferred
      some_enum |> Enum.reverse()

  This task rewrites the code when `mix recode` runs with `autocorrect: true`.
  """

  use Recode.Task, correct: true, check: true

  alias Recode.Issue
  alias Recode.Source
  alias Recode.Task.SinglePipe
  alias Sourceror.Zipper

  def run(source, opts) do
    {zipper, issues} =
      source
      |> Source.zipper()
      |> Zipper.traverse([], fn zipper, issues ->
        single_pipe(zipper, issues, opts[:autocorrect])
      end)

    case opts[:autocorrect] do
      true ->
        Source.update(source, SinglePipe, code: zipper)

      false ->
        Source.add_issues(source, issues)
    end
  end

  defp single_pipe(
         {{:|>, _meta1, [{:|>, _meta2, _args}, _ast]}, _zipper_meta} = zipper,
         issues,
         _autocorrect
       ) do
    {skip(zipper), issues}
  end

  defp single_pipe({{:|>, _meta, _ast}, _zipper_meta} = zipper, issues, true) do
    zipper = zipper |> Zipper.update(&update/1) |> skip()

    {zipper, issues}
  end

  defp single_pipe({{:|>, meta, _ast}, _zipper_meta} = zipper, issues, false) do
    issue =
      Issue.new(
        SinglePipe,
        "Use a function call when a pipeline is only one function long.",
        meta
      )

    {zipper, [issue | issues]}
  end

  defp single_pipe(zipper, issues, _autocorrect), do: {zipper, issues}

  defp skip({{:|>, _meta, _ast}, _zipper_meta} = zipper) do
    zipper |> Zipper.next() |> skip()
  end

  defp skip(zipper), do: zipper

  defp update({:|>, _meta1, [{_name, _meta2, nil} = arg, {fun, meta, args}]}) do
    {fun, meta, [arg | args]}
  end

  defp update({:|>, _meta1, [{_name, _meta2, []} = arg, {fun, meta, args}]}) do
    {fun, meta, [arg | args]}
  end

  defp update({:|>, meta, [{fun1, meta1, [arg1 | args1]}, {fun2, meta2, args2}]}) do
    {:|>, meta,
     [
       {:|>, [], [arg1, {fun1, meta1, args1}]},
       {fun2, meta2, args2}
     ]}
  end
end

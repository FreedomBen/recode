defmodule Recode.Task.AliasExpansion do
  @moduledoc """
  Multi aliases makes module uses harder to search for in large code bases.

          # preferred
          alias Module.Foo
          alias Module.Bar

          # not preferred
          alias Module.{Foo, Bar}

  This task rewrites the code when `mix recode` runs with `autocorrect: true`.
  """

  use Recode.Task, correct: true, check: true

  alias Recode.Issue
  alias Recode.Project
  alias Recode.Source
  alias Recode.Task.AliasExpansion
  alias Sourceror.Zipper

  def run(project, opts) do
    Project.map(project, fn source ->
      {zipper, issues} =
        source
        |> Source.zipper!()
        |> Zipper.traverse([], fn zipper, issues ->
          expand_alias(zipper, issues, opts[:autocorrect])
        end)

      source =
        source
        |> Source.update(AliasExpansion, code: zipper)
        |> Source.add_issues(issues)

      {:ok, source}
    end)
  end

  defp expand_alias(~z/{:alias, _meta, _args} = ast/ = zipper, issues, true) do
    zipper =
      case extract(ast) do
        {:ok, {base, segments, alias_meta, call_meta}} ->
          segments
          |> segments_to_alias(base)
          |> put_leading_comments(alias_meta)
          |> put_trailing_comments(call_meta)
          |> insert(zipper)

        :error ->
          zipper
      end

    {zipper, issues}
  end

  defp expand_alias(~z/{:alias, meta, _args} = ast/ = zipper, issues, false) do
    issues =
      case extract(ast) do
        {:ok, _data} ->
          message = "Avoid multi aliases."
          issue = Issue.new(AliasExpansion, message, meta)
          [issue | issues]

        :error ->
          issues
      end

    {zipper, issues}
  end

  defp expand_alias(zipper, issues, _autocorrect), do: {zipper, issues}

  defp extract(tree) do
    case tree do
      {:alias, alias_meta, [{{:., _meta, [base, :{}]}, call_meta, segments}]} ->
        {:ok, {base, segments, alias_meta, call_meta}}

      _tree ->
        :error
    end
  end

  defp insert(aliases, zipper) do
    aliases
    |> Enum.reduce(zipper, fn alias, zip -> Zipper.insert_left(zip, alias) end)
    |> Zipper.remove()
  end

  defp segments_to_alias(segments, {_name, _meta, base_segments}) when is_list(segments) do
    Enum.map(segments, fn {_name, meta, segments} ->
      {:alias, meta, [{:__aliases__, [], base_segments ++ segments}]}
    end)
  end

  defp put_leading_comments([first | rest], meta) do
    comments = meta[:leading_comments] || []
    [Sourceror.prepend_comments(first, comments) | rest]
  end

  defp put_trailing_comments(list, meta) do
    comments = meta[:trailing_comments] || []

    case List.pop_at(list, -1) do
      {nil, list} ->
        list

      {last, list} ->
        last =
          {:__block__,
           [
             trailing_comments: comments,
             end_of_expression: [newlines: 2]
           ], [last]}

        list ++ [last]
    end
  end
end

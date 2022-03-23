defmodule Recode.Task.TestFileExt do
  @moduledoc """
  Tests must be in a file with the extension `*_test.exs`.

  This module searches for `*_test.ex` to rename the file and/or report an
  issue.
  """

  use Recode.Task, correct: true, check: true

  alias Recode.Issue
  alias Recode.Project
  alias Recode.Source
  alias Recode.Task.TestFileExt

  def run(project, opts) do
    Project.map(project, fn source ->
      source = test_file_ext(source, opts[:autocorrect])

      {:ok, source}
    end)
  end

  defp test_file_ext(%Source{path: path} = source, autocrecct) do
    case update_path(path) do
      ^path -> source
      updated_path -> update_source(source, updated_path, autocrecct)
    end
  end

  defp update_path(path) do
    String.replace(path, ~r/_test\.ex$/, "_test.exs")
  end

  defp update_source(source, path, true) do
    Source.update(source, TestFileExt, path: path)
  end

  defp update_source(source, path, false) do
    message = "The file must be renamed to #{path} so that ExUnit can find it."
    Source.add_issue(source, Issue.new(TestFileExt, message))
  end
end

defmodule Recode.Runner.Impl do
  @moduledoc false

  @behaviour Recode.Runner

  alias Recode.Project

  @impl true
  def run(config) do
    config
    |> tasks()
    |> run(config)
  end

  @impl true
  def run(tasks, config) when is_list(tasks) do
    project =
      config
      |> project()
      |> format(:project, config)

    tasks
    |> run_tasks(project, config)
    |> format(:results, config)
    |> tap(fn project -> write(project, config) end)
  end

  def run({module, opts}, config) do
    run([{module, opts}], config)
  end

  defp run_tasks(tasks, project, config) do
    Enum.reduce(tasks, project, fn {module, opts}, project ->
      run_task(project, config, module, opts)
    end)
  end

  defp run_task(%Project{} = project, config, module, opts) do
    Project.map(project, fn source ->
      exclude = Keyword.get(opts, :exclude, [])

      case source.path in exclude do
        true ->
          source

        false ->
          format(project, :task, config, {source, module, opts})
          module.run(source, opts)
      end
    end)
  end

  defp format(%Project{} = project, label, config, info \\ nil) do
    case Keyword.fetch(config, :formatter) do
      {:ok, {formatter, opts}} ->
        format(formatter, label, project, opts, config, info)
        project

      :error ->
        project
    end
  end

  defp format(formatter, label, project, opts, config, nil) do
    formatter.format(label, {project, config}, opts)
  end

  defp format(formatter, label, project, opts, config, info) do
    formatter.format(label, {project, config}, info, opts)
  end

  defp project(config) do
    config |> Keyword.fetch!(:inputs) |> List.wrap() |> Project.new()
  end

  defp tasks(config) do
    config
    |> Keyword.fetch!(:tasks)
    |> tasks(:skip)
    |> tasks(:exclude)
    |> tasks(:correct_first)
    |> tasks(:filter, config)
    |> update_opts(config)
  end

  defp tasks(tasks, :filter, config) do
    case config[:autocorrect] do
      false -> Enum.filter(tasks, fn {task, _opts} -> task.config(:check) end)
      true -> tasks
    end
  end

  defp tasks(tasks, :exclude) do
    Enum.map(tasks, fn {task, config} ->
      config =
        case Keyword.has_key?(config, :exclude) do
          false -> config
          true -> expand_exclude(config)
        end

      {task, config}
    end)
  end

  defp tasks(tasks, :skip) do
    Enum.reject(tasks, fn {_task, config} -> config == :skip end)
  end

  defp tasks(tasks, :correct_first) do
    groups =
      Enum.group_by(tasks, fn {task, _opts} ->
        task.config(:correct)
      end)

    Enum.concat(Map.get(groups, true, []), Map.get(groups, false, []))
  end

  defp expand_exclude(config) do
    Keyword.update!(config, :exclude, fn exclude ->
      exclude |> List.wrap() |> Enum.flat_map(&Path.wildcard/1)
    end)
  end

  defp update_opts(tasks, config) do
    Enum.map(tasks, fn {task, opts} ->
      opts = Keyword.put_new(opts, :autocorrect, config[:autocorrect])
      {task, opts}
    end)
  end

  defp write(project, config) do
    case Keyword.fetch!(config, :dry) do
      true -> project
      false -> write(project)
    end
  end

  defp write(project) do
    exclude = project |> Project.conflicts() |> Map.keys()

    with {:error, errors} <- Project.save(project, exclude) do
      Enum.each(errors, fn {file, reason} ->
        Mix.Shell.IO.error("Writing file #{file} fails, reason: #{inspect(reason)}")
      end)
    end
  end
end

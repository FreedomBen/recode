defmodule Recode.Task.PipeFunOne do
  @moduledoc """
  Add parentheses to one-arity functions.
  """
  alias Sourceror.Zipper

  def run(quoted) do
    Zipper.zip(quoted)
    |> Zipper.traverse(&pipe_fun_one/1)
    |> Zipper.root()
  end

  defp pipe_fun_one({{:|>, _meta, _tree}, _} = zipper) do
    Zipper.update(zipper, &update/1)
  end

  defp pipe_fun_one(zipper), do: zipper

  defp update({:|>, meta, [a, b]}) do
    {:|>, meta, [a, update(b)]}
  end

  defp update({name, meta, nil}) do
    {name, meta, []}
  end

  defp update(tree), do: tree
end

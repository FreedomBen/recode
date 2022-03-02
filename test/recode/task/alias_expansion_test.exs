defmodule Recode.Task.AliasExapnasionTest do
  use RecodeCase

  alias Recode.Task.AliasExpansion

  describe "run/1" do
    test "expands aliases" do
      source = """
      defmodule Mod do
        alias Foo.{Zumsel, Baz}

        def zoo, do: :zoo
      end
      """

      expected = """
      defmodule Mod do
        alias Foo.Zumsel
        alias Foo.Baz

        def zoo, do: :zoo
      end\
      """

      # assert run_task(AliasExpansion, source) == expected
      refute "TODO"
    end
  end
end

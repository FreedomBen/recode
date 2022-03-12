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
      end
      """

      [updated] = run_task_with_sources({AliasExpansion, []}, [source])

      assert updated == expected
    end

    test "expands aliases with with comments" do
      source = """
      defmodule Mod do
        # a comment
        alias Bar
        alias Foo.{Zumsel, Baz}
        # another comment

        def zoo, do: :zoo
      end
      """

      expected = """
      defmodule Mod do
        # a comment
        alias Bar
        alias Foo.Zumsel
        alias Foo.Baz

        # another comment

        def zoo, do: :zoo
      end
      """

      [updated] = run_task_with_sources({AliasExpansion, []}, [source])

      assert updated == expected
    end
  end
end

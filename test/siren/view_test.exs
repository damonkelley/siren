defmodule Siren.ViewTest do
  use ExUnit.Case
  use Plug.Test
  defmodule TestView do
    use Siren.View
  end

  describe "class" do
    test "it will not render a class" do
      entity =
        conn(:get, "/")
        |> TestView.render

      refute Map.get(entity, "class")
    end

    test "it will render the class" do
      defmodule PostView do
        use Siren.View

        def class, do: ["post"]
      end

      conn = conn(:get, "/")
      assert %{"class" => ["post"]} = PostView.render(conn)
    end
  end

  describe "properties" do
    test "it will not render properties" do
      entity =
        conn(:get, "/")
        |> TestView.render

      refute Map.get(entity, "properties")
    end
  end

  test "it will render properties" do
    defmodule PostView do
      use Siren.View

      def properties(data) do
        data
        |> Enum.map(fn {key, value} -> {String.capitalize(key), String.capitalize(value)} end)
        |> Enum.into(%{})
      end
    end

    assert %{"properties" => %{"Foo" => "Bar"}} =
      conn(:get, "/")
      |> PostView.render(%{"foo" => "bar"})
  end
end

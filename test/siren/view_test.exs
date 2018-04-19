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

      refute Map.get(entity, :class)
    end

    test "it will render the class" do
      defmodule PostView do
        use Siren.View

        def class, do: ["post"]
      end

      conn = conn(:get, "/")
      assert %{:class => ["post"]} = PostView.render(conn)
    end
  end

  describe "properties" do
    test "it will not render properties" do
      entity =
        conn(:get, "/")
        |> TestView.render

      refute Map.get(entity, :properties)
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

    assert %{:properties => %{"Foo" => "Bar"}} =
      conn(:get, "/")
      |> PostView.render(%{"foo" => "bar"})
  end

  describe "links" do
    test "it will not render links" do
      entity =
        conn(:get, "/")
        |> TestView.render

      refute Map.get(entity, :links)
    end

    test "it will render a links" do
      defmodule PostView do
        use Siren.View

        def links(_conn, %{page: page}) do
          [
            %{rel: :self, href: "http://example.com"},
            %{rel: :next, href: "http://example.com?page=#{page}"},
          ]
        end
      end

      entity =
        conn(:get, "/")
        |> PostView.render(%{page: 2})

      assert %{
        :links => [
          %{rel: :self, href: "http://example.com"},
          %{rel: :next, href: "http://example.com?page=2"}
        ]
      } = entity
    end
  end

  describe "entities" do
    test "it will not render entities" do
      entity =
        conn(:get, "/")
        |> TestView.render

      refute Map.get(entity, :links)
    end

    test "it will render entities as links" do
      defmodule CommentView do
        use Siren.View

        def class, do: [:comment]

        def self(%{host: host}, %{id: id}), do: "#{host}/comments/#{id}"
      end

      defmodule PostView do
        use Siren.View

        def entities(conn, %{comment: comment}) do
          [
            entity_link(CommentView, conn, ["post-comment"], comment)
          ]
        end
      end

      entity =
        conn(:get, "/")
        |> Map.put(:host, "http://blog.example.com")
        |> PostView.render(%{comment: %{id: 4}})

      assert %{
        :entities => [
          %{
            class: [:comment],
            rel: ["post-comment"],
            href: "http://blog.example.com/comments/4"
          }
        ]
      } = entity
    end

    test "it will render an embeded entities" do
      defmodule CommentView do
        use Siren.View

        def class, do: [:comment]

        def self(%{host: host}, %{id: id}), do: "#{host}/comments/#{id}"

        def properties(%{body: body, user: user}) do
          %{body: body, user: user}
        end

        def links(%{host: host}, %{id: id}) do
          [
            %{rel: :self, href: "#{host}/comments/#{id}"},
          ]
        end
      end

      defmodule PostView do
        use Siren.View

        def entities(conn, %{comment: comment}) do
          [
            embedded(CommentView, conn, ["post-comment"], comment)
          ]
        end
      end

      entity =
        conn(:get, "/")
        |> Map.put(:host, "http://blog.example.com")
        |> PostView.render(%{comment: %{id: 349, body: "Great post!", user: "anuuser"}})

      assert %{
        :entities => [
          %{
            class: [:comment],
            rel: ["post-comment"],
            properties: %{
              body: "Great post!",
              user: "anuuser"
            },
            links: [
              %{rel: :self, href: "http://blog.example.com/comments/349"},
            ]
          }
        ]
      } = entity
    end
  end
end

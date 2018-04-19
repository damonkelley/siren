defmodule Siren.ViewTest do
  use ExUnit.Case
  use Plug.Test

  defmodule TestView do
    use Siren.View
  end

  setup do
    conn =
      conn(:get, "/")
      |> Map.put(:host, "http://blog.example.com")

    [conn: conn]
  end

  describe "class" do
    test "it will not render a class", %{conn: conn} do
      entity = TestView.render(conn)

      refute Map.get(entity, :class)
    end

    test "it will render the class", %{conn: conn} do
      defmodule PostView do
        use Siren.View

        def class, do: ["post"]
      end

      assert %{:class => ["post"]} = PostView.render(conn)
    end
  end

  describe "properties" do
    test "it will not render properties", %{conn: conn} do
      entity = TestView.render(conn)

      refute Map.get(entity, :properties)
    end
  end

  test "it will render properties", %{conn: conn} do
    defmodule PostView do
      use Siren.View

      def properties(data) do
        data
        |> Enum.map(fn {key, value} -> {String.capitalize(key), String.capitalize(value)} end)
        |> Enum.into(%{})
      end
    end

    assert %{:properties => %{"Foo" => "Bar"}} = PostView.render(conn, %{"foo" => "bar"})
  end

  describe "links" do
    test "it will not render links", %{conn: conn} do
      entity = TestView.render(conn)

      refute Map.get(entity, :links)
    end

    test "it will render a links", %{conn: conn} do
      defmodule PostView do
        use Siren.View

        def links(_conn, %{page: page}) do
          [
            %{rel: :self, href: "http://example.com"},
            %{rel: :next, href: "http://example.com?page=#{page}"},
          ]
        end
      end

      assert %{
        :links => [
          %{rel: :self, href: "http://example.com"},
          %{rel: :next, href: "http://example.com?page=2"}
        ]
      } = PostView.render(conn, %{page: 2})
    end
  end

  describe "entities" do
    test "it will not render entities", %{conn: conn} do
      entity = TestView.render(conn)

      refute Map.get(entity, :links)
    end

    test "it will render entities as links", %{conn: conn} do
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

      assert %{
        :entities => [
          %{
            class: [:comment],
            rel: ["post-comment"],
            href: "http://blog.example.com/comments/4"
          }
        ]
      } = PostView.render(conn, %{comment: %{id: 4}})
    end

    test "it will render an embeded entities", %{conn: conn} do
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
      } = PostView.render(conn, %{comment: %{id: 349, body: "Great post!", user: "anuuser"}})
    end
  end
end

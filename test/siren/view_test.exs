defmodule Siren.ViewTest do
  use ExUnit.Case
  use Plug.Test

  defmodule TestView do
    use Siren.View
  end

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

    def class, do: ["post"]

    def properties(data) do
      Map.take(data, [:author, :title])
    end

    def links(%{host: host} = _conn, data) do
      [
        %{rel: :self, href: host},
        %{rel: :next, href: "#{host}?page=#{Map.get(data, :page, 1)}"},
      ]
    end
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
      assert %{class: ["post"]} = PostView.render(conn)
    end
  end

  describe "properties" do
    test "it will not render properties", %{conn: conn} do
      entity = TestView.render(conn)

      refute Map.get(entity, :properties)
    end
  end

  test "it will render properties", %{conn: conn} do
    assert %{
      properties: %{
        author: "admin",
        title: "A Nu Post"
      }
    } = PostView.render(conn, %{author: "admin", title: "A Nu Post"})
  end

  describe "links" do
    test "it will not render links", %{conn: conn} do
      entity = TestView.render(conn)

      refute Map.get(entity, :links)
    end

    test "it will render a links", %{conn: conn} do
      assert %{
        :links => [
          %{rel: :self, href: "http://blog.example.com"},
          %{rel: :next, href: "http://blog.example.com?page=2"}
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
      defmodule PostViewWithLinkedEntity do
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
      } = PostViewWithLinkedEntity.render(conn, %{comment: %{id: 4}})
    end

    test "it will render an embeded entities", %{conn: conn} do
      defmodule PostViewWithEmbeddedEntity do
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
      } = PostViewWithEmbeddedEntity.render(conn, %{comment: %{id: 349, body: "Great post!", user: "anuuser"}})
    end
  end
end

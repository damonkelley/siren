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
        link(:raw, "#{host}/comments/#{id}?raw")
      ]
    end
  end

  defmodule PostView do
    use Siren.View

    def class, do: ["post"]

    def self(%{host: host}, _), do: host

    def properties(data) do
      Map.take(data, [:author, :title])
    end

    def links(%{host: host} = _conn, data) do
      [
        link(:next, "#{host}?page=#{Map.get(data, :page, 1)}")
      ]
    end
  end

  setup do
    conn =
      conn(:get, "/")
      |> Map.put(:host, "http://blog.example.com")

    [conn: conn]
  end

  describe "self" do
    test "it will add self to the links", %{conn: conn} do
      defmodule WithSelf do
        use Siren.View

        def self(_, _), do: "http://self.net"
      end
      %{links: links} = WithSelf.render(conn)

      assert Enum.member?(links, %{rel: [:self], href: "http://self.net"})
    end
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
        links: [
          %{rel: [:self], href: "http://blog.example.com"},
          %{rel: [:next], href: "http://blog.example.com?page=2"}
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
        entities: [
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
        entities: [
          %{
            class: [:comment],
            rel: ["post-comment"],
            properties: %{
              body: "Great post!",
              user: "anuuser"
            },
            links: [
              %{rel: [:self], href: "http://blog.example.com/comments/349"},
              %{rel: [:raw], href: "http://blog.example.com/comments/349?raw"},
            ]
          }
        ]
      } = PostViewWithEmbeddedEntity.render(conn, %{comment: %{id: 349, body: "Great post!", user: "anuuser"}})
    end
  end

  describe "link" do
    test "it will accept a single rel" do
      assert %{rel: [:self], href: "http://example.com"} == Siren.View.link(:self, "http://example.com")
    end

    test "it will accept a list of rels" do
      assert %{rel: [:blogs, :posts], href: "http://example.com/posts"} ==
        Siren.View.link([:blogs, :posts], "http://example.com/posts")
    end
  end
end

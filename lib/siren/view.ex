defmodule Siren.Viewable do
  @callback self(Plug.Conn.t, any) :: String.t
  @callback class() :: [String.t | atom]
  @callback properties(any) :: map
  @callback entities(Plug.Conn.t, any) :: map
  @callback links(Plug.Conn.t, any) :: list
end

defmodule Siren.View do
  @moduledoc """
  Documentation for Siren.View.
  """
  defmacro __using__(_opts) do
    quote do
      import Siren.View

      @behaviour Siren.Viewable

      def render(conn, data \\ %{}) do
        %{class: [], properties: %{}, entities: %{}, links: %{}}
        |> put_attribute(:class, class())
        |> put_attribute(:properties, properties(data))
        |> put_attribute(:entities, entities(conn, data))
        |> put_attribute(:links, do_links(conn, data))
        |> remove_empty()
      end

      def self(_conn, _data), do: nil
      def class, do: []
      def properties(_data), do: %{}
      def links(_conn, _data), do: []
      def entities(_conn, _data), do: %{}

      defp put_attribute(data, _name, nil), do: data
      defp put_attribute(data, name, value), do: Map.merge(data, %{name => value})

      def remove_empty(data) do
        data
        |> Enum.reject(fn {key, value} -> Enum.empty?(value) end)
        |> Enum.into(%{})
      end

      defp do_links(conn, data) do
        case self(conn, data) do
          nil -> links(conn, data)
          _ -> [Siren.View.link(:self, self(conn, data)) | links(conn, data)]
        end
      end

      defoverridable Siren.Viewable
    end
  end

  def entity_link(view, conn, rel, data) do
    %{
      class: view.class(),
      rel: rel,
      href: view.self(conn, data)
    }
  end

  def link(rel, href) when is_list(rel), do: %{rel: rel, href: href}
  def link(rel, href), do: %{rel: [rel], href: href}

  def embedded(view, conn, rel, data) do
    conn
    |> view.render(data)
    |> Map.put(:rel, rel)
  end
end

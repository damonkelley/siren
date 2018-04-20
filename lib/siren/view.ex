defmodule Siren.View do
  @moduledoc """
  Documentation for Siren.View.
  """
  defmacro __using__(_opts) do
    quote do
      import Siren.View

      def render(conn, data \\ %{}) do
        %{}
        |> put_attribute(:class, class())
        |> put_attribute(:properties, properties(data))
        |> put_attribute(:entities, entities(conn, data))
        |> put_attribute(:links, links(conn, data))
      end

      def class, do: nil
      def properties(_data), do: nil
      def links(_conn, _data), do: nil
      def entities(_conn, _data), do: nil

      defp put_attribute(data, _name, nil), do: data
      defp put_attribute(data, name, value), do: Map.merge(data, %{name => value})

      defoverridable [class: 0, properties: 1, links: 2, entities: 2]
    end
  end

  def entity_link(view, conn, rel, data) do
    %{
      class: view.class(),
      rel: rel,
      href: view.self(conn, data)
    }
  end

  def embedded(view, conn, rel, data) do
    conn
    |> view.render(data)
    |> Map.put(:rel, rel)
  end
end

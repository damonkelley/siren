defmodule Siren.View do
  @moduledoc """
  Documentation for Siren.View.
  """
  defmacro __using__(_opts) do
    quote do
      import Siren.View

      def render(_, data \\ %{}) do
        %{}
        |> add_attribute("class", class())
        |> add_attribute("properties", properties(data))
      end

      def class, do: nil
      def properties(data), do: nil

      defp add_attribute(data, _name, nil), do: data
      defp add_attribute(data, name, value) do
        Map.merge(data, %{name => value})
      end

      defoverridable [class: 0,
                      properties: 1]
    end
  end
end

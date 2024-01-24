defmodule HousingApp.Utils.String do
  @moduledoc false

  def titlize(nil), do: nil
  def titlize(""), do: ""

  def titlize(string) when is_binary(string) do
    if String.contains?(string, "{{") do
      # NOTE: Don't muck with a string containing mustache
      # FUTURE: Unit test
      string
    else
      string |> String.split([" ", "_"], trim: true) |> Enum.map_join(" ", &capitalize_first_grapheme/1)
    end
  end

  defp capitalize_first_grapheme(nil), do: nil
  defp capitalize_first_grapheme(""), do: ""

  # https://elixirforum.com/t/string-capitalize-should-have-a-leave-the-rest-of-the-word-alone-option/31095/9
  defp capitalize_first_grapheme(string) when is_binary(string) do
    <<first_grapheme::utf8, rest::binary>> = string
    String.capitalize(<<first_grapheme::utf8>>) <> rest
  end
end

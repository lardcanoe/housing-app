defmodule HousingApp.Utils.String do
  @moduledoc false

  def titlize(nil), do: nil
  def titlize(""), do: ""

  def titlize(string) when is_binary(string) do
    string |> String.split(" ", trim: true) |> Enum.map_join(" ", &capitalize_first_grapheme/1)
  end

  def capitalize_first_grapheme(nil), do: nil
  def capitalize_first_grapheme(""), do: ""

  # https://elixirforum.com/t/string-capitalize-should-have-a-leave-the-rest-of-the-word-alone-option/31095/9
  def capitalize_first_grapheme(string) when is_binary(string) do
    <<first_grapheme::utf8, rest::binary>> = string
    String.capitalize(<<first_grapheme::utf8>>) <> rest
  end
end

defmodule HousingApp.Utils.Random do
  # https://puid.github.io/Elixir/
  @moduledoc false

  # iex> Random.AlphaNumPuid.generate()
  # "TooiUAMHDsCojbhv0XwYxCW1q"
  defmodule(AlphaNumPuid, do: use(Puid, chars: :alphanum, total: 10.0e12, risk: 1.0e18))

  # iex> Random.Token.generate()
  # "6621e014ba61d7c314107a28"
  defmodule(Token, do: use(Puid, bits: 256, chars: :hex))
end

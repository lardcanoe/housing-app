defmodule HousingApp.Cldr do
  @moduledoc false

  # https://dev.to/mnishiguchi/phoenix-liveview-formatting-date-time-with-local-time-zone-49c
  use Cldr,
    locales: ["en"],
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime]

  @default_locale "en"
  @default_timezone "UTC"
  @default_format :long

  @doc """
  Formats datatime based on specified options.

  ## Examples

      iex> format_time(~U[2021-03-02 22:05:28Z], locale: "ja", timezone: "Asia/Tokyo")
      "2021年3月3日 7:05:28 JST"

      iex> format_time(~U[2021-03-02 22:05:28Z], locale: "ja", timezone: "America/New_York")
      "2021年3月2日 17:05:28 EST"

      iex> format_time(~U[2021-03-02 22:05:28Z], locale: "en-US", timezone: "America/New_York")
      "March 2, 2021 at 5:05:28 PM EST"

      # Fallback to ISO8601 string.
      iex> format_time(~U[2021-03-02 22:05:28Z], timezone: "Hello")
      "2021-03-02T22:05:28+00:00"

  """
  @spec format_time(DateTime.t(), nil | list | map) :: binary
  def format_time(datetime, options \\ []) do
    locale = options[:locale] || @default_locale
    timezone = options[:timezone] || @default_timezone
    format = options[:format] || @default_format
    cldr_options = [locale: locale, format: format]

    time_in_tz = Timex.Timezone.convert(datetime, timezone)

    case __MODULE__.DateTime.to_string(time_in_tz, cldr_options) do
      {:ok, formatted_time} ->
        formatted_time

      {:error, _reason} ->
        Timex.format!(datetime, "{ISO:Extended}")
    end
  end
end

defmodule Timex.TimezoneInfo do
  @moduledoc """
  All relevant timezone information for a given period, i.e. Europe/Moscow on March 3rd, 2013

  Notes:
    - `full_name` is the name of the zone, but does not indicate anything about the current period (i.e. CST vs CDT)
    - `abbreviation` is the abbreviated name for the zone in the current period, i.e. "America/Chicago" on 3/30/15 is "CDT"
    - `offset_std` is the offset in seconds from standard time for this period
    - `offset_utc` is the offset in seconds from UTC for this period

  Spec:
    - `day_of_week`: :sunday, :monday, :tuesday, etc
    - `datetime`:    {{year, month, day}, {hour, minute, second}}
    - `from`:      :min | {day_of_week, datetime}, when this zone starts
    - `until`:     :max | {day_of_week, datetime}, when this zone ends
  """

  defstruct full_name: "Etc/UTC",
            abbreviation: "UTC",
            offset_std: 0,
            offset_utc: 0,
            from: :min,
            until: :max

  @valid_day_names [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday]
  @max_seconds_in_day 60 * 60 * 24

  @type day_of_week :: :sunday | :monday | :tuesday | :wednesday | :thursday | :friday | :saturday
  @type datetime :: {{non_neg_integer, 1..12, 1..31}, {0..24, 0..59, 0..60}}
  @type offset :: -85399..85399
  @type from_constraint :: :min | {day_of_week, datetime}
  @type until_constraint :: :max | {day_of_week, datetime}
  @type t :: %__MODULE__{
          full_name: String.t(),
          abbreviation: String.t(),
          offset_std: offset,
          offset_utc: offset,
          from: from_constraint,
          until: until_constraint
        }

  @doc """
  Create a custom timezone if a built-in one does not meet your needs.

  You must provide the name, abbreviation, offset from UTC, daylight savings time offset,
  and the from/until reference points for when the zone takes effect and ends.

  To clarify the two offsets, `offset_utc` is the absolute offset relative to UTC,
  `offset_std` is the offset to apply to `offset_utc` which gives us the offset from UTC
  during daylight savings time for this timezone. If DST does not apply for this zone, simply
  set it to 0.

  The from/until reference points must meet the following criteria:

      - Be set to `:min` for from, or `:max` for until, which represent
        "infinity" for the start/end of the zone period.
      - OR, be a tuple of {day_of_week, datetime}, where:
        - `day_of_week` is an atom like `:sunday`
        - `datetime` is an Erlang datetime tuple, e.g. `{{2016,10,8},{2,0,0}}`

  *IMPORTANT*: Offsets are in seconds, not minutes, if you do not ensure they
               are in the correct unit, runtime errors or incorrect results are probable.

  ## Examples

      iex> #{__MODULE__}.create("Etc/Test", "TST", 120*60, 0, :min, :max)
      %TimezoneInfo{full_name: "Etc/Test", abbreviation: "TST", offset_std: 7200, offset_utc: 0, from: :min, until: :max}
      ...> #{__MODULE__}.create("Etc/Test", "TST", 24*60*60, 0, :min, :max)
      {:error, "invalid timezone offset '86400'"}
  """
  @spec create(String.t(), String.t(), offset, offset, from_constraint, until_constraint) ::
          __MODULE__.t() | {:error, String.t()}
  def create(name, abbr, offset_utc, offset_std, from, until) do
    %__MODULE__{
      full_name: name,
      abbreviation: abbr,
      offset_std: offset_std,
      offset_utc: offset_utc,
      from: from || :min,
      until: until || :max
    }
    |> validate_and_return()
  end

  def from_datetime(%DateTime{
        time_zone: name,
        zone_abbr: abbr,
        std_offset: std_offset,
        utc_offset: utc_offset
      }) do
    %__MODULE__{
      full_name: name,
      abbreviation: abbr,
      offset_std: std_offset,
      offset_utc: utc_offset,
      from: :min,
      until: :max
    }
  end

  @doc false
  def to_period(%__MODULE__{offset_utc: utc, offset_std: std, abbreviation: abbr}) do
    %{std_offset: std, utc_offset: utc, zone_abbr: abbr}
  end

  defp validate_and_return(%__MODULE__{} = tz) do
    with true <- is_valid_name(tz.full_name),
         true <- is_valid_name(tz.abbreviation),
         true <- is_valid_offset(tz.offset_std),
         true <- is_valid_offset(tz.offset_utc),
         true <- is_valid_from_constraint(tz.from),
         true <- is_valid_until_constraint(tz.until),
         do: tz
  end

  defp is_valid_name(name) when is_binary(name), do: true
  defp is_valid_name(name), do: {:error, "invalid timezone name '#{inspect(name)}'!"}

  defp is_valid_offset(offset)
       when is_integer(offset) and
              (offset < @max_seconds_in_day and offset > -@max_seconds_in_day),
       do: true

  defp is_valid_offset(offset), do: {:error, "invalid timezone offset '#{inspect(offset)}'"}

  defp is_valid_from_constraint(:min), do: true

  defp is_valid_from_constraint(:max),
    do: {:error, ":max is not a valid from constraint for timezones"}

  defp is_valid_from_constraint(c), do: is_valid_constraint(c)

  defp is_valid_until_constraint(:min),
    do: {:error, ":min is not a valid until constraint for timezones"}

  defp is_valid_until_constraint(:max), do: true
  defp is_valid_until_constraint(c), do: is_valid_constraint(c)

  defp is_valid_constraint({day_of_week, {{y, m, d}, {h, mm, s}}} = datetime)
       when day_of_week in @valid_day_names do
    cond do
      :calendar.valid_date({y, m, d}) ->
        valid_hour = h >= 1 and h <= 24
        valid_min = mm >= 0 and mm <= 59
        valid_sec = s >= 0 and s <= 59

        cond do
          valid_hour && valid_min && valid_sec ->
            true

          :else ->
            {:error,
             "invalid datetime constraint for timezone: #{inspect(datetime)} (invalid time)"}
        end

      :else ->
        {:error, "invalid datetime constraint for timezone: #{inspect(datetime)} (invalid date)"}
    end
  end

  defp is_valid_constraint(c),
    do: {:error, "'#{inspect(c)}' is not a valid constraint for timezones"}
end

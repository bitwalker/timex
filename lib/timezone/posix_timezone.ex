defmodule Timex.PosixTimezone do
  @moduledoc """
  Used when parsing POSIX-TZ timezone rules.
  """
  alias Timex.TimezoneInfo

  defstruct name: nil,
            std_abbr: nil,
            std_offset: 0,
            dst_abbr: nil,
            dst_offset: nil,
            dst_start: nil,
            dst_end: nil

  @type rule_bound ::
          {{:julian_leap, 0..365}, Time.t()}
          | {{:julian, 1..365}, Time.t()}
          | {{:mwd, {month :: 1..12, week :: 1..5, day_of_week :: 0..6}}, Time.t()}
          | nil

  @type t :: %__MODULE__{
          name: nil | String.t(),
          std_abbr: nil | String.t(),
          dst_abbr: nil | String.t(),
          std_offset: integer(),
          dst_offset: integer(),
          dst_start: rule_bound(),
          dst_end: rule_bound()
        }

  @doc """
  Obtains a `NaiveDateTime` representing the start of DST for this zone.

  Returns nil if there is no DST period.
  """
  @spec dst_start(t, DateTime.t() | NaiveDateTime.t() | Date.t()) :: NaiveDateTime.t() | nil
  def dst_start(posix_tz, date)

  def dst_start(%__MODULE__{dst_start: nil}, _), do: nil

  def dst_start(%__MODULE__{dst_start: dst_start}, %{year: year}) do
    bound_to_naive_datetime(dst_start, year)
  end

  @doc """
  Obtains a `NaiveDateTime` representing the end of DST for this zone.

  Returns nil if there is no DST period.
  """
  @spec dst_end(t, DateTime.t() | NaiveDateTime.t() | Date.t()) :: NaiveDateTime.t() | nil
  def dst_end(posix_tz, date)

  def dst_end(%__MODULE__{dst_end: nil}, _), do: nil

  def dst_end(%__MODULE__{dst_end: dst_end}, %{year: year}) do
    bound_to_naive_datetime(dst_end, year)
  end

  @doc """
  Returns a `TimezoneInfo` struct representing this timezone for the given datetime
  """
  @spec to_timezone_info(t, DateTime.t() | NaiveDateTime.t() | Date.t()) :: TimezoneInfo.t()
  def to_timezone_info(%__MODULE__{} = tz, date) do
    date = to_naive_datetime(date)

    if is_dst?(tz, date) do
      %TimezoneInfo{
        full_name: tz.name,
        abbreviation: tz.dst_abbr,
        offset_std: tz.dst_offset,
        offset_utc: tz.std_offset,
        from: :min,
        until: :max
      }
    else
      %TimezoneInfo{
        full_name: tz.name,
        abbreviation: tz.std_abbr,
        offset_std: 0,
        offset_utc: tz.std_offset,
        from: :min,
        until: :max
      }
    end
  end

  @doc """
  Returns a `Calendar.TimeZoneDatabase` compatible map, representing this timezone for the given datetime
  """
  def to_period_for_date(%__MODULE__{} = tz, date) do
    date = to_naive_datetime(date)

    if is_dst?(tz, date) do
      std_offset = tz.dst_offset
      utc_offset = tz.std_offset

      %{
        std_offset: std_offset,
        utc_offset: utc_offset,
        zone_abbr: tz.dst_abbr,
        time_zone: tz.name
      }
    else
      %{std_offset: 0, utc_offset: tz.std_offset, zone_abbr: tz.std_abbr, time_zone: tz.name}
    end
  end

  @doc """
  Returns a boolean indicating if the datetime provided occurs during DST of the given POSIX timezone.
  """
  @spec is_dst?(t, DateTime.t() | NaiveDateTime.t() | Date.t()) :: boolean
  def is_dst?(%__MODULE__{} = tz, date) do
    with %NaiveDateTime{} = dst_start <- dst_start(tz, date),
         %NaiveDateTime{} = dst_end <- dst_end(tz, date) do
      cond do
        NaiveDateTime.compare(date, dst_start) == :lt ->
          false

        NaiveDateTime.compare(date, dst_end) == :gt ->
          false

        :else ->
          true
      end
    else
      nil ->
        false
    end
  end

  defp bound_to_naive_datetime({{:mwd, month, week, weekday}, time}, year) do
    month_start = Timex.Date.new!(year, month, 1)
    month_start_dow = Timex.Date.day_of_week(month_start, :sunday) - 1

    if weekday == month_start_dow and week == 1 do
      # Got lucky, we're done
      Timex.NaiveDateTime.new!(month_start, time)
    else
      first_week_date =
        if month_start_dow <= weekday do
          # The week starting on the 1st includes our weekday, so it is the first week of the month
          %{month_start | day: month_start.day + (weekday - month_start_dow)}
        else
          # The week starting on the 1st does not include our weekday, so shift forward a week
          eow = Timex.Date.end_of_week(month_start)
          %{eow | day: eow.day + 1 + weekday}
        end

      cond do
        week == 1 ->
          first_week_date

        :else ->
          day_shift = (week - 1) * 7
          day = first_week_date.day + day_shift
          ldom = :calendar.last_day_of_the_month(year, month)

          date =
            if ldom > day do
              # Last occurrence is in week 4, so shift back a week
              %{first_week_date | day: day - 7}
            else
              %{first_week_date | day: day}
            end

          Timex.NaiveDateTime.new!(date, time)
      end
    end
  end

  defp bound_to_naive_datetime({{:julian, day}, time}, year) do
    date = Timex.Calendar.Julian.date_for_day_of_year(day - 1, year, leaps: false)
    Timex.NaiveDateTime.new!(date, time)
  end

  defp bound_to_naive_datetime({{:julian_leap, day}, time}, year) do
    date = Timex.Calendar.Julian.date_for_day_of_year(day, year, leaps: true)
    Timex.NaiveDateTime.new!(date, time)
  end

  defp to_naive_datetime(%NaiveDateTime{} = date), do: date
  defp to_naive_datetime(%DateTime{} = date), do: DateTime.to_naive(date)
  defp to_naive_datetime(%Date{} = date), do: Timex.NaiveDateTime.new!(date, ~T[12:00:00])
end

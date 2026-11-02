defmodule Timex.PosixTimezone do
  @moduledoc """
  Used when parsing POSIX-TZ timezone rules.

  Explicit rules recur each year. Transition times use the wall clock in effect
  before the change: standard time at DST start and daylight time at DST end.
  A daylight abbreviation without explicit transition rules retains standard time;
  Timex does not infer regional DST defaults.

  Parsed rule times are signed seconds from midnight, allowing day carry. Legacy
  structs containing `Time` values in their rule bounds are also accepted.
  """
  alias Timex.{AmbiguousTimezoneInfo, TimezoneInfo}

  defstruct name: nil,
            std_abbr: nil,
            std_offset: 0,
            dst_abbr: nil,
            dst_offset: nil,
            dst_start: nil,
            dst_end: nil

  @type transition_time :: -604_799..604_799 | Time.t()
  @type rule_bound ::
          {{:julian_leap, 0..365}, transition_time()}
          | {{:julian, 1..365}, transition_time()}
          | {{:mwd, {month :: 1..12, week :: 1..5, day_of_week :: 0..6}}, transition_time()}
          | nil

  @type t :: %__MODULE__{
          name: nil | String.t(),
          std_abbr: nil | String.t(),
          dst_abbr: nil | String.t(),
          std_offset: integer(),
          dst_offset: integer() | nil,
          dst_start: rule_bound(),
          dst_end: rule_bound()
        }

  @doc """
  Obtains a `NaiveDateTime` representing the wall-clock start of DST for this zone.
  Returns nil if there is no explicit DST period.
  """
  @spec dst_start(t, DateTime.t() | NaiveDateTime.t() | Date.t()) :: NaiveDateTime.t() | nil
  def dst_start(%__MODULE__{dst_start: nil}, _), do: nil

  def dst_start(%__MODULE__{dst_start: bound}, %{year: year}),
    do: bound |> bound_seconds(year) |> NaiveDateTime.from_gregorian_seconds()

  @doc """
  Obtains a `NaiveDateTime` representing the wall-clock end of DST for this zone.
  Returns nil if there is no explicit DST period.
  """
  @spec dst_end(t, DateTime.t() | NaiveDateTime.t() | Date.t()) :: NaiveDateTime.t() | nil
  def dst_end(%__MODULE__{dst_end: nil}, _), do: nil

  def dst_end(%__MODULE__{dst_end: bound}, %{year: year}),
    do: bound |> bound_seconds(year) |> NaiveDateTime.from_gregorian_seconds()

  @doc """
  Returns timezone information for an instant (`DateTime`) or local wall time.

  Overlapping wall times return `AmbiguousTimezoneInfo`; nonexistent wall times
  return a resolution error. The optional clock basis can be `:utc` or `:wall`.
  """
  @spec to_timezone_info(t, DateTime.t() | NaiveDateTime.t() | Date.t(), :utc | :wall | nil) ::
          TimezoneInfo.t() | AmbiguousTimezoneInfo.t() | {:error, term()}
  def to_timezone_info(%__MODULE__{} = tz, date, basis \\ nil) do
    case resolve(tz, date, basis) do
      {:ok, period} ->
        to_info(tz, period)

      {:ambiguous, earlier, later} ->
        AmbiguousTimezoneInfo.new(to_info(tz, earlier), to_info(tz, later))

      {:gap, _, _} ->
        {:error, {:could_not_resolve_timezone, tz.name, seconds(to_naive(date)), :wall}}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Returns a calendar period for an instant or local wall time.

  Ambiguous and nonexistent wall times return the corresponding
  `Calendar.TimeZoneDatabase` ambiguity or gap tuple.
  """
  def to_period_for_date(%__MODULE__{} = tz, date) do
    case resolve(tz, date, nil) do
      {:ok, period} -> period
      other -> other
    end
  end

  @doc """
  Returns true when the datetime resolves uniquely to daylight time.

  Ambiguous or nonexistent local wall times return false. A `DateTime` is always
  evaluated as an instant, including its UTC offset; a `Date` uses local noon.
  """
  @spec is_dst?(t, DateTime.t() | NaiveDateTime.t() | Date.t()) :: boolean()
  def is_dst?(%__MODULE__{} = tz, %DateTime{} = date) do
    utc = to_utc(date)
    kind_at(transitions(tz, utc.year), seconds(utc)) == :dst
  end

  def is_dst?(%__MODULE__{} = tz, date) do
    date = to_naive(date)

    wall_candidates(tz, seconds(date), transitions(tz, date.year)) |> Enum.map(&elem(&1, 1)) == [
      :dst
    ]
  end

  @doc false
  def period_from_utc(%__MODULE__{} = tz, utc) do
    utc = to_utc(utc)
    {:ok, period(tz, kind_at(transitions(tz, utc.year), seconds(utc)))}
  end

  @doc false
  def periods_from_wall_datetime(%__MODULE__{} = tz, wall) do
    wall = to_naive(wall)
    events = transitions(tz, wall.year)
    wall_seconds = seconds(wall)

    case wall_candidates(tz, wall_seconds, events) do
      [{_, kind}] ->
        {:ok, period(tz, kind)}

      [{_, earlier}, {_, later}] ->
        {:ambiguous, period(tz, earlier), period(tz, later)}

      [] ->
        gap_for_wall(tz, wall_seconds, events)
    end
  end

  defp resolve(tz, %DateTime{} = date, basis) when basis in [nil, :utc] do
    period_from_utc(tz, date)
  end

  defp resolve(tz, date, :utc), do: period_from_utc(tz, to_naive(date))

  defp resolve(tz, date, basis) when basis in [nil, :wall],
    do: periods_from_wall_datetime(tz, to_naive(date))

  defp wall_candidates(tz, wall, events) do
    [:std, :dst]
    |> Enum.map(&offset(tz, &1))
    |> Enum.uniq()
    |> Enum.flat_map(fn total ->
      utc = wall - total
      kind = kind_at(events, utc)
      if offset(tz, kind) == total, do: [{utc, kind}], else: []
    end)
    |> Enum.sort()
  end

  defp transitions(%__MODULE__{dst_start: nil}, _year), do: []
  defp transitions(%__MODULE__{dst_end: nil}, _year), do: []

  defp transitions(tz, year) do
    for rule_year <- (year - 1)..(year + 1),
        event <- [
          {bound_seconds(tz.dst_start, rule_year) - tz.std_offset, :std, :dst},
          {bound_seconds(tz.dst_end, rule_year) - tz.dst_offset, :dst, :std}
        ] do
      event
    end
    # At coincident year-boundary transitions, the next season starts immediately.
    |> Enum.sort_by(fn {at, _, after_kind} -> {at, after_kind == :dst} end)
  end

  defp kind_at(events, utc) do
    initial =
      case events do
        [{_, before_kind, _} | _] -> before_kind
        [] -> :std
      end

    Enum.reduce_while(events, initial, fn {at, _, after_kind}, kind ->
      if at <= utc, do: {:cont, after_kind}, else: {:halt, kind}
    end)
  end

  defp gap_for_wall(tz, wall, events) do
    case Enum.find(events, fn {at, before_kind, after_kind} ->
           wall >= at + offset(tz, before_kind) and wall < at + offset(tz, after_kind)
         end) do
      {at, before_kind, after_kind} ->
        {:gap,
         {period(tz, before_kind),
          NaiveDateTime.from_gregorian_seconds(at + offset(tz, before_kind))},
         {period(tz, after_kind),
          NaiveDateTime.from_gregorian_seconds(at + offset(tz, after_kind))}}

      nil ->
        {:error, :time_zone_not_found}
    end
  end

  defp offset(tz, :std), do: tz.std_offset
  defp offset(%__MODULE__{dst_offset: nil} = tz, :dst), do: tz.std_offset
  defp offset(tz, :dst), do: tz.dst_offset

  defp period(tz, kind) do
    %{
      utc_offset: tz.std_offset,
      std_offset: offset(tz, kind) - tz.std_offset,
      zone_abbr: if(kind == :dst, do: tz.dst_abbr, else: tz.std_abbr),
      time_zone: tz.name
    }
  end

  defp to_info(tz, period) do
    %TimezoneInfo{
      full_name: tz.name,
      abbreviation: period.zone_abbr,
      offset_utc: period.utc_offset,
      offset_std: period.std_offset
    }
  end

  defp bound_seconds({rule, time}, year) do
    # Gregorian rules repeat every 400 years. Work inside that cycle so adjacent
    # rule years remain evaluable at the calendar's supported year boundaries.
    cycle_days = Integer.floor_div(year, 400) * 146_097
    days = cycle_days + rule_days(rule, Integer.mod(year, 400))
    days * 86_400 + transition_seconds(time)
  end

  defp transition_seconds(seconds) when is_integer(seconds), do: seconds
  defp transition_seconds(%Time{} = time), do: time |> Time.to_seconds_after_midnight() |> elem(0)

  defp rule_days({:mwd, {month, week, weekday}}, year) do
    first = Calendar.ISO.date_to_iso_days(year, month, 1)
    first_weekday = Integer.mod(first + 6, 7)
    day = 1 + Integer.mod(weekday - first_weekday, 7) + (week - 1) * 7
    last = Calendar.ISO.days_in_month(year, month)
    first + if(day > last, do: day - 7, else: day) - 1
  end

  defp rule_days({:julian, day}, year) do
    leap_day = if Calendar.ISO.leap_year?(year) and day >= 60, do: 1, else: 0
    Calendar.ISO.date_to_iso_days(year, 1, 1) + day - 1 + leap_day
  end

  defp rule_days({:julian_leap, day}, year),
    do: Calendar.ISO.date_to_iso_days(year, 1, 1) + day

  defp seconds(date), do: date |> NaiveDateTime.to_gregorian_seconds() |> elem(0)

  defp to_utc(%DateTime{} = date) do
    {utc, microseconds} = DateTime.to_gregorian_seconds(date)
    NaiveDateTime.from_gregorian_seconds(utc, {microseconds, elem(date.microsecond, 1)})
  end

  defp to_utc(date), do: to_naive(date)
  defp to_naive(%NaiveDateTime{} = date), do: date
  defp to_naive(%DateTime{} = date), do: DateTime.to_naive(date)
  defp to_naive(%Date{} = date), do: NaiveDateTime.new!(date, ~T[12:00:00])
end

defimpl Timex.Protocol, for: DateTime do
  @moduledoc """
  A type which represents a date and time with timezone information (optional, UTC will
  be assumed for date/times with no timezone information provided).

  Functions that produce time intervals use UNIX epoch (or simly Epoch) as the
  default reference date. Epoch is defined as UTC midnight of January 1, 1970.

  Time intervals in this module don't account for leap seconds.
  """
  import Timex.Macros
  use Timex.Constants

  alias Timex.{Duration, AmbiguousDateTime}
  alias Timex.{Timezone, TimezoneInfo}
  alias Timex.Types
  alias Timex.DateTime.Helpers

  @epoch_seconds :calendar.datetime_to_gregorian_seconds({{1970,1,1},{0,0,0}})

  @spec to_julian(DateTime.t) :: float
  def to_julian(%DateTime{:year => y, :month => m, :day => d}) do
    Timex.Calendar.Julian.julian_date(y, m, d)
  end

  @spec to_gregorian_seconds(DateTime.t) :: non_neg_integer
  def to_gregorian_seconds(date), do: to_seconds(date, :zero)

  @spec to_gregorian_microseconds(DateTime.t) :: non_neg_integer
  def to_gregorian_microseconds(%DateTime{microsecond: {us,_}} = date) do
    s = to_seconds(date, :zero)
    (s*(1_000*1_000))+us
  end

  @spec to_unix(DateTime.t) :: non_neg_integer
  def to_unix(date), do: trunc(to_seconds(date, :epoch))

  @spec to_date(DateTime.t) :: Date.t
  def to_date(date), do: DateTime.to_date(date)

  @spec to_datetime(DateTime.t, timezone :: Types.valid_timezone) :: DateTime.t | AmbiguousDateTime.t | {:error, term}
  def to_datetime(%DateTime{time_zone: timezone} = d, timezone), do: d
  def to_datetime(%DateTime{} = d, timezone), do: Timezone.convert(d, timezone)

  @spec to_naive_datetime(DateTime.t) :: NaiveDateTime.t
  def to_naive_datetime(%DateTime{time_zone: nil} = d) do
    %NaiveDateTime{
      year: d.year, month: d.month, day: d.day,
      hour: d.hour, minute: d.minute, second: d.second,
      microsecond: d.microsecond
    }
  end
  def to_naive_datetime(%DateTime{} = d) do
    nd = %NaiveDateTime{
      year: d.year, month: d.month, day: d.day,
      hour: d.hour, minute: d.minute, second: d.second,
      microsecond: d.microsecond
    }
    Timex.shift(nd, [seconds: -1 * Timex.Timezone.total_offset(d.std_offset, d.utc_offset)])
  end

  @spec to_erl(DateTime.t) :: Types.datetime
  def to_erl(%DateTime{} = d) do
    {{d.year,d.month,d.day},{d.hour,d.minute,d.second}}
  end

  @spec century(DateTime.t) :: non_neg_integer
  def century(%DateTime{:year => year}), do: Timex.century(year)

  @spec is_leap?(DateTime.t) :: boolean
  def is_leap?(%DateTime{year: year}), do: :calendar.is_leap_year(year)

  @spec beginning_of_day(DateTime.t) :: DateTime.t
  def beginning_of_day(%DateTime{} = datetime) do
    Timex.Timezone.beginning_of_day(datetime)
  end

  @spec end_of_day(DateTime.t) :: DateTime.t
  def end_of_day(%DateTime{} = datetime) do
    Timex.Timezone.end_of_day(datetime)
  end

  @spec beginning_of_week(DateTime.t, Types.weekstart) :: DateTime.t | AmbiguousDateTime.t | {:error, term}
  def beginning_of_week(%DateTime{} = date, weekstart) do
    case Timex.days_to_beginning_of_week(date, weekstart) do
      {:error, _} = err -> err
      days -> beginning_of_day(shift(date, [days: -days]))
    end
  end

  @spec end_of_week(DateTime.t, Types.weekstart) :: DateTime.t | AmbiguousDateTime.t | {:error, term}
  def end_of_week(%DateTime{} = date, weekstart) do
    case Timex.days_to_end_of_week(date, weekstart) do
      {:error, _} = err -> err
      days_to_end ->
        end_of_day(shift(date, [days: days_to_end]))
    end
  end

  @spec beginning_of_year(DateTime.t) :: DateTime.t
  def beginning_of_year(%DateTime{year: year, time_zone: tz}) do
    Timex.to_datetime({year, 1, 1}, tz)
  end

  @spec end_of_year(DateTime.t) :: DateTime.t
  def end_of_year(%DateTime{year: year, time_zone: tz}),
    do: %{Timex.to_datetime({{year, 12, 31}, {23, 59, 59}}, tz) | :microsecond => {999_999, 6}}

  @spec beginning_of_quarter(DateTime.t) :: DateTime.t
  def beginning_of_quarter(%DateTime{year: year, month: month, time_zone: tz}) do
    month = 1 + (3 * (Timex.quarter(month) - 1))
    Timex.DateTime.Helpers.construct({year, month, 1}, tz)
  end

  @spec end_of_quarter(DateTime.t) :: DateTime.t | AmbiguousDateTime.t
  def end_of_quarter(%DateTime{year: year, month: month, time_zone: tz}) do
    month = 3 * Timex.quarter(month)
    case Timex.DateTime.Helpers.construct({year,month,1}, tz) do
      {:error, _} = err -> err
      %DateTime{} = d -> end_of_month(d)
      %AmbiguousDateTime{:before => b, :after => a} ->
        %AmbiguousDateTime{:before => end_of_month(b),
                           :after => end_of_month(a)}
    end
  end

  @spec beginning_of_month(DateTime.t) :: DateTime.t
  def beginning_of_month(%DateTime{microsecond: {_, _precision}} = datetime),
    do: %{datetime | :day => 1, :hour => 0, :minute => 0, :second => 0, :microsecond => {0, 0}}

  @spec end_of_month(DateTime.t) :: DateTime.t
  def end_of_month(%DateTime{year: year, month: month, time_zone: tz} = date),
    do: Timex.DateTime.Helpers.construct({{year, month, days_in_month(date)},{23,59,59,999_999}}, tz)

  @spec quarter(DateTime.t) :: 1..4
  def quarter(%DateTime{month: month}), do: Timex.quarter(month)

  def days_in_month(%DateTime{:year => y, :month => m}), do: Timex.days_in_month(y, m)

  def week_of_month(%DateTime{:year => y, :month => m, :day => d}), do: Timex.week_of_month(y,m,d)

  def weekday(%DateTime{:year => y, :month => m, :day => d}),      do: :calendar.day_of_the_week({y, m, d})

  def day(%DateTime{} = date) do
    ref = beginning_of_year(date)
    1 + Timex.diff(date, ref, :days)
  end

  def is_valid?(%DateTime{:year => y, :month => m, :day => d,
                          :hour => h, :minute => min, :second => sec}) do
    :calendar.valid_date({y,m,d}) and Timex.is_valid_time?({h,min,sec})
  end

  def iso_week(%DateTime{:year => y, :month => m, :day => d}),
    do: Timex.iso_week(y, m, d)

  def from_iso_day(%DateTime{year: year} = date, day) when is_day_of_year(day) do
    {year, month, day_of_month} = Timex.Helpers.iso_day_to_date_tuple(year, day)
    %{date | :year => year, :month => month, :day => day_of_month}
  end

  @spec set(DateTime.t, list({atom(), term})) :: DateTime.t | {:error, term}
  def set(%DateTime{} = date, options) do
    validate? = Keyword.get(options, :validate, true)
    Enum.reduce(options, date, fn
      _option, {:error, _} = err ->
        err
      option, result ->
        case option do
          {:validate, _} -> result
          {:datetime, {{y, m, d}, {h, min, sec}}} ->
            if validate? do
              %{result |
                :year =>   Timex.normalize(:year,   y),
                :month =>  Timex.normalize(:month,  m),
                :day =>    Timex.normalize(:day,    {y,m,d}),
                :hour =>   Timex.normalize(:hour,   h),
                :minute => Timex.normalize(:minute, min),
                :second => Timex.normalize(:second, sec)
              }
            else
              %{result | :year => y, :month => m, :day => d, :hour => h, :minute => min, :second => sec}
            end
          {:date, {y, m, d}} ->
            if validate? do
              {yn,mn,dn} = Timex.normalize(:date, {y,m,d})
              %{result | :year => yn, :month => mn, :day => dn}
            else
              %{result | :year => y, :month => m, :day => d}
            end
          {:time, {h, m, s}} ->
            if validate? do
              %{result | :hour => Timex.normalize(:hour, h), :minute => Timex.normalize(:minute, m), :second => Timex.normalize(:second, s)}
            else
              %{result | :hour => h, :minute => m, :second => s}
            end
          {:time, t} ->
            Timex.set(result, [time: {t.hour, t.minute, t.second}])
          {:day, d} ->
            if validate? do
              %{result | :day => Timex.normalize(:day, {result.year, result.month, d})}
            else
              %{result | :day => d}
            end
          {:timezone, tz} ->
            tz = case tz do
              %TimezoneInfo{} -> tz
              _ -> Timezone.get(tz, result)
            end
            %{result | :time_zone => tz.full_name, :zone_abbr => tz.abbreviation,
                       :utc_offset => tz.offset_utc, :std_offset => tz.offset_std}
          {name, val} when name in [:year, :month, :hour, :minute, :second, :microsecond] ->
            if validate? do
              Map.put(result, name, Timex.normalize(name, val))
            else
              Map.put(result, name, val)
            end
          {option_name, _} ->
            {:error, {:bad_option, option_name}}
        end
      end)
  end

  @doc """
  Shifts the given DateTime based on a series of options.

  See docs for Timex.shift/2 for details.
  """
  @spec shift(DateTime.t, list({atom(), term})) :: DateTime.t | {:error, term}
  def shift(%DateTime{} = datetime, shifts) when is_list(shifts) do
    apply_shifts(datetime, shifts)
  end
  defp apply_shifts(datetime, []),
    do: datetime
  defp apply_shifts(datetime, [{:duration, %Duration{} = duration} | rest]) do
    total_microseconds = Duration.to_microseconds(duration)
    seconds = div(total_microseconds, 1_000*1_000)
    rem_microseconds = rem(total_microseconds, 1_000*1_000)
    shifted = case shift_by(datetime, seconds, :seconds) do
      %AmbiguousDateTime{before: b, after: a} = adt ->
        %{adt | :before => apply_microseconds(b, rem_microseconds),
                :after => apply_microseconds(a, rem_microseconds)}
      %DateTime{} = dt ->
        apply_microseconds(dt, rem_microseconds)
    end
    apply_shifts(shifted, rest)
  end
  defp apply_shifts(datetime, [{unit, 0} | rest]) when is_atom(unit),
    do: apply_shifts(datetime, rest)
  defp apply_shifts(datetime, [{unit, value} | rest]) when is_atom(unit) and is_integer(value) do
    shifted = shift_by(datetime, value, unit)
    apply_shifts(shifted, rest)
  end
  defp apply_shifts({:error, _} = err, _),
    do: err

  defp apply_microseconds(%DateTime{microsecond: {_, precision}} = datetime, ms) do
    case precision do
      0 -> %{datetime | :microsecond => Helpers.construct_microseconds(ms)}
      _ ->
        {new_ms, _} = Helpers.construct_microseconds(ms)
        %{datetime | :microsecond => {new_ms, precision}}
    end
  end

  defp shift_by(%AmbiguousDateTime{:before => before_dt, :after => after_dt}, value, unit) do
    # Since we're presumably in the middle of a shifting operation, rather than failing because
    # we're crossing an ambiguous time period, process both the before and after DateTime individually,
    # and if both return AmbiguousDateTimes, choose the AmbiguousDateTime from :after to return,
    # if one returns a valid DateTime, return that instead, since the shift has resolved the ambiguity.
    # if one returns an error, but the other does not, return the non-errored one.
    case {shift_by(before_dt, value, unit), shift_by(after_dt, value, unit)} do
      # other could be an error too, but that's fine
      {{:error, _}, other} ->
        other
      {other, {:error, _}} ->
        other
      # We'll always use :after when choosing between two ambiguous datetimes
      {%AmbiguousDateTime{}, %AmbiguousDateTime{} = new_after} ->
        new_after
      # The shift resolved the ambiguity!
      {%AmbiguousDateTime{}, %DateTime{} = resolved} ->
        resolved
      {%DateTime{}, %AmbiguousDateTime{} = resolved} ->
        resolved
    end
  end
  defp shift_by(%DateTime{:year => y} = datetime, value, :years) do
    shifted = %{datetime | :year => y + value}
    # If a plain shift of the year fails, then it likely falls on a leap day,
    # so set the day to the last day of that month
    case :calendar.valid_date({shifted.year,shifted.month,shifted.day}) do
      false ->
        last_day = :calendar.last_day_of_the_month(shifted.year, shifted.month)
        shifted = cond do
          shifted.day <= last_day ->
            shifted
          :else ->
            %{shifted | :day => last_day}
        end
        resolve_timezone_info(shifted)
      true ->
        resolve_timezone_info(shifted)
    end
  end
  defp shift_by(%DateTime{:year => year, :month => month} = datetime, value, :months) do
    m = month + value
    shifted =
      cond do
        m > 0 ->
          years = div(m - 1, 12)
          month = rem(m - 1, 12) + 1
          %{datetime | :year => year + years, :month => month}
        m <= 0  ->
          years = div(m, 12) - 1
          month = 12 + rem(m, 12)
          %{datetime | :year => year + years, :month => month}
      end

    # setting months to remainders may result in invalid :month => 0
    shifted =
      case shifted.month do
        0 -> %{shifted | :year => shifted.year - 1, :month => 12}
        _ -> shifted
      end

    # If the shift fails, it's because it's a high day number, and the month
    # shifted to does not have that many days. This will be handled by always
    # shifting to the last day of the month shifted to.
    if :calendar.valid_date({shifted.year,shifted.month,shifted.day}) do
      shifted
    else
      last_day = :calendar.last_day_of_the_month(shifted.year, shifted.month)
      cond do
        shifted.day <= last_day ->
          shifted
        :else ->
          %{shifted | :day => last_day}
      end
    end
    |> resolve_timezone_info
  end
  defp shift_by(%DateTime{microsecond: {current_usecs, _}} = datetime, value, :microseconds) do
    usecs_from_zero = :calendar.datetime_to_gregorian_seconds({
      {datetime.year,datetime.month,datetime.day},
      {datetime.hour,datetime.minute,datetime.second}
    }) * (1_000*1_000) + current_usecs + value

    secs_from_zero = div(usecs_from_zero, 1_000*1_000)
    rem_microseconds = rem(usecs_from_zero, 1_000*1_000)

    {{_y,_m,_d}=date,{h,mm,s}} = :calendar.gregorian_seconds_to_datetime(secs_from_zero)
    Timezone.resolve(datetime.time_zone, {date, {h,mm,s}})
    |> apply_microseconds(rem_microseconds)
  end
  defp shift_by(%DateTime{microsecond: {current_usecs, _}} = datetime, value, :milliseconds) do
    usecs_from_zero = :calendar.datetime_to_gregorian_seconds({
      {datetime.year,datetime.month,datetime.day},
      {datetime.hour,datetime.minute,datetime.second}
    }) * (1_000*1_000) + current_usecs + (value*1_000)

    secs_from_zero = div(usecs_from_zero, 1_000*1_000)
    rem_microseconds = rem(usecs_from_zero, 1_000*1_000)

    {{_y,_m,_d}=date,{h,mm,s}} = :calendar.gregorian_seconds_to_datetime(secs_from_zero)
    Timezone.resolve(datetime.time_zone, {date, {h,mm,s}})
    |> apply_microseconds(rem_microseconds)
  end
  defp shift_by(%DateTime{microsecond: {us, p}} = datetime, value, units) do
    secs_from_zero = :calendar.datetime_to_gregorian_seconds({
      {datetime.year,datetime.month,datetime.day},
      {datetime.hour,datetime.minute,datetime.second}
    })
    shift_by = case units do
      :microseconds -> div(value + us, 1_000)
      :milliseconds -> div(value + (us*1_000), 1_000)
      :seconds      -> value
      :minutes      -> value * 60
      :hours        -> value * 60 * 60
      :days         -> value * 60 * 60 * 24
      :weeks        -> value * 60 * 60 * 24 * 7
      _ ->
        {:error, {:unknown_shift_unit, units}}
    end
    case shift_by do
      {:error, _} = err -> err
      0 when units in [:microseconds] ->
        total_us = rem(value + us, 1_000)
        apply_microseconds(datetime, total_us)
      0 when units in [:milliseconds] ->
        total_ms = rem(value + (us*1_000), 1_000)
        apply_microseconds(datetime, total_ms*1_000)
      0 ->
        datetime
      _ ->
        new_secs_from_zero = secs_from_zero + shift_by
        cond do
          new_secs_from_zero <= 0 ->
            {:error, :shift_to_invalid_date}
          :else ->
            {{_y,_m,_d}=date,{h,mm,s}} = :calendar.gregorian_seconds_to_datetime(new_secs_from_zero)
            resolved = Timezone.resolve(datetime.time_zone, {date, {h,mm,s}})
            case {resolved, units} do
              {%DateTime{} = dt, :microseconds} ->
                apply_microseconds(dt, rem(value+us, 1_000))
              {%DateTime{} = dt, :milliseconds} ->
                apply_microseconds(dt, rem(value+(us*1_000), 1_000))
              {%AmbiguousDateTime{before: b, after: a}, :microseconds} ->
                bd = apply_microseconds(b, rem(value+us, 1_000))
                ad = apply_microseconds(a, rem(value+us, 1_000))
                %AmbiguousDateTime{before: bd, after: ad}
              {%AmbiguousDateTime{before: b, after: a}, :milliseconds} ->
                bd = apply_microseconds(b, rem(value+(us*1_000), 1_000))
                ad = apply_microseconds(a, rem(value+(us*1_000), 1_000))
                %AmbiguousDateTime{before: bd, after: ad}
              {%DateTime{} = dt, _} ->
                %{dt | :microsecond => {us,p}}
              {%AmbiguousDateTime{before: b, after: a}, _} ->
                bd = %{b | :microsecond => {us,p}}
                ad = %{a | :microsecond => {us,p}}
                %AmbiguousDateTime{before: bd, after: ad}
            end
        end
    end
  end

  defp resolve_timezone_info(%DateTime{:time_zone => tzname} = datetime) do
    Timezone.resolve(tzname, {
      {datetime.year, datetime.month, datetime.day},
      {datetime.hour, datetime.minute, datetime.second, datetime.microsecond}})
  end

  @spec to_seconds(DateTime.t, :epoch | :zero) :: integer | {:error, atom}
  defp to_seconds(%DateTime{} = date, :epoch) do
    case to_seconds(date, :zero) do
      {:error, _} = err -> err
      secs -> secs - @epoch_seconds
    end
  end
  defp to_seconds(%DateTime{} = date, :zero) do
    total_offset = Timezone.total_offset(date.std_offset, date.utc_offset) * -1
    date = %{date | :time_zone => "Etc/UTC", :zone_abbr => "UTC", :std_offset => 0, :utc_offset => 0}
    date = Timex.shift(date, seconds: total_offset)
    utc_to_secs(date)
  end
  defp to_seconds(_, _), do: {:error, :badarg}

  defp utc_to_secs(%DateTime{:year => y, :month => m, :day => d, :hour => h, :minute => mm, :second => s}) do
    :calendar.datetime_to_gregorian_seconds({{y,m,d},{h,mm,s}})
  end

end

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

  @epoch_seconds :calendar.datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}})

  @spec to_julian(DateTime.t()) :: float
  def to_julian(%DateTime{:year => y, :month => m, :day => d}) do
    Timex.Calendar.Julian.julian_date(y, m, d)
  end

  @spec to_gregorian_seconds(DateTime.t()) :: non_neg_integer
  def to_gregorian_seconds(date), do: to_seconds(date, :zero)

  @spec to_gregorian_microseconds(DateTime.t()) :: non_neg_integer
  def to_gregorian_microseconds(%DateTime{microsecond: {us, _}} = date) do
    s = to_seconds(date, :zero)
    s * (1_000 * 1_000) + us
  end

  @spec to_unix(DateTime.t()) :: non_neg_integer
  def to_unix(date), do: trunc(to_seconds(date, :epoch))

  @spec to_date(DateTime.t()) :: Date.t()
  def to_date(date), do: DateTime.to_date(date)

  @spec to_datetime(DateTime.t(), timezone :: Types.valid_timezone()) ::
          DateTime.t() | AmbiguousDateTime.t() | {:error, term}
  def to_datetime(%DateTime{time_zone: timezone} = d, timezone), do: d
  def to_datetime(%DateTime{} = d, timezone), do: Timezone.convert(d, timezone)

  @spec to_naive_datetime(DateTime.t()) :: NaiveDateTime.t()
  def to_naive_datetime(%DateTime{time_zone: nil} = d) do
    %NaiveDateTime{
      year: d.year,
      month: d.month,
      day: d.day,
      hour: d.hour,
      minute: d.minute,
      second: d.second,
      microsecond: d.microsecond
    }
  end

  def to_naive_datetime(%DateTime{} = d) do
    nd = %NaiveDateTime{
      year: d.year,
      month: d.month,
      day: d.day,
      hour: d.hour,
      minute: d.minute,
      second: d.second,
      microsecond: d.microsecond
    }

    Timex.shift(nd, seconds: -1 * Timex.Timezone.total_offset(d.std_offset, d.utc_offset))
  end

  @spec to_erl(DateTime.t()) :: Types.datetime()
  def to_erl(%DateTime{} = d) do
    {{d.year, d.month, d.day}, {d.hour, d.minute, d.second}}
  end

  @spec century(DateTime.t()) :: non_neg_integer
  def century(%DateTime{:year => year}), do: Timex.century(year)

  @spec is_leap?(DateTime.t()) :: boolean
  def is_leap?(%DateTime{year: year}), do: :calendar.is_leap_year(year)

  @spec beginning_of_day(DateTime.t()) :: DateTime.t()
  def beginning_of_day(%DateTime{} = datetime) do
    Timex.Timezone.beginning_of_day(datetime)
  end

  @spec end_of_day(DateTime.t()) :: DateTime.t()
  def end_of_day(%DateTime{} = datetime) do
    Timex.Timezone.end_of_day(datetime)
  end

  @spec beginning_of_week(DateTime.t(), Types.weekstart()) ::
          DateTime.t() | AmbiguousDateTime.t() | {:error, term}
  def beginning_of_week(%DateTime{} = date, weekstart) do
    case Timex.days_to_beginning_of_week(date, weekstart) do
      {:error, _} = err -> err
      days -> beginning_of_day(shift(date, days: -days))
    end
  end

  @spec end_of_week(DateTime.t(), Types.weekstart()) ::
          DateTime.t() | AmbiguousDateTime.t() | {:error, term}
  def end_of_week(%DateTime{} = date, weekstart) do
    case Timex.days_to_end_of_week(date, weekstart) do
      {:error, _} = err ->
        err

      days_to_end ->
        end_of_day(shift(date, days: days_to_end))
    end
  end

  @spec beginning_of_year(DateTime.t()) :: DateTime.t()
  def beginning_of_year(%DateTime{year: year, time_zone: tz}) do
    Timex.to_datetime({year, 1, 1}, tz)
  end

  @spec end_of_year(DateTime.t()) :: DateTime.t()
  def end_of_year(%DateTime{year: year, time_zone: tz, microsecond: {_, precision}}) do
    us = Timex.DateTime.Helpers.to_precision(999_999, precision)
    %{Timex.to_datetime({{year, 12, 31}, {23, 59, 59}}, tz) | :microsecond => {us, precision}}
  end

  @spec beginning_of_quarter(DateTime.t()) :: DateTime.t()
  def beginning_of_quarter(%DateTime{year: year, month: month, time_zone: tz} = date) do
    month = 1 + 3 * (Timex.quarter(month) - 1)
    {_, precision} = date.microsecond
    Timex.DateTime.Helpers.construct({{year, month, 1}, {0, 0, 0, 0}}, precision, tz)
  end

  @spec end_of_quarter(DateTime.t()) :: DateTime.t() | AmbiguousDateTime.t()
  def end_of_quarter(%DateTime{year: year, month: month, time_zone: tz} = date) do
    month = 3 * Timex.quarter(month)
    {_, precision} = date.microsecond

    case Timex.DateTime.Helpers.construct(
           {{year, month, 1}, {23, 59, 59, 999_999}},
           precision,
           tz
         ) do
      {:error, _} = err ->
        err

      %DateTime{} = d ->
        end_of_month(d)

      %AmbiguousDateTime{:before => b, :after => a} ->
        %AmbiguousDateTime{:before => end_of_month(b), :after => end_of_month(a)}
    end
  end

  @spec beginning_of_month(DateTime.t()) :: DateTime.t()
  def beginning_of_month(%DateTime{
        year: year,
        month: month,
        time_zone: tz,
        microsecond: {_, precision}
      }) do
    Timex.DateTime.Helpers.construct({{year, month, 1}, {0, 0, 0, 0}}, precision, tz)
  end

  @spec end_of_month(DateTime.t()) :: DateTime.t()
  def end_of_month(
        %DateTime{year: year, month: month, time_zone: tz, microsecond: {_, precision}} = date
      ) do
    Timex.DateTime.Helpers.construct(
      {{year, month, days_in_month(date)}, {23, 59, 59, 999_999}},
      precision,
      tz
    )
  end

  @spec quarter(DateTime.t()) :: 1..4
  def quarter(%DateTime{month: month}), do: Timex.quarter(month)

  def days_in_month(%DateTime{:year => y, :month => m}), do: Timex.days_in_month(y, m)

  def week_of_month(%DateTime{:year => y, :month => m, :day => d}),
    do: Timex.week_of_month(y, m, d)

  def weekday(%DateTime{:year => y, :month => m, :day => d}),
    do: :calendar.day_of_the_week({y, m, d})

  def day(%DateTime{} = date) do
    ref = beginning_of_year(date)
    1 + Timex.diff(date, ref, :days)
  end

  def is_valid?(%DateTime{
        :year => y,
        :month => m,
        :day => d,
        :hour => h,
        :minute => min,
        :second => sec
      }) do
    :calendar.valid_date({y, m, d}) and Timex.is_valid_time?({h, min, sec})
  end

  def iso_week(%DateTime{:year => y, :month => m, :day => d}),
    do: Timex.iso_week(y, m, d)

  def from_iso_day(%DateTime{year: year} = date, day) when is_day_of_year(day) do
    {year, month, day_of_month} = Timex.Helpers.iso_day_to_date_tuple(year, day)
    %{date | :year => year, :month => month, :day => day_of_month}
  end

  @spec set(DateTime.t(), list({atom(), term})) :: DateTime.t() | {:error, term}
  def set(%DateTime{} = date, options) do
    validate? = Keyword.get(options, :validate, true)

    Enum.reduce(options, date, fn
      _option, {:error, _} = err ->
        err

      option, result ->
        case option do
          {:validate, _} ->
            result

          {:datetime, {{y, m, d}, {h, min, sec}}} ->
            if validate? do
              %{
                result
                | :year => Timex.normalize(:year, y),
                  :month => Timex.normalize(:month, m),
                  :day => Timex.normalize(:day, {y, m, d}),
                  :hour => Timex.normalize(:hour, h),
                  :minute => Timex.normalize(:minute, min),
                  :second => Timex.normalize(:second, sec)
              }
            else
              %{
                result
                | :year => y,
                  :month => m,
                  :day => d,
                  :hour => h,
                  :minute => min,
                  :second => sec
              }
            end

          {:date, {y, m, d}} ->
            if validate? do
              {yn, mn, dn} = Timex.normalize(:date, {y, m, d})
              %{result | :year => yn, :month => mn, :day => dn}
            else
              %{result | :year => y, :month => m, :day => d}
            end

          {:date, %Date{} = d} ->
            Timex.set(result, date: {d.year, d.month, d.day})

          {:time, {h, m, s}} ->
            if validate? do
              %{
                result
                | :hour => Timex.normalize(:hour, h),
                  :minute => Timex.normalize(:minute, m),
                  :second => Timex.normalize(:second, s)
              }
            else
              %{result | :hour => h, :minute => m, :second => s}
            end

          {:time, %Time{} = t} ->
            Timex.set(result, time: {t.hour, t.minute, t.second})

          {:day, d} ->
            if validate? do
              %{result | :day => Timex.normalize(:day, {result.year, result.month, d})}
            else
              %{result | :day => d}
            end

          {:timezone, tz} ->
            tz =
              case tz do
                %TimezoneInfo{} -> tz
                _ -> Timezone.get(tz, result)
              end

            %{
              result
              | :time_zone => tz.full_name,
                :zone_abbr => tz.abbreviation,
                :utc_offset => tz.offset_utc,
                :std_offset => tz.offset_std
            }

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
  @spec shift(DateTime.t(), list({atom(), term})) :: DateTime.t() | {:error, term}
  def shift(%DateTime{time_zone: tz, microsecond: {_us, precision}} = datetime, shifts)
      when is_list(shifts) do
    {logical_shifts, shifts} = Keyword.split(shifts, [:years, :months, :weeks, :days])
    # applied_offset is applied when converting to gregorian microseconds, 
    # we want to reverse that when converting back to the origin timezone
    applied_offset_ms = Timezone.total_offset(datetime.std_offset, datetime.utc_offset) * -1
    datetime = logical_shift(datetime, logical_shifts)
    us = to_gregorian_microseconds(datetime)
    shift = calculate_shift(shifts)
    shifted_us = us + shift
    shifted_secs = div(shifted_us, 1_000 * 1_000) + applied_offset_ms * -1
    rem_us = rem(shifted_us, 1_000 * 1_000)

    new_precision =
      case Timex.DateTime.Helpers.precision(rem_us) do
        np when np < precision ->
          precision

        np ->
          np
      end

    # Convert back to original timezone
    case raw_convert(shifted_secs, {rem_us, new_precision}, tz, :wall) do
      {:error, {:could_not_resolve_timezone, _, _, _}} ->
        # This occurs when the shifted date/time doesn't exist because of a leap forward
        # This doesn't mean the shift is invalid, simply that we need to ask for the right wall time
        # Which in these cases means asking for the time + 1h
        raw_convert(shifted_secs + 3600, {rem_us, new_precision}, tz, :wall)

      result ->
        result
    end
  catch
    :throw, {:error, _} = err ->
      err
  end

  defp raw_convert(secs, {us, precision}, tz, utc_or_wall) do
    {date, {h, mm, s}} = :calendar.gregorian_seconds_to_datetime(secs)
    Timex.DateTime.Helpers.construct({date, {h, mm, s, us}}, precision, tz, utc_or_wall)
  end

  defp logical_shift(datetime, []), do: datetime

  defp logical_shift(datetime, shifts) do
    sorted = Enum.sort_by(shifts, &elem(&1, 0), &compare_unit/2)
    do_logical_shift(datetime, sorted)
  end

  defp do_logical_shift(datetime, []), do: datetime

  defp do_logical_shift(datetime, [{unit, value} | rest]) do
    do_logical_shift(shift_by(datetime, value, unit), rest)
  end

  # Consider compare_unit/2 an analog of Kernel.<=/2
  # We want the largest units first
  defp compare_unit(:years, _), do: true
  defp compare_unit(_, :years), do: false
  defp compare_unit(:months, _), do: true
  defp compare_unit(_, :months), do: false
  defp compare_unit(:weeks, _), do: true
  defp compare_unit(_, :weeks), do: false
  defp compare_unit(:days, _), do: true
  defp compare_unit(_, :days), do: false

  defp calculate_shift(shifts), do: calculate_shift(shifts, 0)

  defp calculate_shift([], acc), do: acc

  defp calculate_shift([{:duration, %Duration{} = duration} | rest], acc) do
    total_microseconds = Duration.to_microseconds(duration)
    calculate_shift(rest, acc + total_microseconds)
  end

  defp calculate_shift([{:hours, value} | rest], acc) when is_integer(value) do
    calculate_shift(rest, acc + value * 60 * 60 * 1_000 * 1_000)
  end

  defp calculate_shift([{:minutes, value} | rest], acc) when is_integer(value) do
    calculate_shift(rest, acc + value * 60 * 1_000 * 1_000)
  end

  defp calculate_shift([{:seconds, value} | rest], acc) when is_integer(value) do
    calculate_shift(rest, acc + value * 1_000 * 1_000)
  end

  defp calculate_shift([{:milliseconds, value} | rest], acc) when is_integer(value) do
    calculate_shift(rest, acc + value * 1_000)
  end

  defp calculate_shift([{:microseconds, value} | rest], acc) when is_integer(value) do
    calculate_shift(rest, acc + value)
  end

  defp calculate_shift([other | _], _acc),
    do: throw({:error, {:invalid_shift, other}})

  defp shift_by(%DateTime{year: y} = datetime, value, :years) do
    shifted = %DateTime{datetime | year: y + value}
    # If a plain shift of the year fails, then it likely falls on a leap day,
    # so set the day to the last day of that month
    case :calendar.valid_date({shifted.year, shifted.month, shifted.day}) do
      false ->
        last_day = :calendar.last_day_of_the_month(shifted.year, shifted.month)
        %DateTime{shifted | day: last_day}

      true ->
        shifted
    end
  end

  defp shift_by(%DateTime{} = datetime, 0, :months),
    do: datetime

  # Positive shifts
  defp shift_by(%DateTime{year: year, month: month, day: day} = datetime, value, :months)
       when value > 0 do
    if month + value <= 12 do
      ldom = :calendar.last_day_of_the_month(year, month + value)

      if day > ldom do
        %DateTime{datetime | month: month + value, day: ldom}
      else
        %DateTime{datetime | month: month + value}
      end
    else
      diff = 12 - month + 1
      shift_by(%DateTime{datetime | year: year + 1, month: 1}, value - diff, :months)
    end
  end

  # Negative shifts
  defp shift_by(%DateTime{year: year, month: month, day: day} = datetime, value, :months) do
    cond do
      month + value >= 1 ->
        ldom = :calendar.last_day_of_the_month(year, month + value)

        if day > ldom do
          %DateTime{datetime | month: month + value, day: ldom}
        else
          %DateTime{datetime | month: month + value}
        end

      :else ->
        shift_by(%DateTime{datetime | year: year - 1, month: 12}, value + month, :months)
    end
  end

  defp shift_by(datetime, value, :weeks),
    do: shift_by(datetime, value * 7, :days)

  defp shift_by(%DateTime{} = datetime, 0, :days),
    do: datetime

  # Positive shifts
  defp shift_by(%DateTime{year: year, month: month, day: day} = datetime, value, :days)
       when value > 0 do
    ldom = :calendar.last_day_of_the_month(year, month)

    cond do
      day + value <= ldom ->
        %DateTime{datetime | day: day + value}

      month + 1 <= 12 ->
        diff = ldom - day + 1
        shift_by(%DateTime{datetime | month: month + 1, day: 1}, value - diff, :days)

      :else ->
        diff = ldom - day + 1
        shift_by(%DateTime{datetime | year: year + 1, month: 1, day: 1}, value - diff, :days)
    end
  end

  # Negative shifts
  defp shift_by(%DateTime{year: year, month: month, day: day} = datetime, value, :days) do
    cond do
      day + value >= 1 ->
        %DateTime{datetime | day: day + value}

      month - 1 >= 1 ->
        ldom = :calendar.last_day_of_the_month(year, month - 1)
        shift_by(%DateTime{datetime | month: month - 1, day: ldom}, value + day, :days)

      :else ->
        ldom = :calendar.last_day_of_the_month(year - 1, 12)
        shift_by(%DateTime{datetime | year: year - 1, month: 12, day: ldom}, value + day, :days)
    end
  end

  @spec to_seconds(DateTime.t(), :epoch | :zero) :: integer | {:error, atom}
  defp to_seconds(%DateTime{} = date, :epoch) do
    case to_seconds(date, :zero) do
      {:error, _} = err -> err
      secs -> secs - @epoch_seconds
    end
  end

  defp to_seconds(%DateTime{} = dt, :zero) do
    total_offset = Timezone.total_offset(dt.std_offset, dt.utc_offset) * -1
    date = {dt.year, dt.month, dt.day}
    time = {dt.hour, dt.minute, dt.second}
    :calendar.datetime_to_gregorian_seconds({date, time}) + total_offset
  end

  defp to_seconds(_, _), do: {:error, :badarg}
end

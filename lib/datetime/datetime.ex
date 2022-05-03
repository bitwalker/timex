defimpl Timex.Protocol, for: DateTime do
  @moduledoc """
  A type which represents a date and time with timezone information (optional, UTC will
  be assumed for date/times with no timezone information provided).

  Functions that produce time intervals use UNIX epoch (or simply Epoch) as the
  default reference date. Epoch is defined as UTC midnight of January 1, 1970.

  Time intervals in this module don't account for leap seconds.
  """
  import Timex.Macros
  use Timex.Constants

  alias Timex.{Duration, AmbiguousDateTime}
  alias Timex.{Timezone, TimezoneInfo}

  def to_julian(%DateTime{:year => y, :month => m, :day => d}) do
    Timex.Calendar.Julian.julian_date(y, m, d)
  end

  def to_gregorian_seconds(date) do
    with {s, _} <- Timex.DateTime.to_gregorian_seconds(date), do: s
  end

  def to_gregorian_microseconds(%DateTime{} = date) do
    with {s, us} <- Timex.DateTime.to_gregorian_seconds(date), do: s * (1_000 * 1_000) + us
  end

  def to_unix(date), do: DateTime.to_unix(date)

  def to_date(date), do: DateTime.to_date(date)

  def to_datetime(%DateTime{time_zone: timezone} = d, timezone),
    do: d

  def to_datetime(%DateTime{time_zone: tz} = d, %TimezoneInfo{full_name: tz}),
    do: d

  def to_datetime(%DateTime{} = d, timezone) do
    Timezone.convert(d, timezone)
  end

  def to_naive_datetime(%DateTime{} = d) do
    # NOTE: For legacy reasons we shift DateTimes to UTC when making them naive, 
    # but the standard library just drops the timezone info
    d
    |> Timex.DateTime.shift_zone!("Etc/UTC", Timex.Timezone.Database)
    |> DateTime.to_naive()
  end

  def to_erl(%DateTime{} = d) do
    {{d.year, d.month, d.day}, {d.hour, d.minute, d.second}}
  end

  def century(%DateTime{:year => year}), do: Timex.century(year)

  def is_leap?(%DateTime{year: year}), do: :calendar.is_leap_year(year)

  def beginning_of_day(%DateTime{time_zone: time_zone, microsecond: {_, precision}} = datetime) do
    us = Timex.DateTime.Helpers.construct_microseconds(0, precision)
    time = Timex.Time.new!(0, 0, 0, us)

    with {:ok, datetime} <-
           Timex.DateTime.new(
             DateTime.to_date(datetime),
             time,
             time_zone,
             Timex.Timezone.Database
           ) do
      datetime
    else
      {:gap, _a, b} ->
        # Beginning of the day is after the gap
        b

      {:ambiguous, _a, b} ->
        # Choose the latter of the ambiguous times
        b
    end
  end

  def end_of_day(%DateTime{time_zone: time_zone, microsecond: {_, precision}} = datetime) do
    us = Timex.DateTime.Helpers.construct_microseconds(999_999, precision)
    time = Timex.Time.new!(23, 59, 59, us)

    with {:ok, datetime} <-
           Timex.DateTime.new(
             DateTime.to_date(datetime),
             time,
             time_zone,
             Timex.Timezone.Database
           ) do
      datetime
    else
      {:gap, a, _b} ->
        # End of day is before the gap
        a

      {:ambiguous, a, _b} ->
        # Choose the former of the ambiguous times
        a
    end
  end

  def beginning_of_week(
        %DateTime{time_zone: time_zone, microsecond: {_, precision}} = date,
        weekstart
      ) do
    us = Timex.DateTime.Helpers.construct_microseconds(0, precision)
    time = Timex.Time.new!(0, 0, 0, us)

    with weekstart when is_atom(weekstart) <- Timex.standardize_week_start(weekstart),
         date = Timex.Date.beginning_of_week(DateTime.to_date(date), weekstart),
         {:ok, datetime} <- Timex.DateTime.new(date, time, time_zone, Timex.Timezone.Database) do
      datetime
    else
      {:gap, _a, b} ->
        # Beginning of week is after the gap
        b

      {:ambiguous, _a, b} ->
        b

      {:error, _} = err ->
        err
    end
  end

  def end_of_week(%DateTime{time_zone: time_zone, microsecond: {_, precision}} = date, weekstart) do
    with weekstart when is_atom(weekstart) <- Timex.standardize_week_start(weekstart),
         date = Timex.Date.end_of_week(DateTime.to_date(date), weekstart),
         us = Timex.DateTime.Helpers.construct_microseconds(999_999, precision),
         time = Timex.Time.new!(23, 59, 59, us),
         {:ok, datetime} <- Timex.DateTime.new(date, time, time_zone, Timex.Timezone.Database) do
      datetime
    else
      {:gap, a, _b} ->
        # End of week is before the gap
        a

      {:ambiguous, a, _b} ->
        a

      {:error, _} = err ->
        err
    end
  end

  def beginning_of_year(%DateTime{year: year, time_zone: time_zone, microsecond: {_, precision}}) do
    us = Timex.DateTime.Helpers.construct_microseconds(0, precision)
    time = Timex.Time.new!(0, 0, 0, us)

    with {:ok, datetime} <-
           Timex.DateTime.new(
             Timex.Date.new!(year, 1, 1),
             time,
             time_zone,
             Timex.Timezone.Database
           ) do
      datetime
    else
      {:gap, _a, b} ->
        # Beginning of year is after the gap
        b

      {:ambiguous, _a, b} ->
        b
    end
  end

  def end_of_year(%DateTime{year: year, time_zone: time_zone, microsecond: {_, precision}}) do
    us = Timex.DateTime.Helpers.construct_microseconds(999_999, precision)
    time = Timex.Time.new!(23, 59, 59, us)

    with {:ok, datetime} <-
           Timex.DateTime.new(
             Timex.Date.new!(year, 12, 31),
             time,
             time_zone,
             Timex.Timezone.Database
           ) do
      datetime
    else
      {:gap, a, _b} ->
        # End of year is before the gap
        a

      {:ambiguous, a, _b} ->
        a
    end
  end

  def beginning_of_quarter(%DateTime{
        year: year,
        month: month,
        time_zone: time_zone,
        microsecond: {_, precision}
      }) do
    month = 1 + 3 * (Timex.quarter(month) - 1)
    us = Timex.DateTime.Helpers.construct_microseconds(0, precision)
    time = Timex.Time.new!(0, 0, 0, us)

    with {:ok, datetime} <-
           Timex.DateTime.new(
             Timex.Date.new!(year, month, 1),
             time,
             time_zone,
             Timex.Timezone.Database
           ) do
      datetime
    else
      {:gap, _a, b} ->
        # Beginning of quarter is after the gap
        b

      {:ambiguous, _a, b} ->
        b
    end
  end

  def end_of_quarter(%DateTime{
        year: year,
        month: month,
        time_zone: time_zone,
        microsecond: {_, precision}
      }) do
    month = 3 * Timex.quarter(month)
    date = Timex.Date.end_of_month(Timex.Date.new!(year, month, 1))
    us = Timex.DateTime.Helpers.construct_microseconds(999_999, precision)
    time = Timex.Time.new!(23, 59, 59, us)

    with {:ok, datetime} <- Timex.DateTime.new(date, time, time_zone, Timex.Timezone.Database) do
      datetime
    else
      {:gap, a, _b} ->
        # End of quarter is before the gap
        a

      {:ambiguous, a, _b} ->
        a
    end
  end

  def beginning_of_month(%DateTime{
        year: year,
        month: month,
        time_zone: time_zone,
        microsecond: {_, precision}
      }) do
    us = Timex.DateTime.Helpers.construct_microseconds(0, precision)
    time = Timex.Time.new!(0, 0, 0, us)

    with {:ok, datetime} <-
           Timex.DateTime.new(
             Timex.Date.new!(year, month, 1),
             time,
             time_zone,
             Timex.Timezone.Database
           ) do
      datetime
    else
      {:gap, _a, b} ->
        # Beginning of month is after the gap
        b

      {:ambiguous, _a, b} ->
        b
    end
  end

  def end_of_month(%DateTime{
        year: year,
        month: month,
        time_zone: time_zone,
        microsecond: {_, precision}
      }) do
    date = Timex.Date.end_of_month(Timex.Date.new!(year, month, 1))
    us = Timex.DateTime.Helpers.construct_microseconds(999_999, precision)
    time = Timex.Time.new!(23, 59, 59, us)

    with {:ok, datetime} <- Timex.DateTime.new(date, time, time_zone, Timex.Timezone.Database) do
      datetime
    else
      {:gap, a, _b} ->
        # End of month is before the gap
        a

      {:ambiguous, a, _b} ->
        a
    end
  end

  def quarter(%DateTime{year: y, month: m, day: d}),
    do: Calendar.ISO.quarter_of_year(y, m, d)

  def days_in_month(d), do: Date.days_in_month(d)

  def week_of_month(%DateTime{:year => y, :month => m, :day => d}),
    do: Timex.week_of_month(y, m, d)

  def weekday(datetime), do: Timex.Date.day_of_week(datetime)
  def weekday(datetime, weekstart), do: Timex.Date.day_of_week(datetime, weekstart)

  def day(datetime), do: Date.day_of_year(datetime)

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
    %DateTime{date | :year => year, :month => month, :day => day_of_month}
  end

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

          {:time, {h, m, s, ms}} ->
            if validate? do
              %{
                result
                | :hour => Timex.normalize(:hour, h),
                  :minute => Timex.normalize(:minute, m),
                  :second => Timex.normalize(:second, s),
                  :microsecond => Timex.normalize(:microsecond, ms)
              }
            else
              %{result | :hour => h, :minute => m, :second => s, :microsecond => ms}
            end

          {:time, %Time{} = t} ->
            Timex.set(result, time: {t.hour, t.minute, t.second, t.microsecond})

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
  def shift(%DateTime{} = datetime, shifts) when is_list(shifts) do
    {logical_shifts, shifts} = Keyword.split(shifts, [:years, :months, :weeks, :days])
    shift = calculate_shift(shifts)

    shifted =
      case logical_shift(datetime, logical_shifts) do
        {:error, _} = err ->
          err

        %DateTime{} = datetime when shift != 0 ->
          DateTime.add(datetime, shift, :microsecond, Timex.Timezone.Database)

        %DateTime{} = datetime ->
          datetime

        {{ty, _, _}, %DateTime{} = orig} when ty in [:gap, :ambiguous] and shift != 0 ->
          DateTime.add(orig, shift, :microsecond, Timex.Timezone.Database)

        {{ty, _a, _b} = amb, _} when ty in [:gap, :ambiguous] ->
          amb
      end

    case shifted do
      {ty, a, b} when ty in [:gap, :ambiguous] ->
        %AmbiguousDateTime{before: a, after: b, type: ty}

      result ->
        result
    end
  rescue
    err in [FunctionClauseError] ->
      case {err.module, err.function} do
        {Calendar.ISO, _} ->
          {:error, :invalid_date}

        _ ->
          reraise err, __STACKTRACE__
      end
  catch
    :throw, {:error, _} = err ->
      err
  end

  defp logical_shift(datetime, []), do: datetime

  defp logical_shift(datetime, shifts) do
    sorted = Enum.sort_by(shifts, &elem(&1, 0), &compare_unit/2)

    case do_logical_shift(datetime, sorted) do
      %DateTime{time_zone: time_zone} = dt ->
        with {:ok, shifted} <-
               DateTime.from_naive(DateTime.to_naive(dt), time_zone, Timex.Timezone.Database) do
          shifted
        else
          {ty, _, _} = amb when ty in [:gap, :ambiguous] ->
            {amb, dt}

          {:error, _} = err ->
            err
        end

      err ->
        err
    end
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

  defp calculate_shift([{k, _} | _], _acc),
    do: throw({:error, {:unknown_shift_unit, k}})

  defp shift_by(%DateTime{year: y, month: m, day: d} = datetime, value, :years) do
    new_year = y + value
    shifted = %DateTime{datetime | year: new_year}

    cond do
      new_year < 0 ->
        {:error, :shift_to_invalid_date}

      m == 2 and d == 29 and :calendar.is_leap_year(y) and :calendar.is_leap_year(new_year) ->
        shifted

      m == 2 and d == 29 and :calendar.is_leap_year(y) ->
        # Shift to March 1st in non-leap years
        %DateTime{shifted | month: 3, day: 1}

      :else ->
        shifted
    end
  end

  defp shift_by(%DateTime{} = datetime, 0, :months),
    do: datetime

  # Positive shifts
  defp shift_by(%DateTime{year: year, month: month, day: day} = datetime, value, :months)
       when value > 0 do
    add_years = div(value, 12)
    add_months = rem(value, 12)

    {year, month} =
      if month + add_months <= 12 do
        {year + add_years, month + add_months}
      else
        total_months = month + add_months
        {year + add_years + 1, total_months - 12}
      end

    ldom = :calendar.last_day_of_the_month(year, month)

    cond do
      day > ldom ->
        %DateTime{datetime | year: year, month: month, day: ldom}

      :else ->
        %DateTime{datetime | year: year, month: month}
    end
  end

  # Negative shifts
  defp shift_by(%DateTime{year: year, month: month, day: day} = datetime, value, :months) do
    add_years = div(value, 12)
    add_months = rem(value, 12)

    {year, month} =
      if month + add_months < 1 do
        total_months = month + add_months
        {year + (add_years - 1), 12 + total_months}
      else
        {year + add_years, month + add_months}
      end

    if year < 0 do
      {:error, :shift_to_invalid_date}
    else
      ldom = :calendar.last_day_of_the_month(year, month)

      cond do
        day > ldom ->
          %DateTime{datetime | year: year, month: month, day: ldom}

        :else ->
          %DateTime{datetime | year: year, month: month}
      end
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

      year == 0 ->
        {:error, :shift_to_invalid_date}

      :else ->
        ldom = :calendar.last_day_of_the_month(year - 1, 12)
        shift_by(%DateTime{datetime | year: year - 1, month: 12, day: ldom}, value + day, :days)
    end
  end
end

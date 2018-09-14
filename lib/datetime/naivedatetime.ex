defimpl Timex.Protocol, for: NaiveDateTime do
  @moduledoc """
  This module implements Timex functionality for NaiveDateTime
  """
  alias Timex.{Types, Duration}
  import Timex.Macros

  @epoch_seconds :calendar.datetime_to_gregorian_seconds({{1970,1,1},{0,0,0}})

  @spec now() :: NaiveDateTime.t
  def now() do
    Timex.to_naive_datetime(Timex.from_unix(:os.system_time, :native))
  end

  @spec to_julian(NaiveDateTime.t) :: float
  def to_julian(%NaiveDateTime{:year => y, :month => m, :day => d}) do
    Timex.Calendar.Julian.julian_date(y, m, d)
  end

  @spec to_gregorian_seconds(NaiveDateTime.t) :: non_neg_integer
  def to_gregorian_seconds(date), do: to_seconds(date, :zero)

  @spec to_gregorian_microseconds(NaiveDateTime.t) :: non_neg_integer
  def to_gregorian_microseconds(%NaiveDateTime{microsecond: {us,_}} = date) do
    s = to_seconds(date, :zero)
    (s*(1_000*1_000))+us
  end

  @spec to_unix(NaiveDateTime.t) :: non_neg_integer
  def to_unix(date), do: trunc(to_seconds(date, :epoch))

  @spec to_date(NaiveDateTime.t) :: Date.t
  def to_date(date), do: NaiveDateTime.to_date(date)

  @spec to_datetime(NaiveDateTime.t, timezone :: Types.valid_timezone) :: DateTime.t | {:error, term}
  def to_datetime(%NaiveDateTime{:microsecond => {us,_}} = d, timezone) do
    {date,{h,mm,s}} = NaiveDateTime.to_erl(d)
    Timex.DateTime.Helpers.construct({date,{h,mm,s,us}}, timezone)
  end

  @spec to_naive_datetime(NaiveDateTime.t) :: NaiveDateTime.t
  def to_naive_datetime(%NaiveDateTime{} = date), do: date

  @spec to_erl(NaiveDateTime.t) :: Types.datetime
  def to_erl(%NaiveDateTime{} = d), do: NaiveDateTime.to_erl(d)

  @spec century(NaiveDateTime.t) :: non_neg_integer
  def century(%NaiveDateTime{:year => year}), do: Timex.century(year)

  @spec is_leap?(NaiveDateTime.t) :: boolean
  def is_leap?(%NaiveDateTime{year: year}), do: :calendar.is_leap_year(year)

  @spec beginning_of_day(NaiveDateTime.t) :: NaiveDateTime.t
  def beginning_of_day(%NaiveDateTime{:microsecond => {_, _precision}} = datetime) do
    %{datetime | :hour => 0, :minute => 0, :second => 0, :microsecond => {0, 0}}
  end

  @spec end_of_day(NaiveDateTime.t) :: NaiveDateTime.t
  def end_of_day(%NaiveDateTime{microsecond: {_, _precision}} = datetime) do
    %{datetime | :hour => 23, :minute => 59, :second => 59, :microsecond => {999_999, 6}}
  end

  @spec beginning_of_week(NaiveDateTime.t, Types.weekstart) :: NaiveDateTime.t
  def beginning_of_week(%NaiveDateTime{} = date, weekstart) do
    case Timex.days_to_beginning_of_week(date, weekstart) do
      {:error, _} = err -> err
      days ->
        beginning_of_day(shift(date, [days: -days]))
    end
  end

  @spec end_of_week(NaiveDateTime.t, Types.weekstart) :: NaiveDateTime.t
  def end_of_week(%NaiveDateTime{} = date, weekstart) do
    case Timex.days_to_end_of_week(date, weekstart) do
      {:error, _} = err -> err
      days_to_end ->
        end_of_day(shift(date, [days: days_to_end]))
    end
  end

  @spec beginning_of_year(NaiveDateTime.t) :: NaiveDateTime.t
  def beginning_of_year(%NaiveDateTime{:year => y}) do
    {:ok, nd} = NaiveDateTime.new(y, 1, 1, 0, 0, 0)
    nd
  end

  @spec end_of_year(NaiveDateTime.t) :: NaiveDateTime.t
  def end_of_year(%NaiveDateTime{} = date),
    do: %{date | :month => 12, :day => 31, :hour => 23, :minute => 59, :second => 59, :microsecond => {999_999, 6}}

  @spec beginning_of_quarter(NaiveDateTime.t) :: NaiveDateTime.t
  def beginning_of_quarter(%NaiveDateTime{month: month} = date) do
    month = 1 + (3 * (Timex.quarter(month) - 1))
    beginning_of_month(%{date | :month => month, :day => 1})
  end

  @spec end_of_quarter(NaiveDateTime.t) :: NaiveDateTime.t
  def end_of_quarter(%NaiveDateTime{month: month} = date) do
    month = 3 * Timex.quarter(month)
    end_of_month(%{date | :month => month, :day => 1})
  end

  @spec beginning_of_month(NaiveDateTime.t) :: NaiveDateTime.t
  def beginning_of_month(%NaiveDateTime{} = datetime),
    do: %{datetime | :day => 1, :hour => 0, :minute => 0, :second => 0, :microsecond => {0,0}}

  @spec end_of_month(NaiveDateTime.t) :: NaiveDateTime.t
  def end_of_month(%NaiveDateTime{} = date),
    do: %{date | :day => days_in_month(date), :hour => 23, :minute => 59, :second => 59, :microsecond => {999_999, 6}}

  @spec quarter(NaiveDateTime.t) :: 1..4
  def quarter(%NaiveDateTime{month: month}), do: Timex.quarter(month)

  def days_in_month(%NaiveDateTime{:year => y, :month => m}), do: Timex.days_in_month(y, m)

  def week_of_month(%NaiveDateTime{:year => y, :month => m, :day => d}), do: Timex.week_of_month(y,m,d)

  def weekday(%NaiveDateTime{:year => y, :month => m, :day => d}), do: :calendar.day_of_the_week({y, m, d})

  def day(%NaiveDateTime{} = date) do
    {:ok, nd} = NaiveDateTime.new(date.year,1,1,0,0,0)
    1 + Timex.diff(date, nd, :days)
  end

  def is_valid?(%NaiveDateTime{:year => y, :month => m, :day => d,
                               :hour => h, :minute => min, :second => sec}) do
    :calendar.valid_date({y,m,d}) and Timex.is_valid_time?({h,min,sec})
  end

  def iso_week(%NaiveDateTime{:year => y, :month => m, :day => d}),
    do: Timex.iso_week(y, m, d)

  def from_iso_day(%NaiveDateTime{year: year} = date, day) when is_day_of_year(day) do
    {year, month, day_of_month} = Timex.Helpers.iso_day_to_date_tuple(year, day)
    %{date | :year => year, :month => month, :day => day_of_month}
  end

  @spec set(NaiveDateTime.t, list({atom(), term})) :: NaiveDateTime.t | {:error, term}
  def set(%NaiveDateTime{} = date, options) do
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
              %{result |
                :hour => Timex.normalize(:hour, h),
                :minute => Timex.normalize(:minute, m),
                :second => Timex.normalize(:second, s)}
            else
              %{result | :hour => h, :minute => m, :second => s}
            end
          {:day, d} ->
            if validate? do
              %{result | :day => Timex.normalize(:day, {result.year, result.month, d})}
            else
              %{result | :day => d}
            end
          {name, val} when name in [:year, :month, :hour, :minute, :second, :microsecond] ->
            if validate? do
              Map.put(result, name, Timex.normalize(name, val))
            else
              Map.put(result, name, val)
            end
          {name, _} when name in [:timezone] ->
            result
          {option_name, _} ->
            {:error, {:bad_option, option_name}}
        end
      end)
  end

  @spec shift(NaiveDateTime.t, list({atom(), term})) :: NaiveDateTime.t | {:error, term}
  def shift(%NaiveDateTime{} = datetime, shifts) when is_list(shifts) do
    apply_shifts(datetime, shifts)
  end
  defp apply_shifts(datetime, []),
    do: datetime
  defp apply_shifts(datetime, [{:duration, %Duration{} = duration} | rest]) do
    duration_microseconds = Duration.to_microseconds(duration)
    shifted = shift_by(datetime, duration_microseconds, :microseconds)
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

  defp shift_by(%NaiveDateTime{:year => y} = datetime, value, :years) do
    shifted = %{datetime | :year => y + value}
    # If a plain shift of the year fails, then it likely falls on a leap day,
    # so set the day to the last day of that month
    case :calendar.valid_date({shifted.year,shifted.month,shifted.day}) do
      false ->
        last_day = :calendar.last_day_of_the_month(shifted.year, shifted.month)
        cond do
          shifted.day <= last_day ->
            shifted
          :else ->
            %{shifted | :day => last_day}
        end
      true ->
        shifted
    end
  end
  defp shift_by(%NaiveDateTime{:year => year, :month => month} = datetime, value, :months) do
    m = month + value
    shifted =
      cond do
        m > 0 ->
          years = div(m - 1, 12)
          month = rem(m - 1, 12) + 1
          %{datetime | :year => year + years, :month => month}
        m <= 0 ->
          years = div(m, 12) - 1
          month = 12 + rem(m, 12)
          %{datetime | :year => year + years, :month => month}
      end

    # If the shift fails, it's because it's a high day number, and the month
    # shifted to does not have that many days. This will be handled by always
    # shifting to the last day of the month shifted to.
    case :calendar.valid_date({shifted.year,shifted.month,shifted.day}) do
      false ->
        last_day = :calendar.last_day_of_the_month(shifted.year, shifted.month)
        cond do
          shifted.day <= last_day ->
            shifted
          :else ->
            %{shifted | :day => last_day}
        end
      true ->
        shifted
    end
  end
  defp shift_by(datetime, value, :weeks),
    do: shift_by(datetime, (value * 60 * 60 * 24 * 7 * 1_000_000), :microseconds)
  defp shift_by(datetime, value, :days),
    do: shift_by(datetime, (value * 60 * 60 * 24 * 1_000_000), :microseconds)
  defp shift_by(datetime, value, :hours),
    do: shift_by(datetime, (value * 60 * 60 * 1_000_000), :microseconds)
  defp shift_by(datetime, value, :minutes),
    do: shift_by(datetime, (value * 60 * 1_000_000), :microseconds)
  defp shift_by(datetime, value, :seconds),
    do: shift_by(datetime, (value * 1_000_000), :microseconds)
  defp shift_by(datetime, value, :milliseconds),
    do: shift_by(datetime, (value * 1_000), :microseconds)
  defp shift_by(%NaiveDateTime{microsecond: {current_microseconds, current_precision}} = datetime, value, :microseconds) do
    microseconds_from_zero = :calendar.datetime_to_gregorian_seconds({
      {datetime.year, datetime.month, datetime.day},
      {datetime.hour, datetime.minute, datetime.second}
    }) * 1_000_000 + current_microseconds + value

    if microseconds_from_zero < 0 do
      {:error, :shift_to_invalid_date}
    else
      seconds_from_zero = div(microseconds_from_zero, 1_000_000)
      rem_microseconds = rem(microseconds_from_zero, 1_000_000)

      seconds_from_zero
      |> :calendar.gregorian_seconds_to_datetime
      |> Timex.to_naive_datetime
      |> Map.put(:microsecond, {rem_microseconds, current_precision})
    end
  end
  defp shift_by(_datetime, _value, units),
    do: {:error, {:unknown_shift_unit, units}}

  defp to_seconds(%NaiveDateTime{year: y, month: m, day: d, hour: h, minute: mm, second: s}, :zero) do
    :calendar.datetime_to_gregorian_seconds({{y,m,d},{h,mm,s}})
  end
  defp to_seconds(%NaiveDateTime{year: y, month: m, day: d, hour: h, minute: mm, second: s}, :epoch) do
    :calendar.datetime_to_gregorian_seconds({{y,m,d},{h,mm,s}}) - @epoch_seconds
  end

end

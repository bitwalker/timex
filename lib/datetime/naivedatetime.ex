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

  @spec to_julian(NaiveDateTime.t) :: integer
  def to_julian(%NaiveDateTime{:year => y, :month => m, :day => d}) do
    Timex.Calendar.Julian.julian_date(y, m, d)
  end

  @spec to_gregorian_seconds(NaiveDateTime.t) :: integer
  def to_gregorian_seconds(date), do: to_seconds(date, :zero)

  @spec to_gregorian_microseconds(NaiveDateTime.t) :: integer
  def to_gregorian_microseconds(%NaiveDateTime{microsecond: {us,_}} = date) do
    s = to_seconds(date, :zero)
    (s*(1_000*1_000))+us
  end

  @spec to_unix(NaiveDateTime.t) :: integer
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

  @spec beginning_of_week(NaiveDateTime.t, Types.weekday) :: NaiveDateTime.t
  def beginning_of_week(%NaiveDateTime{} = date, weekstart) do
    case Timex.days_to_beginning_of_week(date, weekstart) do
      {:error, _} = err -> err
      days ->
        beginning_of_day(shift(date, [days: -days]))
    end
  end

  @spec end_of_week(NaiveDateTime.t, Types.weekday) :: NaiveDateTime.t
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

  @spec quarter(NaiveDateTime.t) :: integer
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
    total_microseconds = Duration.to_microseconds(duration)
    seconds = div(total_microseconds, 1_000*1_000)
    rem_microseconds = rem(total_microseconds, 1_000*1_000)
    shifted = shift_by(datetime, seconds, :seconds)
    shifted = %{shifted | :microsecond => Timex.DateTime.Helpers.construct_microseconds(rem_microseconds)}
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
    shifted = cond do
      value == 12  -> %{datetime | :year => year + 1}
      value == -12 -> %{datetime | :year => year - 1}
      m == 0 -> %{datetime | :year => year - 1, :month => 12}
      m > 12 -> %{datetime | :year => year + div(m, 12), :month => rem(m, 12)}
      m < 0  -> %{datetime | :year => year + min(div(m, 12), -1), :month => 12 + rem(m, 12)}
      :else  -> %{datetime | :month => m}
    end

    # setting months to remainders may result in invalid :month => 0
    shifted = case shifted.month do
      0 -> %{ shifted | :year => shifted.year - 1, :month => 12 }
      _ -> shifted
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
  defp shift_by(%NaiveDateTime{microsecond: {current_usecs, _}} = datetime, value, :microseconds) do
    usecs_from_zero = :calendar.datetime_to_gregorian_seconds({
      {datetime.year,datetime.month,datetime.day},
      {datetime.hour,datetime.minute,datetime.second}
    }) * (1_000*1_000) + current_usecs + value

    secs_from_zero = div(usecs_from_zero, 1_000*1_000)
    rem_microseconds = rem(usecs_from_zero, 1_000*1_000)

    shifted = :calendar.gregorian_seconds_to_datetime(secs_from_zero)
    shifted = Timex.to_naive_datetime(shifted)
    %{shifted | :microsecond => Timex.DateTime.Helpers.construct_microseconds(rem_microseconds)}
  end
  defp shift_by(%NaiveDateTime{microsecond: {current_usecs, _}} = datetime, value, :milliseconds) do
    usecs_from_zero = :calendar.datetime_to_gregorian_seconds({
      {datetime.year,datetime.month,datetime.day},
      {datetime.hour,datetime.minute,datetime.second}
    }) * (1_000*1_000) + current_usecs + (value*1_000)

    secs_from_zero = div(usecs_from_zero, 1_000*1_000)
    rem_microseconds = rem(usecs_from_zero, 1_000*1_000)

    shifted = :calendar.gregorian_seconds_to_datetime(secs_from_zero)
    shifted = Timex.to_naive_datetime(shifted)
    %{shifted | :microsecond => Timex.DateTime.Helpers.construct_microseconds(rem_microseconds)}
  end
  defp shift_by(%NaiveDateTime{microsecond: {us, _}} = datetime, value, units) do
    secs_from_zero = :calendar.datetime_to_gregorian_seconds({
      {datetime.year,datetime.month,datetime.day},
      {datetime.hour,datetime.minute,datetime.second}
    })
    shift_by = case units do
      :microseconds -> div(value + us, 1_000*1_000)
      :milliseconds -> div((value*1_000 + us), 1_000*1_000)
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
        %{datetime | :microsecond => Timex.DateTime.Helpers.construct_microseconds(value+us)}
      0 when units in [:milliseconds] ->
        %{datetime | :microsecond => Timex.DateTime.Helpers.construct_microseconds((value*1_000)+us)}
      0 ->
        datetime
      _ ->
        new_secs_from_zero = secs_from_zero + shift_by
        cond do
          new_secs_from_zero <= 0 ->
            {:error, :shift_to_invalid_date}
          :else ->
            shifted = :calendar.gregorian_seconds_to_datetime(new_secs_from_zero)
            shifted = Timex.to_naive_datetime(shifted)
            %{shifted | :microsecond => Timex.DateTime.Helpers.construct_microseconds(us)}
        end
    end
  end

  defp to_seconds(%NaiveDateTime{year: y, month: m, day: d, hour: h, minute: mm, second: s}, :zero) do
    :calendar.datetime_to_gregorian_seconds({{y,m,d},{h,mm,s}})
  end
  defp to_seconds(%NaiveDateTime{year: y, month: m, day: d, hour: h, minute: mm, second: s}, :epoch) do
    :calendar.datetime_to_gregorian_seconds({{y,m,d},{h,mm,s}}) - @epoch_seconds
  end

end

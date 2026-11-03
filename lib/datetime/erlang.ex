defimpl Timex.Protocol, for: Tuple do
  alias Timex.AmbiguousDateTime
  import Timex.Macros

  @epoch :calendar.datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}})

  def to_julian(date) do
    with {:ok, {{y, m, d}, _time}} <- to_erl_datetime(date),
         do: Timex.Calendar.Julian.julian_date(y, m, d)
  end

  def to_gregorian_seconds(date) do
    with {:ok, date} <- to_erl_datetime(date),
         do: :calendar.datetime_to_gregorian_seconds(date)
  end

  def to_gregorian_microseconds(date) do
    with {:ok, erl_date} <- to_erl_datetime(date),
         do:
           :calendar.datetime_to_gregorian_seconds(erl_date) * 1_000 * 1_000 +
             get_microseconds(date)
  end

  def to_unix(date) do
    with {:ok, date} <- to_erl_datetime(date),
         do: :calendar.datetime_to_gregorian_seconds(date) - @epoch
  end

  def to_date(date) do
    with {:ok, {date, _}} <- to_erl_datetime(date),
         do: Date.from_erl!(date)
  end

  def to_datetime({_y, _m, _d} = date, timezone) do
    to_datetime({date, {0, 0, 0}}, timezone)
  end

  def to_datetime({{_y, _m, _d} = date, {h, mm, s}}, timezone) do
    to_datetime({date, {h, mm, s, {0, 0}}}, timezone)
  end

  def to_datetime({{y, m, d}, {h, mm, s, us}}, timezone) when is_datetime(y, m, d, h, mm, s) do
    us = Timex.DateTime.Helpers.construct_microseconds(us)
    dt = Timex.NaiveDateTime.new!(y, m, d, h, mm, s, us)

    with %DateTime{} = datetime <- Timex.Timezone.convert(dt, timezone) do
      datetime
    else
      %AmbiguousDateTime{} = datetime ->
        datetime

      {:error, _} = err ->
        err
    end
  end

  def to_datetime(_, _), do: {:error, :invalid_date}

  def to_naive_datetime({{y, m, d}, {h, mm, s, us}}) when is_datetime(y, m, d, h, mm, s) do
    us = Timex.DateTime.Helpers.construct_microseconds(us)
    Timex.NaiveDateTime.new!(y, m, d, h, mm, s, us)
  end

  def to_naive_datetime(date) do
    with {:ok, {{y, m, d}, {h, mm, s}}} <- to_erl_datetime(date) do
      Timex.NaiveDateTime.new!(y, m, d, h, mm, s)
    end
  end

  def to_erl({y, m, d} = date) when is_date(y, m, d), do: date

  def to_erl(date) do
    with {:ok, date} <- to_erl_datetime(date),
         do: date
  end

  def century({y, m, d}) when is_date(y, m, d), do: Timex.century(y)
  def century({{y, m, d}, _}) when is_date(y, m, d), do: Timex.century(y)
  def century(_), do: {:error, :invalid_date}

  def is_leap?({y, m, d}) when is_date(y, m, d), do: :calendar.is_leap_year(y)
  def is_leap?({{y, m, d}, _}) when is_date(y, m, d), do: :calendar.is_leap_year(y)
  def is_leap?(_), do: {:error, :invalid_date}

  def beginning_of_day({y, m, d} = date) when is_date(y, m, d), do: date

  def beginning_of_day({{y, m, d} = date, _}) when is_date(y, m, d),
    do: {date, {0, 0, 0}}

  def beginning_of_day(_), do: {:error, :invalid_date}

  def end_of_day({y, m, d} = date) when is_date(y, m, d), do: date

  def end_of_day({{y, m, d} = date, _}) when is_date(y, m, d),
    do: {date, {23, 59, 59}}

  def end_of_day(_), do: {:error, :invalid_date}

  def beginning_of_week({y, m, d}, weekstart) when is_date(y, m, d) do
    with ws when is_atom(ws) <- Timex.standardize_week_start(weekstart) do
      Timex.Date.new!(y, m, d)
      |> Timex.Date.beginning_of_week(ws)
      |> Date.to_erl()
    end
  end

  def beginning_of_week({{y, m, d}, _}, weekstart) when is_date(y, m, d) do
    with ws when is_atom(ws) <- Timex.standardize_week_start(weekstart) do
      date =
        Timex.Date.new!(y, m, d)
        |> Timex.Date.beginning_of_week(ws)
        |> Date.to_erl()

      {date, {0, 0, 0}}
    end
  end

  def beginning_of_week(_, _), do: {:error, :invalid_date}

  def end_of_week({y, m, d}, weekstart) when is_date(y, m, d) do
    with ws when is_atom(ws) <- Timex.standardize_week_start(weekstart) do
      Timex.Date.new!(y, m, d)
      |> Timex.Date.end_of_week(ws)
      |> Date.to_erl()
    end
  end

  def end_of_week({{y, m, d}, _}, weekstart) when is_date(y, m, d) do
    with ws when is_atom(ws) <- Timex.standardize_week_start(weekstart) do
      date =
        Timex.Date.new!(y, m, d)
        |> Timex.Date.end_of_week(ws)
        |> Date.to_erl()

      {date, {23, 59, 59}}
    end
  end

  def end_of_week(_, _), do: {:error, :invalid_date}

  def beginning_of_year({y, m, d}) when is_date(y, m, d),
    do: {y, 1, 1}

  def beginning_of_year({{y, m, d}, _}) when is_date(y, m, d),
    do: {{y, 1, 1}, {0, 0, 0}}

  def beginning_of_year(_), do: {:error, :invalid_date}

  def end_of_year({y, m, d}) when is_date(y, m, d),
    do: {y, 12, 31}

  def end_of_year({{y, m, d}, _}) when is_date(y, m, d),
    do: {{y, 12, 31}, {23, 59, 59}}

  def end_of_year(_), do: {:error, :invalid_date}

  def beginning_of_quarter({y, m, d}) when is_date(y, m, d) do
    month = 1 + 3 * (Timex.quarter(m) - 1)
    {y, month, 1}
  end

  def beginning_of_quarter({{y, m, d}, {h, mm, s} = _time}) when is_datetime(y, m, d, h, mm, s) do
    month = 1 + 3 * (Timex.quarter(m) - 1)
    {{y, month, 1}, {0, 0, 0}}
  end

  def beginning_of_quarter({{y, m, d}, {h, mm, s, _us} = _time})
      when is_datetime(y, m, d, h, mm, s) do
    month = 1 + 3 * (Timex.quarter(m) - 1)
    {{y, month, 1}, {0, 0, 0, 0}}
  end

  def beginning_of_quarter(_), do: {:error, :invalid_date}

  def end_of_quarter({y, m, d}) when is_date(y, m, d) do
    month = 3 * Timex.quarter(m)
    end_of_month({y, month, d})
  end

  def end_of_quarter({{y, m, d}, {h, mm, s} = time}) when is_datetime(y, m, d, h, mm, s) do
    month = 3 * Timex.quarter(m)
    end_of_month({{y, month, d}, time})
  end

  def end_of_quarter({{y, m, d}, {h, mm, s, _us}}) when is_datetime(y, m, d, h, mm, s) do
    month = 3 * Timex.quarter(m)
    end_of_month({{y, month, d}, {h, mm, s}})
  end

  def end_of_quarter(_), do: {:error, :invalid_date}

  def beginning_of_month({y, m, d}) when is_date(y, m, d),
    do: {y, m, 1}

  def beginning_of_month({{y, m, d}, _}) when is_date(y, m, d),
    do: {{y, m, 1}, {0, 0, 0}}

  def beginning_of_month(_), do: {:error, :invalid_date}

  def end_of_month({y, m, d} = date) when is_date(y, m, d),
    do: {y, m, days_in_month(date)}

  def end_of_month({{y, m, d}, _} = date) when is_date(y, m, d),
    do: {{y, m, days_in_month(date)}, {23, 59, 59}}

  def end_of_month(_), do: {:error, :invalid_date}

  def quarter({y, m, d}) when is_date(y, m, d), do: Calendar.ISO.quarter_of_year(y, m, d)
  def quarter({{y, m, d}, _}) when is_date(y, m, d), do: Calendar.ISO.quarter_of_year(y, m, d)
  def quarter(_), do: {:error, :invalid_date}

  def days_in_month({y, m, d}) when is_date(y, m, d), do: Timex.days_in_month(y, m)
  def days_in_month({{y, m, d}, _}) when is_date(y, m, d), do: Timex.days_in_month(y, m)
  def days_in_month(_), do: {:error, :invalid_date}

  def week_of_month({y, m, d}) when is_date(y, m, d), do: Timex.week_of_month(y, m, d)
  def week_of_month({{y, m, d}, _}) when is_date(y, m, d), do: Timex.week_of_month(y, m, d)
  def week_of_month(_), do: {:error, :invalid_date}

  def weekday({y, m, d} = date) when is_date(y, m, d), do: :calendar.day_of_the_week(date)
  def weekday({{y, m, d} = date, _}) when is_date(y, m, d), do: :calendar.day_of_the_week(date)
  def weekday(_), do: {:error, :invalid_date}

  def weekday({y, m, d}, weekstart) when is_date(y, m, d),
    do: Timex.Date.day_of_week(Timex.Date.new!(y, m, d), weekstart)

  def weekday({{y, m, d}, _}, weekstart) when is_date(y, m, d),
    do: Timex.Date.day_of_week(Timex.Date.new!(y, m, d), weekstart)

  def weekday(_, _), do: {:error, :invalid_date}

  def day({y, m, d} = date) when is_date(y, m, d),
    do: 1 + Timex.diff(date, {y, 1, 1}, :days)

  def day({{y, m, d} = date, _}) when is_date(y, m, d),
    do: 1 + Timex.diff(date, {y, 1, 1}, :days)

  def day(_), do: {:error, :invalid_date}

  def is_valid?({y, m, d}) when is_date(y, m, d), do: true
  def is_valid?({{y, m, d}, {h, mm, s}}) when is_datetime(y, m, d, h, mm, s), do: true
  def is_valid?({{y, m, d}, {h, mm, s, _us}}) when is_datetime(y, m, d, h, mm, s), do: true
  def is_valid?(_), do: false

  def iso_week({y, m, d}) when is_date(y, m, d),
    do: Timex.iso_week(y, m, d)

  def iso_week({{y, m, d}, _}) when is_date(y, m, d),
    do: Timex.iso_week(y, m, d)

  def iso_week(_), do: {:error, :invalid_date}

  def from_iso_day({y, m, d}, day) when is_day_of_year(day) and is_date(y, m, d) do
    {year, month, day_of_month} = Timex.Helpers.iso_day_to_date_tuple(y, day)
    {year, month, day_of_month}
  end

  def from_iso_day({{y, m, d}, {_, _, _} = time}, day)
      when is_day_of_year(day) and is_date(y, m, d) do
    {year, month, day_of_month} = Timex.Helpers.iso_day_to_date_tuple(y, day)
    {{year, month, day_of_month}, time}
  end

  def from_iso_day({{y, m, d}, {_, _, _, _} = time}, day)
      when is_day_of_year(day) and is_date(y, m, d) do
    {year, month, day_of_month} = Timex.Helpers.iso_day_to_date_tuple(y, day)
    {{year, month, day_of_month}, time}
  end

  def from_iso_day(_, _), do: {:error, :invalid_date}

  def set({y, m, d}, options) when is_date(y, m, d) do
    with %Date{} = date <- Timex.Set.set(%Date{year: y, month: m, day: d}, options) do
      {date.year, date.month, date.day}
    end
  end

  def set({{y, m, d}, {h, mm, s}}, options) when is_datetime(y, m, d, h, mm, s) do
    with %NaiveDateTime{} = date <- set_datetime(y, m, d, h, mm, s, {0, 0}, options) do
      {{date.year, date.month, date.day}, {date.hour, date.minute, date.second}}
    end
  end

  def set({{y, m, d}, {h, mm, s, us}}, options) when is_datetime(y, m, d, h, mm, s) do
    with %NaiveDateTime{} = date <- set_datetime(y, m, d, h, mm, s, us, options) do
      {{date.year, date.month, date.day}, {date.hour, date.minute, date.second, date.microsecond}}
    end
  end

  def set(_, _), do: {:error, :invalid_date}

  defp set_datetime(y, m, d, h, mm, s, us, options) do
    Timex.Set.set(
      %NaiveDateTime{year: y, month: m, day: d, hour: h, minute: mm, second: s, microsecond: us},
      options
    )
  end

  def shift(date, [{_, 0}]),
    do: date

  def shift({y, m, d} = date, options) when is_date(y, m, d),
    do: do_shift(date, options, :date)

  def shift({{y, m, d}, {h, mm, s}} = datetime, options) when is_datetime(y, m, d, h, mm, s),
    do: do_shift(datetime, options, :datetime)

  def shift({{y, m, d}, {h, mm, s, _us}} = datetime, options) when is_datetime(y, m, d, h, mm, s),
    do: do_shift(datetime, options, :datetime)

  def shift(_, _), do: {:error, :invalid_date}

  defp to_erl_datetime({y, m, d} = date) when is_date(y, m, d),
    do: {:ok, {date, {0, 0, 0}}}

  defp to_erl_datetime({{y, m, d}, {h, mm, s}} = dt) when is_datetime(y, m, d, h, mm, s),
    do: {:ok, dt}

  defp to_erl_datetime({{y, m, d}, {h, mm, s, _us}}) when is_datetime(y, m, d, h, mm, s),
    do: {:ok, {{y, m, d}, {h, mm, s}}}

  defp to_erl_datetime(_),
    do: {:error, :invalid_date}

  defp get_microseconds({_, _, _, us}) when is_integer(us),
    do: us

  defp get_microseconds({_, _, _, {us, _precision}}) when is_integer(us),
    do: us

  defp get_microseconds({_, _, _}),
    do: 0

  defp get_microseconds({date, time}) when is_tuple(date) and is_tuple(time),
    do: get_microseconds(time)

  defp do_shift(date, options, type) do
    allowed_options =
      Enum.reject(options, fn
        {:weeks, _} ->
          false

        {:days, _} ->
          false

        {:hours, value} when value >= 24 or value <= -24 ->
          true

        {:hours, _} ->
          false

        {:minutes, value} when value >= 24 * 60 or value <= -24 * 60 ->
          true

        {:minutes, _} ->
          false

        {:seconds, value} when value >= 24 * 60 * 60 or value <= -24 * 60 * 60 ->
          true

        {:seconds, _} ->
          false

        {:milliseconds, value}
        when value >= 24 * 60 * 60 * 1000 or value <= -24 * 60 * 60 * 1000 ->
          true

        {:milliseconds, _} ->
          false

        {:microseconds, {value, _}}
        when value >= 24 * 60 * 60 * 1000 * 1000 or value <= -24 * 60 * 60 * 1000 * 1000 ->
          true

        {:microseconds, value}
        when value >= 24 * 60 * 60 * 1000 * 1000 or value <= -24 * 60 * 60 * 1000 * 1000 ->
          true

        {:microseconds, _} ->
          false

        {_type, _value} ->
          true
      end)

    case Timex.shift(to_naive_datetime(date), allowed_options) do
      {:error, _} = err ->
        err

      %NaiveDateTime{} = nd when type == :date ->
        {nd.year, nd.month, nd.day}

      %NaiveDateTime{} = nd when type == :datetime ->
        {{nd.year, nd.month, nd.day}, {nd.hour, nd.minute, nd.second}}
    end
  end
end

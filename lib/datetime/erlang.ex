defimpl Timex.Protocol, for: Tuple do
  alias Timex.Types
  import Timex.Macros

  @epoch :calendar.datetime_to_gregorian_seconds({{1970,1,1},{0,0,0}})

  @spec to_julian(Types.date | Types.datetime) :: integer
  def to_julian({y,m,d}) when is_date(y,m,d) do
    Timex.Calendar.Julian.julian_date(y, m, d)
  end
  def to_julian({{y,m,d},_}) when is_date(y,m,d) do
    Timex.Calendar.Julian.julian_date(y, m, d)
  end
  def to_julian(_), do: {:error, :invalid_date}

  @spec to_gregorian_seconds(Types.date | Types.datetime) :: integer
  def to_gregorian_seconds({y,m,d} = date) when is_date(y,m,d),
    do: :calendar.datetime_to_gregorian_seconds({date,{0,0,0}})
  def to_gregorian_seconds({{y,m,d},{h,mm,s}} = dt) when is_datetime(y,m,d,h,mm,s),
    do: :calendar.datetime_to_gregorian_seconds(dt)
  def to_gregorian_seconds(_), do: {:error, :invalid_date}

  @spec to_gregorian_microseconds(Types.date | Types.datetime) :: integer
  def to_gregorian_microseconds({y,m,d} = date) when is_date(y,m,d),
    do: (to_gregorian_seconds(date)*(1_000*1_000))
  def to_gregorian_microseconds({{y,m,d},{h,mm,s}} = date) when is_datetime(y,m,d,h,mm,s),
    do: (to_gregorian_seconds(date)*(1_000*1_000))
  def to_gregorian_microseconds(_), do: {:error, :invalid_date}

  @spec to_unix(Types.date | Types.datetime) :: integer
  def to_unix({y,m,d} = date) when is_date(y,m,d),
    do: (:calendar.datetime_to_gregorian_seconds({date,{0,0,0}}) - @epoch)
  def to_unix({{y,m,d},{h,mm,s}} = dt) when is_datetime(y,m,d,h,mm,s),
    do: (:calendar.datetime_to_gregorian_seconds(dt) - @epoch)
  def to_unix(_), do: {:error, :invalid_date}

  @spec to_date(Types.date | Types.datetime) :: Date.t
  def to_date({y,m,d}) when is_date(y,m,d),
    do: %Date{year: y, month: m, day: d}
  def to_date({{y,m,d},_}) when is_date(y,m,d),
    do: %Date{year: y, month: m, day: d}
  def to_date(_), do: {:error, :invalid_date}

  @spec to_datetime(Types.date | Types.datetime, Types.valid_timezone) ::
    DateTime.t | {:error, term}
  def to_datetime({y,m,d} = date, timezone) when is_date(y,m,d) do
    Timex.DateTime.Helpers.construct({date, {0,0,0}}, timezone)
  end
  def to_datetime({{y,m,d},{h,mm,s}} = dt, timezone) when is_datetime(y,m,d,h,mm,s) do
    Timex.DateTime.Helpers.construct(dt, timezone)
  end
  def to_date(_, _), do: {:error, :invalid_date}

  @spec to_naive_datetime(Types.date | Types.datetime) :: NaiveDateTime.t
  def to_naive_datetime({y,m,d}) when is_date(y,m,d) do
    %NaiveDateTime{year: y, month: m, day: d, hour: 0, minute: 0, second: 0, microsecond: {0,0}}
  end
  def to_naive_datetime({{y,m,d},{h,mm,s}}) when is_datetime(y,m,d,h,mm,s) do
    %NaiveDateTime{year: y, month: m, day: d, hour: h, minute: mm, second: s, microsecond: {0,0}}
  end
  def to_naive_datetime(_), do: {:error, :invalid_date}

  @spec to_erl(Types.date | Types.datetime) :: Types.date | Types.datetime
  def to_erl({y,m,d} = date) when is_date(y,m,d), do: date
  def to_erl({{y,m,d},{h,mm,s}} = dt) when is_datetime(y,m,d,h,mm,s), do: dt
  def to_erl(_), do: {:error, :invalid_date}

  @spec century(Types.date | Types.datetime) :: non_neg_integer
  def century({y,m,d}) when is_date(y,m,d),     do: Timex.century(y)
  def century({{y,m,d},_}) when is_date(y,m,d), do: Timex.century(y)
  def century(_), do: {:error, :invalid_date}

  @spec is_leap?(Types.date | Types.datetime) :: boolean
  def is_leap?({y,m,d}) when is_date(y,m,d), do: :calendar.is_leap_year(y)
  def is_leap?({{y,m,d},{h,mm,s}}) when is_datetime(y,m,d,h,mm,s), do: :calendar.is_leap_year(y)
  def is_leap?(_), do: {:error, :invalid_date}

  @spec beginning_of_day(Types.date | Types.datetime) :: Types.date | Types.datetime
  def beginning_of_day({y,m,d} = date) when is_date(y,m,d), do: date
  def beginning_of_day({{y,m,d}=date,{h,mm,s}}) when is_datetime(y,m,d,h,mm,s),
    do: {date, {0,0,0}}
  def beginning_of_day(_), do: {:error, :invalid_date}

  @spec end_of_day(Types.date | Types.datetime) :: Types.date | Types.datetime
  def end_of_day({y,m,d} = date) when is_date(y,m,d), do: date
  def end_of_day({{y,m,d}=date,{h,mm,s}}) when is_datetime(y,m,d,h,mm,s),
    do: {date, {23,59,59}}
  def end_of_day(_), do: {:error, :invalid_date}

  @spec beginning_of_week(Types.date | Types.datetime, Types.weekday) :: Types.date | Types.datetime
  def beginning_of_week({y,m,d} = date, weekstart) when is_date(y,m,d) do
    case Timex.days_to_beginning_of_week(date, weekstart) do
      {:error, _} = err -> err
      days -> shift(date, [days: -days])
    end
  end
  def beginning_of_week({{y,m,d},{h,mm,s}} = date, weekstart) when is_datetime(y,m,d,h,mm,s) do
    case Timex.days_to_beginning_of_week(date, weekstart) do
      {:error, _} = err -> err
      days -> beginning_of_day(shift(date, [days: -days]))
    end
  end
  def beginning_of_week(_,_), do: {:error, :invalid_date}

  @spec end_of_week(Types.date | Types.datetime, Types.weekday) :: Types.date | Types.datetime
  def end_of_week({y,m,d} = date, weekstart) when is_date(y,m,d) do
    case Timex.days_to_end_of_week(date, weekstart) do
      {:error, _} = err -> err
      days_to_end ->
        shift(date, [days: days_to_end])
    end
  end
  def end_of_week({{y,m,d},{h,mm,s}} = date, weekstart) when is_datetime(y,m,d,h,mm,s) do
    case Timex.days_to_end_of_week(date, weekstart) do
      {:error, _} = err -> err
      days_to_end ->
        end_of_day(shift(date, [days: days_to_end]))
    end
  end
  def end_of_week(_,_), do: {:error, :invalid_date}

  @spec beginning_of_year(Types.date | Types.datetime) :: Types.date | Types.datetime
  def beginning_of_year({y,m,d}) when is_date(y,m,d),
    do: {y,1,1}
  def beginning_of_year({{y,m,d},{h,mm,s}}) when is_datetime(y,m,d,h,mm,s),
    do: {{y,1,1},{0,0,0}}
  def beginning_of_year(_), do: {:error, :invalid_date}

  @spec end_of_year(Types.date | Types.datetime) :: Types.date | Types.datetime
  def end_of_year({y,m,d}) when is_date(y,m,d),
    do: {y,12,31}
  def end_of_year({{y,m,d},{h,mm,s}}) when is_datetime(y,m,d,h,mm,s),
    do: {{y,12,31},{23,59,59}}
  def end_of_year(_), do: {:error, :invalid_date}

  @spec beginning_of_quarter(Types.date | Types.datetime) :: Types.date | Types.datetime
  def beginning_of_quarter({y,m,d}) when is_date(y,m,d) do
    month = 1 + (3 * (Timex.quarter(m) - 1))
    {y,month,1}
  end
  def beginning_of_quarter({{y,m,d},{h,mm,s} = time}) when is_datetime(y,m,d,h,mm,s) do
    month = 1 + (3 * (Timex.quarter(m) - 1))
    {{y,month,1},time}
  end
  def beginning_of_quarter(_), do: {:error, :invalid_date}

  @spec end_of_quarter(Types.date | Types.datetime) :: Types.date | Types.datetime
  def end_of_quarter({y,m,d}) when is_date(y,m,d) do
    month = 3 * Timex.quarter(m)
    end_of_month({y,month,d})
  end
  def end_of_quarter({{y,m,d},{h,mm,s} = time}) when is_datetime(y,m,d,h,mm,s) do
    month = 3 * Timex.quarter(m)
    end_of_month({{y,month,d}, time})
  end
  def end_of_quarter(_), do: {:error, :invalid_date}

  @spec beginning_of_month(Types.date | Types.datetime) :: Types.date | Types.datetime
  def beginning_of_month({y,m,d}) when is_date(y,m,d),
    do: {y,m,1}
  def beginning_of_month({{y,m,d},{h,mm,s}}) when is_datetime(y,m,d,h,mm,s),
    do: {{y,m,1},{0,0,0}}
  def beginning_of_month(_), do: {:error, :invalid_date}

  @spec end_of_month(Types.date | Types.datetime) :: Types.date | Types.datetime
  def end_of_month({y,m,d} = date) when is_date(y,m,d),
    do: {y,m,days_in_month(date)}
  def end_of_month({{y,m,d},{h,mm,s}} = date) when is_datetime(y,m,d,h,mm,s),
    do: {{y,m,days_in_month(date)},{23,59,59}}
  def end_of_month(_), do: {:error, :invalid_date}

  @spec quarter(Types.date | Types.datetime) :: integer
  def quarter({y,m,d}) when is_date(y,m,d), do: Timex.quarter(m)
  def quarter({{y,m,d},{h,mm,s}}) when is_datetime(y,m,d,h,mm,s), do: Timex.quarter(m)
  def quarter(_), do: {:error, :invalid_date}

  def days_in_month({y,m,d}) when is_date(y,m,d), do: Timex.days_in_month(y, m)
  def days_in_month({{y,m,d},_}) when is_date(y,m,d), do: Timex.days_in_month(y, m)
  def days_in_month(_), do: {:error, :invalid_date}

  def week_of_month({y,m,d}) when is_date(y,m,d), do: Timex.week_of_month(y,m,d)
  def week_of_month({{y,m,d},_}) when is_date(y,m,d), do: Timex.week_of_month(y,m,d)
  def week_of_month(_), do: {:error, :invalid_date}

  def weekday({y,m,d} = date) when is_date(y,m,d), do: :calendar.day_of_the_week(date)
  def weekday({{y,m,d} = date,_}) when is_date(y,m,d), do: :calendar.day_of_the_week(date)
  def weekday(_), do: {:error, :invalid_date}

  def day({y,m,d} = date) when is_date(y,m,d),
    do: 1 + Timex.diff(date, {y,1,1}, :days)
  def day({{y,m,d} = date,_}) when is_date(y,m,d),
    do: 1 + Timex.diff(date, {y,1,1}, :days)
  def day(_), do: {:error, :invalid_date}

  def is_valid?({y,m,d}) when is_date(y,m,d), do: true
  def is_valid?({{y,m,d},{h,mm,s}}) when is_datetime(y,m,d,h,mm,s), do: true
  def is_valid?(_), do: false

  def iso_week({y,m,d}) when is_date(y,m,d),
    do: Timex.iso_week(y, m, d)
  def iso_week({{y,m,d}, _}) when is_date(y,m,d),
    do: Timex.iso_week(y, m, d)
  def iso_week(_), do: {:error, :invalid_date}

  def from_iso_day({y,m,d}, day) when is_day_of_year(day) and is_date(y,m,d) do
    {year, month, day_of_month} = Timex.Helpers.iso_day_to_date_tuple(y, day)
    {year, month, day_of_month}
  end
  def from_iso_day({{y,m,d},{_,_,_}=time}, day) when is_day_of_year(day) and is_date(y,m,d) do
    {year, month, day_of_month} = Timex.Helpers.iso_day_to_date_tuple(y, day)
    {{year, month, day_of_month}, time}
  end
  def from_iso_day(_,_), do: {:error, :invalid_date}

  @spec set(Types.date | Types.datetime, list({atom(), term})) :: Types.date | Types.datetime | {:error, term}
  def set({y,m,d} = d, options) when is_date(y,m,d),
    do: do_set({d,{0,0,0}}, options, :date)
  def set({{y,m,d},{h,mm,s}} = d, options) when is_datetime(y,m,d,h,mm,s),
    do: do_set(d, options, :datetime)
  def set(_,_), do: {:error, :invalid_date}

  defp do_set(date, options, datetime_type) do
    validate? = Keyword.get(options, :validate, true)
    Enum.reduce(options, date, fn
      _option, {:error, _} = err ->
        err
      option, result ->
        case option do
          {:validate, _} -> result
          {:datetime, {{_,_,_} = date, {_,_,_} = time} = dt} ->
            if validate? do
              case datetime_type do
                :date -> Timex.normalize(:date, date)
                :datetime ->
                  {Timex.normalize(:date, date), Timex.normalize(:time, time)}
              end
            else
              case datetime_type do
                :date -> date
                :datetime -> dt
              end
            end
          {:date, {_, _, _} = d} ->
            if validate? do
              case result do
                {_,_,_} -> Timex.normalize(:date, d)
                {{_,_,_}, {_,_,_} = t} -> {Timex.normalize(:date, d), t}
              end
            else
              case result do
                {_,_,_} -> d
                {{_,_,_}, {_,_,_} = t} -> {d,t}
              end
            end
          {:time, {_,_,_} = t} ->
            if validate? do
              case result do
                {_,_,_} -> date
                {{_,_,_}=d,{_,_,_}} -> {d, Timex.normalize(:time, t)}
              end
            else
              case result do
                {_,_,_} -> date
                {{_,_,_}=d,{_,_,_}} -> {d,t}
              end
            end
          {:day, d} ->
            {y,m,_} = date
            if validate? do
              case result do
                {y,m,_} -> {y,m, Timex.normalize(:day, {y,m,d})}
                {{y,m,_},{_,_,_}=t} -> {{y,m, Timex.normalize(:day, {y,m,d})}, t}
              end
            else
              case result do
                {y,m,_} -> {y,m,d}
                {{y,m,_}, {_,_,_} = t} -> {{y,m,d}, t}
              end
            end
          {:year, year} ->
            if validate? do
              case result do
                {_,m,d} -> {Timex.normalize(:year, year), m, d}
                {{_,m,d},{_,_,_} = t} -> {{Timex.normalize(:year, year),m,d}, t}
              end
            else
              case result do
                {_,m,d} -> {year,m,d}
                {{_,m,d},{_,_,_} = t} -> {{year,m,d}, t}
              end
            end
          {:month, month} ->
            if validate? do
              case result do
                {y,_,d} ->
                  {y, Timex.normalize(:month, month), Timex.normalize(:day, {y, month, d})}
                {{y,_,d},{_,_,_} = t} ->
                  {{y, Timex.normalize(:month, month),Timex.normalize(:day, {y, month, d})}, t}
              end
            else
              case result do
                {y,_,d} -> {y,month,d}
                {{y,_,d},{_,_,_} = t} -> {{y,month,d}, t}
              end
            end
          {:hour, hour} ->
            if validate? do
              case result do
                {_,_,_} -> result
                {{_,_,_} = d,{_,m,s}} -> {d, {Timex.normalize(:hour, hour),m,s}}
              end
            else
              case result do
                {_,_,_} -> result
                {{_,_,_} = d,{_,m,s}} -> {d, {hour,m,s}}
              end
            end
          {:minute, min} ->
            if validate? do
              case result do
                {_,_,_} -> result
                {{_,_,_} = d,{h,_,s}} -> {d, {h, Timex.normalize(:minute, min),s}}
              end
            else
              case result do
                {_,_,_} -> result
                {{_,_,_} = d,{h,_,s}} -> {d, {h,min,s}}
              end
            end
          {:second, sec} ->
            if validate? do
              case result do
                {_,_,_} -> result
                {{_,_,_} = d,{h,m,_}} -> {d, {h, m, Timex.normalize(:second, sec)}}
              end
            else
              case result do
                {_,_,_} -> result
                {{_,_,_} = d,{h,m,_}} -> {d, {h,m,sec}}
              end
            end
          {name, _} when name in [:timezone, :microsecond] ->
            result
          {option_name, _} ->
            {:error, {:bad_option, option_name}}
        end
      end)
  end

  @spec shift(Types.date | Types.datetime, list({atom(), term})) ::
    Types.date | Types.datetime | {:error, term}
  def shift(date, [{_, 0}]),
    do: date
  def shift({y,m,d}=date, options) when is_date(y,m,d),
    do: do_shift(date, options, :date)
  def shift({{y,m,d},{h,mm,s}}=datetime, options) when is_datetime(y,m,d,h,mm,s),
    do: do_shift(datetime, options, :datetime)
  def shift(_, _), do: {:error, :invalid_date}

  defp do_shift(date, options, type) do
    allowed_options = Enum.filter(options, fn
      {:hours, value} when value >= 24 or value <= -24 -> true
      {:hours, _} -> false
      {:minutes, value} when value >= 24*60 or value <= -24*60 -> true
      {:minutes, _} -> false
      {:seconds, value} when value >= 24*60*60 or value <= -24*60*60 -> true
      {:seconds, _} -> false
      {:milliseconds, value} when value >= 24*60*60*1000 or value <= -24*60*60*1000 -> true
      {:milliseconds, _} -> false
      {:microseconds, {value, _}} when value >= 24*60*60*1000*1000 or value <= -24*60*60*1000*1000 -> true
      {:microseconds, value} when value >= 24*60*60*1000*1000 or value <= -24*60*60*1000*1000 -> true
      {:microseconds, _} -> false
      {_type, _value} -> true
    end)
    case Timex.shift(to_naive_datetime(date), allowed_options) do
      {:error, _} = err -> err
      %NaiveDateTime{} = nd when type == :date ->
        {nd.year,nd.month,nd.day}
      %NaiveDateTime{} = nd when type == :datetime ->
        {{nd.year,nd.month,nd.day}, {nd.hour,nd.minute,nd.second}}
    end
  end

end

defimpl Timex.Convertable, for: Tuple do
  alias Timex.Date
  alias Timex.DateTime
  alias Timex.Time
  alias Timex.Convertable
  import Timex.Macros

  def to_gregorian({y, m, d} = date) when is_date(y,m,d) do
    case :calendar.valid_date(date) do
      true ->
        {date, {0, 0, 0}, {0, "UTC"}}
      false ->
        {:error, :invalid_date}
    end
  end
  def to_gregorian({mega, secs, micro}) when is_date_timestamp(mega,secs,micro) do
    DateTime.from_timestamp({mega, secs, micro}) |> Convertable.to_gregorian
  end
  def to_gregorian({{y, m, d} = date, {h, mm, s} = time}) when is_datetime(y,m,d,h,mm,s),
    do: {date, time, {0, "UTC"}}
  def to_gregorian(_),
    do: {:error, :badarg}

  def to_gregorian_seconds({y, m, d} = date) when is_date(y,m,d) do
    case :calendar.valid_date(date) do
      true  -> :calendar.datetime_to_gregorian_seconds({{y,m,d},{0,0,0}})
      false -> {:error, :invalid_date}
    end
  end
  def to_gregorian_seconds({{y, m, d} = date, {h, mm, s}} = datetime) when is_datetime(y,m,d,h,mm,s) do
    case :calendar.valid_date(date) do
      true  -> :calendar.datetime_to_gregorian_seconds(datetime)
      false -> {:error, :invalid_date}
    end
  end
  def to_gregorian_seconds(_),
    do: {:error, :badarg}

  def to_erlang_datetime({y, m, d} = date) when is_date(y,m,d) do
    case :calendar.valid_date(date) do
      true ->
        {date, {0, 0, 0}}
      false ->
        {:error, :invalid_date}
    end
  end
  def to_erlang_datetime({mega,secs,micro}) when is_date_timestamp(mega,secs,micro) do
    DateTime.from_timestamp({mega,secs,micro}) |> Convertable.to_erlang_datetime
  end
  def to_erlang_datetime({{y, m, d}, {h, mm, s}} = datetime) when is_datetime(y,m,d,h,mm,s),
    do: datetime
  def to_erlang_datetime(_),
    do: {:error, :badarg}

  def to_date({_,_,_} = date),                do: Date.from_erl(date)
  def to_date({{_,_,_}, {_,_,_}} = datetime), do: Date.from_erl(datetime)
  def to_date(_),                             do: {:error, :badarg}

  def to_datetime({_,_,_} = date),                do: DateTime.from_erl(date)
  def to_datetime({{_,_,_}, {_,_,_}} = datetime), do: DateTime.from_erl(datetime)
  def to_datetime(_),                             do: {:error, :badarg}

  def to_unix({y, m, d} = date) when is_date(y,m,d) do
    case :calendar.valid_date(date) do
      true  -> DateTime.to_seconds(DateTime.from_erl(date), :epoch)
      false -> {:error, :invalid_date}
    end
  end
  def to_unix({mega,secs,micro} = timestamp) when is_date_timestamp(mega,secs,micro) do
    Time.to_seconds(timestamp)
  end
  def to_unix({{_,_,_}, {_,_,_}} = datetime) do
    case DateTime.from_erl(datetime) do
      {:error, _} = err -> err
      %DateTime{} = dt  -> DateTime.to_seconds(dt, :epoch)
    end
  end
  def to_unix({{_,_,_}, {_,_,_,_}} = datetime) do
    case DateTime.from_erl(datetime) do
      {:error, _} = err -> err
      %DateTime{} = dt  -> DateTime.to_seconds(dt, :epoch)
    end
  end
  def to_unix(_), do: {:error, :badarg}

  def to_timestamp({y, m, d} = date) when is_date(y,m,d) do
    case Date.from_erl(date) do
      {:error, _} = err -> err
      %Date{} = dt      -> Date.to_timestamp(dt)
    end
  end
  def to_timestamp({{y, m, d}, {h, mm, s}} = datetime) when is_datetime(y,m,d,h,mm,s) do
    case Date.from_erl(datetime) do
      {:error, _} = err -> err
      %Date{} = dt -> Date.to_timestamp(dt)
    end
  end
end

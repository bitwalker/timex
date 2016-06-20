defmodule Timex.Date do
  @moduledoc """
  This module represents all functions specific to creating/manipulating/comparing Dates (year/month/day)
  """
  defstruct calendar: :gregorian, day: 1, month: 1, year: 0

  alias __MODULE__
  alias Timex.DateTime
  alias Timex.TimezoneInfo
  alias Timex.Helpers
  use Timex.Constants
  import Timex.Macros

  @type t :: %__MODULE__{}

  @doc """
  Returns today's date as a Date struct. If given a timezone, returns whatever "today" is in that timezone
  """
  @spec today() :: Date.t | {:error, term}
  @spec today(Types.valid_timezone) :: Date.t | {:error, term}
  def today,     do: now()
  def today(%TimezoneInfo{} = tz),         do: now(tz)
  def today(tz) when is_binary(tz),        do: now(tz)
  def today(tz) when tz in [:utc, :local], do: now(tz)
  def today(_), do: {:error, :invalid_timezone}

  @doc """
  Returns today's date as a Date struct. If given a timezone, returns whatever "today" is in that timezone
  """
  @spec now() :: Date.t | {:error, term}
  @spec now(Types.valid_timezone) :: DateTime.t | {:error, term}
  def now,                               do: from_erl(Helpers.calendar_universal_time())
  def now(tz) when is_binary(tz),        do: from(DateTime.now(tz))
  def now(%TimezoneInfo{} = tz),         do: from(DateTime.now(tz))
  def now(tz) when tz in [:utc, :local], do: from(DateTime.now(tz))
  def now(:days),                        do: to_days(now())
  def now(_), do: {:error, :invalid_timezone}

  @doc """
  Returns a Date representing the first day of year zero
  """
  @spec zero() :: Date.t
  def zero, do: from_erl({0, 1, 1})

  @doc """
  Returns a Date representing the date of the UNIX epoch
  """
  @spec epoch() :: DateTime.t
  @spec epoch(:seconds) :: DateTime.t
  def epoch, do: from_erl({1970, 1, 1})
  def epoch(:seconds), do: to_seconds(from_erl({1970, 1, 1}), :zero)
  def epoch(:secs) do
    IO.write :stderr, "warning: :secs is a deprecated unit name, use :seconds instead\n"
    epoch(:seconds)
  end

  @doc """
  Converts from a date/time value to a Date struct representing that date
  """
  @spec from(Types.valid_datetime | Types.dtz | Types.phoenix_datetime_select_params) :: Date.t | {:error, term}
  # From Timex types
  def from(%Date{} = date), do: date
  def from(%DateTime{year: y, month: m, day: d}), do: %Date{year: y, month: m, day: d}
  # From Erlang/Ecto datetime tuples
  def from({y,m,d} = date) when is_date(y,m,d),
    do: from_erl(date)
  def from({{y,m,d} = date, {h,mm,s}}) when is_datetime(y,m,d,h,mm,s),
    do: from_erl(date)
  def from({{y,m,d} = date, {h,mm,s,ms}}) when is_datetime(y,m,d,h,mm,s,ms),
    do: from_erl(date)
  # Phoenix datetime select value
  def from(%{"year" => _, "month" => _, "day" => _} = dt) do
    validated = Enum.reduce(dt, %{}, fn
      _, :error -> :error
    {key, value}, acc ->
        case Integer.parse(value) do
          {v, _} -> Map.put(acc, key, v)
          :error -> :error
        end
    end)
    case validated do
      %{"year" => y, "month" => m, "day" => d} ->
        from({{y,m,d},{0,0,0}})
      {:error, _} ->
        {:error, :invalid}
    end
  end
  def from(_), do: {:error, :invalid_date}

  @doc """
  WARNING: This is here to ease the migration to 2.x, but is deprecated.

  Converts a value of the provided type to a Date struct, relative to the reference date (:epoch or :zero)
  """
  def from(value, type, ref \\ :epoch)
  defdeprecated from(ts, :timestamp, ref), "use Date.from_timestamp/1 instead",
    do: from_timestamp(ts, ref)
  defdeprecated from(n, :us, ref), "use Date.from_microseconds/1 instead",
    do: from_microseconds(n, ref)
  defdeprecated from(n, :msecs, ref), "use Date.from_milliseconds/1 instead",
    do: from_milliseconds(n, ref)
  defdeprecated from(n, :secs, ref), "use Date.from_seconds/1 instead",
    do: from_seconds(n, ref)
  defdeprecated from(n, :days, ref), "use Date.from_days/1 instead",
    do: from_days(n, ref)

  @doc """
  Like from/1, but more explicit about it's inputs (Erlang date/datetime tuples only).
  """
  def from_erl({y,m,d}) when is_date(y,m,d) do
    case :calendar.valid_date({y,m,d}) do
      true  -> %Date{year: y, month: m, day: d}
      false -> {:error, :invalid_date}
    end
  end
  def from_erl({{y,m,d}, {_,_,_}}) when is_date(y,m,d),   do: from_erl({y,m,d})
  def from_erl({{y,m,d}, {_,_,_,_}}) when is_date(y,m,d), do: from_erl({y,m,d})
  def from_erl(_), do: {:error, :invalid_date}

  @doc """
  Given an Erlang timestamp, converts it to a Date struct representing the date of that timestamp
  """
  @spec from_timestamp(Types.timestamp, :epoch | :zero) :: Date.t | {:error, term}
  def from_timestamp(timestamp, ref \\ :epoch)
  def from_timestamp({mega,sec,micro} = timestamp, ref)
    when is_date_timestamp(mega,sec,micro) and ref in [:epoch, :zero]
    do
      case ok!(DateTime.from_timestamp(timestamp, ref)) do
        {:error, _} = err -> err
        {:ok, datetime} -> from(datetime)
      end
  end
  def from_timestamp(_, _), do: {:error, :badarg}

  @doc """
  Given an integer value representing days since the reference date (:epoch or :zero), returns
  a Date struct representing that date
  """
  @spec from_days(non_neg_integer, :epoch | :zero) :: Date.t | {:error, term}
  def from_days(n, ref \\ :epoch)
  def from_days(n, ref) when is_positive_number(n) and ref in [:epoch, :zero] do
    case ok!(DateTime.from_days(trunc(n), ref)) do
      {:error, _} = err -> err
      {:ok, datetime} -> from(datetime)
    end
  end
  def from_days(_, _), do: {:error, :badarg}

  @doc """
  Given an integer value representing seconds since the reference date (:epoch or :zero), returns
  a Date struct representing that date
  """
  @spec from_seconds(non_neg_integer, :epoch | :zero) :: Date.t | {:error, term}
  def from_seconds(n, ref \\ :epoch)
  def from_seconds(n, ref) when is_positive_number(n) and ref in [:epoch, :zero] do
    case ok!(DateTime.from_seconds(trunc(n), ref)) do
      {:error, _} = err -> err
      {:ok, datetime} -> from(datetime)
    end
  end
  def from_seconds(_, _), do: {:error, :badarg}

  @doc """
  Given an integer value representing milliseconds since the reference date (:epoch or :zero), returns
  a Date struct representing that date
  """
  @spec from_milliseconds(non_neg_integer, :epoch | :zero) :: Date.t | {:error, term}
  def from_milliseconds(n, ref \\ :epoch)
  def from_milliseconds(n, ref) when is_positive_number(n) and ref in [:epoch, :zero] do
    case ok!(DateTime.from_milliseconds(trunc(n), ref)) do
      {:error, _} = err -> err
      {:ok, datetime} -> from(datetime)
    end
  end
  def from_millisecond(_, _), do: {:error, :badarg}

  @doc """
  Given an integer value representing microseconds since the reference date (:epoch or :zero), returns
  a Date struct representing that date
  """
  @spec from_microseconds(non_neg_integer, :epoch | :zero) :: Date.t | {:error, term}
  def from_microseconds(n, ref \\ :epoch)
  def from_microseconds(n, ref) when is_positive_number(n) and ref in [:epoch, :zero] do
    case ok!(DateTime.from_microseconds(trunc(n), ref)) do
      {:error, _} = err -> err
      {:ok, datetime} -> from(datetime)
    end
  end
  def from_microseconds(_, _), do: {:error, :badarg}

  @doc """
  Convert a date to a timestamp value consumable by the Time module.

  See also `diff/2` if you want to specify an arbitrary reference date.

  ## Examples

    iex> #{__MODULE__}.epoch |> #{__MODULE__}.to_timestamp
    {0,0,0}

  """
  @spec to_timestamp(Date.t) :: Types.timestamp | {:error, term}
  @spec to_timestamp(Date.t, :epoch | :zero) :: Types.timestamp | {:error, term}
  def to_timestamp(date, ref \\ :epoch)
  def to_timestamp(%Date{} = date, ref) when ref in [:epoch, :zero] do
    case ok!(to_datetime(date)) do
      {:error, _} = err -> err
      {:ok, datetime} -> DateTime.to_timestamp(datetime, ref)
    end
  end
  def to_timestamp(_, _), do: {:error, :badarg}

  defdelegate to_secs(date),      to: __MODULE__, as: :to_seconds
  defdelegate to_secs(date, ref), to: __MODULE__, as: :to_seconds

  @doc """
  Convert a date to an integer number of seconds since Epoch or year 0.

  See also `Timex.diff/3` if you want to specify an arbitrary reference date.

  ## Examples

      iex> Timex.date({1999, 1, 2}) |> #{__MODULE__}.to_seconds
      915235200

  """
  @spec to_seconds(Date.t) :: integer | {:error, term}
  @spec to_seconds(Date.t, :epoch | :zero) :: integer | {:error, term}
  def to_seconds(date, ref \\ :epoch)
  def to_seconds(%Date{} = date, ref) when ref in [:epoch, :zero] do
    case ok!(to_datetime(date)) do
      {:error, _} = err -> err
      {:ok, datetime} -> DateTime.to_seconds(datetime, ref)
    end
  end
  def to_seconds(_, _), do: {:error, :badarg}

  @doc """
  Convert the date to an integer number of days since Epoch or year 0.

  See also `Timex.diff/3` if you want to specify an arbitray reference date.

  ## Examples

      iex> Timex.date({1970, 1, 15}) |> #{__MODULE__}.to_days
      14

  """
  @spec to_days(Date.t) :: integer | {:error, term}
  @spec to_days(Date.t, :epoch | :zero) :: integer | {:error, term}
  def to_days(date, ref \\ :epoch)
  def to_days(date, ref) when ref in [:epoch, :zero] do
    case ok!(to_datetime(date)) do
      {:error, _} = err -> err
      {:ok, datetime} -> DateTime.to_days(datetime, ref)
    end
  end
  def to_days(_, _), do: {:error, :badarg}

  @doc """
  Converts a Date to a DateTime in UTC
  """
  @spec to_datetime(Date.t) :: DateTime.t | {:error, term}
  def to_datetime(%DateTime{} = dt), do: dt
  def to_datetime(%Date{:year => y, :month => m, :day => d}) do
    %DateTime{:year => y, :month => m, :day => d, :timezone => %TimezoneInfo{}}
  end
  def to_datetime(_), do: {:error, :badarg}

  @doc """
  See docs for Timex.set/2 for details.
  """
  @spec set(Date.t, list({atom(), term})) :: Date.t | {:error, term}
  def set(%Date{} = date, options) do
    validate? = case options |> List.keyfind(:validate, 0, true) do
      {:validate, bool} -> bool
      _                 -> true
    end
    Enum.reduce(options, date, fn
      _option, {:error, _} = err ->
        err
      option, %Date{} = result ->
        case option do
          {:validate, _} -> result
          {:datetime, {{y, m, d}, {_, _, _}}} ->
            if validate? do
              %{result |
                :year =>   Timex.normalize(:year,   y),
                :month =>  Timex.normalize(:month,  m),
                :day =>    Timex.normalize(:day,    {y,m,d}),
              }
            else
              %{result | :year => y, :month => m, :day => d}
            end
          {:date, {y, m, d}} ->
            if validate? do
              {yn,mn,dn} = Timex.normalize(:date, {y,m,d})
              %{result | :year => yn, :month => mn, :day => dn}
            else
              %{result | :year => y, :month => m, :day => d}
            end
          {:day, d} ->
            if validate? do
              %{result | :day => Timex.normalize(:day, {result.year, result.month, d})}
            else
              %{result | :day => d}
            end
          {name, val} when name in [:year, :month] ->
            if validate? do
              Map.put(result, name, Timex.normalize(name, val))
            else
              Map.put(result, name, val)
            end
          {:ms, _} ->
            IO.write :stderr, "warning: using :ms with shift is deprecated, use :millisecond instead"
            result
          {name, _} when name in [:time, :timezone, :hour, :minute, :second] ->
            result
          {option_name, _}   ->
            {:error, {:invalid_option, option_name}}
        end
    end)
  end

  @doc """
  See docs for `Timex.compare/3`
  """
  defdelegate compare(a, b), to: Timex.Comparable
  defdelegate compare(a, b, granularity), to: Timex.Comparable

  @doc """
  See docs for `Timex.diff/3`
  """
  defdelegate diff(a, b), to: Timex.Comparable
  defdelegate diff(a, b, granularity), to: Timex.Comparable

  @doc """
  Shifts the given Date based on the provided options.
  See Timex.shift/2 for more information.
  """
  @spec shift(Date.t, list({atom(), term})) :: Date.t | {:error, term}
  def shift(%Date{} = date, [{_, 0}]),               do: date
  def shift(%Date{} = date, [timestamp: {0,0,0}]),   do: date
  def shift(%Date{} = date, options) do
    allowed_options = Enum.filter(options, fn
      {:hours, value} when value >= 24 or value <= -24 -> true
      {:hours, _} -> false
      {:mins, value} when value >= 24*60 or value <= -24*60 ->
        IO.write :stderr, "warning: :mins is a deprecated unit name, use :minutes instead"
        true
      {:mins, _} ->
        IO.write :stderr, "warning: :mins is a deprecated unit name, use :minutes instead"
        false
      {:minutes, value} when value >= 24*60 or value <= -24*60 -> true
      {:minutes, _} -> false
      {:secs, value} when value >= 24*60*60 or value <= -24*60*60 ->
        IO.write :stderr, "warning: :secs is a deprecated unit name, use :seconds instead"
        true
      {:secs, _} ->
        IO.write :stderr, "warning: :secs is a deprecated unit name, use :seconds instead"
        false
      {:seconds, value} when value >= 24*60*60 or value <= -24*60*60 -> true
      {:seconds, _} -> false
      {:msecs, value} when value >= 24*60*60*1000 or value <= -24*60*60*1000 ->
        IO.write :stderr, "warning: :msecs is a deprecated unit name, use :milliseconds instead"
        true
      {:msecs, _} ->
        IO.write :stderr, "warning: :msecs is a deprecated unit name, use :milliseconds instead"
        false
      {:milliseconds, value} when value >= 24*60*60*1000 or value <= -24*60*60*1000 -> true
      {:milliseconds, _} -> false
      {_type, _value} -> true
    end)
    case DateTime.shift(to_datetime(date), allowed_options) do
      {:error, _} = err -> err
      datetime -> from(datetime)
    end
  end
  def shift(_, _), do: {:error, :badarg}

end

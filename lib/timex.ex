defmodule Timex do
  @moduledoc File.read!("README.md")

  defmacro __using__(_) do
    quote do
      alias Timex.DateTime
      alias Timex.AmbiguousDateTime
      alias Timex.Date
      alias Timex.Time
      alias Timex.Interval
      alias Timex.TimezoneInfo
      alias Timex.AmbiguousTimezoneInfo
      alias Timex.Timezone
      alias Timex.Convertable
    end
  end

  alias Timex.Date
  alias Timex.DateTime
  alias Timex.AmbiguousDateTime
  alias Timex.Timezone
  alias Timex.TimezoneInfo
  alias Timex.AmbiguousTimezoneInfo
  alias Timex.Types
  alias Timex.Helpers
  alias Timex.Convertable
  alias Timex.Comparable
  alias Timex.Translator
  use Timex.Constants
  import Timex.Macros

  @doc """
  Creates a new Date value, which represents the first day of year zero.

  If a date/time value is provided, it will convert it to a Date struct.
  """
  @spec date(Timex.Convertable.t) :: Date.t | {:error, term}
  defdelegate date(from), to: Timex.Convertable, as: :to_date

  @doc """
  Creates a new DateTime value, which represents the first moment of the first day of year zero.

  The provided date/time value will be converted via the `Timex.Convertable` protocol.
  """
  @spec datetime(Convertable.t) :: DateTime.t | {:error, term}
  defdelegate datetime(from), to: Timex.Convertable, as: :to_datetime

  @doc """
  Same as `datetime/1`, except this version returns a DateTime or AmbiguousDateTime in the provided timezone.
  """
  @spec datetime(Convertable.t, Types.valid_timezone) :: DateTime.t | AmbiguousDateTime.t | {:error, term}
  def datetime(from, timezone) do
    case Convertable.to_datetime(from) do
      {:error, _} = err ->
        err
      %DateTime{} = datetime ->
        case Timezone.name_of(timezone) do
          {:error, _} = err ->
            err
          name ->
            seconds_from_zeroyear = DateTime.to_seconds(datetime, :zero)
            case Timezone.resolve(name, seconds_from_zeroyear) do
              {:error, _} = err ->
                err
              %TimezoneInfo{} = tzinfo ->
                %{datetime | :timezone => tzinfo}
              %AmbiguousTimezoneInfo{:before => b, :after => a} ->
                %AmbiguousDateTime{:before => %{datetime | :timezone => b},
                                   :after  => %{datetime | :timezone => a}}
            end
        end
    end
  end

  @doc """
  WARNING: Added to ease the migration to 2.x, but it is deprecated.

  Returns a DateTime, like the old `Date.from/1` API
  """
  def from(from) do
    IO.write :stderr, "warning: Timex.from/1 is deprecated, use Timex.date/1 or Timex.datetime/1 instead\n"
    Convertable.to_datetime(from)
  end
  @doc """
  WARNING: Added to ease the migration to 2.x, but it is deprecated.
           Use Timex.date/1 or Timex.datetime/2 instead.

  Returns a DateTime, like the old `Date.from/2` API
  """
  def from(from, timezone) do
    IO.write :stderr, "warning: Timex.from/1 is deprecated, use Timex.date/1 or Timex.datetime/1 instead\n"
    Timex.datetime(from, timezone)
  end

  @doc """
  Convert a date/time value to a Gregorian calendar datetme+timezone tuple.
  i.e. { {year, month, day}, {hour, minute, second}, {offset_hours, timezone_abbreviation}}
  """
  @spec to_gregorian(Convertable.t) :: Types.gregorian | {:error, term}
  defdelegate to_gregorian(datetime), to: Convertable

  @doc """
  Convert a date/time value to a Julian calendar date number
  """
  @spec to_julian(Convertable.t) :: float
  defdelegate to_julian(datetime), to: Convertable

  @doc """
  Convert a date/time value to gregorian seconds (seconds since start of year zero)
  """
  @spec to_gregorian_seconds(Convertable.t) :: non_neg_integer | {:error, term}
  defdelegate to_gregorian_seconds(datetime), to: Convertable

  @doc """
  Convert a date/time value to a standard Erlang datetme tuple.
  i.e. { {year, month, day}, {hour, minute, second} }
  """
  @spec to_erlang_datetime(Convertable.t) :: Types.datetime | {:error, term}
  defdelegate to_erlang_datetime(datetime), to: Convertable

  @doc """
  Convert a date/time value to a Date struct
  """
  @spec to_date(Convertable.t) :: Date.t | {:error, term}
  defdelegate to_date(datetime), to: Convertable

  @doc """
  Convert a date/time value to a DateTime struct
  """
  @spec to_datetime(Convertable.t) :: DateTime.t | {:error, term}
  defdelegate to_datetime(datetime), to: Convertable

  @doc """
  Convert a date/time value to seconds since the UNIX epoch
  """
  @spec to_unix(Convertable.t) :: non_neg_integer | {:error, term}
  defdelegate to_unix(datetime), to: Convertable

  @doc """
  Convert a date/time value to an Erlang timestamp
  """
  @spec to_timestamp(Convertable.t) :: Types.timestamp | {:error, term}
  defdelegate to_timestamp(datetime), to: Convertable

  @doc """
  Formats a date/time value using the given format string (and optional formatter).

  See Timex.Format.DateTime.Formatters.Default or Timex.Format.DateTime.Formatters.Strftime
  for documentation on the syntax supported by those formatters.

  To use the Default formatter, simply call format/2. To use the Strftime formatter, you
  can either alias and pass Strftime by module name, or as a shortcut, you can pass :strftime
  instead.

  Formatting uses the Convertable protocol to convert non-DateTime structs to DateTime structs.

  ## Examples

      iex> date = Timex.date({2016, 2, 29})
      ...> Timex.format!(date, "{YYYY}-{0M}-{D}")
      "2016-02-29"

      iex> Timex.format!({{2016,2,29},{22,25,0}}, "{ISO:Extended}")
      "2016-02-29T22:25:00+00:00"
  """
  @spec format(Convertable.t, format :: String.t) :: {:ok, String.t} | {:error, term}
  defdelegate format(datetime, format_string), to: Timex.Format.DateTime.Formatter

  @doc """
  Same as format/2, except using a custom formatter

  ## Examples

      iex> use Timex
      ...> datetime = Timex.datetime({{2016,2,29},{22,25,0}}, "America/Chicago")
      iex> Timex.format!(datetime, "%FT%T%:z", :strftime)
      "2016-02-29T22:25:00-06:00"
  """
  @spec format(Convertable.t, format :: String.t, formatter :: atom) :: {:ok, String.t} | {:error, term}
  defdelegate format(datetime, format_string, formatter), to: Timex.Format.DateTime.Formatter

  @doc """
  Same as format/2, except takes a locale name to translate text to.

  Translations only apply to units, relative time phrases, and only for the locales in the
  list of supported locales in the Timex documentation.
  """
  @spec lformat(Convertable.t, format :: String.t, locale :: String.t) :: {:ok, String.t} | {:error, term}
  defdelegate lformat(datetime, format_string, locale), to: Timex.Format.DateTime.Formatter

  @doc """
  Same as lformat/3, except takes a formatter as it's last argument.

  Translations only apply to units, relative time phrases, and only for the locales in the
  list of supported locales in the Timex documentation.
  """
  @spec lformat(Convertable.t, format :: String.t, locale :: String.t, formatter :: atom) :: {:ok, String.t} | {:error, term}
  defdelegate lformat(datetime, format_string, locale, formatter), to: Timex.Format.DateTime.Formatter

  @doc """
  Same as format/2, except format! raises on error.

  See format/2 docs for usage examples.
  """
  @spec format!(Convertable.t, format :: String.t) :: String.t | no_return
  defdelegate format!(datetime, format_string), to: Timex.Format.DateTime.Formatter

  @doc """
  Same as format/3, except format! raises on error.

  See format/3 docs for usage examples
  """
  @spec format!(Convertable.t, format :: String.t, formatter :: atom) :: String.t | no_return
  defdelegate format!(datetime, format_string, formatter), to: Timex.Format.DateTime.Formatter

  @doc """
  Same as lformat/3, except local_format! raises on error.

  See lformat/3 docs for usage examples.
  """
  @spec lformat!(Convertable.t, format :: String.t, locale :: String.t) :: String.t | no_return
  defdelegate lformat!(datetime, format_string, locale), to: Timex.Format.DateTime.Formatter

  @doc """
  Same as lformat/4, except local_format! raises on error.

  See lformat/4 docs for usage examples
  """
  @spec lformat!(Convertable.t, format :: String.t, locale :: String.t, formatter :: atom) :: String.t | no_return
  defdelegate lformat!(datetime, format_string, locale, formatter), to: Timex.Format.DateTime.Formatter

  @doc """
  Formats a DateTime using a fuzzy relative duration, from now.

  ## Examples


      iex> use Timex
      ...> Timex.from_now(Timex.shift(DateTime.now, days: 2))
      "in 2 days"

      iex> use Timex
      ...> Timex.from_now(Timex.shift(DateTime.now, days: -2))
      "2 days ago"
  """
  @spec from_now(Convertable.t) :: String.t | {:error, term}
  def from_now(datetime), do: from_now(datetime, Timex.Translator.default_locale)

  @doc """
  Formats a DateTime using a fuzzy relative duration, translated using given locale

  ## Examples

      iex> use Timex
      ...> Timex.from_now(Timex.shift(DateTime.now, days: 2), "ru")
      "через 2 дней"

      iex> use Timex
      ...> Timex.from_now(Timex.shift(DateTime.now, days: -2), "ru")
      "2 дня назад"

  """
  @spec from_now(Convertable.t, String.t) :: String.t | {:error, term}
  def from_now(datetime, locale) when is_binary(locale) do
    case Convertable.to_datetime(datetime) do
      {:error, _} = err -> err
      %DateTime{} = dt ->
        case lformat(dt, "{relative}", locale, :relative) do
          {:ok, formatted}  -> formatted
          {:error, _} = err -> err
        end
    end
  end

  @doc """
  Formats a DateTime using a fuzzy relative duration, with a reference datetime other than now
  """
  @spec from_now(Convertable.t, Convertable.t) :: String.t | {:error, term}
  def from_now(datetime, reference_date), do: from_now(datetime, reference_date, Timex.Translator.default_locale)

  @doc """
  Formats a DateTime using a fuzzy relative duration, with a reference datetime other than now,
  translated using the given locale
  """
  @spec from_now(Convertable.t, Convertable.t, String.t) :: String.t | {:error, term}
  def from_now(datetime, reference_date, locale) when is_binary(locale) do
    case Convertable.to_datetime(datetime) do
      {:error, _} = err -> err
      %DateTime{} = dt ->
        case Convertable.to_datetime(reference_date) do
          {:error, _} = err -> err
          %DateTime{} = ref ->
            case Timex.Format.DateTime.Formatters.Relative.relative_to(dt, ref, "{relative}", locale) do
              {:ok, formatted}  -> formatted
              {:error, _} = err -> err
            end
        end
    end
  end

  @doc """
  Formats an Erlang timestamp using the ISO-8601 duration format, or optionally, with a custom
  formatter of your choosing.

  See Timex.Format.Time.Formatters.Default or Timex.Format.Time.Formatters.Humanized
  for documentation on the specific formatter behaviour.

  To use the Default formatter, simply call format_time/2. To use the Humanized formatter, you
  can either alias and pass Humanized by module name, or as a shortcut, you can pass :humanized
  instead.

  ## Examples

      iex> use Timex
      ...> date = Date.to_timestamp(Timex.date({2016, 2, 29}), :epoch)
      ...> Timex.format_time(date)
      "P46Y2M10D"

      iex> use Timex
      ...> date = Date.to_timestamp(Timex.date({2016, 2, 29}), :epoch)
      ...> Timex.format_time(date, :humanized)
      "46 years, 2 months, 1 week, 3 days"

      iex> use Timex
      ...> datetime = Timex.datetime({{2016, 2, 29}, {22, 25, 0}}) |> DateTime.to_timestamp
      ...> Timex.format_time(datetime, :humanized)
      "46 years, 2 months, 1 week, 3 days, 22 hours, 25 minutes"

  """
  @spec format_time(Types.timestamp) :: String.t | {:error, term}
  defdelegate format_time(timestamp), to: Timex.Format.Time.Formatter, as: :format

  @doc """
  Same as format_time/1, except it also accepts a formatter
  """
  @spec format_time(Types.timestamp, atom) :: String.t | {:error, term}
  defdelegate format_time(timestamp, formatter),
    to: Timex.Format.Time.Formatter, as: :format

  @doc """
  Same as format_time/1, except takes a locale for use in translation
  """
  @spec lformat_time(Types.timestamp, locale :: String.t) :: String.t | {:error, term}
  defdelegate lformat_time(timestamp, locale),
    to: Timex.Format.Time.Formatter, as: :lformat

  @doc """
  Same as lformat_time/2, except takes a formatter as an argument
  """
  @spec lformat_time(Types.timestamp, locale :: String.t, atom) :: String.t | {:error, term}
  defdelegate lformat_time(timestamp, locale, formatter),
    to: Timex.Format.Time.Formatter, as: :lformat

  @doc """
  Parses a datetime string into a DateTime struct, using the provided format string (and optional tokenizer).

  See Timex.Format.DateTime.Formatters.Default or Timex.Format.DateTime.Formatters.Strftime
  for documentation on the syntax supported in format strings by their respective tokenizers.

  To use the Default tokenizer, simply call parse/2. To use the Strftime tokenizer, you
  can either alias and pass Timex.Parse.DateTime.Tokenizer.Strftime by module name,
  or as a shortcut, you can pass :strftime instead.

  ## Examples

      iex> use Timex
      ...> expected = Timex.datetime({2016, 2, 29})
      ...> {:ok, result} = Timex.parse("2016-02-29", "{YYYY}-{0M}-{D}")
      ...> result == expected
      true

      iex> use Timex
      ...> expected = Timex.datetime({{2016, 2, 29}, {22, 25, 0}}, "America/Chicago")
      ...> {:ok, result} = Timex.parse("2016-02-29T22:25:00-06:00", "{ISO:Extended}")
      ...> Timex.equal?(expected, result)
      true

      iex> use Timex
      ...> expected = Timex.datetime({{2016, 2, 29}, {22, 25, 0}}, "America/Chicago")
      ...> {:ok, result} = Timex.parse("2016-02-29T22:25:00-06:00", "%FT%T%:z", :strftime)
      ...> Timex.equal?(expected, result)
      true

  """
  @spec parse(String.t, String.t) :: {:ok, Timex.DateTime.t} | {:error, term}
  @spec parse(String.t, String.t, atom) :: {:ok, Timex.DateTime.t} | {:error, term}
  defdelegate parse(datetime_string, format_string), to: Timex.Parse.DateTime.Parser
  defdelegate parse(datetime_string, format_string, tokenizer), to: Timex.Parse.DateTime.Parser

  @doc """
  Same as parse/2 and parse/3, except parse! raises on error.

  See parse/2 or parse/3 docs for usage examples.
  """
  @spec parse!(String.t, String.t) :: Timex.DateTime.t | no_return
  @spec parse!(String.t, String.t, atom) :: Timex.DateTime.t | no_return
  defdelegate parse!(datetime_string, format_string), to: Timex.Parse.DateTime.Parser
  defdelegate parse!(datetime_string, format_string, tokenizer), to: Timex.Parse.DateTime.Parser

  @doc """
  Given a format string, validates that the format string is valid for the Default formatter.

  Given a format string and a formatter, validates that the format string is valid for that formatter.

  ## Examples

      iex> use Timex
      ...> Timex.validate_format("{YYYY}-{M}-{D}")
      :ok

      iex> use Timex
      ...> Timex.validate_format("{YYYY}-{M}-{V}")
      {:error, "Expected end of input at line 1, column 11"}

      iex> use Timex
      ...> Timex.validate_format("%FT%T%:z", :strftime)
      :ok
  """
  @spec validate_format(String.t) :: :ok | {:error, term}
  @spec validate_format(String.t, atom) :: :ok | {:error, term}
  defdelegate validate_format(format_string),            to: Timex.Format.DateTime.Formatter, as: :validate
  defdelegate validate_format(format_string, formatter), to: Timex.Format.DateTime.Formatter, as: :validate

  @doc """
  Gets the current century

  ## Examples

  iex> #{__MODULE__}.century
  21

  """
  @spec century() :: non_neg_integer
  def century(), do: century(Date.today)

  @doc """
  Given a date, get the century this date is in.

  ## Examples

  iex> Timex.Date.today |> #{__MODULE__}.century
  21
  iex> Timex.DateTime.now |> #{__MODULE__}.century
  21
  iex> #{__MODULE__}.century(2016)
  21

  """
  @spec century(Convertable.t | Types.year) :: non_neg_integer | {:error, term}
  def century(date) when not is_integer(date) do
    case Convertable.to_date(date) do
      {:error, _} = err    -> err
      %Date{:year => year} -> century(year)
    end
  end
  def century(year) when is_integer(year) do
    base_century = div(year, 100)
    years_past   = rem(year, 100)
    cond do
      base_century == (base_century - years_past) -> base_century
      true -> base_century + 1
    end
  end

  @doc """
  Convert an iso ordinal day number to the day it represents in the current year.

   ## Examples

      iex> use Timex
      iex> %Date{:year => year} = Timex.from_iso_day(180)
      ...> %Date{:year => todays_year} = Date.today
      ...> year == todays_year
      true
  """
  @spec from_iso_day(non_neg_integer) :: Date.t | {:error, term}
  def from_iso_day(day) when is_day_of_year(day) do
    {{year,_,_},_} = :calendar.universal_time
    from_iso_day(day, year)
  end
  def from_iso_day(_), do: {:error, {:from_iso_day, :invalid_iso_day}}

  @doc """
  Same as from_iso_day/1, except you can expect the following based on the second parameter:

  - If an integer year is given, the result will be a Date struct
  - If a Date struct is given, the result will be a Date struct
  - If a DateTime struct is given, the result will be a DateTime struct
  - If a Convertable is given, the result will be a DateTime struct

  In all cases, the resulting value will be the date representation of the provided ISO day in that year

  ## Examples

  ### Creating a Date from the given day

      iex> use Timex
      ...> expected = Timex.date({2015, 6, 29})
      ...> (expected === Timex.from_iso_day(180, 2015))
      true

  ### Creating a Date/DateTime from the given day

      iex> use Timex
      ...> expected = Timex.datetime({{2015, 6, 29}, {0,0,0}})
      ...> (expected === Timex.from_iso_day(180, Timex.datetime({{2015,1,1}, {0,0,0}})))
      true

  ### Shifting a Date/DateTime to the given day

      iex> use Timex
      ...> date = Timex.datetime({{2015,6,26}, {12,0,0}})
      ...> expected = Timex.datetime({{2015, 6, 29}, {12,0,0}})
      ...> (Timex.from_iso_day(180, date) === expected)
      true
  """
  @spec from_iso_day(non_neg_integer, Types.year | Date.t | DateTime.t | Convertable.t) :: Date.t | DateTime.t | {:error, term}
  def from_iso_day(day, year) when is_day_of_year(day) and is_year(year) do
    datetime = Helpers.iso_day_to_date_tuple(year, day)
    Timex.date(datetime)
  end
  def from_iso_day(day, %Date{year: year} = date) when is_day_of_year(day) and is_year(year) do
    {year, month, day_of_month} = Helpers.iso_day_to_date_tuple(year, day)
    %{date | :year => year, :month => month, :day => day_of_month}
  end
  def from_iso_day(day, %DateTime{year: year} = date) when is_day_of_year(day) and is_year(year) do
    {year, month, day_of_month} = Helpers.iso_day_to_date_tuple(year, day)
    %{date | :year => year, :month => month, :day => day_of_month}
  end
  def from_iso_day(day, date) when is_day_of_year(day) do
    case Convertable.to_datetime(date) do
      {:error, _} = err -> err
      %DateTime{} = datetime ->
        from_iso_day(day, datetime)
    end
  end
  def from_iso_day(_, _),
    do: {:error, {:from_iso_day, :invalid_iso_day}}

  @doc """
  Return a pair {year, week number} (as defined by ISO 8601) that the given
  Date/DateTime value falls on.

  ## Examples

      iex> #{__MODULE__}.iso_week({1970, 1, 1})
      {1970,1}
  """
  @spec iso_week(Convertable.t) :: {Types.year, Types.weeknum} | {:error, term}

  def iso_week(%Date{:year => y, :month => m, :day => d}) when is_date(y,m,d),
    do: iso_week(y, m, d)
  def iso_week(%DateTime{:year => y, :month => m, :day => d}) when is_date(y,m,d),
    do: iso_week(y, m, d)
  def iso_week(date) do
    case Convertable.to_date(date) do
      {:error, _} = err ->
        err
      %Date{} = d ->
        iso_week(d)
    end
  end

  @doc """
  Same as iso_week/1, except this takes a year, month, and day as distinct arguments.

  ## Examples

      iex> #{__MODULE__}.iso_week(1970, 1, 1)
      {1970,1}
  """
  @spec iso_week(Types.year, Types.month, Types.day) :: {Types.year, Types.weeknum} | {:error, term}
  def iso_week(year, month, day) when is_date(year, month, day),
    do: :calendar.iso_week_number({year, month, day})
  def iso_week(_, _, _),
    do: {:error, {:iso_week, :invalid_date}}

  @doc """
  Return a 3-tuple {year, week number, weekday} for the given Date/DateTime.

  ## Examples

      iex> #{__MODULE__}.iso_triplet(Timex.DateTime.epoch)
      {1970, 1, 4}

  """
  @spec iso_triplet(Convertable.t) :: {Types.year, Types.weeknum, Types.weekday} | {:error, term}
  def iso_triplet(datetime) do
    case Convertable.to_date(datetime) do
      {:error, _} = err ->
        err
      %Date{} = d ->
        {iso_year, iso_week} = iso_week(d)
        {iso_year, iso_week, Timex.weekday(d)}
    end
  end

  @doc """
  Given an ISO triplet `{year, week number, weekday}`, convert it to a Date struct.

  ## Examples

      iex> expected = Timex.date({2014, 1, 28})
      iex> Timex.from_iso_triplet({2014, 5, 2}) === expected
      true

  """
  @spec from_iso_triplet(Types.iso_triplet) :: Date.t | {:error, term}
  def from_iso_triplet({year, week, weekday})
    when is_year(year) and is_week_of_year(week) and is_day_of_week(weekday, :mon)
      do
      {_, _, jan4weekday} = Date.from({year, 1, 4}) |> iso_triplet
      offset = jan4weekday + 3
      ordinal_date = ((week * 7) + weekday) - offset
      date = Helpers.iso_day_to_date_tuple(year, ordinal_date)
      Timex.date(date)
  end
  def from_iso_triplet(_, _, _), do: {:error, {:from_iso_triplet, :invalid_triplet}}

  @doc """
  Returns a list of all valid timezone names in the Olson database
  """
  @spec timezones() :: [String.t]
  def timezones(), do: Tzdata.zone_list

  @doc """
  Get a TimezoneInfo object for the specified offset or name.

  When offset or name is invalid, exception is raised.

  If no DateTime value is given for the second parameter, the current date/time
  will be used (in other words, it will return the current timezone info for the
  given zone). If one is provided, the timezone info returned will be based on
  the provided DateTime (or Erlang datetime tuple) value.

  ## Examples

      iex> date = Timex.datetime({2015, 4, 12})
      ...> tz = Timex.timezone(:utc, date)
      ...> tz.full_name
      "UTC"

      iex> tz = Timex.timezone("America/Chicago", {2015,4,12})
      ...> {tz.full_name, tz.abbreviation}
      {"America/Chicago", "CDT"}

      iex> tz = #{__MODULE__}.timezone(+2, {2015, 4, 12})
      ...> {tz.full_name, tz.abbreviation}
      {"Etc/GMT-2", "GMT-2"}

  """
  @spec timezone(Types.valid_timezone, Convertable.t) :: TimezoneInfo.t | AmbiguousTimezoneInfo.t

  def timezone(:utc, _),                 do: %TimezoneInfo{}
  def timezone(%TimezoneInfo{full_name: name}, datetime) do
    case Convertable.to_datetime(datetime) do
      {:error, _} = err ->
        err
      %DateTime{} = d ->
        seconds_from_zeroyear = DateTime.to_seconds(d, :zero)
        Timezone.resolve(name, seconds_from_zeroyear)
    end
  end
  def timezone(:local, datetime) do
    case Convertable.to_datetime(datetime) do
      {:error, _} = err ->
        err
      %DateTime{} = d ->
        Timezone.local(d)
    end
  end
  def timezone(tz, datetime) do
    case Convertable.to_datetime(datetime) do
      {:error, _} = err ->
        err
      %DateTime{} = d ->
        Timezone.get(tz, d)
    end
  end

  @doc """
  Return a boolean indicating whether the given date is valid.

  ## Examples

      iex> use Timex
      ...> Timex.is_valid?({{1,1,1},{1,1,1}})
      true

      iex> use Timex
      ...> %DateTime{} |> #{__MODULE__}.set([month: 13, validate: false]) |> #{__MODULE__}.is_valid?
      false

      iex> use Timex
      ...> %DateTime{} |> #{__MODULE__}.set(hour: -1) |> #{__MODULE__}.is_valid?
      false

  """
  @spec is_valid?(Convertable.t) :: boolean
  def is_valid?(%Date{:year => y, :month => m, :day => d}) do
    :calendar.valid_date({y,m,d})
  end
  def is_valid?(%DateTime{:year => y, :month => m, :day => d, :hour => h, :minute => min, :second => sec, :timezone => tz}) do
    :calendar.valid_date({y,m,d}) and is_valid_time?({h,min,sec}) and is_valid_timezone?(tz)
  end
  def is_valid?(datetime) do
    case Convertable.to_datetime(datetime) do
      {:error, _} -> false
      %DateTime{} -> true
    end
  end

  @doc """
  Returns a boolean indicating whether the provided term represents a valid time,
  valid times are one of:

  - `{hour, min, sec}`
  - `{hour, min, sec, ms}`

  """
  @spec is_valid_time?(term) :: boolean
  def is_valid_time?({hour,min,sec}) when is_time(hour,min,sec),       do: true
  def is_valid_time?({hour,min,sec,ms}) when is_time(hour,min,sec,ms), do: true
  def is_valid_time?(_), do: false

  @doc """
  Returns a boolean indicating whether the provided term represents a valid timezone,
  valid timezones are one of:

  - TimezoneInfo struct
  - A timezone name as a string
  - `:utc` as a shortcut for the UTC timezone
  - `:local` as a shortcut for the local timezone
  - A number representing an offset from UTC

  """
  @spec is_valid_timezone?(term) :: boolean
  def is_valid_timezone?(timezone) do
    case Timezone.name_of(timezone) do
      {:error, _} -> false
      _name       -> true
    end
  end

  @doc """
  Returns a boolean indicating whether the first `Timex.Comparable` occurs before the second
  """
  @spec before?(Comparable.comparable, Comparable.comparable) :: boolean | {:error, term}
  def before?(a, b), do: Comparable.compare(a, b) == -1

  @doc """
  Returns a boolean indicating whether the first `Timex.Comparable` occurs after the second
  """
  @spec after?(Comparable.comparable, Comparable.comparable) :: boolean | {:error, term}
  def after?(a, b), do: Comparable.compare(a, b) == 1

  @doc """
  Returns a boolean indicating whether the first `Timex.Comparable` occurs between the second and third
  """
  @spec between?(Comparable.comparable, Comparable.comparable, Comparable.comparable) :: boolean | {:error, term}
  def between?(a, start, ending) do
    is_after_start? = after?(a, start)
    is_before_end?  = before?(a, ending)
    case {is_after_start?, is_before_end?} do
      {{:error, _} = err, _} -> err
      {_, {:error, _} = err} -> err
      {true, true} -> true
      _ -> false
    end
  end

  @doc """
  Returns a boolean indicating whether the two `Timex.Comparable` values are equivalent.
  Equality here implies that the two Comparables represent the same moment in time,
  not equality of the data structure.

  ## Examples

      iex> date1 = Timex.date({2014, 3, 1})
      ...> date2 = Timex.date({2014, 3, 1})
      ...> #{__MODULE__}.equal?(date1, date2)
      true

      iex> date1 = Timex.date({2014, 3, 1})
      ...> date2 = Timex.datetime({2014, 3, 1})
      ...> #{__MODULE__}.equal?(date1, date2)
      true
  """
  @spec equal?(Date.t | DateTime.t, Date.t | DateTime.t) :: boolean | {:error, :badarg}
  def equal?(a, a), do: true
  def equal?(a, b), do: Comparable.compare(a, b, :seconds) == 0

  @doc """
  See docs for `compare/3`
  """
  @spec compare(Comparable.comparable, Comparable.comparable) :: Comparable.compare_result | {:error, term}
  defdelegate compare(a, b), to: Timex.Comparable

  @doc """
  Compare two `Timex.Comparable` values, returning one of the following values:

   * `-1` -- the first date comes before the second one
   * `0`  -- both arguments represent the same date when coalesced to the same timezone.
   * `1`  -- the first date comes after the second one

  You can provide a few reference constants for the second argument:

  - :epoch will compare the first parameter against the Date/DateTime of the first moment of the UNIX epoch
  - :zero will compare the first parameter against the Date/DateTime of the first moment of year zero
  - :distant_past will compare the first parameter against a date/time infinitely in the past (i.e. it will always return 1)
  - :distant_future will compare the first parameter against a date/time infinitely in the future (i.e. it will always return -1)

  You can optionally specify a comparison granularity, any of the following:

  - :years
  - :months
  - :weeks
  - :calendar_weeks (weeks of the calendar as opposed to actual weeks in terms of days)
  - :days
  - :hours
  - :minutes
  - :seconds
  - :timestamp

  and the dates will be compared with the cooresponding accuracy.
  The default granularity is :seconds.

  ## Examples

      iex> date1 = Timex.date({2014, 3, 4})
      iex> date2 = Timex.date({2015, 3, 4})
      iex> Timex.compare(date1, date2, :years)
      -1
      iex> Timex.compare(date2, date1, :years)
      1
      iex> Timex.compare(date1, date1)
      0

  """

  @spec compare(Comparable.comparable, Comparable.comparable, Comparable.granularity) :: Comparable.compare_result | {:error, term}
  defdelegate compare(a, b, granularity), to: Timex.Comparable

  @doc """
  See docs for `diff/3`
  """
  @spec diff(Comparable.comparable, Comparable.comparable) :: Types.timestamp | {:error, term}
  defdelegate diff(a, b), to: Timex.Comparable

  @doc """
  Calculate time interval between two dates. The result will always be a non-negative integer

  You must specify one of the following units:

  - :years
  - :months
  - :calendar_weeks (weeks of the calendar as opposed to actual weeks in terms of days)
  - :weeks
  - :days
  - :hours
  - :minutes
  - :seconds
  - :timestamp

  and the result will be an integer value of those units or a timestamp.
  """
  @spec diff(Timex.Comparable.comparable, Timex.Comparable.comparable, Timex.Comparable.granularity) :: Types.timestamp | non_neg_integer | {:error, term}
  defdelegate diff(a, b, granularity), to: Timex.Comparable


  @doc """
  Add time to a date using a timestamp, i.e. {megasecs, secs, microsecs}
  Same as shift(date, Time.to_timestamp(5, :minutes), :timestamp).
  """
  @spec add(Convertable.t, Types.timestamp) :: DateTime.t | {:error, term}
  def add(%Date{} = date, {mega,sec,_}),     do: shift(date, [seconds: (mega * @million) + sec])
  def add(%DateTime{} = date, {mega,sec,_}), do: shift(date, [seconds: (mega * @million) + sec])
  def add(datetime, {_,_,_} = timestamp) do
    case Convertable.to_datetime(datetime) do
      {:error, _} = err -> err
      %DateTime{} = d   -> add(d, timestamp)
    end
  end

  @doc """
  Subtract time from a date using a timestamp, i.e. {megasecs, secs, microsecs}
  Same as shift(date, Time.to_timestamp(5, :minutes) |> Time.invert, :timestamp).
  """
  @spec subtract(Convertable.t, Types.timestamp) :: DateTime.t | {:error, term}
  def subtract(%Date{} = date, {mega,sec,_}),     do: shift(date, [seconds: (-mega * @million) - sec])
  def subtract(%DateTime{} = date, {mega,sec,_}), do: shift(date, [seconds: (-mega * @million) - sec])
  def subtract(datetime, {_,_,_} = timestamp) do
    case Convertable.to_datetime(datetime) do
      {:error, _} = err -> err
      %DateTime{} = d   -> subtract(d, timestamp)
    end
  end

  @doc """
  A single function for adjusting the date using various units: timestamp,
  milliseconds, seconds, minutes, hours, days, weeks, months, years.

  TODO: When shifting by timestamps, microseconds are ignored.

  The result of applying the shift will either be:

  - a Date
  - a DateTime
  - an AmbiguousDateTime, which will require you to make a choice about which DateTime to use
  - an error tuple, which should only occur if something goes wrong with timezone resolution

  ## Examples

  ### Shifting across timezone changes

      iex> use Timex
      ...> %DateTime{} = datetime = Timex.datetime({{2016,3,13}, {1,0,0}}, "America/Chicago")
      ...> # 2-3 AM doesn't exist
      ...> shifted = Timex.shift(datetime, hours: 1)
      ...> {datetime.timezone.abbreviation, shifted.timezone.abbreviation, shifted.hour}
      {"CST", "CDT", 3}

  ### Shifting into an ambiguous time period

      iex> use Timex
      ...> %DateTime{} = datetime = Timex.datetime({{1895,12,31}, {0,0,0}}, "Asia/Taipei")
      ...> %AmbiguousDateTime{} = expected = Timex.datetime({{1895,12,31}, {23,55,0}}, "Asia/Taipei")
      ...> expected == Timex.shift(datetime, hours: 23, minutes: 53, seconds: 120)
      true

  ### Shifting and leap days

      iex> use Timex
      ...> %DateTime{} = datetime = Timex.datetime({2016,2,29})
      ...> Timex.shift(datetime, years: -1)
      Timex.datetime({2015, 2, 28})

  """
  @spec shift(Date.t | DateTime.t, list({Types.shift_units, term})) :: DateTime.t | {:error, term}
  def shift(%Date{} = date, options),         do: Date.shift(date, options)
  def shift(%DateTime{} = datetime, options), do: DateTime.shift(datetime, options)
  def shift(datetime, options) do
    case Convertable.to_datetime(datetime) do
      {:error, _} = err -> err
      %DateTime{} = d   -> shift(d, options)
    end
  end

  @doc """
  Get the day of the week corresponding to the given name.

  ## Examples

      iex> #{__MODULE__}.day_to_num("Monday")
      1
      iex> #{__MODULE__}.day_to_num("monday")
      1
      iex> #{__MODULE__}.day_to_num("Mon")
      1
      iex> #{__MODULE__}.day_to_num("mon")
      1
      iex> #{__MODULE__}.day_to_num(:mon)
      1

  """
  @spec day_to_num(binary | atom()) :: integer | {:error, :invalid_day_name}
  Enum.each(@weekdays, fn {day_name, day_num} ->
    lower      = day_name |> String.downcase
    abbr_cased = day_name |> String.slice(0..2)
    abbr_lower = lower |> String.slice(0..2)
    symbol     = abbr_lower |> String.to_atom

    day_quoted = quote do
      def day_to_num(unquote(day_name)),   do: unquote(day_num)
      def day_to_num(unquote(lower)),      do: unquote(day_num)
      def day_to_num(unquote(abbr_cased)), do: unquote(day_num)
      def day_to_num(unquote(abbr_lower)), do: unquote(day_num)
      def day_to_num(unquote(symbol)),     do: unquote(day_num)
    end
    Module.eval_quoted __MODULE__, day_quoted, [], __ENV__
  end)
  # Make an attempt at cleaning up the provided string
  def day_to_num(_), do: {:error, :invalid_day_name}

  @doc """
  Get the name of the day corresponding to the provided number

  ## Examples

      iex> #{__MODULE__}.day_name(1)
      "Monday"
      iex> #{__MODULE__}.day_name(0)
      {:error, :invalid_weekday_number}
  """
  @spec day_name(Types.weekday) :: String.t | {:error, :invalid_weekday_number}
  def day_name(num) when num in 1..7 do
    weekdays = Translator.get_weekdays(Translator.default_locale)
    Map.get(weekdays, num)
  end
  def day_name(_), do: {:error, :invalid_weekday_number}

  @doc """
  Get the short name of the day corresponding to the provided number

  ## Examples

      iex> #{__MODULE__}.day_shortname(1)
      "Mon"
      iex> #{__MODULE__}.day_shortname(0)
      {:error, :invalid_weekday_number}
  """
  @spec day_shortname(Types.weekday) :: String.t | {:error, :invalid_weekday_number}
  def day_shortname(num) when num in 1..7 do
    weekdays = Translator.get_weekdays_abbreviated(Translator.default_locale)
    Map.get(weekdays, num)
  end
  def day_shortname(_), do: {:error, :invalid_weekday_number}

  @doc """
  Get the number of the month corresponding to the given name.

  ## Examples

      iex> #{__MODULE__}.month_to_num("January")
      1
      iex> #{__MODULE__}.month_to_num("january")
      1
      iex> #{__MODULE__}.month_to_num("Jan")
      1
      iex> #{__MODULE__}.month_to_num("jan")
      1
      iex> #{__MODULE__}.month_to_num(:jan)
      1
  """
  @spec month_to_num(binary) :: integer | {:error, :invalid_month_name}
  Enum.each(@months, fn {month_name, month_num} ->
    lower      = month_name |> String.downcase
    abbr_cased = month_name |> String.slice(0..2)
    abbr_lower = lower |> String.slice(0..2)
    symbol     = abbr_lower |> String.to_atom
    full_chars = month_name |> String.to_char_list
    abbr_chars = abbr_cased |> String.to_char_list

    month_quoted = quote do
      def month_to_num(unquote(month_name)), do: unquote(month_num)
      def month_to_num(unquote(lower)),      do: unquote(month_num)
      def month_to_num(unquote(abbr_cased)), do: unquote(month_num)
      def month_to_num(unquote(abbr_lower)), do: unquote(month_num)
      def month_to_num(unquote(symbol)),     do: unquote(month_num)
      def month_to_num(unquote(full_chars)), do: unquote(month_num)
      def month_to_num(unquote(abbr_chars)), do: unquote(month_num)
    end
    Module.eval_quoted __MODULE__, month_quoted, [], __ENV__
  end)
  # Make an attempt at cleaning up the provided string
  def month_to_num(_), do: {:error, :invalid_month_name}

  @doc """
  Get the name of the month corresponding to the provided number

  ## Examples

      iex> #{__MODULE__}.month_name(1)
      "January"
      iex> #{__MODULE__}.month_name(0)
      {:error, :invalid_month_number}
  """
  @spec month_name(Types.month) :: String.t | {:error, :invalid_month_number}
  def month_name(num) when num in 1..12 do
    months = Translator.get_months(Translator.default_locale)
    Map.get(months, num)
  end
  def month_name(_), do: {:error, :invalid_month_number}

  @doc """
  Get the short name of the month corresponding to the provided number

  ## Examples

      iex> #{__MODULE__}.month_name(1)
      "January"
      iex> #{__MODULE__}.month_name(0)
      {:error, :invalid_month_number}
  """
  @spec month_shortname(Types.month) :: String.t | {:error, :invalid_month_number}
  def month_shortname(num) when num in 1..12 do
    months = Translator.get_months_abbreviated(Translator.default_locale)
    Map.get(months, num)
  end
  def month_shortname(_), do: {:error, :invalid_month_number}

  @doc """
  Return weekday number (as defined by ISO 8601) of the specified date.

  ## Examples

  iex> Timex.Date.epoch |> #{__MODULE__}.weekday
  4 # (i.e. Thursday)

  """
  @spec weekday(Convertable.t) :: Types.weekday | {:error, term}

  def weekday(%Date{:year => y, :month => m, :day => d}),     do: :calendar.day_of_the_week({y, m, d})
  def weekday(%DateTime{:year => y, :month => m, :day => d}), do: :calendar.day_of_the_week({y, m, d})
  def weekday(datetime) do
    case Convertable.to_date(datetime) do
      {:error, _} = err -> err
      %Date{} = d       -> weekday(d)
    end
  end

  @doc """
  Returns the ordinal day number of the date.

  ## Examples

  iex> Timex.datetime({{2015,6,26},{0,0,0}}) |> Timex.day
  177
  """
  @spec day(Convertable.t) :: Types.daynum | {:error, term}

  def day(%Date{} = date), do: day(to_datetime(date))
  def day(%DateTime{} = date) do
    start_of_year = DateTime.set(date, [month: 1, day: 1])
    1 + diff(start_of_year, date, :days)
  end
  def day(datetime) do
    case Convertable.to_date(datetime) do
      {:error, _} = err -> err
      %Date{} = d -> day(d)
    end
  end

  @doc """
  Return the number of days in the month which the date falls on.

  ## Examples

      iex> Timex.Date.epoch |> Timex.days_in_month
      31

  """
  @spec days_in_month(Convertable.t) :: Types.num_of_days | {:error, term}
  def days_in_month(%DateTime{:year => y, :month => m}), do: days_in_month(y, m)
  def days_in_month(%Date{:year => y, :month => m}),     do: days_in_month(y, m)
  def days_in_month(date) do
    case Convertable.to_date(date) do
      {:error, _} = err -> err
      %Date{} = d -> days_in_month(d)
    end
  end

  @doc """
  Same as days_in_month/2, except takes year and month as distinct arguments
  """
  @spec days_in_month(Types.year, Types.month) :: Types.num_of_days | {:error, term}
  defdelegate days_in_month(year, month), to: Timex.Helpers

  @doc """
  Given a Convertable, this function returns the week number of the date provided, starting at 1.

  ## Examples

      iex> Timex.week_of_month({2016,3,5})
      1

      iex> Timex.week_of_month(Timex.datetime({2016, 3, 14}))
      3
  """
  @spec week_of_month(Convertable.t) :: Types.week_of_month
  def week_of_month(%DateTime{:year => y, :month => m, :day => d}), do: week_of_month(y,m,d)
  def week_of_month(%Date{:year => y, :month => m, :day => d}),     do: week_of_month(y,m,d)
  def week_of_month(datetime) do
    case Convertable.to_date(datetime) do
      {:error, _} = err -> err
      %Date{} = d -> week_of_month(d)
    end
  end

  @doc """
  Same as week_of_month/1, except takes year, month, and day as distinct arguments

  ## Examples

      iex> Timex.week_of_month(2016, 3, 30)
      5
  """
  @spec week_of_month(Types.year, Types.month, Types.day) :: Types.week_of_month
  def week_of_month(year, month, day) when is_date(year, month, day) do
    {_, week_index_of_given_date} = iso_week(year, month, day)
    {_, week_index_of_first_day_of_given_month} = iso_week(year, month, 1)
    week_index_of_given_date - week_index_of_first_day_of_given_month + 1
  end
  def week_of_month(_, _, _), do: {:error, :invalid_date}

  @doc """
  Given a date returns a date at the beginning of the month.

    iex> date = Timex.datetime({{2015, 6, 15}, {12,30,0}}, "Europe/Paris")
    iex> #{__MODULE__}.beginning_of_month(date)
    Timex.datetime({{2015, 6, 1}, {0, 0, 0}}, "Europe/Paris")

  """
  @spec beginning_of_month(Date.t | DateTime.t | Comparable) :: Date.t | DateTime.t | {:error, term}
  def beginning_of_month(%Date{year: year, month: month}),
    do: Timex.date({year, month, 1})
  def beginning_of_month(%DateTime{year: year, month: month, timezone: tz}) when not is_nil(tz),
    do: Timex.datetime({{year, month, 1},{0, 0, 0}}, tz)
  def beginning_of_month(%DateTime{year: year, month: month}),
    do: Timex.datetime({{year, month, 1},{0, 0, 0}})
  def beginning_of_month(datetime) do
    case Convertable.to_datetime(datetime) do
      {:error, _} = err -> err
      %DateTime{} = d ->
        %{d | :day => 1, :hour => 0, :minute => 0, :second => 0, :millisecond => 0}
    end
  end

  @doc """
  Same as beginning_of_month/1, except takes year and month as distinct arguments
  """
  @spec beginning_of_month(Types.year, Types.month) :: Date.t | {:error, term}
  def beginning_of_month(year, month) when is_year(month) and is_month(month),
    do: Timex.date({year, month, 1})
  def beginning_of_month(_, _),
    do: {:error, :invalid_year_or_month}

  @doc """
  Given a date returns a date at the end of the month.

    iex> date = Timex.datetime({{2015, 6, 15}, {12, 30, 0}}, "Europe/London")
    iex> Timex.end_of_month(date)
    Timex.datetime({{2015, 6, 30}, {23, 59, 59}}, "Europe/London")

  """
  @spec end_of_month(Date.t | DateTime.t) :: Date.t | DateTime.t | {:error, term}
  def end_of_month(%Date{year: year, month: month} = date),
    do: Timex.date({year, month, days_in_month(date)})
  def end_of_month(%DateTime{year: year, month: month, timezone: tz} = date) when not is_nil(tz),
    do: Timex.datetime({{year, month, days_in_month(date)},{23, 59, 59}}, tz)
  def end_of_month(%DateTime{year: year, month: month} = date),
    do: Timex.datetime({{year, month, days_in_month(date)},{23, 59, 59}})
  def end_of_month(datetime) do
    case Convertable.to_datetime(datetime) do
      {:error, _} = err -> err
      %DateTime{} = d   -> end_of_month(d)
    end
  end

  @doc """
  Same as end_of_month/1, except takes year and month as distinct arguments

  ## Examples

      iex> Timex.end_of_month(2016, 2)
      Timex.date({2016, 2, 29})
  """
  @spec end_of_month(Types.year, Types.month) :: Date.t
  def end_of_month(year, month) when is_year(year) and is_month(month),
    do: end_of_month(Timex.date({year, month, 1}))
  def end_of_month(_, _),
    do: {:error, :invalid_year_or_month}

  @spec quarter(Convertable.t | Types.month) :: integer | {:error, term}
  defp quarter(month) when is_month(month) do
    case month do
      m when m in 1..3   -> 1
      m when m in 4..6   -> 2
      m when m in 7..9   -> 3
      m when m in 10..12 -> 4
    end
  end
  defp quarter(m) when is_integer(m),    do: {:error, :invalid_month}
  defp quarter(%Date{month: month}),     do: quarter(month)
  defp quarter(%DateTime{month: month}), do: quarter(month)
  defp quarter(datetime) do
    case Convertable.to_date(datetime) do
      {:error, _} = err   -> err
      %Date{month: month} -> quarter(month)
    end
  end

  @doc """
  Given a date returns a date at the beginning of the quarter.

    iex> date = Timex.datetime({{2015, 6, 15}, {12,30,0}}, "CST")
    iex> Timex.beginning_of_quarter(date)
    Timex.datetime({{2015, 4, 1}, {0, 0, 0}}, "CST")

  """
  @spec beginning_of_quarter(Date.t | Convertable.t) :: Date.t | DateTime.t | {:error, term}
  def beginning_of_quarter(%Date{year: year, month: month}) when is_year(year) and is_month(month) do
    month = 1 + (3 * (quarter(month) - 1))
    Timex.date({year, month, 1})
  end
  def beginning_of_quarter(%DateTime{year: year, month: month, timezone: tz})
    when is_year(year) and is_month(month) and not is_nil(tz)
    do
      month = 1 + (3 * (quarter(month) - 1))
      Timex.datetime({{year, month, 1},{0, 0, 0}}, tz)
  end
  def beginning_of_quarter(%DateTime{year: year, month: month}) when is_year(year) and is_month(month) do
    month = 1 + (3 * (quarter(month) - 1))
    Timex.datetime({{year, month, 1},{0, 0, 0}})
  end
  def beginning_of_quarter(datetime) do
    case Convertable.to_datetime(datetime) do
      {:error, _} = err -> err
      %DateTime{} = d -> beginning_of_quarter(d)
    end
  end

  @doc """
  Given a date or a year and month returns a date at the end of the quarter.

    iex> date = Timex.datetime({{2015, 6, 15}, {12,30,0}}, "CST")
    iex> Timex.end_of_quarter(date)
    Timex.datetime({{2015, 6, 30}, {23, 59, 59}}, "CST")

    iex> Timex.end_of_quarter(2015, 4)
    Timex.date({{2015, 6, 30}, {23, 59, 59}})

  """
  @spec end_of_quarter(Convertable.t) :: Date.t | DateTime.t | {:error, term}
  def end_of_quarter(%Date{year: year, month: month}) when is_year(year) and is_month(month) do
    month = 3 * quarter(month)
    end_of_month(Timex.date({year, month, 1}))
  end
  def end_of_quarter(%DateTime{year: year, month: month, timezone: tz})
    when is_year(year) and is_month(month) and not is_nil(tz)
    do
      month = 3 * quarter(month)
      case Timex.datetime({{year,month,1},{0,0,0}}, tz) do
        {:error, _} = err -> err
        %DateTime{} = d -> end_of_month(d)
        %AmbiguousDateTime{:before => b, :after => a} ->
          %AmbiguousDateTime{:before => end_of_month(b),
                             :after => end_of_month(a)}
      end
  end
  def end_of_quarter(%DateTime{year: year, month: month}) when is_year(year) and is_month(month) do
    month = 3 * quarter(month)
    end_of_month(Timex.datetime({year, month, 1}))
  end
  def end_of_quarter(datetime) do
    case Convertable.to_datetime(datetime) do
      {:error, _} = err -> err
      %DateTime{} = d   -> end_of_quarter(d)
      %AmbiguousDateTime{:before => b, :after => a} ->
        %AmbiguousDateTime{:before => end_of_quarter(b),
                           :after => end_of_quarter(a)}
    end
  end

  @doc """
  Same as end_of_quarter/1, except takes year and month as distinct arguments
  """
  @spec end_of_quarter(Types.year, Types.month) :: Date.t | {:error, term}
  def end_of_quarter(year, month) when is_year(year) and is_month(month) do
    end_of_month(Timex.date({year, 3 * quarter(month), 1}))
  end
  def end_of_quarter(_, _), do: {:error, :invalid_year_or_month}

  @doc """
  Given a date or a number create a date at the beginning of that year

  Examples

      iex> date = Timex.datetime({{2015, 6, 15}, {0, 0, 0, 0}})
      iex> Timex.beginning_of_year(date)
      Timex.datetime({{2015, 1, 1}, {0, 0, 0, 0}})

      iex> Timex.beginning_of_year(2015)
      Timex.date({{2015, 1, 1}, {0, 0, 0, 0}})

      iex> Timex.beginning_of_year(2015, "Europe/London")
      Timex.datetime({{2015, 1, 1}, {0, 0, 0, 0}}, "Europe/London")

  """
  @spec beginning_of_year(Date.t | Comparable | Types.year) :: Date.t | DateTime.t | {:error, term}
  def beginning_of_year(%Date{year: year}) when is_year(year),
    do: Timex.date({year, 1, 1})
  def beginning_of_year(%DateTime{year: year, timezone: tz}) when is_year(year) and not is_nil(tz),
    do: Timex.datetime({year, 1, 1}, tz)
  def beginning_of_year(%DateTime{year: year}) when is_year(year),
    do: Timex.datetime({year, 1, 1})
  def beginning_of_year(year) when is_year(year),
    do: Timex.date({year, 1, 1})
  def beginning_of_year(datetime) do
    case Convertable.to_datetime(datetime) do
      {:error, _} = err -> err
      %DateTime{} = d   -> beginning_of_year(d)
    end
  end

  @doc """
  Same as beginning_of_year, except takes an integer year + timezone as arguments.
  """
  @spec beginning_of_year(Types.year, Types.valid_timezone) :: DateTime.t | {:error, term}
  def beginning_of_year(year, %TimezoneInfo{} = tz) when is_year(year) and is_binary(tz),
    do: Timex.datetime({year, 1, 1}, tz)
  def beginning_of_year(year, tz) when is_year(year) and is_tz_value(tz),
    do: Timex.datetime({year, 1, 1}, tz)
  def beginning_of_year(_, _),
    do: {:error, :badarg}

  @doc """
  Given a date or a number create a date at the end of that year

  Examples

      iex> date = Timex.datetime({{2015, 6, 15}, {0, 0, 0, 0}})
      iex> Timex.end_of_year(date)
      Timex.datetime({{2015, 12, 31}, {23, 59, 59}})

      iex> Timex.end_of_year(2015)
      Timex.date({{2015, 12, 31}, {23, 59, 59}})

      iex> Timex.end_of_year(2015, "Europe/London")
      Timex.datetime {{2015, 12, 31}, {23, 59, 59}}, "Europe/London"

  """
  @spec end_of_year(Date.t | Types.year | Comparable) :: Date.t | DateTime.t | {:error, term}
  def end_of_year(%Date{year: year}) when is_year(year),
    do: Timex.date({year, 12, 31})
  def end_of_year(%DateTime{year: year, timezone: tz}) when is_year(year) and not is_nil(tz),
    do: Timex.datetime({{year, 12, 31}, {23, 59, 59}}, tz)
  def end_of_year(%DateTime{year: year}) when is_year(year),
    do: Timex.datetime({{year, 12, 31}, {23, 59, 59}})
  def end_of_year(year) when is_year(year),
    do: Timex.date({{year, 12, 31}, {23, 59, 59}})
  def end_of_year(datetime) do
    case Convertable.to_datetime(datetime) do
      {:error, _} = err -> err
      %DateTime{} = d -> end_of_year(d)
    end
  end

  @doc """
  Same as end_of_year/1, except takes an integer year + timezone as arguments
  """
  @spec end_of_year(Types.year, Types.valid_timezone) :: DateTime.t | {:error, term}
  def end_of_year(year, %TimezoneInfo{} = tz) when is_year(year),
    do: Timex.datetime({{year, 12, 31}, {23, 59, 59}}, tz)
  def end_of_year(year, tz) when is_year(year) and is_tz_value(tz),
    do: Timex.datetime({{year, 12, 31}, {23, 59, 59}}, tz)
  def end_of_year(_, _),
    do: {:error, :badarg}

  @doc """
  Number of days to the beginning of the week

  The weekstart can between 1..7, an atom e.g. :mon, or a string e.g. "Monday"

  ## Examples

      Week starting Monday
      iex> date = Timex.datetime({2015, 11, 30}) # Monday 30th November
      iex> Timex.days_to_beginning_of_week(date)
      0

      Week starting Sunday
      iex> date = Timex.date({2015, 11, 30}) # Monday 30th November
      iex> Timex.days_to_beginning_of_week(date, :sun)
      1

  """
  @spec days_to_beginning_of_week(Types.valid_datetime, Types.weekday) :: integer | {:error, term}
  def days_to_beginning_of_week(date, weekstart \\ 1)

  def days_to_beginning_of_week(date, weekstart) when is_atom(weekstart) or is_binary(weekstart)  do
    days_to_beginning_of_week(date, Timex.day_to_num(weekstart))
  end
  def days_to_beginning_of_week(date, weekstart) when is_day_of_week(weekstart, :mon) do
    case weekday(date) do
      {:error, _} = err ->
        err
      wd ->
        case wd - weekstart do
          diff when diff < 0 ->
            7 + diff
          diff ->
            diff
        end
    end
  end
  def days_to_beginning_of_week(_, {:error, _} = err), do: err
  def days_to_beginning_of_week(_, _), do: {:error, :badarg}

  @doc """
  Number of days to the end of the week.

  The weekstart can between 1..7, an atom e.g. :mon, or a string e.g. "Monday"

  ## Examples

      Week starting Monday
      iex> date = Timex.datetime({2015, 11, 30}) # Monday 30th November
      iex> Timex.days_to_end_of_week(date)
      6

      Week starting Sunday
      iex> date = Timex.date({2015, 11, 30}) # Monday 30th November
      iex> Timex.days_to_end_of_week(date, :sun)
      5

  """
  @spec days_to_end_of_week(Convertable.t, Types.weekday) :: integer | {:error, term}
  def days_to_end_of_week(date, weekstart \\ :mon) do
    case days_to_beginning_of_week(date, weekstart) do
      {:error, _} = err -> err
      days              -> abs(days - 6)
    end
  end

  @doc """
  Shifts the date to the beginning of the week

  The weekstart can between 1..7, an atom e.g. :mon, or a string e.g. "Monday"

  ## Examples

      iex> date = Timex.datetime({{2015, 11, 30}, {13, 30, 30}}) # Monday 30th November
      iex> Timex.beginning_of_week(date)
      Timex.datetime({2015, 11, 30})

      iex> date = Timex.date({{2015, 11, 30}, {13, 30, 30}}) # Monday 30th November
      iex> Timex.beginning_of_week(date, :sun)
      Timex.date({2015, 11, 29})

  """
  @spec beginning_of_week(Types.valid_datetime, Types.weekday) :: Date.t | DateTime.t | {:error, term}
  def beginning_of_week(date, weekstart \\ :mon)

  def beginning_of_week(%Date{} = date, weekstart) do
    days_to_beginning = days_to_beginning_of_week(date, weekstart)
    case days_to_beginning do
      {:error, _} = err -> err
      _ ->
        date
        |> Date.shift([days: -days_to_beginning])
        |> beginning_of_day
    end
  end
  def beginning_of_week(%DateTime{} = datetime, weekstart) do
    days_to_beginning = days_to_beginning_of_week(datetime, weekstart)
    case days_to_beginning do
      {:error, _} = err -> err
      _ ->
        datetime
        |> DateTime.shift([days: -days_to_beginning])
        |> beginning_of_day
    end
  end
  def beginning_of_week(datetime, weekstart) do
    case Convertable.to_datetime(datetime) do
      {:error, _} = err -> err
      %DateTime{} = d ->
        beginning_of_week(d, weekstart)
    end
  end

  @doc """
  Returns a Date or a DateTime representing the end of the week, depending on the input,
  i.e. if you pass a date/time value which represents just a date, you will get back a Date,
  if both a date and time are present, you will get back a DateTime

  The weekstart can between 1..7, an atom e.g. :mon, or a string e.g. "Monday"

  ## Examples

      iex> date = Timex.datetime({{2015, 11, 30}, {13, 30, 30}}) # Monday 30th November
      ...> Timex.end_of_week(date)
      Timex.datetime({{2015, 12, 6}, {23, 59, 59}})

      iex> date = Timex.date({{2015, 11, 30}, {13, 30, 30}}) # Monday 30th November
      ...> Timex.end_of_week(date, :sun)
      Timex.date({2015, 12, 5})

  """
  @spec end_of_week(Convertable.t, Types.weekday) :: Date.t | DateTime.t | {:error, term}
  def end_of_week(datetime, weekstart \\ 1)

  def end_of_week(%Date{} = date, weekstart) do
    days_to_end = days_to_end_of_week(date, weekstart)
    case days_to_end do
      {:error, _} = err -> err
      _ ->
        date
        |> Date.shift([days: days_to_end])
        |> end_of_day
    end
  end
  def end_of_week(%DateTime{} = datetime, weekstart) do
    days_to_end = days_to_end_of_week(datetime, weekstart)
    case days_to_end do
      {:error, _} = err -> err
      _ ->
        datetime
        |> DateTime.shift([days: days_to_end])
        |> end_of_day
    end
  end
  def end_of_week(datetime, weekstart) do
    case Convertable.to_datetime(datetime) do
      {:error, _} = err -> err
      %DateTime{} = d -> end_of_week(d, weekstart)
    end
  end

  @doc """
  Returns a DateTime representing the beginning of the day

  ## Examples

      iex> date = Timex.datetime({{2015, 1, 1}, {13, 14, 15}})
      iex> Timex.beginning_of_day(date)
      Timex.datetime({{2015, 1, 1}, {0, 0, 0}})

      iex> date = Timex.date({{2015, 1, 1}, {13, 14, 15}})
      ...> Timex.beginning_of_day(date)
      Timex.date({{2015,1,1}, {0,0,0}})

  """
  @spec beginning_of_day(Convertable.t) :: DateTime.t | {:error, term}
  def beginning_of_day(%Date{} = date), do: date
  def beginning_of_day(%DateTime{} = datetime) do
    DateTime.set(datetime, [hour: 0, minute: 0, second: 0])
  end
  def beginning_of_day(datetime) do
    case Convertable.to_datetime(datetime) do
      {:error, _} = err -> err
      %DateTime{} = d -> beginning_of_day(d)
    end
  end

  @doc """
  Returns a DateTime representing the end of the day

  ## Examples

      iex> date = Timex.datetime({{2015, 1, 1}, {13, 14, 15}})
      ...> Timex.end_of_day(date)
      Timex.datetime({{2015, 1, 1}, {23, 59, 59}})

      iex> date = Timex.date({{2015, 1, 1}, {13, 14, 15}})
      ...> Timex.end_of_day(date)
      Timex.date({{2015,1,1}, {23,59,59}})

  """
  @spec end_of_day(Convertable.t) :: DateTime.t | {:error, term}
  def end_of_day(%Date{} = date), do: date
  def end_of_day(%DateTime{} = datetime) do
    DateTime.set(datetime, [hour: 23, minute: 59, second: 59])
  end
  def end_of_day(datetime) do
    case Convertable.to_datetime(datetime) do
      {:error, _} = err -> err
      %DateTime{} = d -> end_of_day(d)
    end
  end

  @doc """
  Return a boolean indicating whether the given year is a leap year. You may
  pase a date or a year number.

  ## Examples

      iex> DateTime.epoch |> #{__MODULE__}.is_leap?
      false
      iex> #{__MODULE__}.is_leap?(2012)
      true

  """
  @spec is_leap?(Types.valid_datetime | Types.year) :: boolean | {:error, term}
  def is_leap?(year) when is_year(year),
    do: :calendar.is_leap_year(year)
  def is_leap?(%Date{:year => year}),
    do: is_leap?(year)
  def is_leap?(%DateTime{:year => year}),
    do: is_leap?(year)
  def is_leap?(datetime) do
    case Convertable.to_date(datetime) do
      {:error, _} = err -> err
      %Date{:year => y} -> :calendar.is_leap_year(y)
    end
  end

  @doc """
  Produces a valid Date or DateTime object based on a date or datetime tuple respectively.

  All date's components will be clamped to the minimum or maximum valid value.

  ## Examples

    iex> use Timex
    ...> localtz  = Timezone.local({{1,12,31},{0,59,59}})
    ...> Timex.normalize({{1,12,31},{0,59,59}, localtz})
    Timex.datetime({{1,12,31},{0,59,59}}, :local)

    iex> use Timex
    ...> Timex.normalize({1,12,31})
    Timex.date({1,12,31})

  """
  @spec normalize(Types.valid_datetime) :: Date.t | DateTime.t | {:error, term}

  def normalize({{_,_,_} = date, {_,_,_} = time}),
    do: Timex.datetime({normalize(:date, date), normalize(:time, time)})
  def normalize({y,m,d} = date) when is_integer(y) and is_integer(m) and is_integer(d),
    do: Timex.date(normalize(:date, date))
  def normalize({{_,_,_}=date, time, {_offset, tz}}),
    do: Timex.datetime({normalize(:date, date), normalize(:time, time), tz})
  def normalize({{_,_,_}=date, time, %TimezoneInfo{} = tz}),
    do: Timex.datetime({normalize(:date, date), normalize(:time, time), tz})
  def normalize({{_,_,_}=date, time, tz}) when is_tz_value(tz),
    do: Timex.datetime({normalize(:date, date), normalize(:time, time), tz})
  def normalize(%Date{:year => y, :month => m, :day => d}),
    do: Timex.date(normalize(:date, {y,m,d}))
  def normalize(%DateTime{:year => y, :month => m, :day => d, :hour => h, :minute => m, :second => s, :millisecond => ms, :timezone => tz}),
    do: Timex.datetime({normalize(:date, {y,m,d}), normalize(:time, {h,m,s,ms}), normalize(:timezone, tz)})
  def normalize(datetime) do
    case Convertable.to_datetime(datetime) do
      {:error, _} = err -> err
      %DateTime{} = d   -> normalize(d)
    end
  end

  @doc """
  Like normalize/1, but for specific types of values.
  """
  @spec normalize(:date, {integer,integer,integer}) :: {Types.year, Types.month, Types.day}
  @spec normalize(:time, {integer,integer,integer} | {integer,integer,integer,integer}) :: Types.time
  @spec normalize(:year | :month | :day | :hour | :minute | :second | :millisecond, integer) :: integer
  @spec normalize(:timezone, term) :: TimezoneInfo.t
  def normalize(:date, {year, month, day}) do
    year  = normalize(:year, year)
    month = normalize(:month, month)
    day   = normalize(:day, {year, month, day})
    {year, month, day}
  end
  def normalize(:year, year) when year < 0, do: 0
  def normalize(:year, year), do: year
  def normalize(:month, month) do
    cond do
      month < 1   -> 1
      month > 12  -> 12
      true        -> month
    end
  end
  def normalize(:time, {hour,min,sec}) do
    hour  = normalize(:hour, hour)
    min   = normalize(:minute, min)
    sec   = normalize(:second, sec)
    {hour, min, sec}
  end
  def normalize(:time, {hour,min,sec,ms}) do
    {h,m,s} = normalize(:time, {hour,min,sec})
    msecs   = normalize(:millisecond, ms)
    {h, m, s, msecs}
  end
  def normalize(:hour, hour) do
    cond do
      hour < 0    -> 0
      hour > 23   -> 23
      true        -> hour
    end
  end
  def normalize(:minute, min) do
    cond do
      min < 0    -> 0
      min > 59   -> 59
      true       -> min
    end
  end
  def normalize(:second, sec) do
    cond do
      sec < 0    -> 0
      sec > 59   -> 59
      true       -> sec
    end
  end
  def normalize(:millisecond, ms) do
    cond do
      ms < 0   -> 0
      ms > 999 -> 999
      true     -> ms
    end
  end
  def normalize(:timezone, tz), do: tz
  def normalize(:day, {year, month, day}) do
    year  = normalize(:year, year)
    month = normalize(:month, month)
    ndays = Timex.days_in_month(year, month)
    cond do
      day < 1     -> 1
      day > ndays -> ndays
      true        -> day
    end
  end

  @doc """
  Return a new Date/DateTime with the specified fields replaced by new values.

  Values are automatically validated and clamped to good values by default. If
  you wish to skip validation, perhaps for performance reasons, pass `validate: false`.

  Values are applied in order, so if you pass `[datetime: dt, date: d]`, the date value
  from `date` will override `datetime`'s date value.

  ## Example

      iex> use Timex
      ...> expected = Timex.date({2015, 2, 28})
      ...> result = Timex.set(expected, [month: 2, day: 30])
      ...> result == expected
      true

      iex> use Timex
      ...> expected = Timex.datetime({{2016, 2, 29}, {23, 30, 0}})
      ...> result = Timex.set(expected, [hour: 30])
      ...> result === expected
      true

  """
  def set(%Date{} = date, options),         do: Date.set(date, options)
  def set(%DateTime{} = datetime, options), do: DateTime.set(datetime, options)
  def set(datetime, options) do
    case Convertable.to_datetime(datetime) do
      {:error, _} = err -> err
      %DateTime{} = d -> DateTime.set(d, options)
    end
  end

end

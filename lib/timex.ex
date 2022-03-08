defmodule Timex do
  @moduledoc File.read!("README.md")

  use Application

  @doc false
  def start(_type, _args) do
    apps = Application.started_applications()
    tzdata_started? = Enum.find(apps, &(elem(&1, 0) == :tzdata)) != nil

    cond do
      tzdata_started? ->
        case Calendar.get_time_zone_database() do
          Calendar.UTCOnlyTimeZoneDatabase ->
            Calendar.put_time_zone_database(Timex.Timezone.Database)

          _ ->
            :ok
        end

        Supervisor.start_link([], strategy: :one_for_one, name: Timex.Supervisor)

      :else ->
        {:error, ":tzdata application not started! Ensure :timex is in your applications list!"}
    end
  end

  defmacro __using__(_) do
    quote do
      alias Timex.AmbiguousDateTime
      alias Timex.TimezoneInfo
      alias Timex.AmbiguousTimezoneInfo
      alias Timex.Interval
      alias Timex.Duration
      alias Timex.Timezone
    end
  end

  alias Timex.{Duration, AmbiguousDateTime}
  alias Timex.{Timezone, TimezoneInfo, AmbiguousTimezoneInfo}
  alias Timex.{Types, Helpers, Translator}
  alias Timex.{Comparable}

  use Timex.Constants
  import Timex.Macros

  @doc """
  Returns a Date representing the current day in UTC
  """
  @spec today() :: Date.t()
  defdelegate today(), to: Date, as: :utc_today

  @doc """
  Returns a Date representing the current day in the provided timezone.
  """
  @spec today(Types.valid_timezone()) :: Date.t()
  def today(timezone), do: now(timezone) |> DateTime.to_date()

  @doc """
  Returns a DateTime representing the current moment in time in UTC
  """
  @spec now() :: DateTime.t()
  defdelegate now(), to: DateTime, as: :utc_now

  @doc """
  Returns a DateTime representing the current moment in time in the provided
  timezone.
  """
  @spec now(Types.valid_timezone()) :: DateTime.t() | AmbiguousDateTime.t() | {:error, term}
  def now(tz) do
    with tzname when is_binary(tzname) <- Timezone.name_of(tz),
         {:ok, dt} <- DateTime.now(tzname, Timex.Timezone.Database) do
      dt
    else
      {:error, _} = err ->
        err
    end
  end

  @doc """
  Returns a DateTime representing the current moment in time in the local timezone.

  ## Example

      iex> %DateTime{time_zone: tz} = Timex.local();
      ...> tz != nil
      true
  """
  @spec local() :: DateTime.t() | {:error, term}
  def local() do
    with tz when is_binary(tz) <- Timezone.Local.lookup(),
         {:ok, datetime} <- DateTime.now(tz, Timex.Timezone.Database) do
      datetime
    else
      {:error, _} = err ->
        err
    end
  end

  @doc """
  Returns a DateTime representing the given date/time in the local timezone

  ## Example

      iex> %DateTime{time_zone: tz} = Timex.local(DateTime.utc_now());
      ...> tz != nil
      true
  """
  @spec local(Types.valid_datetime()) :: DateTime.t() | AmbiguousDateTime.t() | {:error, term}
  def local(%DateTime{} = datetime) do
    with tz when is_binary(tz) <- Timezone.Local.lookup(),
         {:ok, datetime} <- DateTime.shift_zone(datetime, tz, Timex.Timezone.Database) do
      datetime
    else
      {:error, _} = err ->
        err
    end
  end

  def local(date) do
    with tz when is_binary(tz) <- Timezone.Local.lookup() do
      to_datetime(date, tz)
    else
      {:error, _} = err ->
        err
    end
  end

  @doc """
  Returns a Date representing the start of the UNIX epoch
  """
  @spec epoch() :: Date.t()
  def epoch(), do: %Date{year: 1970, month: 1, day: 1}

  @doc """
  Returns a Date representing the start of the Gregorian epoch
  """
  @spec zero() :: Date.t()
  def zero(), do: %Date{year: 0, month: 1, day: 1}

  @doc """
  Convert a date/time value to a Date struct.
  """
  @spec to_date(Types.valid_datetime()) :: Date.t() | {:error, term}
  defdelegate to_date(date), to: Timex.Protocol

  @doc """
  Convert a date/time value to a NaiveDateTime struct.
  """
  @spec to_naive_datetime(Types.valid_datetime()) :: NaiveDateTime.t() | {:error, term}
  defdelegate to_naive_datetime(date), to: Timex.Protocol

  @doc """
  Convert a date/time value and timezone name to a DateTime struct.
  If the DateTime is ambiguous and cannot be resolved, an AmbiguousDateTime will be returned,
  allowing the developer to choose which of the two choices is desired.

  If no timezone is provided, "Etc/UTC" will be used
  """
  @spec to_datetime(Types.valid_datetime()) :: DateTime.t() | {:error, term}
  @spec to_datetime(Types.valid_datetime(), Types.valid_timezone()) ::
          DateTime.t() | AmbiguousDateTime.t() | {:error, term}
  def to_datetime(%DateTime{} = dt), do: dt
  def to_datetime(from), do: Timex.Protocol.to_datetime(from, "Etc/UTC")
  defdelegate to_datetime(from, timezone), to: Timex.Protocol

  @doc """
  Convert a date/time value to it's Erlang representation
  """
  @spec to_erl(Types.valid_datetime()) :: Types.date() | Types.datetime() | {:error, term}
  defdelegate to_erl(date), to: Timex.Protocol

  @doc """
  Convert a date/time value to a Julian calendar date number
  """
  @spec to_julian(Types.valid_datetime()) :: integer | {:error, term}
  defdelegate to_julian(datetime), to: Timex.Protocol

  @doc """
  Convert a date/time value to gregorian seconds (seconds since start of year zero)
  """
  @spec to_gregorian_seconds(Types.valid_datetime()) :: non_neg_integer | {:error, term}
  defdelegate to_gregorian_seconds(datetime), to: Timex.Protocol

  @doc """
  Convert a date/time value to gregorian microseconds (microseconds since start of year zero)
  """
  @spec to_gregorian_microseconds(Types.valid_datetime()) :: non_neg_integer | {:error, term}
  defdelegate to_gregorian_microseconds(datetime), to: Timex.Protocol

  @doc """
  Convert a date/time value to seconds since the UNIX epoch
  """
  @spec to_unix(Types.valid_datetime()) :: non_neg_integer | {:error, term}
  defdelegate to_unix(datetime), to: Timex.Protocol

  @doc """
  Delegates to `DateTime.from_unix!/2`. To recap the docs:

  Converts the given Unix time to DateTime.

  The integer can be given in different units according to `System.convert_time_unit/3`
  and it will be converted to microseconds internally. Defaults to `:second`.

  Unix times are always in UTC and therefore the DateTime will be returned in UTC.
  """
  @spec from_unix(secs :: non_neg_integer, :native | Types.second_time_units()) ::
          DateTime.t() | no_return
  def from_unix(secs, unit \\ :second)

  def from_unix(secs, :seconds) do
    from_unix(secs, :second)
  end

  def from_unix(secs, :milliseconds) do
    from_unix(secs, :millisecond)
  end

  def from_unix(secs, :microseconds) do
    from_unix(secs, :microsecond)
  end

  def from_unix(secs, :nanoseconds) do
    from_unix(secs, :nanosecond)
  end

  def from_unix(secs, unit) do
    DateTime.from_unix!(secs, unit)
  end

  @doc """
  Formats a date/time value using the given format string (and optional formatter).

  See Timex.Format.DateTime.Formatters.Default or Timex.Format.DateTime.Formatters.Strftime
  for documentation on the syntax supported by those formatters.

  To use the Default formatter, simply call format/2. To use the Strftime formatter, you
  can either alias and pass Strftime by module name, or as a shortcut, you can pass :strftime
  instead.

  Formatting will convert other dates than Elixir date types (Date, DateTime, NaiveDateTime)
  to a NaiveDateTime using `to_naive_datetime/1` before formatting.

  ## Examples

      iex> date = ~D[2016-02-29]
      ...> Timex.format(date, "{YYYY}-{0M}-{D}")
      {:ok, "2016-02-29"}

      iex> datetime = Timex.to_datetime({{2016,2,29},{22,25,0}}, "Etc/UTC")
      ...> Timex.format(datetime, "{ISO:Extended}")
      {:ok, "2016-02-29T22:25:00+00:00"}
  """
  @spec format(Types.valid_datetime(), format :: String.t()) :: {:ok, String.t()} | {:error, term}
  defdelegate format(datetime, format_string), to: Timex.Format.DateTime.Formatter

  @doc """
  Same as format/2, except using a custom formatter

  ## Examples

      iex> use Timex
      ...> datetime = Timex.to_datetime({{2016,2,29},{22,25,0}}, "America/Chicago")
      iex> Timex.format(datetime, "%FT%T%:z", :strftime)
      {:ok, "2016-02-29T22:25:00-06:00"}
  """
  @spec format(Types.valid_datetime(), format :: String.t(), formatter :: atom) ::
          {:ok, String.t()} | {:error, term}
  defdelegate format(datetime, format_string, formatter), to: Timex.Format.DateTime.Formatter

  @doc """
  Same as format/2, except takes a locale name to translate text to.

  Translations only apply to units, relative time phrases, and only for the locales in the
  list of supported locales in the Timex documentation.
  """
  @spec lformat(Types.valid_datetime(), format :: String.t(), locale :: String.t()) ::
          {:ok, String.t()} | {:error, term}
  defdelegate lformat(datetime, format_string, locale), to: Timex.Format.DateTime.Formatter

  @doc """
  Same as lformat/3, except takes a formatter as it's last argument.

  Translations only apply to units, relative time phrases, and only for the locales in the
  list of supported locales in the Timex documentation.
  """
  @spec lformat(
          Types.valid_datetime(),
          format :: String.t(),
          locale :: String.t(),
          formatter :: atom
        ) :: {:ok, String.t()} | {:error, term}
  defdelegate lformat(datetime, format_string, locale, formatter),
    to: Timex.Format.DateTime.Formatter

  @doc """
  Same as format/2, except it returns only the value (not a tuple) and raises on error.

  ## Examples

      iex> date = ~D[2016-02-29]
      ...> Timex.format!(date, "{YYYY}-{0M}-{D}")
      "2016-02-29"
  """
  @spec format!(Types.valid_datetime(), format :: String.t()) :: String.t() | no_return
  defdelegate format!(datetime, format_string), to: Timex.Format.DateTime.Formatter

  @doc """
  Same as format/3, except it returns only the value (not a tuple) and raises on error.

  ## Examples

      iex> use Timex
      ...> datetime = Timex.to_datetime({{2016,2,29},{22,25,0}}, "America/Chicago")
      iex> Timex.format!(datetime, "%FT%T%:z", :strftime)
      "2016-02-29T22:25:00-06:00"
  """
  @spec format!(Types.valid_datetime(), format :: String.t(), formatter :: atom) ::
          String.t() | no_return
  defdelegate format!(datetime, format_string, formatter), to: Timex.Format.DateTime.Formatter

  @doc """
  Same as lformat/3, except local_format! raises on error.

  See lformat/3 docs for usage examples.
  """
  @spec lformat!(Types.valid_datetime(), format :: String.t(), locale :: String.t()) ::
          String.t() | no_return
  defdelegate lformat!(datetime, format_string, locale), to: Timex.Format.DateTime.Formatter

  @doc """
  Same as lformat/4, except local_format! raises on error.

  See lformat/4 docs for usage examples
  """
  @spec lformat!(
          Types.valid_datetime(),
          format :: String.t(),
          locale :: String.t(),
          formatter :: atom
        ) :: String.t() | no_return
  defdelegate lformat!(datetime, format_string, locale, formatter),
    to: Timex.Format.DateTime.Formatter

  @doc """
  Formats a DateTime using a fuzzy relative duration, from now.

  ## Examples


      iex> use Timex
      ...> Timex.from_now(Timex.shift(DateTime.utc_now(), days: 2, hours: 1))
      "in 2 days"

      iex> use Timex
      ...> Timex.from_now(Timex.shift(DateTime.utc_now(), days: -2))
      "2 days ago"
  """
  @spec from_now(Types.valid_datetime()) :: String.t() | {:error, term}
  def from_now(datetime), do: from_now(datetime, Timex.Translator.current_locale())

  @doc """
  Formats a DateTime using a fuzzy relative duration, translated using given locale

  ## Examples

      iex> use Timex
      ...> Timex.from_now(Timex.shift(DateTime.utc_now(), days: 2, hours: 1), "ru")
      "через 2 дня"

      iex> use Timex
      ...> Timex.from_now(Timex.shift(DateTime.utc_now(), days: -2), "ru")
      "2 дня назад"

  """
  @spec from_now(Types.valid_datetime(), String.t()) :: String.t() | {:error, term}
  def from_now(datetime, locale) when is_binary(locale) do
    case to_naive_datetime(datetime) do
      {:error, _} = err ->
        err

      %NaiveDateTime{} = dt ->
        case lformat(dt, "{relative}", locale, :relative) do
          {:ok, formatted} -> formatted
          {:error, _} = err -> err
        end
    end
  end

  # Formats a DateTime using a fuzzy relative duration, with a reference datetime other than now
  @spec from_now(Types.valid_datetime(), Types.valid_datetime()) :: String.t() | {:error, term}
  def from_now(datetime, reference_date),
    do: from_now(datetime, reference_date, Timex.Translator.current_locale())

  @doc """
  Formats a DateTime using a fuzzy relative duration, with a reference datetime other than now,
  translated using the given locale
  """
  @spec from_now(Types.valid_datetime(), Types.valid_datetime(), String.t()) ::
          String.t() | {:error, term}
  def from_now(datetime, reference_date, locale) when is_binary(locale) do
    case to_naive_datetime(datetime) do
      {:error, _} = err ->
        err

      %NaiveDateTime{} = dt ->
        case to_naive_datetime(reference_date) do
          {:error, _} = err ->
            err

          %NaiveDateTime{} = ref ->
            case Timex.Format.DateTime.Formatters.Relative.relative_to(
                   dt,
                   ref,
                   "{relative}",
                   locale
                 ) do
              {:ok, formatted} -> formatted
              {:error, _} = err -> err
            end
        end
    end
  end

  @doc """
  Formats an Erlang timestamp using the ISO-8601 duration format, or optionally, with a custom
  formatter of your choosing.

  See Timex.Format.Duration.Formatters.Default or Timex.Format.Duration.Formatters.Humanized
  for documentation on the specific formatter behaviour.

  To use the Default formatter, simply call format_duration/2.
  To use the Humanized formatter, you can either alias and pass Humanized by module name,
  or as a shortcut, you can pass :humanized instead.

  ## Examples

      iex> use Timex
      ...> duration = Duration.from_seconds(Timex.to_unix({2016, 2, 29}))
      ...> Timex.format_duration(duration)
      "P46Y2M10D"

      iex> use Timex
      ...> duration = Duration.from_seconds(Timex.to_unix({2016, 2, 29}))
      ...> Timex.format_duration(duration, :humanized)
      "46 years, 2 months, 1 week, 3 days"

      iex> use Timex
      ...> datetime = Duration.from_seconds(Timex.to_unix(~N[2016-02-29T22:25:00]))
      ...> Timex.format_duration(datetime, :humanized)
      "46 years, 2 months, 1 week, 3 days, 22 hours, 25 minutes"

  """
  @spec format_duration(Duration.t()) :: String.t() | {:error, term}
  defdelegate format_duration(timestamp), to: Timex.Format.Duration.Formatter, as: :format

  @doc """
  Same as format_duration/1, except it also accepts a formatter
  """
  @spec format_duration(Duration.t(), atom) :: String.t() | {:error, term}
  defdelegate format_duration(timestamp, formatter),
    to: Timex.Format.Duration.Formatter,
    as: :format

  @doc """
  Same as format_duration/1, except takes a locale for use in translation
  """
  @spec lformat_duration(Duration.t(), locale :: String.t()) :: String.t() | {:error, term}
  defdelegate lformat_duration(timestamp, locale),
    to: Timex.Format.Duration.Formatter,
    as: :lformat

  @doc """
  Same as lformat_duration/2, except takes a formatter as an argument
  """
  @spec lformat_duration(Duration.t(), locale :: String.t(), atom) :: String.t() | {:error, term}
  defdelegate lformat_duration(timestamp, locale, formatter),
    to: Timex.Format.Duration.Formatter,
    as: :lformat

  @doc """
  Parses a datetime string into a DateTime struct, using the provided format string (and optional tokenizer).

  See Timex.Format.DateTime.Formatters.Default or Timex.Format.DateTime.Formatters.Strftime
  for documentation on the syntax supported in format strings by their respective tokenizers.

  To use the Default tokenizer, simply call parse/2. To use the Strftime tokenizer, you
  can either alias and pass Timex.Parse.DateTime.Tokenizer.Strftime by module name,
  or as a shortcut, you can pass :strftime instead.

  ## Examples

      iex> use Timex
      ...> {:ok, result} = Timex.parse("2016-02-29", "{YYYY}-{0M}-{D}")
      ...> result
      ~N[2016-02-29T00:00:00]

      iex> use Timex
      ...> expected = Timex.to_datetime({{2016, 2, 29}, {22, 25, 0}}, "America/Chicago")
      ...> {:ok, result} = Timex.parse("2016-02-29T22:25:00-06:00", "{ISO:Extended}")
      ...> Timex.equal?(expected, result)
      true

      iex> use Timex
      ...> expected = Timex.to_datetime({{2016, 2, 29}, {22, 25, 0}}, "America/Chicago")
      ...> {:ok, result} = Timex.parse("2016-02-29T22:25:00-06:00", "%FT%T%:z", :strftime)
      ...> Timex.equal?(expected, result)
      true

  """
  @spec parse(String.t(), String.t()) :: {:ok, DateTime.t() | NaiveDateTime.t()} | {:error, term}
  @spec parse(String.t(), String.t(), atom) ::
          {:ok, DateTime.t() | NaiveDateTime.t()} | {:error, term}
  defdelegate parse(datetime_string, format_string), to: Timex.Parse.DateTime.Parser
  defdelegate parse(datetime_string, format_string, tokenizer), to: Timex.Parse.DateTime.Parser

  @doc """
  Same as parse/2 and parse/3, except parse! raises on error.

  See parse/2 or parse/3 docs for usage examples.
  """
  @spec parse!(String.t(), String.t()) :: DateTime.t() | NaiveDateTime.t() | no_return
  @spec parse!(String.t(), String.t(), atom) :: DateTime.t() | NaiveDateTime.t() | no_return
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
  @spec validate_format(String.t()) :: :ok | {:error, term}
  @spec validate_format(String.t(), atom) :: :ok | {:error, term}
  defdelegate validate_format(format_string), to: Timex.Format.DateTime.Formatter, as: :validate

  defdelegate validate_format(format_string, formatter),
    to: Timex.Format.DateTime.Formatter,
    as: :validate

  @doc """
  Gets the current century

  ## Examples

      iex> Timex.century
      21

  """
  @spec century() :: non_neg_integer | {:error, term}
  def century(), do: century(:calendar.universal_time())

  @doc """
  Given a date, get the century this date is in.

  ## Examples

      iex> Timex.today |> Timex.century
      21
      iex> Timex.now |> Timex.century
      21
      iex> Timex.century(2016)
      21

  """
  @spec century(Types.year() | Types.valid_datetime()) :: non_neg_integer | {:error, term}
  def century(year) when is_integer(year) do
    base_century = div(year, 100)
    years_past = rem(year, 100)

    cond do
      base_century == base_century - years_past -> base_century
      true -> base_century + 1
    end
  end

  def century(date), do: Timex.Protocol.century(date)

  @doc """
  Convert an iso ordinal day number to the day it represents in the current year.

   ## Examples

      iex> %Date{:year => year} = Timex.from_iso_day(180)
      ...> %Date{:year => todays_year} = Timex.today()
      ...> year == todays_year
      true
  """
  @spec from_iso_day(non_neg_integer) :: Date.t() | {:error, term}
  def from_iso_day(day) when is_day_of_year(day) do
    {{year, _, _}, _} = :calendar.universal_time()
    from_iso_day(day, year)
  end

  def from_iso_day(_), do: {:error, {:from_iso_day, :invalid_iso_day}}

  @doc """
  Same as from_iso_day/1, except you can expect the following based on the second parameter:

  - If an integer year is given, the result will be a Date struct
  - For any date/time value, the result will be in the same format (i.e. Date -> Date)

  In all cases, the resulting value will be the date representation of the provided ISO day in that year

  ## Examples

  ### Creating a Date from the given day

      iex> use Timex
      ...> expected = ~D[2015-06-29]
      ...> (expected === Timex.from_iso_day(180, 2015))
      true

  ### Creating a Date/DateTime from the given day

      iex> use Timex
      ...> expected = Timex.to_datetime({{2015, 6, 29}, {0,0,0}}, "Etc/UTC")
      ...> beginning = Timex.to_datetime({{2015,1,1}, {0,0,0}}, "Etc/UTC")
      ...> (expected === Timex.from_iso_day(180, beginning))
      true

  ### Shifting a Date/DateTime to the given day

      iex> use Timex
      ...> date = Timex.to_datetime({{2015,6,26}, {12,0,0}}, "Etc/UTC")
      ...> expected = Timex.to_datetime({{2015, 6, 29}, {12,0,0}}, "Etc/UTC")
      ...> (Timex.from_iso_day(180, date) === expected)
      true
  """
  @spec from_iso_day(non_neg_integer, Types.year() | Types.valid_datetime()) ::
          Types.valid_datetime() | {:error, term}
  def from_iso_day(day, year) when is_day_of_year(day) and is_year(year) do
    {year, month, day} = Helpers.iso_day_to_date_tuple(year, day)
    %Date{year: year, month: month, day: day}
  end

  def from_iso_day(day, datetime), do: Timex.Protocol.from_iso_day(datetime, day)

  @doc """
  Return a pair {year, week number} (as defined by ISO 8601) that the given
  Date/DateTime value falls on.

  ## Examples

      iex> Timex.iso_week({1970, 1, 1})
      {1970,1}
  """
  @spec iso_week(Types.valid_datetime()) :: {Types.year(), Types.weeknum()} | {:error, term}
  defdelegate iso_week(datetime), to: Timex.Protocol

  @doc """
  Same as iso_week/1, except this takes a year, month, and day as distinct arguments.

  ## Examples

      iex> Timex.iso_week(1970, 1, 1)
      {1970,1}
  """
  @spec iso_week(Types.year(), Types.month(), Types.day()) ::
          {Types.year(), Types.weeknum()} | {:error, term}
  def iso_week(year, month, day) when is_date(year, month, day),
    do: :calendar.iso_week_number({year, month, day})

  def iso_week(_, _, _),
    do: {:error, {:iso_week, :invalid_date}}

  @doc """
  Return a 3-tuple {year, week number, weekday} for the given Date/DateTime.

  ## Examples

      iex> Timex.iso_triplet(Timex.epoch)
      {1970, 1, 4}

  """
  @spec iso_triplet(Types.valid_datetime()) ::
          {Types.year(), Types.weeknum(), Types.weekday()} | {:error, term}
  def iso_triplet(datetime) do
    case to_erl(datetime) do
      {:error, _} = err ->
        err

      {y, m, d} = date ->
        {iso_year, iso_week} = iso_week(y, m, d)
        {iso_year, iso_week, Timex.weekday(date)}

      {{y, m, d} = date, _} ->
        {iso_year, iso_week} = iso_week(y, m, d)
        {iso_year, iso_week, Timex.weekday(date)}
    end
  end

  @doc """
  Given an ISO triplet `{year, week number, weekday}`, convert it to a Date struct.

  ## Examples

      iex> expected = Timex.to_date({2014, 1, 28})
      iex> Timex.from_iso_triplet({2014, 5, 2}) === expected
      true

  """
  @spec from_iso_triplet(Types.iso_triplet()) :: Date.t() | {:error, term}
  def from_iso_triplet({year, week, weekday})
      when is_year(year) and is_week_of_year(week) and is_day_of_week(weekday, :mon) do
    {_, _, jan4weekday} = iso_triplet({year, 1, 4})
    offset = jan4weekday + 3
    ordinal_day = week * 7 + weekday - offset

    {year, iso_day} =
      case {year, ordinal_day} do
        {year, ordinal_day} when ordinal_day < 1 and is_leap_year(year - 1) ->
          {year - 1, ordinal_day + 366}

        {year, ordinal_day} when ordinal_day < 1 ->
          {year - 1, ordinal_day + 365}

        {year, ordinal_day} when ordinal_day > 366 and is_leap_year(year) ->
          {year + 1, ordinal_day - 366}

        {year, ordinal_day} when ordinal_day > 365 and not is_leap_year(year) ->
          {year + 1, ordinal_day - 365}

        _ ->
          {year, ordinal_day}
      end

    {year, month, day} = Helpers.iso_day_to_date_tuple(year, iso_day)
    %Date{year: year, month: month, day: day}
  end

  def from_iso_triplet({_, _, _}), do: {:error, {:from_iso_triplet, :invalid_triplet}}

  @doc """
  Returns a list of all valid timezone names in the Olson database
  """
  @spec timezones() :: [String.t()]
  def timezones(), do: Tzdata.zone_list()

  @doc """
  Get a TimezoneInfo object for the specified offset or name.

  When offset or name is invalid, exception is raised.

  If no DateTime value is given for the second parameter, the current date/time
  will be used (in other words, it will return the current timezone info for the
  given zone). If one is provided, the timezone info returned will be based on
  the provided DateTime (or Erlang datetime tuple) value.

  ## Examples

      iex> date = Timex.to_datetime({2015, 4, 12})
      ...> tz = Timex.timezone(:utc, date)
      ...> tz.full_name
      "Etc/UTC"

      iex> tz = Timex.timezone("America/Chicago", {2015,4,12})
      ...> {tz.full_name, tz.abbreviation}
      {"America/Chicago", "CDT"}

      iex> tz = Timex.timezone(+2, {2015, 4, 12})
      ...> {tz.full_name, tz.abbreviation}
      {"Etc/UTC+2", "+02"}

  """
  @spec timezone(Types.valid_timezone() | TimezoneInfo.t(), Types.valid_datetime()) ::
          TimezoneInfo.t() | AmbiguousTimezoneInfo.t() | {:error, term}
  def timezone(tz, datetime), do: Timezone.get(tz, datetime)

  @doc """
  Return a boolean indicating whether the given date is valid.

  ## Examples

      iex> use Timex
      ...> Timex.is_valid?(~N[0001-01-01T01:01:01])
      true

      iex> use Timex
      ...> %Date{year: 1, day: 1, month: 13} |> Timex.is_valid?
      false

  """
  @spec is_valid?(Types.valid_datetime()) :: boolean
  def is_valid?(datetime) do
    case Timex.Protocol.is_valid?(datetime) do
      {:error, _reason} ->
        false

      b when is_boolean(b) ->
        b
    end
  end

  @doc """
  Returns a boolean indicating whether the provided term represents a valid time,
  valid times are one of:

  - `{hour, min, sec}`
  - `{hour, min, sec, ms}`

  """
  @spec is_valid_time?(term) :: boolean
  def is_valid_time?({hour, min, sec}) when is_time(hour, min, sec), do: true
  def is_valid_time?({hour, min, sec, ms}) when is_time(hour, min, sec, ms), do: true
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
      _name -> true
    end
  end

  @doc """
  Returns a boolean indicating whether the first `Timex.Comparable` occurs before the second
  """
  @spec before?(Time.t() | Comparable.comparable(), Time.t() | Comparable.comparable()) :: boolean
  def before?(a, b) do
    case compare(a, b) do
      {:error, reason} ->
        raise ArgumentError, message: "#{inspect(reason)}"

      -1 ->
        true

      _ ->
        false
    end
  end

  @doc """
  Returns a boolean indicating whether the first `Timex.Comparable` occurs after the second
  """
  @spec after?(Time.t() | Comparable.comparable(), Time.t() | Comparable.comparable()) :: boolean
  def after?(a, b) do
    case compare(a, b) do
      {:error, reason} ->
        raise ArgumentError, message: "#{inspect(reason)}"

      1 ->
        true

      _ ->
        false
    end
  end

  @doc """
  Returns a boolean indicating whether the first `Timex.Comparable` occurs between the second
  and third.

  If an error occurs, an error tuple will be returned.

  By default, the `start` and `end` bounds are *exclusive*. You can opt for inclusive bounds with the
  `inclusive: true` option.
  To set just one of the bounds as inclusive, use the
  `inclusive: :start` or `inclusive: :end` option.
  """
  @type between_options :: [
          inclusive:
            boolean
            | :start
            | :end
        ]
  @spec between?(
          Time.t() | Comparable.comparable(),
          Time.t() | Comparable.comparable(),
          Time.t() | Comparable.comparable(),
          between_options
        ) :: boolean
  def between?(a, start, ending, options \\ []) do
    {start_test, ending_test} =
      case Keyword.get(options, :inclusive, false) do
        :start -> {0, 1}
        :end -> {1, 0}
        true -> {0, 0}
        _ -> {1, 1}
      end

    in_bounds?(compare(a, start), compare(ending, a), start_test, ending_test)
  end

  defp in_bounds?({:error, reason}, _, _, _),
    do: raise(ArgumentError, message: "#{inspect(reason)}")

  defp in_bounds?(_, {:error, reason}, _, _),
    do: raise(ArgumentError, message: "#{inspect(reason)}")

  defp in_bounds?(start_comparison, ending_comparison, start_test, ending_test) do
    start_comparison >= start_test && ending_comparison >= ending_test
  end

  @doc """
  Returns a boolean indicating whether the two `Timex.Comparable` values are equivalent.

  Equality here implies that the two Comparables represent the same moment in time (with
  the given granularity), not equality of the data structure.

  The options for granularity is the same as for `compare/3`, defaults to `:seconds`.

  ## Examples

      iex> date1 = ~D[2014-03-01]
      ...> date2 = ~D[2014-03-01]
      ...> Timex.equal?(date1, date2)
      true

      iex> date1 = ~D[2014-03-01]
      ...> date2 = Timex.to_datetime({2014, 3, 1}, "Etc/UTC")
      ...> Timex.equal?(date1, date2)
      true
  """
  @spec equal?(Time.t() | Comparable.comparable(), Time.t() | Comparable.comparable(), Comparable.granularity()) ::
          boolean | no_return
  def equal?(a, a, granularity \\ :seconds)
  def equal?(a, a, _granularity), do: true

  def equal?(a, b, granularity) do
    case compare(a, b, granularity) do
      {:error, reason} ->
        raise ArgumentError, message: "#{inspect(reason)}"

      0 ->
        true

      _ ->
        false
    end
  end

  @doc """
  See docs for `compare/3`
  """
  @spec compare(Time.t() | Comparable.comparable(), Time.t() | Comparable.comparable()) :: Comparable.compare_result()
  def compare(%Time{} = a, %Time{} = b) do
    compare(a, b, :microseconds)
  end

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

  You can optionally specify a comparison granularity from the list below.

  - :year
  - :years
  - :month
  - :months
  - :week (an alias for 7 days)
  - :weeks
  - :calendar_week (weeks of the calendar as opposed to actual weeks in terms of days)
  - :calendar_weeks
  - :day (an alias for 24 hours)
  - :days
  - :hour
  - :hours
  - :minute
  - :minutes
  - :second
  - :seconds
  - :millisecond
  - :milliseconds
  - :microsecond (default)
  - :microseconds
  - :duration

  ## Examples

      iex> date1 = ~D[2014-03-04]
      iex> date2 = ~D[2015-03-04]
      iex> Timex.compare(date1, date2, :year)
      -1
      iex> Timex.compare(date2, date1, :year)
      1
      iex> Timex.compare(date1, date1)
      0

  """
  @spec compare(Time.t() | Comparable.comparable(), Time.t() | Comparable.comparable(), Comparable.granularity()) ::
          Comparable.compare_result()
  def compare(%Time{} = a, %Time{} = b, granularity),
    do: Timex.Comparable.Utils.to_compare_result(diff(a, b, granularity))

  defdelegate compare(a, b, granularity), to: Timex.Comparable

  @doc """
  See docs for `diff/3`
  """
  @spec diff(Time.t() | Comparable.comparable(), Time.t() | Comparable.comparable()) ::
          Duration.t() | integer | {:error, term}
  def diff(%Time{} = a, %Time{} = b), do: diff(a, b, :microseconds)
  defdelegate diff(a, b), to: Timex.Comparable

  @doc """
  Calculate time interval between two dates. The result will be a signed integer, negative
  if the first date/time comes before the second, and positive if the first date/time comes
  after the second.

  You must specify one of the following units:

  - :year
  - :years
  - :month
  - :months
  - :week
  - :weeks
  - :calendar_week (weeks of the calendar as opposed to actual weeks in terms of days)
  - :calendar_weeks
  - :day
  - :days
  - :hour
  - :hours
  - :minute
  - :minutes
  - :second
  - :seconds
  - :millisecond
  - :milliseconds
  - :microsecond (default)
  - :microseconds
  - :duration

  and the result will be an integer value of those units or a Duration.
  """
  @spec diff(Time.t() | Comparable.comparable(), Time.t() | Comparable.comparable(), Comparable.granularity()) ::
          Duration.t() | integer | {:error, term}
  def diff(%Time{}, %Time{}, granularity)
      when granularity in [
             :day,
             :days,
             :week,
             :weeks,
             :calendar_week,
             :calendar_weeks,
             :month,
             :months,
             :year,
             :years
           ] do
    0
  end

  def diff(%Time{} = a, %Time{} = b, granularity) do
    a = ((a.hour * 60 + a.minute) * 60 + a.second) * 1_000 * 1_000 + elem(a.microsecond, 0)
    b = ((b.hour * 60 + b.minute) * 60 + b.second) * 1_000 * 1_000 + elem(b.microsecond, 0)

    case granularity do
      :duration -> Duration.from_seconds(div(a - b, 1_000 * 1_000))
      us when us in [:microseconds, :microsecond] -> a - b
      ms when ms in [:milliseconds, :millisecond] -> div(a - b, 1_000)
      s when s in [:seconds, :second] -> div(a - b, 1_000 * 1_000)
      min when min in [:minutes, :minute] -> div(a - b, 1_000 * 1_000 * 60)
      h when h in [:hours, :hour] -> div(a - b, 1_000 * 1_000 * 60 * 60)
      _ -> {:error, {:invalid_granularity, granularity}}
    end
  end

  defdelegate diff(a, b, granularity), to: Timex.Comparable

  @doc """
  Get the day of the week corresponding to the given name.

  The name can be given as a string of the weekday name or its first three characters
  (lowercase or capitalized) or as a corresponding atom (lowercase only).

  ## Examples

      iex> Timex.day_to_num("Monday")
      1
      iex> Timex.day_to_num("monday")
      1
      iex> Timex.day_to_num("Mon")
      1
      iex> Timex.day_to_num("mon")
      1
      iex> Timex.day_to_num(:mon)
      1
      iex> Timex.day_to_num(:sunday)
      7

  """
  @spec day_to_num(binary | atom()) :: Types.weekday() | {:error, :invalid_day_name}
  Enum.each(@weekdays, fn {day_name, day_num} ->
    lower = day_name |> String.downcase()
    abbr_cased = day_name |> String.slice(0..2)
    abbr_lower = lower |> String.slice(0..2)
    abbr_atom = abbr_lower |> String.to_atom()
    atom = lower |> String.to_atom()

    day_quoted =
      quote do
        def day_to_num(unquote(day_name)), do: unquote(day_num)
        def day_to_num(unquote(lower)), do: unquote(day_num)
        def day_to_num(unquote(abbr_cased)), do: unquote(day_num)
        def day_to_num(unquote(abbr_lower)), do: unquote(day_num)
        def day_to_num(unquote(abbr_atom)), do: unquote(day_num)
        def day_to_num(unquote(atom)), do: unquote(day_num)
      end

    Module.eval_quoted(__MODULE__, day_quoted, [], __ENV__)
  end)

  # Make an attempt at cleaning up the provided string
  def day_to_num(day) when is_binary(day) do
    case Map.get(Timex.Translator.get_weekdays_lookup(Timex.Translator.current_locale()), day) do
      nil ->
        {:error, :invalid_day_name}

      num ->
        num
    end
  end

  def day_to_num(_), do: {:error, :invalid_day_name}

  @doc """
  Get the name of the day corresponding to the provided number

  ## Examples

      iex> Timex.day_name(1)
      "Monday"
      iex> Timex.day_name(0)
      {:error, :invalid_weekday_number}
  """
  @spec day_name(Types.weekday()) :: String.t() | {:error, :invalid_weekday_number}
  def day_name(num) when num in 1..7 do
    weekdays = Translator.get_weekdays(Translator.current_locale())
    Map.get(weekdays, num)
  end

  def day_name(_), do: {:error, :invalid_weekday_number}

  @doc """
  Get the short name of the day corresponding to the provided number

  ## Examples

      iex> Timex.day_shortname(1)
      "Mon"
      iex> Timex.day_shortname(0)
      {:error, :invalid_weekday_number}
  """
  @spec day_shortname(Types.weekday()) :: String.t() | {:error, :invalid_weekday_number}
  def day_shortname(num) when num in 1..7 do
    weekdays = Translator.get_weekdays_abbreviated(Translator.current_locale())
    Map.get(weekdays, num)
  end

  def day_shortname(_), do: {:error, :invalid_weekday_number}

  @doc """
  Get the number of the month corresponding to the given name.

  ## Examples

      iex> Timex.month_to_num("January")
      1
      iex> Timex.month_to_num("january")
      1
      iex> Timex.month_to_num("Jan")
      1
      iex> Timex.month_to_num("jan")
      1
      iex> Timex.month_to_num(:jan)
      1
  """
  @spec month_to_num(binary) :: integer | {:error, :invalid_month_name}
  Enum.each(@months, fn {month_name, month_num} ->
    lower = month_name |> String.downcase()
    abbr_cased = month_name |> String.slice(0..2)
    abbr_lower = lower |> String.slice(0..2)
    symbol = abbr_lower |> String.to_atom()
    full_chars = month_name |> String.to_charlist()
    abbr_chars = abbr_cased |> String.to_charlist()

    # Account for months where full and abbr are equal
    month_quoted =
      if month_name == abbr_cased do
        quote do
          def month_to_num(unquote(month_name)), do: unquote(month_num)
          def month_to_num(unquote(lower)), do: unquote(month_num)
          def month_to_num(unquote(symbol)), do: unquote(month_num)
          def month_to_num(unquote(full_chars)), do: unquote(month_num)
        end
      else
        quote do
          def month_to_num(unquote(month_name)), do: unquote(month_num)
          def month_to_num(unquote(lower)), do: unquote(month_num)
          def month_to_num(unquote(abbr_cased)), do: unquote(month_num)
          def month_to_num(unquote(abbr_lower)), do: unquote(month_num)
          def month_to_num(unquote(symbol)), do: unquote(month_num)
          def month_to_num(unquote(full_chars)), do: unquote(month_num)
          def month_to_num(unquote(abbr_chars)), do: unquote(month_num)
        end
      end

    Module.eval_quoted(__MODULE__, month_quoted, [], __ENV__)
  end)

  # Make an attempt at cleaning up the provided string
  def month_to_num(_), do: {:error, :invalid_month_name}

  @doc """
  Get the name of the month corresponding to the provided number

  ## Examples

      iex> Timex.month_name(1)
      "January"
      iex> Timex.month_name(0)
      {:error, :invalid_month_number}
  """
  @spec month_name(Types.month()) :: String.t() | {:error, :invalid_month_number}
  def month_name(num) when num in 1..12 do
    months = Translator.get_months(Translator.current_locale())
    Map.get(months, num)
  end

  def month_name(_), do: {:error, :invalid_month_number}

  @doc """
  Get the short name of the month corresponding to the provided number

  ## Examples

      iex> Timex.month_shortname(1)
      "Jan"
      iex> Timex.month_shortname(0)
      {:error, :invalid_month_number}
  """
  @spec month_shortname(Types.month()) :: String.t() | {:error, :invalid_month_number}
  def month_shortname(num) when num in 1..12 do
    months = Translator.get_months_abbreviated(Translator.current_locale())
    Map.get(months, num)
  end

  def month_shortname(_), do: {:error, :invalid_month_number}

  @doc """
  Return weekday number (as defined by ISO 8601) of the specified date.

  ## Examples

      iex> Timex.epoch |> Timex.weekday
      4 # (i.e. Thursday)

  """
  @spec weekday(Types.valid_datetime()) :: Types.weekday() | {:error, :invalid_date}
  defdelegate weekday(datetime), to: Timex.Protocol

  @doc """
  Like `weekday/1`, but accepts a valid starting weekday value.

  ## Examples

      iex> Timex.epoch() |> #{__MODULE__}.weekday(:sunday)
      5
  """
  @spec weekday(Types.valid_datetime(), Calendar.day_of_week()) ::
          Types.weekday() | {:error, :invalid_date}
  defdelegate weekday(datetime, weekstart), to: Timex.Protocol

  @doc """
  Provides a version of `weekday/1` and `weekday/2` that raises on error.
  """
  def weekday!(datetime, weekstart \\ :default) do
    case weekday(datetime, weekstart) do
      {:error, :invalid_date} ->
        raise ArgumentError, message: "invalid_date"

      weekday when is_integer(weekday) ->
        weekday
    end
  end

  @doc """
  Returns the ordinal day number of the date.

  ## Examples

      iex> Timex.day(~D[2015-06-26])
      177
  """
  @spec day(Types.valid_datetime()) :: Types.daynum() | {:error, term}
  defdelegate day(datetime), to: Timex.Protocol

  @doc """
  Return the number of days in the month which the date falls on.

  ## Examples

      iex> Timex.days_in_month(~D[1970-01-01])
      31

  """
  @spec days_in_month(Types.valid_datetime()) :: Types.num_of_days() | {:error, term}
  defdelegate days_in_month(datetime), to: Timex.Protocol

  @doc """
  Same as days_in_month/2, except takes year and month as distinct arguments
  """
  @spec days_in_month(Types.year(), Types.month()) :: Types.num_of_days() | {:error, term}
  defdelegate days_in_month(year, month), to: Timex.Helpers

  @doc """
  Returns the week number of the date provided, starting at 1.

  ## Examples

      iex> Timex.week_of_month(~D[2016-03-05])
      1

      iex> Timex.week_of_month(~N[2016-03-14T00:00:00Z])
      3
  """
  @spec week_of_month(Types.valid_datetime()) :: Types.week_of_month()
  defdelegate week_of_month(datetime), to: Timex.Protocol

  @doc """
  Same as week_of_month/1, except takes year, month, and day as distinct arguments

  ## Examples

      iex> Timex.week_of_month(2016, 3, 30)
      5
  """
  @spec week_of_month(Types.year(), Types.month(), Types.day()) :: Types.week_of_month()
  def week_of_month(year, month, day) when is_date(year, month, day) do
    next_year = year + 1
    prev_year = year - 1

    week_index_of_given_date =
      case iso_week(year, month, day) do
        {^prev_year, _} ->
          0

        {^next_year, _} ->
          {_, week_index_of_given_date_shifted} = iso_week(year, month, day - 7)
          week_index_of_given_date_shifted + 1

        {_, week_index} ->
          week_index
      end

    week_index_of_first_day_of_given_month =
      case iso_week(year, month, 1) do
        {^prev_year, _} -> 0
        {_, week_index} -> week_index
      end

    week_index_of_given_date - week_index_of_first_day_of_given_month + 1
  end

  def week_of_month(_, _, _), do: {:error, :invalid_date}

  @doc """
  Given a date returns a date at the beginning of the month.

      iex> date = Timex.to_datetime({{2015, 6, 15}, {12,30,0}}, "Europe/Paris")
      iex> Timex.beginning_of_month(date)
      Timex.to_datetime({{2015, 6, 1}, {0, 0, 0}}, "Europe/Paris")

  """
  @spec beginning_of_month(Types.valid_datetime()) :: Types.valid_datetime() | {:error, term}
  defdelegate beginning_of_month(datetime), to: Timex.Protocol

  @doc """
  Same as beginning_of_month/1, except takes year and month as distinct arguments
  """
  @spec beginning_of_month(Types.year(), Types.month()) :: Date.t() | {:error, term}
  def beginning_of_month(year, month) when is_year(month) and is_month(month),
    do: %Date{year: year, month: month, day: 1}

  def beginning_of_month(_, _),
    do: {:error, :invalid_year_or_month}

  @doc """
  Given a date returns a date at the end of the month.

      iex> date = ~N[2015-06-15T12:30:00Z]
      iex> Timex.end_of_month(date)
      ~N[2015-06-30T23:59:59Z]

  """
  @spec end_of_month(Types.valid_datetime()) :: Types.valid_datetime() | {:error, term}
  defdelegate end_of_month(datetime), to: Timex.Protocol

  @doc """
  Same as end_of_month/1, except takes year and month as distinct arguments

  ## Examples

      iex> Timex.end_of_month(2016, 2)
      ~D[2016-02-29]
  """
  @spec end_of_month(Types.year(), Types.month()) :: Date.t()
  def end_of_month(year, month) when is_year(year) and is_month(month),
    do: end_of_month(%Date{year: year, month: month, day: 1})

  def end_of_month(_, _),
    do: {:error, :invalid_year_or_month}

  @doc """
  Returns what quarter of the year the given date/time falls in.

  ## Examples

      iex> Timex.quarter(4)
      2
  """
  @spec quarter(Types.month() | Types.valid_datetime()) :: 1..4 | {:error, term}
  def quarter(month) when is_month(month) do
    case month do
      m when m in 1..3 -> 1
      m when m in 4..6 -> 2
      m when m in 7..9 -> 3
      m when m in 10..12 -> 4
    end
  end

  def quarter(m) when is_integer(m), do: {:error, :invalid_month}
  def quarter(datetime), do: Timex.Protocol.quarter(datetime)

  @doc """
  Given a date returns a date at the beginning of the quarter.

      iex> date = Timex.to_datetime({{2015, 6, 15}, {12,30,0}}, "America/Chicago")
      iex> Timex.beginning_of_quarter(date)
      Timex.to_datetime({{2015, 4, 1}, {0, 0, 0}}, "America/Chicago")

  """
  @spec beginning_of_quarter(Types.valid_datetime()) :: Types.valid_datetime() | {:error, term}
  defdelegate beginning_of_quarter(datetime), to: Timex.Protocol

  @doc """
  Given a date or a year and month returns a date at the end of the quarter.

      iex> date = ~N[2015-06-15T12:30:00]
      ...> Timex.end_of_quarter(date)
      ~N[2015-06-30T23:59:59]

      iex> Timex.end_of_quarter(2015, 4)
      ~D[2015-06-30]

  """
  @spec end_of_quarter(Types.valid_datetime()) :: Types.valid_datetime() | {:error, term}
  defdelegate end_of_quarter(datetime), to: Timex.Protocol

  @doc """
  Same as end_of_quarter/1, except takes year and month as distinct arguments
  """
  @spec end_of_quarter(Types.year(), Types.month()) :: Date.t() | {:error, term}
  def end_of_quarter(year, month) when is_year(year) and is_month(month) do
    end_of_month(%Date{year: year, month: 3 * quarter(month), day: 1})
  end

  def end_of_quarter(_, _), do: {:error, :invalid_year_or_month}

  @doc """
  Given a date or a number create a date at the beginning of that year

  Examples

      iex> date = ~N[2015-06-15T00:00:00]
      iex> Timex.beginning_of_year(date)
      ~N[2015-01-01T00:00:00]

      iex> Timex.beginning_of_year(2015)
      ~D[2015-01-01]
  """
  @spec beginning_of_year(Types.year() | Types.valid_datetime()) ::
          Types.valid_datetime() | {:error, term}
  def beginning_of_year(year) when is_year(year),
    do: %Date{year: year, month: 1, day: 1}

  def beginning_of_year(datetime), do: Timex.Protocol.beginning_of_year(datetime)

  @doc """
  Given a date or a number create a date at the end of that year

  Examples

      iex> date = ~N[2015-06-15T00:00:00]
      iex> Timex.end_of_year(date)
      ~N[2015-12-31T23:59:59]

      iex> Timex.end_of_year(2015)
      ~D[2015-12-31]

  """
  @spec end_of_year(Types.year() | Types.valid_datetime()) ::
          Types.valid_datetime() | {:error, term}
  def end_of_year(year) when is_year(year),
    do: %Date{year: year, month: 12, day: 31}

  def end_of_year(datetime), do: Timex.Protocol.end_of_year(datetime)

  @doc """
  Number of days to the beginning of the week

  The weekstart determines which is the first day of the week, defaults to monday. It can be a number
  between 1..7 (1 is monday, 7 is sunday), or any value accepted by `day_to_num/1`.

  ## Examples

      iex> date = ~D[2015-11-30] # Monday 30th November
      iex> Timex.days_to_beginning_of_week(date)
      0

      iex> date = ~D[2015-11-30] # Monday 30th November
      iex> Timex.days_to_beginning_of_week(date, :sun)
      1

  """
  @spec days_to_beginning_of_week(Types.valid_datetime(), Types.weekstart()) ::
          integer | {:error, term}
  def days_to_beginning_of_week(date, weekstart \\ 1)

  def days_to_beginning_of_week(date, weekstart)
      when is_atom(weekstart) or is_binary(weekstart) do
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
      iex> date = ~D[2015-11-30] # Monday 30th November
      iex> Timex.days_to_end_of_week(date)
      6

      Week starting Sunday
      iex> date = ~D[2015-11-30] # Monday 30th November
      iex> Timex.days_to_end_of_week(date, :sun)
      5

  """
  @spec days_to_end_of_week(Types.valid_datetime(), Types.weekstart()) :: integer | {:error, term}
  def days_to_end_of_week(date, weekstart \\ :mon) do
    case days_to_beginning_of_week(date, weekstart) do
      {:error, _} = err -> err
      days -> abs(days - 6)
    end
  end

  @doc """
  Shifts the date to the beginning of the week

  The weekstart can between 1..7, an atom e.g. :mon, or a string e.g. "Monday"

  ## Examples

      iex> date = ~N[2015-11-30T13:30:30] # Monday 30th November
      iex> Timex.beginning_of_week(date)
      ~N[2015-11-30T00:00:00]

      iex> date = ~D[2015-11-30] # Monday 30th November
      iex> Timex.beginning_of_week(date, :sun)
      ~D[2015-11-29]

  """
  @spec beginning_of_week(Types.valid_datetime(), Types.weekstart()) ::
          Types.valid_datetime() | {:error, term}
  defdelegate beginning_of_week(date, weekstart \\ :mon), to: Timex.Protocol

  @doc """
  Returns a Date or a DateTime representing the end of the week, depending on the input,
  i.e. if you pass a date/time value which represents just a date, you will get back a Date,
  if both a date and time are present, you will get back a DateTime

  The weekstart can between 1..7, an atom e.g. :mon, or a string e.g. "Monday"

  ## Examples

      iex> date = ~N[2015-11-30T13:30:30] # Monday 30th November
      ...> Timex.end_of_week(date)
      ~N[2015-12-06T23:59:59]

      iex> date = ~D[2015-11-30] # Monday 30th November
      ...> Timex.end_of_week(date, :sun)
      ~D[2015-12-05]

  """
  @spec end_of_week(Types.valid_datetime(), Types.weekstart()) ::
          Types.valid_datetime() | {:error, term}
  defdelegate end_of_week(datetime, weekstart \\ 1), to: Timex.Protocol

  @doc """
  Returns a DateTime representing the beginning of the day

  ## Examples

      iex> date = Timex.to_datetime({{2015, 1, 1}, {13, 14, 15}}, "Etc/UTC")
      iex> Timex.beginning_of_day(date)
      Timex.to_datetime({{2015, 1, 1}, {0, 0, 0}}, "Etc/UTC")

      iex> date = ~D[2015-01-01]
      ...> Timex.beginning_of_day(date)
      ~D[2015-01-01]

  """
  @spec beginning_of_day(Types.valid_datetime()) :: Types.valid_datetime() | {:error, term}
  defdelegate beginning_of_day(datetime), to: Timex.Protocol

  @doc """
  Returns a DateTime representing the end of the day

  ## Examples

      iex> date = ~N[2015-01-01T13:14:15]
      ...> Timex.end_of_day(date)
      ~N[2015-01-01T23:59:59]

  """
  @spec end_of_day(Types.valid_datetime()) :: Types.valid_datetime() | {:error, term}
  defdelegate end_of_day(datetime), to: Timex.Protocol

  @doc """
  Return a boolean indicating whether the given year is a leap year. You may
  pass a date or a year number.

  ## Examples

      iex> Timex.epoch() |> Timex.is_leap?
      false
      iex> Timex.is_leap?(2012)
      true

  """
  @spec is_leap?(Types.valid_datetime() | Types.year()) :: boolean | {:error, term}
  def is_leap?(year) when is_year(year), do: :calendar.is_leap_year(year)
  defdelegate is_leap?(date), to: Timex.Protocol

  @doc """
  Add time to a date using a Duration
  Same as `shift(date, Duration.from_minutes(5), :duration)`.
  """
  @spec add(Types.valid_datetime(), Duration.t()) ::
          Types.valid_datetime() | AmbiguousDateTime.t() | {:error, term}
  def add(date, %Duration{megaseconds: mega, seconds: sec, microseconds: micro}),
    do: shift(date, seconds: mega * @million + sec, microseconds: micro)

  @doc """
  Subtract time from a date using a Duration
  Same as `shift(date, Duration.from_minutes(5) |> Duration.invert, :timestamp)`.
  """
  @spec subtract(Types.valid_datetime(), Duration.t()) ::
          Types.valid_datetime() | AmbiguousDateTime.t() | {:error, term}
  def subtract(date, %Duration{megaseconds: mega, seconds: sec, microseconds: micro}),
    do: shift(date, seconds: -mega * @million - sec, microseconds: -micro)

  @doc """
  A single function for adjusting the date using various units: duration,
  microseconds, seconds, minutes, hours, days, weeks, months, years.

  The result of applying the shift will be the same type as that of the input,
  with the exception of shifting DateTimes, which may result in an AmbiguousDateTime
  if the shift moves to an ambiguous time period for the zone of that DateTime.

  Shifting by months will always return a date in the expected month. Because months
  have different number of days, shifting to a month with fewer days may not be
  the same day of the month as the original date.

  If an error occurs, an error tuple will be returned.

  ## Examples

  ### Shifting across timezone changes

      iex> use Timex
      ...> datetime = Timex.to_datetime({{2016,3,13}, {1,0,0}}, "America/Chicago")
      ...> # 2-3 AM doesn't exist due to leap forward, shift accounts for this
      ...> %DateTime{hour: 3} = Timex.shift(datetime, hours: 1)
      ...> shifted = Timex.shift(datetime, hours: 1)
      ...> {datetime.zone_abbr, shifted.zone_abbr, shifted.hour}
      {"CST", "CDT", 3}

  ### Shifting and leap days

      iex> use Timex
      ...> date = ~D[2016-02-29]
      ...> Timex.shift(date, years: -1)
      ~D[2015-03-01]

  ### Shifting by months

      iex> date = ~D[2016-01-15]
      ...> Timex.shift(date, months: 1)
      ~D[2016-02-15]

      iex> date = ~D[2016-01-31]
      ...> Timex.shift(date, months: 1)
      ~D[2016-02-29]

      iex> date = ~D[2016-01-31]
      ...> Timex.shift(date, months: 2)
      ~D[2016-03-31]
      ...> Timex.shift(date, months: 1) |> Timex.shift(months: 1)
      ~D[2016-03-29]
  """
  @type shift_options :: [
          microseconds: integer,
          milliseconds: integer,
          seconds: integer,
          minutes: integer,
          hours: integer,
          days: integer,
          weeks: integer,
          months: integer,
          years: integer,
          duration: Duration.t()
        ]
  @spec shift(Types.valid_datetime(), shift_options) ::
          Types.valid_datetime() | AmbiguousDateTime.t() | {:error, term}
  defdelegate shift(date, options), to: Timex.Protocol

  @doc """
  Return a new date/time value with the specified fields replaced by new values.

  Values are automatically validated and clamped to good values by default. If
  you wish to skip validation, perhaps for performance reasons, pass `validate: false`.

  Values are applied in order, so if you pass `[datetime: dt, date: d]`, the date value
  from `date` will override `datetime`'s date value.

  Options which do not apply to the input value (for example, `:hour` against a `Date` struct),
  will be ignored.

  ## Example

      iex> use Timex
      ...> expected = ~D[2015-02-28]
      ...> result = Timex.set(expected, [month: 2, day: 30])
      ...> result == expected
      true

      iex> use Timex
      ...> expected = ~N[2016-02-29T23:30:00]
      ...> result = Timex.set(expected, [hour: 30])
      ...> result === expected
      true

  """
  @type set_options :: [
          validate: boolean,
          datetime: Types.datetime(),
          date: Types.valid_date(),
          time: Types.valid_time(),
          year: Types.year(),
          month: Types.month(),
          day: Types.day(),
          hour: Types.hour(),
          minute: Types.minute(),
          second: Types.second(),
          microsecond: Types.microsecond()
        ]
  @spec set(Types.valid_datetime(), set_options) :: Types.valid_datetime()
  defdelegate set(date, options), to: Timex.Protocol

  @doc """
  Given a unit to normalize, and the value to normalize, produces a valid
  value for that unit, clamped to whatever boundaries are defined for that unit.


  ## Example

      iex> Timex.normalize(:hour, 26)
      23
  """
  @spec normalize(:date, {integer, integer, integer}) :: Types.date()
  @spec normalize(:time, {integer, integer, integer} | {integer, integer, integer, integer}) ::
          Types.time()
  @spec normalize(:day, {integer, integer, integer}) :: non_neg_integer
  @spec normalize(
          :year | :month | :day | :hour | :minute | :second | :millisecond | :microsecond,
          integer
        ) :: non_neg_integer
  def normalize(:date, {year, month, day}) do
    year = normalize(:year, year)
    month = normalize(:month, month)
    day = normalize(:day, {year, month, day})
    {year, month, day}
  end

  def normalize(:year, year) when year < 0, do: 0
  def normalize(:year, year), do: year

  def normalize(:month, month) do
    cond do
      month < 1 -> 1
      month > 12 -> 12
      :else -> month
    end
  end

  def normalize(:time, {hour, min, sec}) do
    hour = normalize(:hour, hour)
    min = normalize(:minute, min)
    sec = normalize(:second, sec)
    {hour, min, sec}
  end

  def normalize(:time, {hour, min, sec, ms}) do
    {h, m, s} = normalize(:time, {hour, min, sec})
    msecs = normalize(:millisecond, ms)
    {h, m, s, msecs}
  end

  def normalize(:hour, hour) do
    cond do
      hour < 0 -> 0
      hour > 23 -> 23
      :else -> hour
    end
  end

  def normalize(:minute, min) do
    cond do
      min < 0 -> 0
      min > 59 -> 59
      :else -> min
    end
  end

  def normalize(:second, sec) do
    cond do
      sec < 0 -> 0
      sec > 59 -> 59
      :else -> sec
    end
  end

  def normalize(:millisecond, ms) do
    cond do
      ms < 0 -> 0
      ms > 999 -> 999
      :else -> ms
    end
  end

  def normalize(:microsecond, {us, p}) do
    cond do
      us < 0 -> {0, p}
      us > 999_999 -> {999_999, p}
      :else -> {us, p}
    end
  end

  def normalize(:microsecond, us) when is_integer(us) and us >= 0 and us <= 999_999 do
    Timex.DateTime.Helpers.construct_microseconds(us, -1)
  end

  def normalize(:day, {year, month, day}) do
    year = normalize(:year, year)
    month = normalize(:month, month)

    ndays =
      case Timex.days_in_month(year, month) do
        n when is_integer(n) -> n
      end

    cond do
      day < 1 -> 1
      day > ndays -> ndays
      :else -> day
    end
  end

  @weekdays [
    :monday,
    :tuesday,
    :wednesday,
    :thursday,
    :friday,
    :saturday,
    :sunday
  ]

  @doc false
  def standardize_week_start(value)

  def standardize_week_start(a) when is_atom(a) and a in @weekdays, do: a
  def standardize_week_start(:mon), do: :monday
  def standardize_week_start(:tue), do: :tuesday
  def standardize_week_start(:wed), do: :wednesday
  def standardize_week_start(:thu), do: :thursday
  def standardize_week_start(:fri), do: :friday
  def standardize_week_start(:sat), do: :saturday
  def standardize_week_start(:sun), do: :sunday

  def standardize_week_start(n) when is_integer(n) and n >= 1 and n <= 7 do
    Enum.at(@weekdays, n - 1)
  end

  def standardize_week_start(s) when is_binary(s) do
    a = s |> String.downcase() |> String.to_existing_atom()

    if a in @weekdays do
      a
    else
      {:error, :invalid_week_start}
    end
  rescue
    _ ->
      {:error, :invalid_week_start}
  end

  def standardize_week_start(_), do: {:error, :invalid_week_start}
end

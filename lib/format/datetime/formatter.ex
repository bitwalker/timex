defmodule Timex.Format.DateTime.Formatter do
  use Behaviour

  alias Timex.Date
  alias Timex.Time
  alias Timex.Timezone
  alias Timex.DateTime
  alias Timex.Format.FormatError
  alias Timex.Format.DateTime.Formatters.Default
  alias Timex.Parse.DateTime.Tokenizers.Directive

  defcallback tokenize(format_string :: String.t) :: {:ok, [%Directive{}]} | {:error, term}
  defcallback format(date :: %DateTime{}, format_string :: String.t)  :: {:ok, String.t} | {:error, term}
  defcallback format!(date :: %DateTime{}, format_string :: String.t) :: String.t | no_return

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Timex.Format.DateTime.Formatter

      alias Timex.Parse.DateTime.Tokenizers.Directive
      import Timex.Format.DateTime.Formatter, only: [format_token: 5]
    end
  end

  @doc """
  Formats a DateTime struct as a string, using the provided format
  string and formatter. If a formatter is not provided, the formatter
  used is `Timex.DateFormat.Formatters.DefaultFormatter`.

  If an error is encountered during formatting, `format!` will raise.
  """
  @spec format!(%DateTime{}, String.t, atom | nil) :: String.t | no_return
  def format!(%DateTime{} = date, format_string, formatter \\ Default)
    when is_binary(format_string) and is_atom(formatter)
    do
      case format(date, format_string, formatter) do
        {:ok, result}    -> result
        {:error, reason} -> raise FormatError, message: reason
      end
  end

  @doc """
  Formats a DateTime struct as a string, using the provided format
  string and formatter. If a formatter is not provided, the formatter
  used is `Timex.DateFormat.Formatters.DefaultFormatter`.
  """
  @spec format(%DateTime{}, String.t, atom | nil) :: {:ok, String.t} | {:error, term}
  def format(date, format_string, formatter \\ Default)

  def format(%DateTime{} = date, format_string, formatter)
    when is_binary(format_string) and is_atom(formatter),
    do: formatter.format(date, format_string)

  @doc """
  Validates the provided format string, using the provided formatter,
  or if none is provided, the default formatter. Returns `:ok` when valid,
  or `{:error, reason}` if not valid.
  """
  @spec validate(String.t, atom | nil) :: :ok | {:error, term}
  def validate(format_string, formatter \\ Default) when is_binary(format_string) do
    try do
      case formatter.tokenize(format_string) do
        {:error, _} = error -> error
        {:ok, []} -> {:error, "There were no formatting directives in the provided string."}
        {:ok, directives} when is_list(directives)-> :ok
      end
    rescue
      x -> {:error, x}
    end
  end

  @doc """
  Given a token (as found in `Timex.Parsers.Directive`), and a DateTime struct,
  produce a string representation of the token using values from the struct.
  """
  @spec format_token(atom, %DateTime{}, list(), list(), list()) :: String.t | {:error, term}
  def format_token(token, date, modifiers, flags, width)

  # Formats
  def format_token(:iso_date, %DateTime{} = date, modifiers, _flags, _width) do
    flags = [padding: :zeroes]
    year  = format_token(:year4, date, modifiers, flags, width_spec(4..4))
    month = format_token(:month, date, modifiers, flags, width_spec(2..2))
    day   = format_token(:day, date, modifiers, flags, width_spec(2..2))
    "#{year}-#{month}-#{day}"
  end
  def format_token(:iso_time, %DateTime{} = date, modifiers, _flags, _width) do
    flags  = [padding: :zeroes]
    hour   = format_token(:hour24, date, modifiers, flags, width_spec(2..2))
    minute = format_token(:min, date, modifiers, flags, width_spec(2..2))
    sec    = format_token(:sec, date, modifiers, flags, width_spec(2..2))
    ms     = format_token(:sec_fractional, date, modifiers, flags, width_spec(-1, nil))
    "#{hour}:#{minute}:#{sec}#{ms}"
  end
  def format_token(token, %DateTime{} = date, modifiers, _flags, _width)
    when token in [:iso_8601, :iso_8601z] do
    date  = case token do
      :iso_8601  -> date
      :iso_8601z -> Timezone.convert(date, "UTC")
    end
    flags = [padding: :zeroes]
    year  = format_token(:year4, date, modifiers, flags, width_spec(4..4))
    month = format_token(:month, date, modifiers, flags, width_spec(2..2))
    day   = format_token(:day, date, modifiers, flags, width_spec(2..2))
    hour  = format_token(:hour24, date, modifiers, flags, width_spec(2..2))
    min   = format_token(:min, date, modifiers, flags, width_spec(2..2))
    sec   = format_token(:sec, date, modifiers, flags, width_spec(2..2))
    ms    = format_token(:sec_fractional, date, modifiers, flags, width_spec(-1, nil))
    case token do
      :iso_8601 ->
        tz = format_token(:zoffs, date, modifiers, flags, width_spec(-1, nil))
        "#{year}-#{month}-#{day}T#{hour}:#{min}:#{sec}#{ms}#{tz}"
      :iso_8601z ->
        "#{year}-#{month}-#{day}T#{hour}:#{min}:#{sec}#{ms}Z"
    end
  end
  def format_token(token, %DateTime{} = date, modifiers, _flags, _width)
    when token in [:rfc_822, :rfc_822z] do
    # Mon, 05 Jun 14 23:20:59 +0200
    date = case token do
      :rfc_822  -> date
      :rfc_822z -> Timezone.convert(date, "UTC")
    end
    flags = [padding: :zeroes]
    year  = format_token(:year2, date, modifiers, flags, width_spec(2..2))
    month = format_token(:mshort, date, modifiers, flags, width_spec(-1, nil))
    day   = format_token(:day, date, modifiers, flags, width_spec(2..2))
    hour  = format_token(:hour24, date, modifiers, flags, width_spec(2..2))
    min   = format_token(:min, date, modifiers, flags, width_spec(2..2))
    sec   = format_token(:sec, date, modifiers, flags, width_spec(2..2))
    wday  = format_token(:wdshort, date, modifiers, flags, width_spec(-1, nil))
    case token do
      :rfc_822 ->
        tz = format_token(:zoffs, date, modifiers, flags, width_spec(-1, nil))
        "#{wday}, #{day} #{month} #{year} #{hour}:#{min}:#{sec} #{tz}"
      :rfc_822z ->
        "#{wday}, #{day} #{month} #{year} #{hour}:#{min}:#{sec} Z"
    end
  end
  def format_token(token, %DateTime{} = date, modifiers, _flags, _width)
    when token in [:rfc_1123, :rfc_1123z] do
    # `Tue, 05 Mar 2013 23:25:19 GMT`
    date = case token do
      :rfc_1123  -> date
      :rfc_1123z -> Timezone.convert(date, "UTC")
    end
    flags = [padding: :zeroes]
    year  = format_token(:year4, date, modifiers, flags, width_spec(4..4))
    month = format_token(:mshort, date, modifiers, flags, width_spec(-1, nil))
    day   = format_token(:day, date, modifiers, flags, width_spec(2..2))
    hour  = format_token(:hour24, date, modifiers, flags, width_spec(2..2))
    min   = format_token(:min, date, modifiers, flags, width_spec(2..2))
    sec   = format_token(:sec, date, modifiers, flags, width_spec(2..2))
    wday  = format_token(:wdshort, date, modifiers, flags, width_spec(-1, nil))
    case token do
      :rfc_1123 ->
        tz = format_token(:zoffs, date, modifiers, flags, width_spec(-1, nil))
        "#{wday}, #{day} #{month} #{year} #{hour}:#{min}:#{sec} #{tz}"
      :rfc_1123z ->
        "#{wday}, #{day} #{month} #{year} #{hour}:#{min}:#{sec} Z"
    end
  end
  def format_token(token, %DateTime{} = date, modifiers, _flags, _width)
    when token in [:rfc_3339, :rfc_3339z] do
    # `2013-03-05T23:25:19+02:00`
    date  = case token do
      :rfc_3339  -> date
      :rfc_3339z -> Timezone.convert(date, "UTC")
    end
    flags = [padding: :zeroes]
    year  = format_token(:year4, date, modifiers, flags, width_spec(4..4))
    month = format_token(:month, date, modifiers, flags, width_spec(2..2))
    day   = format_token(:day, date, modifiers, flags, width_spec(2..2))
    hour  = format_token(:hour24, date, modifiers, flags, width_spec(2..2))
    min   = format_token(:min, date, modifiers, flags, width_spec(2..2))
    sec   = format_token(:sec, date, modifiers, flags, width_spec(2..2))
    ms    = format_token(:sec_fractional, date, modifiers, flags, width_spec(-1, nil))
    case token do
      :rfc_3339 ->
        tz = format_token(:zoffs_colon, date, modifiers, flags, width_spec(-1, nil))
        "#{year}-#{month}-#{day}T#{hour}:#{min}:#{sec}#{ms}#{tz}"
      :rfc_3339z ->
        "#{year}-#{month}-#{day}T#{hour}:#{min}:#{sec}#{ms}Z"
    end
  end
  def format_token(:unix, %DateTime{} = date, modifiers, _flags, _width) do
    # Tue Mar  5 23:25:19 PST 2013`
    flags = [padding: :zeroes]
    year  = format_token(:year4, date, modifiers, [padding: :spaces], width_spec(4..4))
    month = format_token(:mshort, date, modifiers, flags, width_spec(-1, nil))
    day   = format_token(:day, date, modifiers, [padding: :spaces], width_spec(2..2))
    hour  = format_token(:hour24, date, modifiers, [padding: :zeroes], width_spec(2..2))
    min   = format_token(:min, date, modifiers, [padding: :zeroes], width_spec(2..2))
    sec   = format_token(:sec, date, modifiers, [padding: :zeroes], width_spec(2..2))
    wday  = format_token(:wdshort, date, modifiers, flags, width_spec(-1, nil))
    tz    = format_token(:zname, date, modifiers, flags, width_spec(-1, nil))
    "#{wday} #{month} #{day} #{hour}:#{min}:#{sec} #{tz} #{year}"
  end
  def format_token(:ansic, %DateTime{} = date, modifiers, flags, _width) do
    # Tue Mar  5 23:25:19 2013`
    year  = format_token(:year4, date, modifiers, [padding: :spaces], width_spec(4..4))
    month = format_token(:mshort, date, modifiers, flags, width_spec(-1, nil))
    day   = format_token(:day, date, modifiers, [padding: :spaces], width_spec(2..2))
    hour  = format_token(:hour24, date, modifiers, [padding: :zeroes], width_spec(2..2))
    min   = format_token(:min, date, modifiers, [padding: :zeroes], width_spec(2..2))
    sec   = format_token(:sec, date, modifiers, [padding: :zeroes], width_spec(2..2))
    wday  = format_token(:wdshort, date, modifiers, flags, width_spec(-1, nil))
    "#{wday} #{month} #{day} #{hour}:#{min}:#{sec} #{year}"
  end
  def format_token(:kitchen, %DateTime{} = date, modifiers, _flags, _width) do
    # `3:25PM`
    hour  = format_token(:hour12, date, modifiers, [], width_spec(2..2))
    min   = format_token(:min, date, modifiers, [padding: :zeroes], width_spec(2..2))
    ampm  = format_token(:AM, date, modifiers, [], width_spec(-1, nil))
    "#{hour}:#{min}#{ampm}"
  end
  def format_token(:slashed, %DateTime{} = date, modifiers, _flags, _width) do
    # `04/12/1987`
    flags = [padding: :zeroes]
    year  = format_token(:year2, date, modifiers, flags, width_spec(2..2))
    month = format_token(:month, date, modifiers, flags, width_spec(2..2))
    day   = format_token(:day, date, modifiers, flags, width_spec(2..2))
    "#{month}/#{day}/#{year}"
  end
  def format_token(token, %DateTime{} = date, modifiers, _flags, _width)
    when token in [:strftime_iso_clock, :strftime_iso_clock_full] do
    # `23:30:05`
    flags = [padding: :zeroes]
    hour  = format_token(:hour24, date, modifiers, flags, width_spec(2..2))
    min   = format_token(:min, date, modifiers, flags, width_spec(2..2))
    case token do
      :strftime_iso_clock -> "#{hour}:#{min}"
      :strftime_iso_clock_full ->
        sec = format_token(:sec, date, modifiers, flags, width_spec(2..2))
        "#{hour}:#{min}:#{sec}"
    end
  end
  def format_token(:strftime_kitchen, %DateTime{} = date, modifiers, _flags, _width) do
    # `04:30:01 PM`
    hour  = format_token(:hour12, date, modifiers, [padding: :zeroes], width_spec(2..2))
    min   = format_token(:min, date, modifiers, [padding: :zeroes], width_spec(2..2))
    sec   = format_token(:sec, date, modifiers, [padding: :zeroes], width_spec(2..2))
    ampm  = format_token(:AM, date, modifiers, [], width_spec(-1, nil))
    "#{hour}:#{min}:#{sec} #{ampm}"
  end
  def format_token(:strftime_iso_shortdate, %DateTime{} = date, modifiers, _flags, _width) do
    # ` 5-Jan-2014`
    flags = [padding: :zeroes]
    year  = format_token(:year4, date, modifiers, flags, width_spec(4..4))
    month = format_token(:mshort, date, modifiers, flags, width_spec(-1, nil))
    day   = format_token(:day, date, modifiers, [padding: :spaces], width_spec(2..2))
    "#{day}-#{month}-#{year}"
  end
  def format_token(:iso_week, %DateTime{} = date, modifiers, _flags, _width) do
    # 2015-W04
    flags = [padding: :zeroes]
    year = format_token(:year4, date, modifiers, flags, width_spec(4..4))
    week = format_token(:iso_weeknum, date, modifiers, flags, width_spec(2..2))
    "#{year}-W#{week}"
  end
  def format_token(:iso_weekday, %DateTime{} = date, modifiers, _flags, _width) do
    # 2015-W04-1
    flags = [padding: :zeroes]
    year = format_token(:year4, date, modifiers, flags, width_spec(4..4))
    week = format_token(:iso_weeknum, date, modifiers, flags, width_spec(2..2))
    day  = format_token(:wday_mon, date, modifiers, flags, width_spec(1, 1))
    "#{year}-W#{week}-#{day}"
  end
  def format_token(:iso_ordinal, %DateTime{} = date, modifiers, _flags, _width) do
    # 2015-180
    flags = [padding: :zeroes]
    year = format_token(:year4, date, modifiers, flags, width_spec(4..4))
    day  = format_token(:oday, date, modifiers, flags, width_spec(3..3))
    "#{year}-#{day}"
  end

  # Years
  def format_token(:year4, %DateTime{year: year}, _modifiers, flags, width),   do: "#{pad_numeric(year, flags, width)}"
  def format_token(:year2, %DateTime{year: year}, _modifiers, flags, width),   do: "#{pad_numeric(rem(year, 100), flags, width)}"
  def format_token(:century, %DateTime{year: year}, _modifiers, flags, width), do: "#{pad_numeric(div(year, 100), flags, width)}"
  def format_token(:iso_year4,  %DateTime{} = date, _modifiers, flags, width) do
    {iso_year, _} = date |> Date.iso_week
    "#{pad_numeric(iso_year, flags, width)}"
  end
  def format_token(:iso_year2,  %DateTime{} = date, _modifiers, flags, width) do
    {iso_year, _} = date |> Date.iso_week
    "#{pad_numeric(rem(iso_year, 100), flags, width)}"
  end
  # Months
  def format_token(:month, %DateTime{month: month}, _modifiers, flags, width), do: "#{pad_numeric(month, flags, width)}"
  def format_token(:mshort, %DateTime{month: month}, _, _, _), do: Date.month_shortname(month)
  def format_token(:mfull, %DateTime{month: month}, _, _, _),  do: Date.month_name(month)
  # Days
  def format_token(:day, %DateTime{day: day}, _modifiers, flags, width), do: "#{pad_numeric(day, flags, width)}"
  def format_token(:oday, %DateTime{} = date, _modifiers, flags, width), do: "#{pad_numeric(Date.day(date), flags, width)}"
  # Weeks
  def format_token(:iso_weeknum, %DateTime{} = date, _modifiers, flags, width) do
    {_, week} = Date.iso_week(date)
    "#{pad_numeric(week, flags, width)}"
  end
  def format_token(:week_mon, %DateTime{} = date, _modifiers, flags, width) do
    {_, week} = Date.iso_week(date)
    "#{pad_numeric(week, flags, width)}"
  end
  def format_token(:week_sun, %DateTime{year: year} = date, _modifiers, flags, width) do
    weeks_in_year = case Date.iso_week({year, 12, 31}) do
      {^year, 53} -> 53
      _           -> 52
    end
    ordinal = Date.day(date)
    weekday = case Date.weekday(date) do # shift back one since our week starts with Sunday instead of Monday
      7 -> 0
      x -> x
    end
    week = div(ordinal - weekday + 10, 7)
    week = cond do
      week < 1  -> 52
      week < 53 -> week
      week > 52 && weeks_in_year == 52 -> 1
      true -> 53
    end
    "#{pad_numeric(week, flags, width)}"
  end
  def format_token(:wday_mon, %DateTime{} = date, _modifiers, flags, width),
    do: "#{Date.weekday(date) |> pad_numeric(flags, width)}"
  def format_token(:wday_sun, %DateTime{} = date, _modifiers, flags, width) do
    # from 1..7 to 0..6
    weekday = case Date.weekday(date) do
      7   -> 0
      day -> day
    end
    "#{pad_numeric(weekday, flags, width)}"
  end
  def format_token(:wdshort, %DateTime{} = date, _modifiers, _flags, _width),
    do: "#{Date.weekday(date) |> Date.day_shortname}"
  def format_token(:wdfull, %DateTime{} = date, _modifiers, _flags, _width),
    do: "#{Date.weekday(date) |> Date.day_name}"
  # Hours
  def format_token(:hour24, %DateTime{hour: hour}, _modifiers, flags, width), do: "#{pad_numeric(hour, flags, width)}"
  def format_token(:hour12, %DateTime{hour: hour}, _modifiers, flags, width) do
    {h, _} = Time.to_12hour_clock(hour)
    "#{pad_numeric(h, flags, width)}"
  end
  def format_token(:min, %DateTime{minute: min}, _modifiers, flags, width), do: "#{pad_numeric(min, flags, width)}"
  def format_token(:sec, %DateTime{second: sec}, _modifiers, flags, width), do: "#{pad_numeric(sec, flags, width)}"
  def format_token(:sec_fractional, %DateTime{ms: 0}, _modifiers, _flags, _width), do: <<>>
  def format_token(:sec_fractional, %DateTime{ms: ms}, _modifiers, _flags, _width)
    when ms < 10, do: ".00#{trunc(ms)}"
  def format_token(:sec_fractional, %DateTime{ms: ms}, _modifiers, _flags, _width)
    when ms < 100, do: ".0#{trunc(ms)}"
  def format_token(:sec_fractional, %DateTime{ms: ms}, _modifiers, _flags, _width),
    do: ".#{trunc(ms)}"

  def format_token(:sec_epoch, %DateTime{} = date, _modifiers, flags, width) do
    case get_in(flags, [:padding]) do
      padding when padding in [:zeroes, :spaces] ->
        {:error, {:formatter, "Invalid directive flag: Cannot pad seconds from epoch, as it is not a fixed width integer."}}
      _ ->
        "#{Date.to_secs(date, :epoch) |> pad_numeric(flags, width)}"
    end
  end
  def format_token(:us, %DateTime{ms: ms}, _modifiers, flags, width) do
    "#{pad_numeric(ms, flags, width)}000"
  end
  def format_token(:am, %DateTime{hour: hour}, _modifiers, _flags, _width),
    do: "#{{_, am_pm} = Time.to_12hour_clock(hour); Atom.to_string(am_pm)}"
  def format_token(:AM, %DateTime{} = date, modifiers, flags, width),
    do: format_token(:am, date, modifiers, flags, width) |> String.upcase
  # Timezones
  def format_token(:zname, %DateTime{timezone: tz}, _modifiers, _flags, _width),
    do: tz.abbreviation
  def format_token(:zoffs, %DateTime{timezone: tz}, _modifiers, flags, _width) do
    case get_in(flags, [:padding]) do
      padding when padding in [:spaces, :none] ->
        {:error, {:formatter, "Invalid directive flag: Timezone offsets require 0-padding to remain unambiguous."}}
      _ ->
        offset_hours = div(tz.offset_std + tz.offset_utc, 60)
        offset_mins  = rem(tz.offset_std + tz.offset_utc, 60)
        hour  = "#{pad_numeric(offset_hours, [padding: :zeroes], width_spec(2..2))}"
        min   = "#{pad_numeric(offset_mins, [padding: :zeroes], width_spec(2..2))}"
        cond do
          (offset_hours + offset_mins) >= 0 -> "+#{hour}#{min}"
          true -> "#{hour}#{min}"
        end
    end
  end
  def format_token(:zoffs_colon, %DateTime{} = date, modifiers, flags, width) do
    case format_token(:zoffs, date, modifiers, flags, width) do
      {:error, _} = err -> err
      offset ->
        [qualifier, <<hour::binary-size(2), min::binary-size(2)>>] = offset |> String.split("", [trim: true, parts: 2])
        <<qualifier::binary, hour::binary, ?:, min::binary>>
    end
  end
  def format_token(:zoffs_sec, %DateTime{} = date, modifiers, flags, width) do
    case format_token(:zoffs, date, modifiers, flags, width) do
      {:error,_} = err -> err
      offset ->
        [qualifier, <<hour::binary-size(2), min::binary-size(2)>>] = offset |> String.split("", [trim: true, parts: 2])
        <<qualifier::binary, hour::binary, ?:, min::binary, ?:, ?0, ?0>>
    end
  end
  def format_token(token, _, _, _, _) do
    {:error, {:formatter, "Unsupported token: #{token}"}}
  end

  defp pad_numeric(number, flags, width) when is_integer(number), do: pad_numeric("#{number}", flags, width)
  defp pad_numeric(number_str, [], _width), do: number_str
  defp pad_numeric(<<?-, number_str::binary>>, flags, width) do
    res = pad_numeric(number_str, flags, width)
    <<?-, res::binary>>
  end
  defp pad_numeric(number_str, flags, [min: min_width, max: max_width]) do
    case get_in(flags, [:padding]) do
      pad_type when pad_type in [nil, :none] -> number_str
      pad_type ->
        len       = String.length(number_str)
        cond do
          min_width == -1 && max_width == nil  -> number_str
          len < min_width && max_width == nil  -> String.duplicate(pad_char(pad_type), min_width - len) <> number_str
          max_width != nil && len < max_width -> String.duplicate(pad_char(pad_type), max_width - len) <> number_str
          true                                 -> number_str
        end
    end
  end
  defp pad_char(:zeroes), do: <<?0>>
  defp pad_char(:spaces), do: <<32>>

  defp width_spec(min..max), do: [min: min, max: max]
  defp width_spec(min, max), do: [min: min, max: max]
end

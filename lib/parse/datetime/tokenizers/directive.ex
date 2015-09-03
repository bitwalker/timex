defmodule Timex.Parse.DateTime.Tokenizers.Directive do
  @moduledoc false
  alias Timex.Parse.DateTime.Parsers
  alias Timex.Parse.DateTime.Tokenizers.Directive

  defstruct type: :literal,
            value: nil,
            modifiers: [],
            flags: [],
            width: [min: -1, max: nil],
            parser: nil,
            weight: 0

  @doc """
  Gets a parsing directive for the given token name, where the token name
  is an atom.

  ## Examples

      iex> alias Timex.Parsers.Directive
      ...> %Directive{type: type, flags: flags} = Directive.get(:year4, "YYYY", padding: :zeros)
      ...> {type, flags}
      {:year4, [padding: :zeros]}

  """
  @spec get(atom, String.t, [{atom, term}] | []) :: %Directive{}
  def get(type, directive, opts \\ []) do
    width     = Keyword.get(opts, :width, [min: 1, max: nil])
    flags     = Keyword.merge(Keyword.get(opts, :flags, []), width)
    modifiers = Keyword.get(opts, :modifiers, [])
    get(type, directive, flags, modifiers, width)
  end

  # Years
  def get(:year4, directive, flags, mods, width),
    do: %Directive{type: :year4, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.year4(flags)}
  def get(:year2, directive, flags, mods, width),
    do: %Directive{type: :year2, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.year2(flags)}
  def get(:century, directive, flags, mods, width),
    do: %Directive{type: :century, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.century(flags)}
  def get(:iso_year4, directive, flags, mods, width),
    do: %Directive{type: :iso_year4, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.year4(flags)}
  def get(:iso_year2, directive, flags, mods, width),
    do: %Directive{type: :iso_year2, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.year2(flags)}
  # Months
  def get(:month, directive, flags, mods, width),
    do: %Directive{type: :month, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.month2(flags)}
  def get(:mshort, directive, flags, mods, width),
    do: %Directive{type: :mshort, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.month_short(flags)}
  def get(:mfull, directive, flags, mods, width),
    do: %Directive{type: :mfull, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.month_full(flags)}
  # Days
  def get(:day, directive, flags, mods, width),
    do: %Directive{type: :day, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.day_of_month(flags)}
  def get(:oday, directive, flags, mods, width),
    do: %Directive{type: :oday, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.day_of_year(flags)}
  # Weeks
  def get(:iso_weeknum, directive, flags, mods, width),
    do: %Directive{type: :iso_weeknum, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.week_of_year(flags)}
  def get(:week_mon, directive, flags, mods, width),
    do: %Directive{type: :week_mon, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.week_of_year(flags)}
  def get(:week_sun, directive, flags, mods, width),
    do: %Directive{type: :week_sun, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.week_of_year(flags)}
  def get(:wday_mon, directive, flags, mods, width),
    do: %Directive{type: :wday_mon, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.weekday(flags)}
  def get(:wday_sun, directive, flags, mods, width),
    do: %Directive{type: :wday_sun, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.weekday(flags)}
  def get(:wdshort, directive, flags, mods, width),
    do: %Directive{type: :wdshort, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.weekday_short(flags)}
  def get(:wdfull, directive, flags, mods, width),
    do: %Directive{type: :wdfull, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.weekday_full(flags)}
  # Hours
  def get(:hour24, directive, flags, mods, width),
    do: %Directive{type: :hour24, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.hour24(flags)}
  def get(:hour12, directive, flags, mods, width),
    do: %Directive{type: :hour12, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.hour12(flags)}
  def get(:min, directive, flags, mods, width),
    do: %Directive{type: :min, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.minute(flags)}
  def get(:sec, directive, flags, mods, width),
    do: %Directive{type: :sec, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.second(flags)}
  def get(:sec_fractional, directive, flags, mods, width),
    do: %Directive{type: :sec_fractional, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.second_fractional(flags)}
  def get(:sec_epoch, directive, flags, mods, width),
    do: %Directive{type: :sec_epoch, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.seconds_epoch(flags)}
  def get(:us, directive, flags, mods, width),
    do: %Directive{type: :us, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.microseconds(flags)}
  def get(:am, directive, flags, mods, width),
    do: %Directive{type: :am, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.ampm(flags)}
  def get(:AM, directive, flags, mods, width),
    do: %Directive{type: :AM, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.ampm(flags)}
  # Timezones
  def get(:zname, directive, flags, mods, width),
    do: %Directive{type: :zname, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.zname(flags)}
  def get(:zoffs, directive, flags, mods, width),
    do: %Directive{type: :zoffs, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.zoffs(flags)}
  def get(:zoffs_colon, directive, flags, mods, width),
    do: %Directive{type: :zoffs_colon, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.zoffs_colon(flags)}
  def get(:zoffs_sec, directive, flags, mods, width),
    do: %Directive{type: :zoffs_sec, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.zoffs_sec(flags)}
  # Preformatted Directives
  def get(:iso_8601, directive, flags, mods, width),
    do: %Directive{type: :iso_8601, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.iso8601(flags)}
  def get(:iso_8601z, directive, flags, mods, width),
    do: %Directive{type: :iso_8601z, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.iso8601([{:zulu, true}|flags])}
  def get(:iso_date, directive, flags, mods, width),
    do: %Directive{type: :iso_date, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.iso_date(flags)}
  def get(:iso_time, directive, flags, mods, width),
    do: %Directive{type: :iso_time, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.iso_time(flags)}
  def get(:iso_week, directive, flags, mods, width),
    do: %Directive{type: :iso_week, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.iso_week(flags)}
  def get(:iso_weekday, directive, flags, mods, width),
    do: %Directive{type: :iso_weekday, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.iso_weekday(flags)}
  def get(:iso_ordinal, directive, flags, mods, width),
    do: %Directive{type: :iso_ordinal, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.iso_ordinal(flags)}
  def get(:rfc_822, directive, flags, mods, width),
    do: %Directive{type: :rfc_822, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.rfc822(flags)}
  def get(:rfc_822z, directive, flags, mods, width),
    do: %Directive{type: :rfc_822z, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.rfc822([{:zulu, true}|flags])}
  def get(:rfc_1123, directive, flags, mods, width),
    do: %Directive{type: :rfc_1123, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.rfc1123(flags)}
  def get(:rfc_1123z, directive, flags, mods, width),
    do: %Directive{type: :rfc_1123z, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.rfc1123([{:zulu, true}|flags])}
  def get(:rfc_3339, directive, flags, mods, width),
    do: %Directive{type: :rfc_3339, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.rfc3339(flags)}
  def get(:rfc_3339z, directive, flags, mods, width),
    do: %Directive{type: :rfc_3339z, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.rfc3339([{:zulu, true}|flags])}
  def get(:ansic, directive, flags, mods, width),
    do: %Directive{type: :ansic, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.ansic(flags)}
  def get(:unix, directive, flags, mods, width),
    do: %Directive{type: :unix, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.unix(flags)}
  def get(:kitchen, directive, flags, mods, width),
    do: %Directive{type: :kitchen, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.kitchen(flags)}
  def get(:slashed, directive, flags, mods, width),
    do: %Directive{type: :slashed, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.slashed(flags)}
  def get(:strftime_iso_date, directive, flags, mods, width),
    do: %Directive{type: :strftime_iso_date, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.iso_date(flags)}
  def get(:strftime_iso_clock, directive, flags, mods, width),
    do: %Directive{type: :strftime_iso_clock, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.strftime_iso_clock(flags)}
  def get(:strftime_iso_clock_full, directive, flags, mods, width),
    do: %Directive{type: :strftime_iso_clock_full, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.strftime_iso_clock_full(flags)}
  def get(:strftime_kitchen, directive, flags, mods, width),
    do: %Directive{type: :strftime_kitchen, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.strftime_kitchen(flags)}
  def get(:strftime_iso_shortdate, directive, flags, mods, width),
    do: %Directive{type: :strftime_iso_shortdate, value: directive, flags: flags, modifiers: mods, width: width, parser: Parsers.strftime_iso_shortdate(flags)}
  # Catch-all
  def get(type, _directive, _flags, _mods, _width), do: {:error, "Unrecognized directive type: #{type}."}
end

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

  @type t :: %__MODULE__{}

  @doc """
  Gets a parsing directive for the given token name, where the token name
  is an atom.

  ## Examples

      iex> alias Timex.Parsers.Directive
      ...> %Directive{type: type, flags: flags} = Directive.get(:year4, "YYYY", padding: :zeros)
      ...> {type, flags}
      {:year4, [padding: :zeros]}

  """
  @spec get(atom, String.t(), [{atom, term}] | []) :: Directive.t()
  def get(type, directive, opts \\ []) do
    min_width = Keyword.get(opts, :min_width, -1)
    width = Keyword.get(opts, :width, min: min_width, max: nil)
    flags = Keyword.merge(Keyword.get(opts, :flags, []), width)
    modifiers = Keyword.get(opts, :modifiers, [])
    get(type, directive, flags, modifiers, width)
  end

  @simple_types [
    :year4,
    :year2,
    :century,
    :hour24,
    :hour12,
    :zname,
    :zoffs,
    :zoffs_colon,
    :zoffs_sec,
    :iso_date,
    :iso_time,
    :iso_week,
    :iso_weekday,
    :iso_ordinal,
    :ansic,
    :unix,
    :kitchen,
    :slashed,
    :asn1_utc_time,
    :asn1_generalized_time,
    :strftime_iso_clock,
    :strftime_iso_clock_full,
    :strftime_kitchen,
    :strftime_iso_shortdate
  ]
  @mapped_types [
    iso_year4: :year4,
    iso_year2: :year2,
    month: :month2,
    mshort: :month_short,
    mfull: :month_full,
    day: :day_of_month,
    oday: :day_of_year,
    iso_weeknum: :week_of_year_iso,
    week_mon: :week_of_year_mon,
    week_sun: :week_of_year_sun,
    wday_mon: :weekday,
    wday_sun: :weekday,
    wdshort: :weekday_short,
    wdfull: :weekday_full,
    min: :minute,
    sec: :second,
    sec_fractional: :second_fractional,
    sec_epoch: :seconds_epoch,
    us: :microseconds,
    ms: :milliseconds,
    am: :ampm,
    AM: :ampm,
    zabbr: :zname,
    iso_8601_extended: :iso8601_extended,
    iso_8601_basic: :iso8601_basic,
    rfc_822: :rfc822,
    rfc_1123: :rfc1123,
    rfc_3339: :rfc3339,
    strftime_iso_date: :iso_date
  ]
  @mapped_zulu_types [
    iso_8601_extended_z: :iso8601_extended,
    iso_8601_basic_z: :iso8601_basic,
    rfc_822z: :rfc822,
    rfc_1123z: :rfc1123,
    rfc_3339z: :rfc3339,
    asn1_generalized_time_z: :asn1_generalized_time
  ]
  for type <- @simple_types do
    def get(unquote(type), directive, flags, mods, width) do
      %Directive{
        type: unquote(type),
        value: directive,
        flags: flags,
        modifiers: mods,
        width: width,
        parser: apply(Parsers, unquote(type), [flags])
      }
    end
  end

  for {type, parser_fun} <- @mapped_types do
    def get(unquote(type), directive, flags, mods, width) do
      %Directive{
        type: unquote(type),
        value: directive,
        flags: flags,
        modifiers: mods,
        width: width,
        parser: apply(Parsers, unquote(parser_fun), [flags])
      }
    end
  end

  for {type, parser_fun} <- @mapped_zulu_types do
    def get(unquote(type), directive, flags, mods, width) do
      %Directive{
        type: unquote(type),
        value: directive,
        flags: flags,
        modifiers: mods,
        width: width,
        parser: apply(Parsers, unquote(parser_fun), [[{:zulu, true} | flags]])
      }
    end
  end

  def get(:asn1_generalized_time_tz, directive, flags, mods, width) do
    %Directive{
      type: :asn1_generalized_time_tz,
      value: directive,
      flags: flags,
      modifiers: mods,
      width: width,
      parser: Parsers.asn1_generalized_time([{:zoffs, true} | flags])
    }
  end

  # Catch-all
  def get(type, _directive, _flags, _mods, _width),
    do: {:error, "Unrecognized directive type: #{type}."}
end

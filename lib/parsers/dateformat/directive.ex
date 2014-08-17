defmodule Timex.Parsers.DateFormat.Directive do
  @moduledoc """
  This module defines parsing directives for all date/time
  tokens timex knows about. It is composed of a Directive struct, 
  containing the rules for parsing a given token, and a `get/1` 
  function, which fetches a directive for a given token value, i.e. `:year4`.
  """
  alias Timex.DateFormat.Formats
  alias Timex.Parsers.DateFormat.Directive

  require Formats

  @derive Access
  defstruct token: :undefined,
            # The number of characters this directive can occupy
            # Should either be :word, meaning it is bounded by the
            # next occurance of whitespace, an integer, which is a
            # strict limit on the length (no more, no less), or a range
            # which defines the min and max lengths that are considered
            # valid
            len: 0,
            # The minimum value of a numeric directive
            min: false,
            # The maximum value of a numeric directive
            max: false,
            # Allows :numeric, :alpha, :match, :format, :char
            type: :undefined, 
            # Either false, or a number representing the amount of padding
            pad: false, 
            pad_type: :zero,
            # Can be false, meaning no validation, a function to call which
            # will be passed the parsed value as a string, and should return
            # true/false, or a regex, which will be required to match the parsed
            # value.
            validate: false,
            # If type: :match is given, this should contain either a match value, or
            # a list of values of which the parsed value should be a member.
            match: false,
            # If type: :format is given, this is the format specification to parse
            # the input string with.
            # Expected format:
            #     [tokenizer: <module>, format: <format string>]
            format: false,
            # If this token is not required in the source string
            optional: false,
            # The raw token
            raw: ""

  @doc """
  Gets a parsing directive for the given token name, where the token name
  is an atom.

  ## Example

    iex> alias Timex.Parsers.Directive
    iex> Directive.get(:year4)
    %Directive{token: :year4, len: 1..4, type: :numeric, pad: 0}

  """
  @spec get(atom) :: %Directive{}
  def get(token)

  # Years
  def get(:year4),       do: %Directive{token: :year4, len: 1..4, type: :numeric, pad: 0}
  def get(:year2),       do: %Directive{token: :year2, len: 1..2, type: :numeric, pad: 0}
  def get(:century),     do: %Directive{token: :century, len: 1..2, type: :numeric, pad: 0}
  def get(:iso_year4),   do: %Directive{token: :iso_year4, len: 1..4, type: :numeric, pad: 0}
  def get(:iso_year2),   do: %Directive{token: :iso_year2, len: 1..2, type: :numeric, pad: 0}
  # Months
  def get(:month),       do: %Directive{token: :month, len: 1..2, min: 1, max: 12, type: :numeric, pad: 0}
  def get(:mshort),      do: %Directive{token: :mshort, len: 3, type: :word, validate: :month_to_num}
  def get(:mfull),       do: %Directive{token: :mfull, len: :word, type: :word, validate: :month_to_num}
  # Days
  def get(:day),         do: %Directive{token: :day, len: 1..2, min: 1, max: 31, type: :numeric, pad: 0}
  def get(:oday),        do: %Directive{token: :oday, len: 1..3, min: 1, max: 366, type: :numeric, pad: 0}
  # Weeks
  def get(:iso_weeknum), do: %Directive{token: :iso_weeknum, len: 1..2, min: 1, max: 53, type: :numeric, pad: 0}
  def get(:week_mon),    do: %Directive{token: :week_mon, len: 1..2, min: 1, max: 53, type: :numeric, pad: 0}
  def get(:week_sun),    do: %Directive{token: :week_sun, len: 1..2, min: 1, max: 53, type: :numeric, pad: 0}
  def get(:wday_mon),    do: %Directive{token: :wday_mon, len: 1, min: 0, max: 6, type: :numeric, pad: 0}
  def get(:wday_sun),    do: %Directive{token: :wday_sun, len: 1, min: 1, max: 7, type: :numeric, pad: 0}
  def get(:wdshort),     do: %Directive{token: :wdshort, len: 3, type: :word, validate: :day_to_num}
  def get(:wdfull),      do: %Directive{token: :wdfull, len: :word, type: :word, validate: :day_to_num}
  # Hours
  def get(:hour24),      do: %Directive{token: :hour24, len: 1..2, min: 0, max: 24, type: :numeric, pad: 0}
  def get(:hour12),      do: %Directive{token: :hour12, len: 1..2, min: 1, max: 12, type: :numeric, pad: 0}
  def get(:min),         do: %Directive{token: :min, len: 1..2, min: 0, max: 59, type: :numeric, pad: 0}
  def get(:sec),         do: %Directive{token: :sec, len: 1..2, min: 0, max: 59, type: :numeric, pad: 0}
  def get(:sec_fractional), do: %Directive{token: :sec_fractional, len: 1..3, min: 0, max: 999, type: :numeric, pad: 0, optional: true}
  def get(:sec_epoch),   do: %Directive{token: :sec_epoch, len: :word, type: :numeric, pad: 0}
  def get(:am),          do: %Directive{token: :am, len: 2, type: :match, match: ["am", "pm"]}
  def get(:AM),          do: %Directive{token: :AM, len: 2, type: :match, match: ["AM", "PM"]}
  # Timezones
  def get(:zname),       do: %Directive{token: :zname, len: 1..4, type: :word}
  def get(:zoffs),       do: %Directive{token: :zoffs, len: 5, type: :word, validate: ~r/^[-+]\d{4}$/}
  def get(:zoffs_colon), do: %Directive{token: :zoffs_colon, len: 6, type: :word, validate: ~r/^[-+]\d{2}:\d{2}$/}
  def get(:zoffs_sec),   do: %Directive{token: :zoffs_sec, len: 9, type: :word, validate: ~r/^[-+]\d{2}:\d{2}\d{2}$/}
  # Preformatted Directives
  def get(:iso_8601),    do: %Directive{token: :iso_8601, type: :format, format: Formats.iso_8601}
  def get(:iso_8601z),   do: %Directive{token: :iso_8601z, type: :format, format: Formats.iso_8601z}
  def get(:iso_date),    do: %Directive{token: :iso_date, type: :format, format: Formats.iso_date}
  def get(:iso_time),    do: %Directive{token: :iso_time, type: :format, format: Formats.iso_time}
  def get(:iso_week),    do: %Directive{token: :iso_week, type: :format, format: Formats.iso_week}
  def get(:iso_weekday), do: %Directive{token: :iso_weekday, type: :format, format: Formats.iso_weekday}
  def get(:iso_ordinal), do: %Directive{token: :iso_ordinal, type: :format, format: Formats.iso_ordinal}
  def get(:rfc_822),     do: %Directive{token: :rfc_822, type: :format, format: Formats.rfc_822}
  def get(:rfc_822z),    do: %Directive{token: :rfc_822z, type: :format, format: Formats.rfc_822z}
  def get(:rfc_1123),    do: %Directive{token: :rfc_1123, type: :format, format: Formats.rfc_1123}
  def get(:rfc_1123z),   do: %Directive{token: :rfc_1123z, type: :format, format: Formats.rfc_1123z}
  def get(:rfc_3339),    do: %Directive{token: :rfc_3339, type: :format, format: Formats.rfc_3339}
  def get(:rfc_3339z),   do: %Directive{token: :rfc_3339z, type: :format, format: Formats.rfc_3339z}
  def get(:ansic),       do: %Directive{token: :ansic, type: :format, format: Formats.ansic}
  def get(:unix),        do: %Directive{token: :unix, type: :format, format: Formats.unix}
  def get(:kitchen),     do: %Directive{token: :kitchen, type: :format, format: Formats.kitchen}
  def get(:slashed),     do: %Directive{token: :slashed, type: :format, format: Formats.slashed_date}
  def get(:strftime_iso_date),  do: %Directive{token: :strftime_iso_date, type: :format, format: Formats.strftime_iso_date}
  def get(:strftime_clock),     do: %Directive{token: :strftime_clock, type: :format, format: Formats.strftime_clock}
  def get(:strftime_kitchen),   do: %Directive{token: :strftime_kitchen, type: :format, format: Formats.strftime_kitchen}
  def get(:strftime_shortdate), do: %Directive{token: :strftime_shortdate, type: :format, format: Formats.strftime_shortdate}
  # Catch-all
  def get(directive),    do: {:error, "Unrecognized directive: #{directive}"}
end
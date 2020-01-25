defmodule Timex.Parse.DateTime.Tokenizers.Default do
  @moduledoc """
  Implements the parser for the default DateTime format strings.
  """
  import Combine.Parsers.Base
  import Combine.Parsers.Text

  use Timex.Parse.DateTime.Tokenizer

  @doc """
  Tokenizes the given format string and returns an error or a list of directives.
  """
  @spec tokenize(String.t()) :: {:ok, [Directive.t()]} | {:error, term}
  def tokenize(<<>>), do: {:error, "Format string cannot be empty."}

  def tokenize(str) do
    token_parser = default_format_parser()

    case Combine.parse(str, token_parser) do
      results when is_list(results) ->
        directives = results |> List.flatten() |> Enum.filter(fn x -> x !== nil end)

        case Enum.any?(directives, fn %Directive{type: type} -> type != :literal end) do
          false -> {:error, "Invalid format string, must contain at least one directive."}
          true -> {:ok, directives}
        end

      {:error, _} = err ->
        err
    end
  end

  @doc """
  Applies a given token + value to the DateTime represented by the current input string.
  """
  @spec apply(DateTime.t(), atom, term) :: DateTime.t() | {:error, term} | :unrecognized
  def apply(_, _, _), do: :unrecognized

  @spec directives() :: (Combine.ParserState.t() -> Combine.ParserState.t())
  defp directives() do
    pipe(
      [
        option(one_of(char(), ["0", "_"])),
        one_of(word_of(~r/[\-\w\:]/), [
          # Years/Centuries
          "YYYY",
          "YY",
          "C",
          "WYYYY",
          "WYY",
          # Months
          "Mshort",
          "Mfull",
          "M",
          # Days
          "Dord",
          "D",
          # Weeks
          "Wiso",
          "Wmon",
          "Wsun",
          "WDmon",
          "WDsun",
          "WDshort",
          "WDfull",
          # Time
          "h24",
          "h12",
          "m",
          "ss",
          "s-epoch",
          "s",
          "am",
          "AM",
          # Timezones
          "Zname",
          "Zabbr",
          "Z::",
          "Z:",
          "Z",
          # Compound
          "ISOord",
          "ISOweek-day",
          "ISOweek",
          "ISOdate",
          "ISOtime",
          "ISOz",
          "ISO",
          "ISO:Extended",
          "ISO:Extended:Z",
          "ISO:Basic",
          "ISO:Basic:Z",
          "RFC822z",
          "RFC822",
          "RFC1123z",
          "RFC1123",
          "RFC3339z",
          "RFC3339",
          "ANSIC",
          "UNIX",
          "ASN1:UTCtime",
          "ASN1:GeneralizedTime",
          "ASN1:GeneralizedTime:Z",
          "ASN1:GeneralizedTime:TZ",
          "kitchen"
        ])
      ],
      &coalesce_token/1
    )
  end

  @spec default_format_parser() :: (Combine.ParserState.t() -> Combine.ParserState.t())
  defp default_format_parser() do
    many1(
      choice([
        # {<padding><directive>}
        label(
          between(char(?{), directives(), char(?})),
          "a valid directive."
        ),
        label(
          map(none_of(char(), ["{", "}"]), &map_literal/1),
          "any character but { or }."
        ),
        label(
          map(pair_left(char(?{), char(?{)), &map_literal/1),
          "an escaped { character"
        ),
        label(
          map(pair_left(char(?}), char(?})), &map_literal/1),
          "an escaped } character"
        )
      ])
    )
    |> eof
  end

  @spec coalesce_token(list(binary)) :: Directive.t()
  defp coalesce_token([flags, directive]) do
    flags = map_flag(flags)
    width = [min: -1, max: nil]
    modifiers = []
    map_directive(directive, flags: flags, width: width, modifiers: modifiers)
  end

  @spec map_directive(String.t(), list()) :: Directive.t()
  defp map_directive(directive, opts) do
    case directive do
      # Years/Centuries
      "YYYY" -> set_width(1, 4, :year4, directive, opts)
      "YY" -> set_width(1, 2, :year2, directive, opts)
      "C" -> set_width(1, 2, :century, directive, opts)
      "WYYYY" -> force_width(4, :iso_year4, directive, opts)
      "WYY" -> force_width(2, :iso_year2, directive, opts)
      # Months
      "M" -> set_width(1, 2, :month, directive, opts)
      "Mfull" -> Directive.get(:mfull, directive, opts)
      "Mshort" -> Directive.get(:mshort, directive, opts)
      # Days
      "D" -> set_width(1, 2, :day, directive, opts)
      "Dord" -> set_width(1, 3, :oday, directive, opts)
      # Weeks
      "Wiso" -> force_width(2, :iso_weeknum, directive, opts)
      "Wmon" -> set_width(1, 2, :week_mon, directive, opts)
      "Wsun" -> set_width(1, 2, :week_sun, directive, opts)
      "WDmon" -> Directive.get(:wday_mon, directive, opts)
      "WDsun" -> Directive.get(:wday_sun, directive, opts)
      "WDshort" -> Directive.get(:wdshort, directive, opts)
      "WDfull" -> Directive.get(:wdfull, directive, opts)
      # Hours
      "h24" -> force_width(2, :hour24, directive, opts)
      "h12" -> set_width(1, 2, :hour12, directive, opts)
      "m" -> force_width(2, :min, directive, opts)
      "s" -> force_width(2, :sec, directive, opts)
      "s-epoch" -> Directive.get(:sec_epoch, directive, opts)
      "ss" -> Directive.get(:sec_fractional, directive, opts)
      "am" -> %{Directive.get(:am, directive, opts) | :weight => 99}
      "AM" -> %{Directive.get(:AM, directive, opts) | :weight => 99}
      # Timezones
      "Zname" -> Directive.get(:zname, directive, opts)
      "Zabbr" -> Directive.get(:zabbr, directive, opts)
      "Z" -> Directive.get(:zoffs, directive, opts)
      "Z:" -> Directive.get(:zoffs_colon, directive, opts)
      "Z::" -> Directive.get(:zoffs_sec, directive, opts)
      # Preformatted Directives
      "ISO:Extended" -> Directive.get(:iso_8601_extended, directive, opts)
      "ISO:Extended:Z" -> Directive.get(:iso_8601_extended_z, directive, opts)
      "ISO:Basic" -> Directive.get(:iso_8601_basic, directive, opts)
      "ISO:Basic:Z" -> Directive.get(:iso_8601_basic_z, directive, opts)
      "ISOdate" -> Directive.get(:iso_date, directive, opts)
      "ISOtime" -> Directive.get(:iso_time, directive, opts)
      "ISOweek" -> Directive.get(:iso_week, directive, opts)
      "ISOweek-day" -> Directive.get(:iso_weekday, directive, opts)
      "ISOord" -> Directive.get(:iso_ordinal, directive, opts)
      "RFC822" -> Directive.get(:rfc_822, directive, opts)
      "RFC822z" -> Directive.get(:rfc_822z, directive, opts)
      "RFC1123" -> Directive.get(:rfc_1123, directive, opts)
      "RFC1123z" -> Directive.get(:rfc_1123z, directive, opts)
      "RFC3339" -> Directive.get(:rfc_3339, directive, opts)
      "RFC3339z" -> Directive.get(:rfc_3339z, directive, opts)
      "ANSIC" -> Directive.get(:ansic, directive, opts)
      "UNIX" -> Directive.get(:unix, directive, opts)
      "ASN1:UTCtime" -> Directive.get(:asn1_utc_time, directive, opts)
      "ASN1:GeneralizedTime" -> Directive.get(:asn1_generalized_time, directive, opts)
      "ASN1:GeneralizedTime:Z" -> Directive.get(:asn1_generalized_time_z, directive, opts)
      "ASN1:GeneralizedTime:TZ" -> Directive.get(:asn1_generalized_time_tz, directive, opts)
      "kitchen" -> Directive.get(:kitchen, directive, opts)
      t -> raise "invalid formatting directive #{t}"
    end
  end

  defp set_width(min, max, type, directive, opts) do
    case get_in(opts, [:flags, :padding]) do
      pad_type when pad_type in [nil, :none] ->
        opts = Keyword.merge(opts, width: [min: min, max: max])
        Directive.get(type, directive, opts)

      pad_type when pad_type in [:spaces, :zeroes] ->
        opts = Keyword.merge(opts, width: [min: max, max: max])
        Directive.get(type, directive, opts)
    end
  end

  defp force_width(size, type, directive, opts) do
    flags = Keyword.merge([padding: :zeroes], get_in(opts, [:flags]))
    mods = get_in(opts, [:modifiers])
    Directive.get(type, directive, flags: flags, modifiers: mods, width: [min: size, max: size])
  end

  defp map_literal([]), do: nil

  defp map_literal(literals)
       when is_list(literals),
       do: Enum.map(literals, &map_literal/1)

  defp map_literal(literal), do: %Directive{type: :literal, value: literal, parser: char(literal)}

  @spec map_flag(binary) :: [{:padding, :spaces | :zeroes}] | []
  defp map_flag("_"), do: [padding: :spaces]
  defp map_flag("0"), do: [padding: :zeroes]
  defp map_flag(_), do: []
end

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
  @spec tokenize(String.t) :: [%Directive{}] | {:error, term}
  def tokenize(<<>>), do: {:error, "Format string cannot be empty."}
  def tokenize(str) do
    case Combine.parse(str, default_format_parser()) do
      results when is_list(results) ->
        directives = results |> List.flatten |> Enum.filter(fn x -> x !== nil end)
        case Enum.any?(directives, fn %Directive{type: type} -> type != :literal end) do
          false -> {:error, "Invalid format string, must contain at least one directive."}
          true  -> {:ok, directives}
        end
      {:error, _} = err -> err
    end
  end

  defp flags(),     do: map(choice([char("0"), char("_")]), &map_flag/1)
  defp directives() do
    choice([
      # Years/Centuries
      string("YYYY"), string("YY"), char("C"), string("WYYYY"), string("WYY"),
      # Months
      string("Mshort"), string("Mfull"), char("M"),
      # Days
      string("Dord"), char("D"),
      # Weeks
      string("Wiso"), string("Wmon"), string("Wsun"), string("WDmon"), string("WDsun"), string("WDshort"), string("WDfull"),
      # Time
      string("h24"), string("h12"), char("m"), string("ss"), string("s-epoch"), char("s"), string("am"), string("AM"),
      # Timezones
      string("Zname"), string("Z::"), string("Z:"), char("Z"),
      # Compound
      string("ISOord"), string("ISOweek-day"), string("ISOweek"), string("ISOdate"), string("ISOtime"), string("ISOz"), string("ISO"),
      string("RFC822z"), string("RFC822"), string("RFC1123z"), string("RFC1123"), string("RFC3339z"), string("RFC3339"),
      string("ANSIC"), string("UNIX"), string("kitchen")
    ])
  end

  defp default_format_parser() do
    sequence([
      many1(choice([
        label(
          map(pair_left(char("{"), char("{")), &map_literal/1),
          "an escaped { character"),
        label(
          map(pair_left(char("}"), char("}")), &map_literal/1),
          "an escaped } character"),
        label(
          map(
            # {<padding><directive>}
            between(char("{"), sequence([option(flags()), directives()]), char("}")),
            &coalesce_token/1
          ),
          "a valid directive."),
        choice([
          sequence([between(char("{"), word, char("}")), fail("Invalid directive!")]),
          map(none_of(char, ["{", "}"]), &map_literal/1)
        ])
      ])),
      eof
    ])
  end

  defp coalesce_token([flags, directive]) do
    flags     = flags || []
    width     = -1
    modifiers = []
    map_directive(directive, [flags: flags, min_width: width, modifiers: modifiers])
  end

  defp map_directive(directive, opts) do
    case directive do
      # Years/Centuries
      "YYYY"  -> set_width(4, :year4, directive, opts)
      "YY"    -> set_width(2, :year2, directive, opts)
      "C"     -> set_width(2, :century, directive, opts)
      "WYYYY" -> set_width(4, :iso_year4, directive, opts)
      "WYY"   -> set_width(2, :iso_year2, directive, opts)
      # Months
      "M"      -> set_width(2, :month, directive, opts)
      "Mfull"  -> Directive.get(:mfull, directive, opts)
      "Mshort" -> Directive.get(:mshort, directive, opts)
      # Days
      "D"    -> set_width(2, :day, directive, opts)
      "Dord" -> set_width(3, :oday, directive, opts)
      # Weeks
      "Wiso"    -> force_width(2, :iso_weeknum, directive, opts)
      "Wmon"    -> set_width(2, :week_mon, directive, opts)
      "Wsun"    -> set_width(2, :week_sun, directive, opts)
      "WDmon"   -> Directive.get(:wday_mon, directive, opts)
      "WDsun"   -> Directive.get(:wday_sun, directive, opts)
      "WDshort" -> Directive.get(:wdshort, directive, opts)
      "WDfull"  -> Directive.get(:wdfull, directive, opts)
      # Hours
      "h24"     -> set_width(2, :hour24, directive, opts)
      "h12"     -> set_width(2, :hour12, directive, opts)
      "m"       -> force_width(2, :min, directive, opts)
      "s"       -> force_width(2, :sec, directive, opts)
      "s-epoch" -> Directive.get(:sec_epoch, directive, opts)
      "ss"      -> Directive.get(:sec_fractional, directive, opts)
      "am"      -> Directive.get(:am, directive, opts)
      "AM"      -> Directive.get(:AM, directive, opts)
      # Timezones
      "Zname" -> Directive.get(:zname, directive, opts)
      "Z"     -> Directive.get(:zoffs, directive, opts)
      "Z:"    -> Directive.get(:zoffs_colon, directive, opts)
      "Z::"   -> Directive.get(:zoffs_sec, directive, opts)
      # Preformatted Directives
      "ISO"         -> Directive.get(:iso_8601, directive, opts)
      "ISOz"        -> Directive.get(:iso_8601z, directive, opts)
      "ISOdate"     -> Directive.get(:iso_date, directive, opts)
      "ISOtime"     -> Directive.get(:iso_time, directive, opts)
      "ISOweek"     -> Directive.get(:iso_week, directive, opts)
      "ISOweek-day" -> Directive.get(:iso_weekday, directive, opts)
      "ISOord"      -> Directive.get(:iso_ordinal, directive, opts)
      "RFC822"      -> Directive.get(:rfc_822, directive, opts)
      "RFC822z"     -> Directive.get(:rfc_822z, directive, opts)
      "RFC1123"     -> Directive.get(:rfc_1123, directive, opts)
      "RFC1123z"    -> Directive.get(:rfc_1123z, directive, opts)
      "RFC3339"     -> Directive.get(:rfc_3339, directive, opts)
      "RFC3339z"    -> Directive.get(:rfc_3339z, directive, opts)
      "ANSIC"       -> Directive.get(:ansic, directive, opts)
      "UNIX"        -> Directive.get(:unix, directive, opts)
      "kitchen"     -> Directive.get(:kitchen, directive, opts)
    end
  end

  defp set_width(size, type, directive, opts) do
    opts = Keyword.merge(opts, [min_width: size])
    Directive.get(type, directive, opts)
  end

  defp force_width(size, type, directive, opts) do
    flags     = Keyword.merge([padding: :zeroes], get_in(opts, [:flags]))
    mods      = get_in(opts, [:modifiers])
    min_width = size
    Directive.get(type, directive, [flags: flags, modifiers: mods, min_width: min_width])
  end

  defp map_literal([]),        do: nil
  defp map_literal(literals)
    when is_list(literals),    do: Enum.map(literals, &map_literal/1)
  defp map_literal(literal),   do: %Directive{type: :literal, value: literal, parser: char(literal)}

  defp map_flag(flag) do
    case flag do
      "_" -> [padding: :spaces]
      "0" -> [padding: :zeroes]
      _   -> []
    end
  end
end

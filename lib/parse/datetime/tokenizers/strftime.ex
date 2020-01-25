defmodule Timex.Parse.DateTime.Tokenizers.Strftime do
  @moduledoc """
  Implements the parser for strftime-style datetime format strings.
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
    case Combine.parse(str, strftime_format_parser()) do
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

  defp flags(), do: map(one_of(char(), ["-", "0", "_"]), &map_flag/1)
  defp min_width(), do: integer()
  defp modifiers(), do: map(one_of(char(), ["E", "O"]), &map_modifier/1)

  defp directives() do
    choice([
      one_of(char(), [
        # Years/Centuries
        "Y",
        "y",
        "C",
        "G",
        "g",
        # Months
        "m",
        "B",
        "b",
        "h",
        # Days, Days of Week
        "d",
        "e",
        "j",
        "u",
        "w",
        "A",
        "a",
        # Weeks
        "V",
        "W",
        "U",
        # Time
        "H",
        "k",
        "I",
        "l",
        "M",
        "S",
        "s",
        "P",
        "p",
        "f",
        "L",
        # Timezones
        "Z",
        "z",
        # Compound
        "D",
        "F",
        "R",
        "r",
        "T",
        "v"
      ]),
      string(":z"),
      string("::z")
    ])
  end

  defp strftime_format_parser() do
    many1(
      choice([
        # %<flag><width><modifier><directive>
        pair_right(
          char("%"),
          pipe(
            [option(flags()), option(min_width()), option(modifiers()), directives()],
            &coalesce_token/1
          )
        ),
        map(none_of(char(), ["%"]), &map_literal/1),
        map(pair_left(char("%"), char("%")), &map_literal/1)
      ])
    )
    |> eof
  end

  defp coalesce_token([flags, width, modifiers, directive]) do
    flags = flags || []
    width = width || -1
    modifiers = modifiers || []
    map_directive(directive, flags: flags, min_width: width, modifiers: modifiers)
  end

  defp map_directive(directive, opts) do
    case directive do
      # Years/Centuries
      "Y" ->
        force_width(4, :year4, directive, opts)

      "y" ->
        force_width(2, :year2, directive, opts)

      "C" ->
        force_width(2, :century, directive, opts)

      "G" ->
        force_width(4, :iso_year4, directive, opts)

      "g" ->
        force_width(2, :iso_year2, directive, opts)

      # Months
      "m" ->
        force_width(2, :month, directive, opts)

      "B" ->
        Directive.get(:mfull, directive, opts)

      "b" ->
        Directive.get(:mshort, directive, opts)

      "h" ->
        Directive.get(:mshort, directive, opts)

      # Days
      "d" ->
        force_width(2, :day, directive, opts)

      "e" ->
        force_width(
          2,
          :day,
          directive,
          Keyword.merge(opts, flags: Keyword.merge([padding: :spaces], get_in(opts, [:flags])))
        )

      "j" ->
        force_width(3, :oday, directive, opts)

      # Weeks
      "V" ->
        force_width(2, :iso_weeknum, directive, opts)

      "W" ->
        force_width(2, :week_mon, directive, opts)

      "U" ->
        force_width(2, :week_sun, directive, opts)

      "u" ->
        Directive.get(:wday_mon, directive, opts)

      "w" ->
        Directive.get(:wday_sun, directive, opts)

      "a" ->
        Directive.get(:wdshort, directive, opts)

      "A" ->
        Directive.get(:wdfull, directive, opts)

      # Hours
      "H" ->
        force_width(2, :hour24, directive, opts)

      "k" ->
        force_width(
          2,
          :hour24,
          directive,
          Keyword.merge(opts, flags: Keyword.merge([padding: :spaces], get_in(opts, [:flags])))
        )

      "I" ->
        force_width(2, :hour12, directive, opts)

      "l" ->
        force_width(
          2,
          :hour12,
          directive,
          Keyword.merge(opts, flags: Keyword.merge([padding: :spaces], get_in(opts, [:flags])))
        )

      "M" ->
        force_width(2, :min, directive, opts)

      "S" ->
        force_width(2, :sec, directive, opts)

      "s" ->
        Directive.get(:sec_epoch, directive, opts)

      "P" ->
        Directive.get(:am, directive, opts)

      "p" ->
        Directive.get(:AM, directive, opts)

      "f" ->
        Directive.get(
          :us,
          directive,
          Keyword.merge(opts, flags: Keyword.merge([padding: :zeroes], get_in(opts, [:flags])))
        )

      "L" ->
        force_width(3, :ms, directive, opts)

      # Timezones
      "Z" ->
        Directive.get(:zname, directive, opts)

      "z" ->
        Directive.get(:zoffs, directive, opts)

      ":z" ->
        Directive.get(:zoffs_colon, directive, opts)

      "::z" ->
        Directive.get(:zoffs_sec, directive, opts)

      # Preformatted Directives
      "D" ->
        Directive.get(:slashed, directive, opts)

      "F" ->
        Directive.get(:iso_date, directive, opts)

      "R" ->
        Directive.get(:strftime_iso_clock, directive, opts)

      "r" ->
        Directive.get(:strftime_kitchen, directive, opts)

      "T" ->
        Directive.get(:strftime_iso_clock_full, directive, opts)

      "v" ->
        Directive.get(:strftime_iso_shortdate, directive, opts)

      # Literals
      "n" ->
        %Directive{value: "\n"}

      "t" ->
        %Directive{value: "\t"}
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

  defp map_flag(flag) do
    case flag do
      "_" -> [padding: :spaces]
      "-" -> [padding: :none]
      "0" -> [padding: :zeroes]
      "^" -> [transform: &String.upcase/1]
      "#" -> [transform: &swap_case/1]
      _ -> []
    end
  end

  defp swap_case(<<char::utf8, _::binary>> = str)
       when char in ?a..?z,
       do: String.upcase(str)

  defp swap_case(<<char::utf8, _::binary>> = str)
       when char in ?A..?Z,
       do: String.downcase(str)

  defp swap_case(str), do: str

  defp map_modifier(modifier) do
    case modifier do
      "E" -> [:locale_dependent_numerics]
      "O" -> [:alternative_numerics]
      _ -> []
    end
  end
end

defmodule MyApp.DateTimeTokenizers.Humanized do
  @moduledoc """
  See https://hexdocs.pm/timex/custom-parsers.html for more context.

  This custom tokenizer accepts format strings containing the following tokens:

    - `{day}` - The phonetic name of the ordinal day of the month, i.e. third
    - `{month}` - The full name of the month, i.e. July
    - `{year}` - The four digit year, i.e. 2015
    - `{shift}` - A shift expression, should be one of the following formats:
      - "currently"
      - "<integer> <seconds|minutes|hours|days|weeks|months|years> <before|after>"

  Combined with `DateFormat.parse`, this allows you to parse strings such as:

    - "currently the eleventh of August, 2015"
    - "3 days before the fourth of July, 2015"
    - "3 minutes after the fourth of July, 2015"
  """
  use Timex.Parse.DateTime.Tokenizer
  use Combine
  alias Timex.Date

  @days [
    "first", "second", "third", "fourth", "fifth",
    "sixth", "seventh", "eighth", "ninth", "tenth",
    "eleventh", "twelfth", "thirteenth", "fourteenth", "fifteenth",
    "sixteenth", "seventeenth", "eighteenth", "nineteenth", "twentieth",
    "twenty-first", "twenty-second", "twenty-third", "twenty-fourth", "twenty-fifth",
    "twenty-sixth", "twenty-seventh", "twenty-eighth", "twenty-ninth", "thirtieth",
    "thirty-first"
  ]

  def tokenize(s) do
    case Combine.parse(s, parser) do
      results when is_list(results) ->
        directives = results |> List.flatten |> Enum.filter(fn x -> x !== nil end)
        case Enum.any?(directives, fn %Directive{type: type} -> type != :literal end) do
          false -> {:error, "Invalid format string, must contain at least one directive."}
          true  -> {:ok, directives}
        end
      {:error, _} = err -> err
    end
  end

  @doc """
  Applies a token to the DateTime representing the current input string
  Only unrecognized tokens are applied via this function, standard tokens,
  such as :year4 will be handled by the parser itself.

  You can return {:ok, date}, {:error, reason}, or :unrecognized (if you don't
  know what to do with the provided token).
  """
  def apply(date, token, value) do
    case token do
      :oday_phonetic ->
        {:ok, %{date | :day => value}}
      :date_shift ->
        case value do
          :none ->
            {:ok, date}
          [{shift, n}] when is_integer(n) ->
            {:ok, Timex.shift(date, [{shift, n}])}
          shift ->
            {:error, "Unrecognized shift operation: #{Macro.to_string(shift)}"}
        end
      _ ->
        {:error, "Unrecognized token: #{token}."}
    end
  end

  # Token parser
  defp parser do
    many1(choice([
      between(char(?{), map(one_of(word, ["shift", "day", "month", "year"]), &map_directive/1), char(?})),
      map(none_of(char, ["{", "}"]), &map_literal/1)
    ]))
  end

  # Gets/builds the Directives for a given token
  defp map_directive("year"), do: Directive.get(:year4, "year")
  defp map_directive("month"), do: Directive.get(:mfull, "month")
  defp map_directive("day"),
    do: %Directive{type: :oday_phonetic, value: "day", parser: oday_phoenetic_parser()}
  defp map_directive("shift"),
    do: %Directive{type: :date_shift, value: "shift", parser: date_shift_parser(), weight: 99}

  # Generates directives for literal characters
  defp map_literal([]),        do: nil
  defp map_literal(literals)
    when is_list(literals),    do: Enum.map(literals, &map_literal/1)
  defp map_literal(literal),   do: %Directive{type: :literal, value: literal, parser: char(literal)}

  # Parses a phonetic ordinal day string, i.e. third
  defp oday_phoenetic_parser() do
    map(one_of(word_of(~r/[\w\-]/), @days), fn day -> [day: to_day(day)] end)
  end

  # Parses a date shift expression, i.e. 3 days after
  defp date_shift_parser() do
    map(either(
      string("currently"),
      sequence([
        integer,
        skip(spaces),
        one_of(word, ["seconds", "minutes", "hours", "days", "weeks", "months", "years"]),
        skip(spaces),
        one_of(word, ["before", "after"])
      ])), fn
      "currently"          -> [date_shift: :none]
      [n, shift, "before"] -> [date_shift: [{to_shift(shift), -n}]]
      [n, shift, "after"]  -> [date_shift: [{to_shift(shift), n}]]
    end)
  end
  defp to_shift("seconds"), do: :seconds
  defp to_shift("minutes"), do: :minutes
  defp to_shift(shift),     do: String.to_atom(shift)

  # Get the ordinal day value based on the ordinal day name
  defp to_day(name), do: Enum.find_index(@days, fn (n) -> n == name end) + 1
end

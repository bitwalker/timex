# Custom Parsers

### How to add custom DateTime parsers to Timex

It is unlikely you will need to write a custom parser for Timex, but should you be in such a position, you can easily plug in your own without much trouble.

## Getting Started

In brief, all you need to know is the following:

- Extend the `Tokenizer` behavior, by adding `use Timex.Parse.DateTime.Tokenizer` to the top of your module.
- Implement `tokenize/1` callback.
- Implement `apply/3` callback.

What we are doing with the above is implementing a tokenizer for the format strings your custom parser will use. Incidentally this also is a prerequisite for implementing a custom formatter (you need to tokenize the format strings). Your best reference is to look at the two built-in tokenizers in Timex, as they are robust and complete implementations, but for the sake of an arbitrary example, let's walk through implementing a very simple parser for humanized strings like "5 days before the fifth of July, 2015", where the following tokens are allowed:

- "{shift}" which should be in the form of "<integer> <unit> <before | after>"
- "{day}" of the form "first", "second", "third", etc.
- "{month}" which is the full name of a month, i.e. "July"
- "{year}" which is the full four digit year

## Tokenizer Implementation

### Implementing the Humanized tokenizer

We start by defining our empty module:

```elixir
defmodule MyApp.DateTimeTokenizers.Humanized do
  use Timex.Parse.DateTime.Tokenizer
end
```

Compiling with this will produce the following errors:

```
../humanized.ex:1: warning: undefined behaviour function tokenize/1 (for behaviour Timex.Parse.DateTime.Tokenizer)
../humanized.ex:1: warning: undefined behaviour function apply/3 (for behaviour Timex.Parse.DateTime.Tokenizer)
```

So we need to implement the `tokenize` function which takes a format string and produces a list of `Directive` structs (or `{:error, term}`). The following implementation makes use of Combine, a dependency pulled in by Timex for parsing tasks, and while you do not need to implement your tokenizer using Combine, the parser function given to each Directive must take a single argument of `%Combine.ParserState{}`, and return it, updated with the status and results from parsing. See [the Combine repo](https://github.com/bitwalker/combine) for examples on how to implement these parsers (it is really rather trivial). My recommendation is to simply use Combine, as it is well suited for these tasks, but now you know how to work around it if so desired.

```elixir
defmodule MyApp.DateTimeTokenizers.Humanized do
  use Timex.Parse.DateTime.Tokenizer
  use Combine

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

  # Generates directives for literals
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
    map(sequence([
      integer,
      skip(spaces),
      one_of(word, ["seconds", "minutes", "hours", "days", "weeks", "months", "years"]),
      skip(spaces),
      one_of(word, ["before", "after"])
    ]), fn
      [n, shift, "before"] -> [date_shift: [{to_shift(shift), -n}]]
      [n, shift, "after"]  -> [date_shift: [{to_shift(shift), n}]]
    end)
  end
  defp to_shift(shift), do: String.to_atom(shift)

  # Get the ordinal day value based on the ordinal day name
  defp to_day(name), do: Enum.find_index(@days, fn (n) -> n == name end) + 1
end
```

## Implementation Notes

A couple of things to notice.

1. Many parsing directives are already built in to Timex, you can see which ones exist by looking at the `Directive` module. Rather than re-implement parsing of month names and 4 digit years, we're using `Directive.get` to pull the predefined Directives for those.
2. However we also have two custom directives to handle the phonetic ordinal names and the date shift expressions, we're defining those directives (and their associated parsers) by hand. This is also the reason why you must implement `apply/3`. The built-in directives are applied via the parser, but custom tokens have to be applied by the tokenizer. I could have split out the tokenize and apply functions into two behaviours (say Tokenizer and Parser), but rather than force that upon you, this is a decision you can make in your own tokenizer (by using defdelegate to keep your `apply/3` code separated).
3. We're creating Directive structs for literal characters. This is important both for parsing and formatting, as it allows your parser to ignore context (i.e. skipping spaces, etc.) and focus on parsing the precise thing it needs to parse. When formatting it's also important, as it makes sure that we output a string which matches the format string precisely.
4. The parsers for the directives return a keyword list of `token: value` as their result. This is a requirement, as the parser will take the input string and parse out a flattened list of `{token, value}` tuples. If your directive parsers do not produce values in this form, they will be ignored, and thus your parser will not work properly (and will likely produce an error).
5. We're setting the `weight` key of the Directive for the shift expression. This will ensure that it is applied last. Consider the input string "3 days after July fourth, 2015", if we try to apply the shift expression to the DateTime we get in `apply/3` (which starts at `0/1/1T00:00:00`), we will get an error for trying to shift the date out of the gregorian calendar, when really we want to apply the shift to the date specified later in the input string. By weighting the directive to be last, we will first apply the month, then the day, then the year to the initial DateTime, then apply the shift to the date we actually wanted it applied to. You can set the weight for all your directives to have them applied in a specific order, so keep it in mind for situations like this.

We are left now with the responsibility of implementing `apply/3`, leaving our tokenizer implementation looking like the following:

```elixir
defmodule MyApp.DateTimeTokenizers.Humanized do
  use Timex.Parse.DateTime.Tokenizer
  use Combine
  alias Timex.Date

  ...snip...

  @doc """
  Applies a token to the DateTime representing the current input string
  Only unrecognized tokens are applied via this function, standard tokens,
  such as :year4 will be handled by the parser itself.

  You can return {:ok, date}, {:error, reason}, or :unrecognized (if you don't
  know what to do with the provided token).
  """
  def apply(%DateTime{} = date, token, value) do
    case token do
      :oday_phonetic ->
        {:ok, %{date | :day => value}}
      :date_shift ->
        case value do
          [{shift, n}] when is_integer(n) ->
            {:ok, Timex.shift(date, [{shift, n}])}
          shift ->
            {:error, "Unrecognized shift operation: #{Macro.to_string(shift)}"}
        end
      _ ->
        {:error, "Unrecognized token: #{token}."}
    end
  end

  ...snip...
end
```

## Usage

After all this, we're now ready to use our custom parser!

```elixir
> alias MyApp.DateTimeTokenizers.Humanized
> phrase = "3 days before the second of July, 2015"
> format = "{shift} the {day} of {month}, {year}"
> Timex.parse(phrase, format, Humanized)
{:ok,
 %Timex.DateTime{calendar: :gregorian, day: 1, hour: 0, minute: 0, month: 7,
  millisecond: 0, second: 0,
  timezone: %Timex.TimezoneInfo{abbreviation: "UTC", from: :min,
   full_name: "UTC", offset_std: 0, offset_utc: 0, until: :max}, year: 2015}}
```

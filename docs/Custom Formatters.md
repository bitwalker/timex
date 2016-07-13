# Custom Formatters

### How to implement a custom formatter for use with Timex

Implementing your own custom formatter is pretty straightforward if you plan to use one of the built-in format string tokenizers (default or strftime). The following example will use a custom tokenizer, and implement the formatter over the top of that.

The tokenizer is implemented as described in the [Custom Parsers](doc:custom-parsers) section, and the source code can be found in the Timex repo [here](https://github.com/bitwalker/timex/blob/master/examples/tokenizer/humanized.exs).

### Getting Started

In brief, all you need to know is the following:

- Extend the `Formatter` behavior, by adding `use Timex.Format.DateTime.Formatter` to the top of your module.
- Implement `tokenize/1` callback.
- Implement `format/2` callback.
- Implement `format!/2` callback.

The `tokenize/1` callback can simply be delegated to the tokenizer you wish to use, while the implementation of `format/2` and `format!/2` are what we really are interested in here.

### Implementing the Humanized formatter

The implementation of the formatter for our "humanized" date format would like something like the following:

```elixir
defmodule MyApp.DateTimeFormatters.Humanized do
  use Timex.Format.DateTime.Formatter

  alias Timex.Format.FormatError
  alias MyApp.DateTimeTokenizers.Humanized, as: Tokenizer

  @days [
    "first", "second", "third", "fourth", "fifth",
    "sixth", "seventh", "eighth", "ninth", "tenth",
    "eleventh", "twelfth", "thirteenth", "fourteenth", "fifteenth",
    "sixteenth", "seventeenth", "eighteenth", "nineteenth", "twentieth",
    "twenty-first", "twenty-second", "twenty-third", "twenty-fourth", "twenty-fifth",
    "twenty-sixth", "twenty-seventh", "twenty-eighth", "twenty-ninth", "thirtieth",
    "thirty-first"
  ]

  defdelegate tokenize(format_string), to: Tokenizer

  def format!(date, format_string) do
    case format(date, format_string) do
      {:ok, result}    -> result
      {:error, reason} -> raise FormatError, message: reason
    end
  end

  def format(date, format_string) do
    case tokenize(format_string) do
      {:ok, []} ->
        {:error, "There were no formatting directives in the provided string."}
      {:ok, dirs} when is_list(dirs) ->
        do_format(Timex.to_naive_datetime(date), dirs, <<>>)
      {:error, reason} -> {:error, {:format, reason}}
    end
  end

  defp do_format(_date, [], result),             do: {:ok, result}
  defp do_format(_date, _, {:error, _} = error), do: error
  defp do_format(date, [%Directive{type: :literal, value: char} | dirs], result) when is_binary(char) do
    do_format(date, dirs, <<result::binary, char::binary>>)
  end
  defp do_format(%NaiveDateTime{day: day} = date, [%Directive{type: :oday_phonetic} | dirs], result) do
    phonetic = Enum.at(@days, day - 1)
    do_format(date, dirs, <<result::binary, phonetic::binary>>)
  end
  defp do_format(date, [%Directive{type: :date_shift} | dirs], result) do
    do_format(date, dirs, <<result::binary, "currently"::binary>>)
  end
  defp do_format(date, [%Directive{type: type, modifiers: mods, flags: flags, width: width} | dirs], result) do
    case format_token(type, date, mods, flags, width) do
      {:error, _} = err -> err
      formatted         -> do_format(date, dirs, <<result::binary, formatted::binary>>)
    end
  end

end
```

As you can see the implementation is pretty straightforward. You'll notice that the last `do_format` implementation calls an imported function `format_token/5`, this allows you to delegate the formatting of known directives to the formatter, which will use standard formatting rules. You can of course override the formatting of directives using the style above (pattern matching on the directive type and handling the formatting directly).

To use our new formatter with `Timex.format`:

```elixir
iex> use Timex
iex> alias MyApp.DateTimeFormatters.Humanized, as: HumanFormat
iex> alias MyApp.DateTimeTokenizers.Humanized
iex> format = "{shift} the {day} of {month}, {year}"
iex> Timex.format(Timex.now, format, HumanFormat)
{:ok, "currently the eleventh of August, 2015"}
```

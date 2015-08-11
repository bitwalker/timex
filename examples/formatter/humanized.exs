defmodule MyApp.DateTimeFormatters.Humanized do
  @moduledoc """
  See https://timex.readme.io/docs/custom-formatters for more context.

  This custom formatter accepts format strings containing the following tokens:

    - `{day}` - The phonetic name of the ordinal day of the month, i.e. third
    - `{month}` - The full name of the month, i.e. July
    - `{year}` - The four digit year, i.e. 2015
    - `{shift}` - A shift expression, i.e. "currently" or "3 days before"
  """
  use Timex.Format.DateTime.Formatter

  alias Timex.DateTime
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

  def format!(%DateTime{} = date, format_string) do
    case format(date, format_string) do
      {:ok, result}    -> result
      {:error, reason} -> raise FormatError, message: reason
    end
  end

  def format(%DateTime{} = date, format_string) do
    case tokenize(format_string) do
      {:ok, []} ->
        {:error, "There were no formatting directives in the provided string."}
      {:ok, dirs} when is_list(dirs) ->
        do_format(date, dirs, <<>>)
      {:error, reason} -> {:error, {:format, reason}}
    end
  end

  defp do_format(_date, [], result),             do: {:ok, result}
  defp do_format(_date, _, {:error, _} = error), do: error
  defp do_format(date, [%Directive{type: :literal, value: char} | dirs], result) when is_binary(char) do
    do_format(date, dirs, <<result::binary, char::binary>>)
  end
  defp do_format(%DateTime{day: day} = date, [%Directive{type: :oday_phonetic} | dirs], result) do
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

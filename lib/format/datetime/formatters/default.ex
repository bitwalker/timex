defmodule Timex.Format.DateTime.Formatters.Default do
  @moduledoc """
  Date formatting language used by default by the `DateFormat` module.

  This is a novel formatting language introduced with `DateFormat`. Its main
  advantage is simplicity and usage of mnemonics that are easy to memorize.

  ## Directive format

  A directive is an optional _padding specifier_ followed by a _mnemonic_, both
  enclosed in braces (`{` and `}`):

      {<padding><mnemonic>}

  Supported padding specifiers:

  * `0` -- pads the number with zeros. Applicable to mnemonics that produce numerical result.
  * `_` -- pads the number with spaces. Applicable to mnemonics that produce numerical result.

  When padding specifier is omitted, numbers will not be padded.

  ## List of all directives

  ### Years and centuries

  * `{YYYY}`    - full year number (0..9999)
  * `{YY}`      - the last two digits of the year number (0.99)
  * `{C}`       - century number (0..99)
  * `{WYYYY}`   - year number (4 digits) corresponding to the date's ISO week (0000..9999)
  * `{WYY}`     - year number (2 digits) corresponding to the date's ISO week (00.99)

  ### Months

  * `{M}`       - month number (1..12)
  * `{Mshort}`  - abbreviated month name (Jan..Dec, no padding)
  * `{Mfull}`   - full month name (January..December, no padding)

  ### Days and weekdays

  * `{D}`       - day number (1..31)
  * `{Dord}`    - ordinal day of the year (1..366)
  * `{WDmon}`   - weekday, Monday first (1..7, no padding)
  * `{WDsun}`   - weekday, Sunday first (1..7, no padding)
  * `{WDshort}` - abbreviated weekday name (Mon..Sun, no padding)
  * `{WDfull}`  - full weekday name (Monday..Sunday, no padding)

  ### Weeks

  * `{Wiso}`    - ISO week number (01..53)
  * `{Wmon}`    - week number of the year, Monday first (01..53)
  * `{Wsun}`    - week number of the year, Sunday first (01..53)

  ### Time

  * `{h24}`     - hour of the day (00..23)
  * `{h12}`     - hour of the day (1..12)
  * `{m}`       - minutes of the hour (00..59)
  * `{s}`       - seconds of the minute (00..60)
  * `{s-epoch}` - number of seconds since UNIX epoch
  * `{am}`      - lowercase am or pm (no padding)
  * `{AM}`      - uppercase AM or PM (no padding)

  ### Time zones

  * `{Zname}`   - time zone name, e.g. `UTC` (no padding)
  * `{Z}`       - time zone offset in the form `+0230` (no padding)
  * `{Z:}`      - time zone offset in the form `-07:30` (no padding)
  * `{Z::}`     - time zone offset in the form `-07:30:00` (no padding)

  ### Compound directives

  These are shortcut directives corresponding to parts of the ISO 8601
  specification. The benefit of using these over manually constructed ISO
  formats is that these directives convert the date to UTC for you.

  * `{ISO}`         - `<date>T<time><offset>`. Full date and time
                      specification (e.g. `2007-08-13T16:48:01 +0300`)

  * `{ISOz}`        - `<date>T<time>Z`. Full date and time in UTC (e.g.
                      `2007-08-13T13:48:01Z`)

  * `{ISOdate}`     - `YYYY-MM-DD`. That is, 4-digit year number, followed by
                      2-digit month and day numbers (e.g. `2007-08-13`)

  * `{ISOtime}`     - `hh:mm:ss`. That is, 2-digit hour, minute, and second,
                      separated by colons (e.g. `13:04:05`). Midnight is 00 hours.

  * `{ISOweek}`     - `YYYY-Www`. That is, ISO week-based year, followed by ISO
                      week number (e.g. `2007-W09`)

  * `{ISOweek-day}` - `YYYY-Www-D`. That is, an `{ISOweek}`, additionally
                      followed by weekday (e.g. `2007-W09-1`)

  * `{ISOord}`      - `YYYY-DDD`. That is, year number, followed by the ordinal
                      day number (e.g. `2007-113`)

  These directives provide support for miscellaneous common formats:

  * `{RFC822}`      - e.g. `Mon, 05 Jun 14 23:20:59 UT`
  * `{RFC822z}`     - e.g. `Mon, 05 Jun 14 23:20:59 Z`
  * `{RFC1123}`     - e.g. `Tue, 05 Mar 2013 23:25:19 GMT`
  * `{RFC1123z}`    - e.g. `Tue, 05 Mar 2013 23:25:19 +0200`
  * `{RFC3339}`     - e.g. `2013-03-05T23:25:19+02:00`
  * `{RFC3339z}`    - e.g. `2013-03-05T23:25:19Z`
  * `{ANSIC}`       - e.g. `Tue Mar  5 23:25:19 2013`
  * `{UNIX}`        - e.g. `Tue Mar  5 23:25:19 PST 2013`
  * `{kitchen}`     - e.g. `3:25PM`

  """
  use Timex.Format.DateTime.Formatter

  alias Timex.DateTime
  alias Timex.Format.FormatError
  alias Timex.Parse.DateTime.Tokenizers.Default, as: Tokenizer

  @spec tokenize(String.t) :: {:ok, [%Directive{}]} | {:error, term}
  defdelegate tokenize(format_string), to: Tokenizer

  @spec format!(%DateTime{}, String.t) :: String.t | no_return
  def format!(%DateTime{} = date, format_string) do
    case format(date, format_string) do
      {:ok, result}    -> result
      {:error, reason} -> raise FormatError, message: reason
    end
  end

  @spec format(%DateTime{}, String.t) :: {:ok, String.t} | {:error, term}
  def format(%DateTime{} = date, format_string) do
    case tokenize(format_string) do
      {:ok, []} ->
        {:error, "There were no formatting directives in the provided string."}
      {:ok, dirs} when is_list(dirs) ->
        do_format(date, dirs, <<>>)
      {:error, reason} -> {:error, {:format, reason}}
    end
  end

  @doc """
  If one wants to use the default formatting semantics with a different
  tokenizer, this is the way.
  """
  @spec format(%DateTime{}, String.t, atom) :: {:ok, String.t} | {:error, term}
  def format(%DateTime{} = date, format_string, tokenizer) do
    case tokenizer.tokenize(format_string) do
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
  defp do_format(date, [%Directive{type: type, modifiers: mods, flags: flags, width: width} | dirs], result) do
    case format_token(type, date, mods, flags, width) do
      {:error, _} = err -> err
      formatted         -> do_format(date, dirs, <<result::binary, formatted::binary>>)
    end
  end

end

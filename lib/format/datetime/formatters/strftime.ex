defmodule Timex.Format.DateTime.Formatters.Strftime do
  @moduledoc """
  Date formatting language defined by the `strftime` function from the Standard
  C Library.

  This implementation in Elixir is mostly compatible with `strftime`. The
  exception is the absence of locale-depended results. All directives that imply
  textual result will produce English names and abbreviations.

  A complete reference of the directives implemented here is given below.

  ## Directive format

  A directive is marked by the percent sign (`%`) followed by one character
  (`<directive>`). In addition, a few optional specifiers can be inserted
  in-between:

      %<flag><width><modifier><directive>

  Supported flags:

  * `-`       - don't pad numerical results (overrides default padding if any)
  * `0`       - use zeros for padding
  * `_`       - use spaces for padding
  * `:`, `::` - used only in combination with `%z`; see description of `%:z`
                and `%::z` below

  `<width>` is a non-negative decimal number specifying the minimum field
  width.

  `<modifier>` can be `E` or `O`. These are locale-sensitive modifiers, and as
  such they are currently ignored by this implementation.

  ## List of all directives

  * `%%` - produces a single `%` in the output

  ### Years and centuries

  * `%Y` - full year number (0..9999)
  * `%y` - the last two digits of the year number (0..99)
  * `%C` - century number (00..99)
  * `%G` - year number corresponding to the date's ISO week (0..9999)
  * `%g` - year number (2 digits) corresponding to the date's ISO week (0..99)

  ### Months

  * `%m` - month number (1..12)
  * `%b` - abbreviated month name (Jan..Dec, no padding)
  * `%h` - same is `%b`
  * `%B` - full month name (January..December, no padding)

  ### Days, and days of week

  * `%d` - day number (1..31)
  * `%e` - same as `%d`, but padded with spaces ( 1..31)
  * `%j` - ordinal day of the year (001..366)
  * `%u` - weekday, Monday first (1..7)
  * `%w` - weekday, Sunday first (0..6)
  * `%a` - abbreviated weekday name (Mon..Sun, no padding)
  * `%A` - full weekday name (Monday..Sunday, no padding)

  ### Weeks

  * `%V` - ISO week number (01..53)
  * `%W` - week number of the year, Monday first (00..52)
  * `%U` - week number of the year, Sunday first (00..52)

  ### Time

  * `%H` - hour of the day (00..23)
  * `%k` - same as `%H`, but padded with spaces ( 0..23)
  * `%I` - hour of the day (1..12)
  * `%l` - same as `%I`, but padded with spaces ( 1..12)
  * `%M` - minutes of the hour (00..59)
  * `%S` - seconds of the minute (00..60)
  * `%f` - microseconds in zero padded decimal form, i.e. 025000
  * `%L` - milliseconds (000..999)
  * `%s` - number of seconds since UNIX epoch
  * `%P` - lowercase am or pm (no padding)
  * `%p` - uppercase AM or PM (no padding)

  ### Time zones

  * `%Z`   - time zone name, e.g. `UTC` (no padding)
  * `%z`   - time zone offset in the form `+0230` (no padding)
  * `%:z`  - time zone offset in the form `-07:30` (no padding)
  * `%::z` - time zone offset in the form `-07:30:00` (no padding)

  ### Compound directives

  * `%D` - same as `%m/%d/%y`
  * `%F` - same as `%Y-%m-%d`
  * `%R` - same as `%H:%M`
  * `%r` - same as `%I:%M:%S %p`
  * `%T` - same as `%H:%M:%S`
  * `%v` - same as `%e-%b-%Y`

  """
  use Timex.Format.DateTime.Formatter

  alias Timex.Format.FormatError
  alias Timex.Format.DateTime.Formatters.Default
  alias Timex.Parse.DateTime.Tokenizers.Strftime
  alias Timex.{Types, Translator}

  @spec tokenize(String.t()) :: {:ok, [Directive.t()]} | {:error, term}
  defdelegate tokenize(format_string), to: Strftime

  def format!(date, format_string), do: lformat!(date, format_string, Translator.current_locale())
  def format(date, format_string), do: lformat(date, format_string, Translator.current_locale())

  @spec lformat!(Types.calendar_types(), String.t(), String.t()) :: String.t() | no_return
  def lformat!(date, format_string, locale) do
    case lformat(date, format_string, locale) do
      {:ok, result} -> result
      {:error, reason} -> raise FormatError, message: reason
    end
  end

  @spec lformat(Types.calendar_types(), String.t(), String.t()) ::
          {:ok, String.t()} | {:error, term}
  def lformat(date, format_string, locale) do
    Default.lformat(date, format_string, Strftime, locale)
  end
end

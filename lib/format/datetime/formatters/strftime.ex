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

  * `%Y` - full year number (0000..9999)
  * `%y` - the last two digits of the year number (00.99)
  * `%C` - century number (00..99)
  * `%G` - year number corresponding to the date's ISO week (0..9999)
  * `%g` - year number (2 digits) corresponding to the date's ISO week (0.99)

  ### Months

  * `%m` - month number (01..12)
  * `%b` - abbreviated month name (Jan..Dec, no padding)
  * `%h` - same is `%b`
  * `%B` - full month name (January..December, no padding)

  ### Days, and days of week

  * `%d` - day number (01..31)
  * `%e` - same as `%d`, but padded with spaces ( 1..31)
  * `%j` - ordinal day of the year (001..366)
  * `%u` - weekday, Monday first (1..7)
  * `%w` - weekday, Sunday first (0..6)
  * `%a` - abbreviated weekday name (Mon..Sun, no padding)
  * `%A` - full weekday name (Monday..Sunday, no padding)

  ### Weeks

  * `%V` - ISO week number (01..53)
  * `%W` - week number of the year, Monday first (00..53)
  * `%U` - week number of the year, Sunday first (00..53)

  ### Time

  * `%H` - hour of the day (00..23)
  * `%k` - same as `%H`, but padded with spaces ( 0..23)
  * `%I` - hour of the day (1..12)
  * `%l` - same as `%I`, but padded with spaces ( 1..12)
  * `%M` - minutes of the hour (0..59)
  * `%S` - seconds of the minute (0..60)
  * `%f` - microseconds in zero padded decimal form, i.e. 025000
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

  alias Timex.DateTime
  alias Timex.Format.DateTime.Formatters.Default
  alias Timex.Parse.DateTime.Tokenizers.Strftime

  @spec tokenize(String.t) :: {:ok, [%Directive{}]} | {:error, term}
  defdelegate tokenize(format_string), to: Strftime

  @spec format!(%DateTime{}, String.t) :: String.t | no_return
  def format!(%DateTime{} = date, format_string) do
    case format(date, format_string) do
      {:ok, result}    -> result
      {:error, reason} -> raise FormatError, message: reason
    end
  end

  @spec format(%DateTime{}, String.t) :: {:ok, String.t} | {:error, term}
  def format(%DateTime{} = date, format_string) do
    Default.format(date, format_string, Strftime)
  end
end

defmodule Timex.DateFormat.Strftime do
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

  `<modifier>` is `E` or `O`. It is ignored by this implementation.

  ## List of all directives

  * `%%` - produces a single `%` in the output

  ### Years and centuries

  * `%Y` - full year number (0000..9999)
  * `%y` - the last two digits of the year number (00.99)
  * `%C` - century number (00..99)
  * `%G` - year number corresponding to the ISO week (0000..9999)
  * `%g` - the last two digits of the ISO week year (00..99)

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

  def process_directive("%" <> _) do
    # false alarm
    { :skip, 1 }
  end

  def process_directive(fmt) when is_binary(fmt) do
    case scan_directive(fmt, 0) do
      { :ok, dir, length } ->
        case translate_directive(dir) do
          { :ok, directive } -> { :ok, directive, length }
          error              -> error
        end

      error -> error
    end
  end

  ###

  defrecordp :directive, dir: nil, flag: nil, width: -1

  defp scan_directive(str, pos) do
    scan_directive_flag(str, pos, directive())
  end

  ###

  defp scan_directive_flag("::" <> rest, pos, dir) do
    scan_directive_width(rest, pos+2, directive(dir, flag: "::"))
  end

  defp scan_directive_flag(<<flag :: utf8>> <> rest, pos, dir)
        when flag in [?-, ?0, ?_, ?:] do
    scan_directive_width(rest, pos+1, directive(dir, flag: flag))
  end

  defp scan_directive_flag(str, pos, dir) do
    scan_directive_width(str, pos, dir)
  end

  ###

  defp scan_directive_width(<<digit :: utf8>> <> rest, pos, directive(width: width)=dir)
        when digit in ?0..?9 do
    new_width = width*10 + digit-?0
    scan_directive_width(rest, pos+1, directive(dir, width: new_width))
  end

  defp scan_directive_width(str, pos, dir) do
    scan_directive_modifier(str, pos, dir)
  end

  ###

  defp scan_directive_modifier(<<mod :: utf8>> <> rest, pos, dir)
        when mod in [?E, ?O] do
    # ignore these modifiers
    scan_directive_final(rest, pos+1, dir)
  end

  defp scan_directive_modifier(str, pos, dir) do
    scan_directive_final(str, pos, dir)
  end

  ###

  defp scan_directive_final(<<char :: utf8>> <> _, pos, dir) do
    { :ok, directive(dir, dir: char), pos+1 }
  end

  defp scan_directive_final("", _, _) do
    { :error, "bad directive" }
  end

  ###

  defp translate_directive(directive(flag: flag, width: width, dir: dir)) do
    val = case dir do
      ?Y -> { :year,      4 }
      ?y -> { :year2,     2 }
      ?C -> { :century,   2 }
      ?G -> { :iso_year,  4 }
      ?g -> { :iso_year2, 2 }

      ?m -> { :month,     2 }
      ?b -> :mshort
      ?h -> :mshort
      ?B -> :mfull

      ?d -> { :day,       2 }
      ?e -> { :day,       2 }
      ?j -> { :oday,      3 }
      ?u -> { :wday_mon,  1 }
      ?w -> { :wday_sun,  1 }
      ?a -> :wdshort
      ?A -> :wdfull

      ?V -> { :iso_week,  2 }
      ?W -> { :week_mon,  2 }
      ?U -> { :week_sun,  2 }

      ?H -> { :hour24,    2 }
      ?k -> { :hour24,    2 }
      ?I -> { :hour12,    2 }
      ?l -> { :hour12,    2 }
      ?M -> { :min,       2 }
      ?S -> { :sec,       2 }
      ?s -> { :sec_epoch, 10 }
      ?P -> :am
      ?p -> :AM

      ?Z -> :zname
      ?z -> :zoffs

      # compound directives
      ?D -> { :subfmt, "%m/%d/%y" }
      ?F -> { :subfmt, "%Y-%m-%d" }
      ?R -> { :subfmt, "%H:%M" }
      ?r -> { :subfmt, "%I:%M:%S %p" }
      ?T -> { :subfmt, "%H:%M:%S" }
      ?v -> { :subfmt, "%e-%b-%Y" }

      _ -> nil
    end

    case val do
      nil -> { :error, "bad directive %#{<<dir::utf8>>}" }

      { :subfmt, _ }=result ->
        { :ok, result }

      { tag, w } ->
        width = max(w, width)
        pad = translate_pad(flag, dir)
        { :ok, {tag, pad && "~#{width}..#{pad}B" || "~B"} }

      :zoffs when flag in [nil, ?:, "::"] ->
        { :ok, translate_zoffs(flag) }

      :zoffs ->
        { :error, "invalid flag for directive %z" }

      tag when nil?(flag) ->
        { :ok, {tag, "~s"} }

      _ ->
        { :error, "invalid flag for directive %#{<<dir::utf8>>}" }
    end
  end

  defp translate_pad(nil, dir) when dir in [?e, ?k, ?l] do
    " "
  end

  defp translate_pad(flag, _) do
    case flag do
      ?-    -> nil
      ?_    -> " "
      nil   -> "0"
      other -> <<other :: utf8>>
    end
  end

  defp translate_zoffs(flag) do
    { case flag do
      nil  -> :zoffs
      ?:   -> :zoffs_colon
      "::" -> :zoffs_sec
    end, "~s" }
  end
end
defmodule Timex.Parsers.DateFormat.Tokenizers.Strftime do
  @moduledoc """
  Responsible for tokenizing date/time format strings
  which use the strftime formatter.
  """
  alias Timex.Parsers.DateFormat.ParserState, as: State
  alias Timex.Parsers.DateFormat.Directive,   as: Directive

  # These are all the strftime formatter's directives
  @directives [
    # Years
    {"Y",   Directive.get(:year4)},
    {"y",   Directive.get(:year2)},
    {"C",   Directive.get(:century)},
    {"G",   Directive.get(:iso_year4)},
    {"g",   Directive.get(:iso_year2)},
    # Months
    {"m",   Directive.get(:month)},
    {"b",   Directive.get(:mshort)},
    {"h",   Directive.get(:mshort)},
    {"B",   Directive.get(:mfull)},
    # Days
    {"d",   Directive.get(:day)},
    {"e",   %{Directive.get(:day) | pad_type: :space}},
    {"j",   Directive.get(:oday)},
    # Weeks
    {"V",   Directive.get(:iso_weeknum)},
    {"W",   Directive.get(:week_mon)},
    {"U",   Directive.get(:week_sun)},
    {"u",   Directive.get(:wday_mon)},
    {"w",   Directive.get(:wday_sun)},
    {"a",   Directive.get(:wdshort)},
    {"A",   Directive.get(:wdfull)},
    # Hours
    {"H",   Directive.get(:hour24)},
    {"k",   %{Directive.get(:hour24) | pad_type: :space}},
    {"I",   Directive.get(:hour12)},
    {"l",   %{Directive.get(:hour12) | pad_type: :space}},
    {"M",   Directive.get(:min)},
    {"S",   Directive.get(:sec)},
    {"s",   Directive.get(:sec_epoch)},
    {"P",   Directive.get(:am)},
    {"p",   Directive.get(:AM)},
    # Timezones
    {"Z",   Directive.get(:zname)},
    {"z",   Directive.get(:zoffs)},
    {":z",  Directive.get(:zoffs_colon)},
    {"::z", Directive.get(:zoffs_sec)},
    # Preformatted Directives
    {"D",   Directive.get(:slashed)},
    {"F",   Directive.get(:strftime_iso_date)},
    {"R",   Directive.get(:strftime_clock)},
    {"r",   Directive.get(:strftime_kitchen)},
    {"T",   Directive.get(:iso_time)},
    {"v",   Directive.get(:strftime_shortdate)}
  ]

  @directive_pattern ~r/\%(?<flags>[-_0:]{1}|[:]{2})?(?<width>[\d]+)?([EO]{1})?(?<dir>\w{1})/
  @doc """
  Takes a format string and extracts parsing directives for the parser.

  ## Example

    iex> Timex.Parsers.Tokenizers.Strftime.tokenize("%Y-%0m-%d")
    [%Directive{token: :year4, ...}, %Directive{token: :month, pad: 1, ...}, ...]
  """
  def tokenize(s) when s in [nil, ""], do: {:error, "Format string cannot be nil or empty!"}
  def tokenize(s) when is_list(s), do: tokenize("#{s}")
  def tokenize(s) do
    case Regex.match?(@directive_pattern, s) do
      true ->
        tokens = @directive_pattern |> Regex.scan(s, capture: :all)
        parts  = @directive_pattern |> Regex.split(s)
        tokens |> weave(parts) |> do_tokenize(%State{}, [])
      false ->
        {:error, "Invalid strftime format string"}
    end
  end

  defp do_tokenize([], _, result), do: result |> Enum.reverse
  defp do_tokenize([part|tokens], %State{col: col} = state, result)
    when is_binary(part)
    do
      # Handle escaped percent signs
      escaped   = String.replace(part, "%%", "%")
      new_col   = col + String.length(part)
      directive = %Directive{type: :char, token: escaped, raw: part}
      state     = %{state | :col => new_col}
      do_tokenize(tokens, state, [directive|result])
  end
  defp do_tokenize([[_, _, _, mod, _]|_], %State{col: col}, _)
    when mod in ["E", "O"],
    do: {:error, "Unsupported modifier #{mod} at column #{col}."}
  defp do_tokenize([[_, _, _, mod, _]|_], %State{col: col}, _)
    when mod != "",
    do: {:error, "Invalid modifier #{mod} at column #{col}."}
  defp do_tokenize([[raw, flags, width, _mod, dir] | tokens], %State{col: col} = state, result) do
    directive = case {dir, flags} do
      {"z", ":"}  -> get_directive(":z")
      {"z", "::"} -> get_directive("::z")
      _           -> get_directive(dir)
    end
    case directive do
      :invalid     -> {:error, "Invalid directive used starting at column #{col}"}
      {_, %Directive{} = directive} ->
        directive = %{directive | :raw => raw}
        directive = directive |> process_padding |> process_flags(flags) |> process_width(width)
        new_col   = col + ((flags <> width <> dir) |> String.length)
        state     = %{state | :col => new_col}
        do_tokenize(tokens, state, [directive | result])
    end
  end
  defp do_tokenize(invalid, %State{col: col}, _) do
    {:error, "Invalid token starting at column #{col}: #{Macro.to_string(invalid)}"}
  end

  # Set padding for numeric tokens to always fill out the full width of the number
  defp process_padding(%Directive{type: :numeric, len: lo..hi} = dir),
    do: %{dir | :pad => hi - lo}
  defp process_padding(%Directive{type: :numeric, len: len} = dir)
    when is_number(len),
    do: %{dir | :pad => len - 1}
  # Everything else keeps default padding (none)
  defp process_padding(%Directive{} = dir),
    do: dir

  # Handles flags for directives
  defp process_flags(%Directive{} = dir, ""),   do: dir
  defp process_flags(%Directive{} = dir, "-"),  do: %{dir | :pad => 0}
  defp process_flags(%Directive{} = dir, "0"),  do: %{dir | :pad_type => :zero}
  defp process_flags(%Directive{} = dir, "_"),  do: %{dir | :pad_type => :space}
  defp process_flags(%Directive{} = dir, ":"),  do: dir
  defp process_flags(%Directive{} = dir, "::"), do: dir
  defp process_flags(%Directive{token: token}, flag)
    when not token in [:zoffs, :zoffs_colon, :zoffs_sec] and flag in [":", "::"],
    do: {:error, "Invalid use of `#{flag}` flag. Can only be used with %z directive!"}
  defp process_flags(%Directive{}, flag),
    do: {:error, "Invalid flag #{flag}!"}

  # Sets the minimum string length for a given directive
  defp process_width(%Directive{} = dir, ""), do: dir
  defp process_width(%Directive{} = dir, width) do
    case Integer.parse(width) do
      :error   -> {:error, "Invalid width specification: #{width}"}
      {num, _} ->
        case dir.len do
          _..hi when hi < num     -> %{dir | :len => num}
          _..hi when hi >= num    -> %{dir | :len => Range.new(num, hi)}
          len when is_number(len) -> %{dir | :len => num}
          :word                   -> %{dir | :len => Range.new(num, 9999)}
          _                       -> dir
        end
    end
  end

  defp get_directive(dir) do
    List.keyfind(@directives, dir, 0) || :invalid
  end

  defp weave(xs, ys),                      do: do_weave(xs, ys, [])
  defp do_weave([], ys, result),           do: (Enum.filter(ys, &non_empty/1) ++ result) |> Enum.reverse
  defp do_weave(xs, [], result),           do: (Enum.filter(xs, &non_empty/1) ++ result) |> Enum.reverse
  # Handle percent escapes
  defp do_weave([[<<?%, _::binary>> = raw, _, _, _, _]=token|xs], [part|ys], result)
    when part != ""
    do
      case String.length(part) - (part |> String.rstrip(?%) |> String.length) do
        len when len != 2 and div(len, 2) == 1 ->
          do_weave(xs, ys, [part <> raw | result])
        _ -> do_weave(xs, ys, [token, part | result])
      end
  end
  defp do_weave([""|xs], [""|ys], result), do: do_weave(xs, ys, result)
  defp do_weave([""|xs], [hy|ys], result), do: do_weave(xs, ys, [hy|result])
  defp do_weave([hx|xs], [""|ys], result), do: do_weave(xs, ys, [hx|result])
  defp do_weave([hx|xs], [hy|ys], result), do: do_weave(xs, ys, [hx, hy | result])

  defp non_empty(""), do: false
  defp non_empty(_),  do: true
end
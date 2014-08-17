defmodule Timex.Parsers.DateFormat.Tokenizers.Default do
  @moduledoc """
  Responsible for tokenizing date/time format strings
  which use the Default formatter.
  """
  alias Timex.Parsers.DateFormat.ParserState, as: State
  alias Timex.Parsers.DateFormat.Directive,   as: Directive

  # These are all the default formatter's directives
  @directives [
    # Years
    {"YYYY",        Directive.get(:year4)},
    {"YY",          Directive.get(:year2)},
    {"C",           Directive.get(:century)},
    {"WYYYY",       Directive.get(:iso_year4)},
    {"WYY",         Directive.get(:iso_year2)},
    # Months
    {"M",           Directive.get(:month)},
    {"Mshort",      Directive.get(:mshort)},
    {"Mfull",       Directive.get(:mfull)},
    # Days
    {"D",           Directive.get(:day)},
    {"Dord",        Directive.get(:oday)},
    # Weeks
    {"Wiso",        Directive.get(:iso_weeknum)},
    {"Wmon",        Directive.get(:week_mon)},
    {"Wsun",        Directive.get(:week_sun)},
    {"WDmon",       Directive.get(:wday_mon)},
    {"WDsun",       Directive.get(:wday_sun)},
    {"WDshort",     Directive.get(:wdshort)},
    {"WDfull",      Directive.get(:wdfull)},
    # Hours
    {"h24",         Directive.get(:hour24)},
    {"h12",         Directive.get(:hour12)},
    {"m",           Directive.get(:min)},
    {"s",           Directive.get(:sec)},
    {"ss",          Directive.get(:sec_fractional)},
    {"s-epoch",     Directive.get(:sec_epoch)},
    {"am",          Directive.get(:am)},
    {"AM",          Directive.get(:AM)},
    # Timezones
    {"Zname",       Directive.get(:zname)},
    {"Z",           Directive.get(:zoffs)},
    {"Z:",          Directive.get(:zoffs_colon)},
    {"Z::",         Directive.get(:zoffs_sec)},
    # Preformatted Directives
    {"ISO",         Directive.get(:iso_8601)},
    {"ISOz",        Directive.get(:iso_8601z)},
    {"ISOdate",     Directive.get(:iso_date)},
    {"ISOtime",     Directive.get(:iso_time)},
    {"ISOweek",     Directive.get(:iso_week)},
    {"ISOweek-day", Directive.get(:iso_weekday)},
    {"ISOord",      Directive.get(:iso_ordinal)},
    {"RFC822",      Directive.get(:rfc_822)},
    {"RFC822z",     Directive.get(:rfc_822z)},
    {"RFC1123",     Directive.get(:rfc_1123)},
    {"RFC1123z",    Directive.get(:rfc_1123z)},
    {"RFC3339",     Directive.get(:rfc_3339)},
    {"RFC3339z",    Directive.get(:rfc_3339z)},
    {"ANSIC",       Directive.get(:ansic)},
    {"UNIX",        Directive.get(:unix)},
    {"kitchen",     Directive.get(:kitchen)}
  ]

  @doc """
  Takes a format string and extracts parsing directives for the parser.

  ## Example

    iex> Timex.Parsers.Tokenizers.Default.tokenize("{YYYY}-{0M}-{D}")
    [%Directive{token: :year4, ...}, %Directive{token: :month, pad: 1, ...}, ...]
  """
  def tokenize(s) when s in [nil, ""], do: {:error, "Format string cannot be nil or empty!"}
  def tokenize(s) when is_list(s), do: tokenize("#{s}")
  def tokenize(s) do
    do_tokenize(s)
  end

  defp do_tokenize(format),
    do: do_tokenize(format, %State{}, :next)
  defp do_tokenize(<<>>, %State{tokens: tokens}, :next),
    do: tokens |> Enum.reverse
  # Invalid strings
  defp do_tokenize(<<>>, %State{start_index: start_index}, status)
    when status != :next,
    do: {:error, "Unclosed directive starting at column #{start_index}"}
  defp do_tokenize(<<?{, _format :: binary>>, %State{col: col}, status)
    when status != :next,
    do: {:error, "Invalid nesting of directives at column #{col}: #{_format}"}
  defp do_tokenize(<<?}, _format :: binary>>, %State{col: col}, status)
    when status != :token,
    do: {:error, "Missing open brace for closing brace at column #{col}!"}
  # Start of directive
  defp do_tokenize(<<?{, format :: binary>>, state, :next) do
    state = %{state | :col => state.col + 1, :start_index => state.col}
    do_tokenize(format, state, :padding)
  end
  # End of directive
  defp do_tokenize(<<?}, format :: binary>>, %State{padding: pad, token: token, tokens: tokens} = state, :token) do
    case get_directive(token) do
      :invalid  -> {:error, "Invalid token beginning at column #{state.start_index}!"}
      {_, %Directive{} = directive} ->
        state = %{state | 
          :col     => state.col + 1,
          :padding => 0,
          :token   => "",
          :tokens  => [%{directive | :pad => pad || false, :pad_type => state.pad_type, :raw => token} | tokens]
        }
        do_tokenize(format, state, :next)
    end
  end
  # Determine padding
  defp do_tokenize(<<c :: utf8, format :: binary>>, %State{padding: pad} = state, :padding)
    when c in [?0, ?_],
    do: do_tokenize(format, %{state | :col => state.col + 1, :padding => pad + 1, :pad_type => pad_type(c)}, :padding)
  defp do_tokenize(<<c :: utf8, format :: binary>>, %State{token: token} = state, :padding),
    do: do_tokenize(format, %{state | :col => state.col + 1, :token => token <> <<c>>}, :token)
  # Parse mnemonic
  defp do_tokenize(<<c :: utf8, format :: binary>>, %State{token: token} = state, :token) do
    state = %{state | :col => state.col + 1, :token => token <> <<c>>}
    do_tokenize(format, state, :token)
  end
  # Handle non-token characters
  defp do_tokenize(<<char :: utf8, format :: binary>>, %State{col: col, tokens: tokens} = state, status) do
    directive = %Directive{type: :char, token: char, raw: <<char>>}
    state     = %{state | :col => col + 1, :tokens => [directive | tokens]}
    do_tokenize(format, state, status)
  end

  defp pad_type(?0), do: :zero
  defp pad_type(?_), do: :space

  defp get_directive(dir) do
    List.keyfind(@directives, dir, 0) || :invalid
  end
end
defmodule Timex.Parse.DateTime.Parser do
  @moduledoc """
  This is the base plugin behavior for all Timex date/time string parsers.
  """
  import Combine.Parsers.Base, only: [eof: 0, map: 2, pipe: 2]

  alias Timex.{Timezone, TimezoneInfo, AmbiguousDateTime, AmbiguousTimezoneInfo}
  alias Timex.Parse.ParseError
  alias Timex.Parse.DateTime.Tokenizers.{Directive, Default, Strftime}


  @doc """
  Parses a date/time string using the default parser.

  ## Examples

      iex> use Timex
      ...> {:ok, dt} = #{__MODULE__}.parse("2014-07-29T00:20:41.196Z", "{ISO:Extended:Z}")
      ...> dt.year
      2014
      iex> dt.month
      7
      iex> dt.day
      29
      iex> dt.time_zone
      "Etc/UTC"

  """
  @spec parse(binary, binary) :: {:ok, DateTime.t | NaiveDateTime.t} | {:error, term}
  def parse(date_string, format_string)
    when is_binary(date_string) and is_binary(format_string),
    do: parse(date_string, format_string, Default)
  def parse(_, _),
    do: {:error, :badarg}

  @doc """
  Parses a date/time string using the provided tokenizer. Tokenizers must implement the
  `Timex.Parse.DateTime.Tokenizer` behaviour.

  ## Examples

      iex> use Timex
      ...> {:ok, dt} = #{__MODULE__}.parse("2014-07-29T00:30:41.196-02:00", "{ISO:Extended}", Timex.Parse.DateTime.Tokenizers.Default)
      ...> dt.year
      2014
      iex> dt.month
      7
      iex> dt.day
      29
      iex> dt.time_zone
      "Etc/GMT+2"

  """
  @spec parse(binary, binary, atom) :: {:ok, DateTime.t | NaiveDateTime.t} | {:error, term}
  def parse(date_string, format_string, tokenizer)
    when is_binary(date_string) and is_binary(format_string)
    do
      try do
        {:ok, parse!(date_string, format_string, tokenizer)}
      catch
        _type, %ParseError{:message => msg} ->
          {:error, msg}
        _type, %{:message => msg} ->
          {:error, msg}
        _type, reason ->
          {:error, reason}
      end
  end
  def parse(_, _, _), do: {:error, :badarg}

  @doc """
  Same as `parse/2` and `parse/3`, but raises on error.
  """
  @spec parse!(String.t, String.t, atom | nil) :: DateTime.t | NaiveDateTime.t | no_return
  def parse!(date_string, format_string, tokenizer \\ Default)

  def parse!(date_string, format_string, :strftime),
    do: parse!(date_string, format_string, Strftime)
  def parse!(date_string, format_string, tokenizer)
    when is_binary(date_string) and is_binary(format_string) and is_atom(tokenizer)
    do
      case tokenizer.tokenize(format_string) do
        {:error, err} when is_binary(err) -> raise ParseError, message: err
        {:error, err} -> raise ParseError, message: "#{inspect err}"
        {:ok, []}     -> raise ParseError, message: "There were no parsing directives in the provided format string."
        {:ok, directives} ->
          case date_string do
            "" -> raise ParseError, message: "Input datetime string cannot be empty!"
            _  ->
              case do_parse(date_string, directives, tokenizer) do
                {:ok, %DateTime{time_zone: nil} = dt} ->
                  Timex.to_naive_datetime(dt)
                {:ok, dt} ->
                    dt
                {:error, reason} when is_binary(reason) ->
                  raise ParseError, message: reason
                {:error, reason} ->
                  raise ParseError, message: "#{inspect reason}"
              end
          end
      end
  end

  # Special case iso8601/rfc3339 for performance
  defp do_parse(str, [%Directive{:type => type}], _tokenizer)
    when type in [:iso_8601_extended, :iso_8601_extended_z, :rfc_3339, :rfc_3339z] do
    case Combine.parse(str, Timex.Parse.DateTime.Parsers.ISO8601Extended.parse) do
      {:error, _} = err -> err
      [[{:year4, y}, {:month, m}, {:day, d}, {:hour24, h}, {:zname, tzname}]] ->
        tz = Timezone.get(tzname, {{y,m,d},{h,0,0}})
        {:ok, %DateTime{:year => y, :month => m, :day => d,
                        :hour => h, :minute => 0, :second => 0, :microsecond => {0,0},
                        :time_zone => tz.full_name,
                        :zone_abbr => tz.abbreviation,
                        :utc_offset => tz.offset_utc,
                        :std_offset => tz.offset_std}}
      [[{:year4, y}, {:month, m}, {:day, d}, {:hour24, h}, {:min, mm}, {:zname, tzname}]] ->
        tz = Timezone.get(tzname, {{y,m,d},{h,mm,0}})
        {:ok, %DateTime{:year => y, :month => m, :day => d,
                        :hour => h, :minute => mm, :second => 0, :microsecond => {0,0},
                        :time_zone => tz.full_name,
                        :zone_abbr => tz.abbreviation,
                        :utc_offset => tz.offset_utc,
                        :std_offset => tz.offset_std}}
      [[{:year4, y}, {:month, m}, {:day, d}, {:hour24, h}, {:min, mm}, {:sec, s}, {:zname, tzname}]] ->
        tz = Timezone.get(tzname, {{y,m,d},{h,mm,s}})
        {:ok, %DateTime{:year => y, :month => m, :day => d,
                        :hour => h, :minute => mm, :second => s, :microsecond => {0,0},
                        :time_zone => tz.full_name,
                        :zone_abbr => tz.abbreviation,
                        :utc_offset => tz.offset_utc,
                        :std_offset => tz.offset_std}}
      [[{:year4, y}, {:month, m}, {:day, d}, {:hour24, h}, {:min, mm}, {:sec, s}, {:sec_fractional, us}, {:zname, tzname}]] ->
        tz = Timezone.get(tzname, {{y,m,d},{h,mm,s}})
        {:ok, %DateTime{:year => y, :month => m, :day => d,
                        :hour => h, :minute => mm, :second => s, :microsecond => us,
                        :time_zone => tz.full_name,
                        :zone_abbr => tz.abbreviation,
                        :utc_offset => tz.offset_utc,
                        :std_offset => tz.offset_std}}
    end
  end
  defp do_parse(str, directives, tokenizer) do
    parsers = directives
              |> Stream.map(fn %Directive{weight: weight, parser: parser} -> map(parser, &({&1, weight})) end)
              |> Stream.filter(fn nil -> false; _ -> true end)
              |> Enum.reverse
    case Combine.parse(str, pipe([eof()|parsers] |> Enum.reverse, &(&1))) do
      [results] when is_list(results) ->
        results
        |> extract_parse_results
        |> Stream.with_index
        |> Enum.sort_by(fn
            # If :force_utc exists, make sure it is applied last
            {{{:force_utc, true}, _}, _} -> 9999
            # Timezones must always be applied after other date/time tokens ->
            {{{tz, _}, _}, _} when tz in [:zname, :zoffs, :zoffs_colon, :zoffs_sec] -> 9998
            # If no weight is set, use the index as its weight
            {{{_token, _value}, 0}, i} -> i
            # Use the directive weight
            {{{_token, _value}, weight}, _} -> weight
          end)
        |> Stream.flat_map(fn {{token, _}, _} -> [token] end)
        |> Enum.filter(&Kernel.is_tuple/1)
        |> apply_directives(tokenizer)
      {:error, _} = err -> err
    end
  end
  defp extract_parse_results(parse_results), do: extract_parse_results(parse_results, [])
  defp extract_parse_results([], acc), do: Enum.reverse(acc)
  defp extract_parse_results([{tokens, weight}|rest], acc) when is_list(tokens) do
    extracted = extract_parse_results(tokens)
      |> Enum.map(fn {{token, value}, _weight} -> {{token, value}, weight} end)
      |> Enum.reverse
    extract_parse_results(rest, extracted ++ acc)
  end
  defp extract_parse_results([{{token, value}, weight}|rest], acc) when is_atom(token) do
    extract_parse_results(rest, [{{token, value}, weight}|acc])
  end
  defp extract_parse_results([{token, value}|rest], acc) when is_atom(token) do
    extract_parse_results(rest, [{{token, value}, 0}|acc])
  end
  defp extract_parse_results([[{token, value}]|rest], acc) when is_atom(token) do
    extract_parse_results(rest, [{{token, value}, 0}|acc])
  end
  defp extract_parse_results([h|rest], acc) when is_list(h) do
    extracted = Enum.reverse(extract_parse_results(h))
    extract_parse_results(rest, extracted ++ acc)
  end
  defp extract_parse_results([_|rest], acc) do
    extract_parse_results(rest, acc)
  end

  # Constructs a DateTime from the parsed tokens
  defp apply_directives([], _),
    do: {:ok, Timex.DateTime.Helpers.empty()}
  defp apply_directives(tokens, tokenizer),
    do: apply_directives(tokens, Timex.DateTime.Helpers.empty(), tokenizer)
  defp apply_directives([], %DateTime{} = date, _), do: {:ok, date}
  defp apply_directives([{token, value}|tokens], %DateTime{} = date, tokenizer) do
    case update_date(date, token, value, tokenizer) do
      {:error, _} = error -> error
      updated             -> apply_directives(tokens, updated, tokenizer)
    end
  end

  # Given a date, a token, and the value for that token, update the
  # date according to the rules for that token and the provided value
  defp update_date(%AmbiguousDateTime{} = adt, token, value, tokenizer) when is_atom(token) do
    bd = update_date(adt.before, token, value, tokenizer)
    ad = update_date(adt.after, token, value, tokenizer)
    %{adt | :before => bd, :after => ad}
  end
  defp update_date(%DateTime{year: year, hour: hh} = date, token, value, tokenizer) when is_atom(token) do
    case token do
      # Formats
      clock when clock in [:kitchen, :strftime_iso_kitchen] ->
        {{y,m,d},_} = :calendar.universal_time()
        date = %{date | :year => y, :month => m, :day => d}
        case apply_directives(value, date, tokenizer) do
          {:error, _} = err -> err
          {:ok, date} when clock == :kitchen ->
            %{date | :second => 0, :microsecond => {0,0}}
          {:ok, date} ->
            %{date | :microsecond => {0,0}}
        end
      # Years
      :century   ->
        century = Timex.century(%{date | :year => year})
        year_shifted = year + ((value - century) * 100)
        %{date | :year => year_shifted}
      y when y in [:year2, :iso_year2] ->
        {{y,_,_},_} = :calendar.universal_time()
        current_century = Timex.century(y)
        year_shifted    = value + ((current_century - 1) * 100)
        %{date | :year => year_shifted}
      y when y in [:year4, :iso_year4] ->
        # Special case for UNIX format dates, where the year is parsed after the timezone,
        # so we must lookup the timezone again to ensure it's properly set
        case date do
          %DateTime{time_zone: nil} ->
            %{date | :year => value}
          %DateTime{time_zone: tzname} ->
            seconds_from_zeroyear = Timex.to_gregorian_seconds(date)
            case Timezone.resolve(tzname, seconds_from_zeroyear) do
              %TimezoneInfo{} = tz ->
                %{date | :year => value,
                  :time_zone => tz.full_name,
                  :zone_abbr => tz.abbreviation,
                  :utc_offset => tz.offset_utc,
                  :std_offset => tz.offset_std}
              %AmbiguousTimezoneInfo{before: b, after: a} ->
                bd = %{date | :year => value,
                       :time_zone => b.full_name,
                       :zone_abbr => b.abbreviation,
                       :utc_offset => b.offset_utc,
                       :std_offset => b.offset_std}
                ad = %{date | :year => value,
                       :time_zone => a.full_name,
                       :zone_abbr => a.abbreviation,
                       :utc_offset => a.offset_utc,
                       :std_offset => a.offset_std}
                %AmbiguousDateTime{:before => bd, :after => ad}
            end
        end
      # Months
      :month ->
        %{date | :month => value}
      month when month in [:mshort, :mfull] ->
        %{date | :month => Timex.month_to_num(value)}
      # Days
      :day ->
        %{date | :day => value}
      :oday when is_integer(value) and value >= 0 ->
        Timex.from_iso_day(value, date)
      :wday_mon ->
        current_day = Timex.weekday(date)
        cond do
          current_day == value -> date
          current_day > value  -> Timex.shift(date, days: current_day - value)
          current_day < value  -> Timex.shift(date, days: value - current_day)
        end
      :wday_sun ->
        current_day = Timex.weekday(date) - 1
        cond do
          current_day == value -> date
          current_day > value -> Timex.shift(date, days: current_day - value)
          current_day < value -> Timex.shift(date, days: value - current_day)
        end
      day when day in [:wdshort, :wdfull] ->
        %{date | :day => Timex.day_to_num(value)}
      # Weeks
      :iso_weeknum ->
        {year, _, weekday} = Timex.iso_triplet(date)
        %Date{year: y, month: m, day: d} = Timex.from_iso_triplet({year, value, weekday})
        %{date | :year => y, :month => m, :day => d}
      week_num when week_num in [:week_mon, :week_sun] ->
        reset = %{date | :month => 1, :day => 1}
        reset |> Timex.shift(weeks: value)
      # Hours
      hour when hour in [:hour24, :hour12] ->
        %{date | :hour => value}
      :min       -> %{date | :minute => value}
      :sec       -> %{date | :second => value}
      :sec_fractional ->
        case value do
          "" -> date
          n when is_number(n) ->
            %{date | :microsecond => {n, 6}}
          {_n, _precision} = us ->
            %{date | :microsecond => us}
        end
      :us -> %{date | :microsecond => {value, 6}}
      :ms -> %{date | :microsecond => {value*1_000, 6}}
      :sec_epoch ->
        DateTime.from_unix!(value)
      am_pm when am_pm in [:am, :AM] ->
        cond do
          hh == 24 ->
            %{date | :hour => 0}
          hh == 12 and (String.downcase(value) == "am") ->
            %{date | :hour => 0}
          hh in (1..11) and String.downcase(value) == "pm" ->
            %{date | :hour => hh + 12} 
          true ->
            date
        end
      # Timezones
      :zoffs ->
        case value do
          <<sign::utf8, h1::utf8, h2::utf8>> ->
            hour    = <<h1::utf8,h2::utf8>>
            hours   = String.to_integer(hour)
            minutes = 0
            {gmt_sign, total_offset} = case sign do
              ?- -> {?+, -1 * ((hours*60*60) + (minutes*60))}
              ?+ -> {?-, ((hours*60*60) + (minutes*60))}
            end
            case hours do
              h when h < 10 ->
                %{date |
                  :time_zone => <<"Etc/GMT", gmt_sign::utf8, h2::utf8>>,
                  :zone_abbr => <<"GMT", gmt_sign::utf8, h2::utf8>>,
                  :utc_offset => total_offset,
                  :std_offset => 0}
              _ ->
                %{date |
                  :time_zone => <<"Etc/GMT", gmt_sign::utf8, hour::binary>>,
                  :zone_abbr => <<"GMT", gmt_sign::utf8, hour::binary>>,
                  :utc_offset => total_offset,
                  :std_offset => 0}
            end
          <<sign::utf8, h1::utf8, h2::utf8, m1::utf8, m2::utf8>> ->
            hour    = <<h1::utf8,h2::utf8>>
            hours   = String.to_integer(hour)
            minute  = <<m1::utf8,m2::utf8>>
            minutes = String.to_integer(minute)
            {gmt_sign, total_offset} = case sign do
              ?- -> {?+, -1 * ((hours*60*60) + (minutes*60))}
              ?+ -> {?-, ((hours*60*60) + (minutes*60))}
            end
            case {hours, minutes} do
              {h, 0} when h < 10 ->
                %{date |
                  :time_zone => <<"Etc/GMT", gmt_sign::utf8, h2::utf8>>,
                  :zone_abbr => <<"GMT", gmt_sign::utf8, h2::utf8>>,
                  :utc_offset => total_offset,
                  :std_offset => 0}
              {_, 0} ->
                %{date |
                  :time_zone => <<"Etc/GMT", gmt_sign::utf8, hour::binary>>,
                  :zone_abbr => <<"GMT", gmt_sign::utf8, hour::binary>>,
                  :utc_offset => total_offset,
                  :std_offset => 0}
              _ ->
                %{date |
                  :time_zone => <<"Etc/GMT", gmt_sign::utf8, hour::binary, ?:, minute::binary>>,
                  :zone_abbr => <<"GMT", gmt_sign::utf8, hour::binary, ?:, minute::binary>>,
                  :utc_offset => total_offset,
                  :std_offset => 0}
            end
          _ ->
            {:error, "invalid offset: #{inspect value}"}
        end
      :zname ->
        seconds_from_zeroyear = Timex.to_gregorian_seconds(date)
        case Timezone.name_of(value) do
          {:error, _} = err -> err
          tzname ->
            case Timezone.resolve(tzname, seconds_from_zeroyear) do
              %TimezoneInfo{} = tz ->
                %{date |
                  :time_zone => tz.full_name,
                  :zone_abbr => tz.abbreviation,
                  :utc_offset => tz.offset_utc,
                  :std_offset => tz.offset_std}
              %AmbiguousTimezoneInfo{before: b, after: a} ->
                bd = %{date |
                      :time_zone => b.full_name,
                      :zone_abbr => b.abbreviation,
                      :utc_offset => b.offset_utc,
                      :std_offset => b.offset_std}
                ad = %{date |
                      :time_zone => a.full_name,
                      :zone_abbr => a.abbreviation,
                      :utc_offset => a.offset_utc,
                      :std_offset => a.offset_std}
                %AmbiguousDateTime{:before => bd, :after => ad}
            end
        end
      :zoffs_colon ->
        case value do
          <<sign::utf8, h1::utf8, h2::utf8, ?:, m1::utf8, m2::utf8>> ->
            hour    = <<h1::utf8,h2::utf8>>
            hours   = String.to_integer(hour)
            minute  = <<m1::utf8,m2::utf8>>
            minutes = String.to_integer(minute)
            {gmt_sign, total_offset} = case sign do
              ?- -> {?+, -1 * ((hours*60*60) + (minutes*60))}
              ?+ -> {?-, ((hours*60*60) + (minutes*60))}
            end
            case {hours, minutes} do
              {h, 0} when h < 10 ->
                %{date |
                  :time_zone => <<"Etc/GMT", gmt_sign::utf8, h2::utf8>>,
                  :zone_abbr => <<"GMT", gmt_sign::utf8, h2::utf8>>,
                  :utc_offset => total_offset,
                  :std_offset => 0}
              {_, 0} ->
                %{date |
                  :time_zone => <<"Etc/GMT", gmt_sign::utf8, hour::binary>>,
                  :zone_abbr => <<"GMT", gmt_sign::utf8, hour::binary>>,
                  :utc_offset => total_offset,
                  :std_offset => 0}
              _ ->
                %{date |
                  :time_zone => <<"Etc/GMT", gmt_sign::utf8, hour::binary, ?:, minute::binary>>,
                  :zone_abbr => <<"GMT", gmt_sign::utf8, hour::binary, ?:, minute::binary>>,
                  :utc_offset => total_offset,
                  :std_offset => 0}
            end
          _ ->
            {:error, "invalid offset: #{inspect value}"}
        end
      :zoffs_sec ->
        case value do
          <<sign::utf8, h1::utf8, h2::utf8, ?:, m1::utf8, m2::utf8, ?:, s1::utf8, s2::utf8>> ->
            hour    = <<h1::utf8,h2::utf8>>
            hours   = String.to_integer(hour)
            minute  = <<m1::utf8,m2::utf8>>
            minutes = String.to_integer(minute)
            second  = <<s1::utf8,s2::utf8>>
            seconds = String.to_integer(second)
            {gmt_sign, total_offset} = case sign do
              ?- -> {?+, -1 * ((hours*60*60) + (minutes*60))}
              ?+ -> {?-, ((hours*60*60) + (minutes*60))}
            end
            case {hours, minutes, seconds} do
              {h, 0, 0} when h < 10 ->
                %{date |
                  :time_zone => <<"Etc/GMT", gmt_sign::utf8, h2::utf8>>,
                  :zone_abbr => <<"GMT", gmt_sign::utf8, h2::utf8>>,
                  :utc_offset => total_offset,
                  :std_offset => 0}
              {_, 0, 0} ->
                %{date |
                  :time_zone => <<"Etc/GMT", gmt_sign::utf8, hour::binary>>,
                  :zone_abbr => <<"GMT", gmt_sign::utf8, hour::binary>>,
                  :utc_offset => total_offset,
                  :std_offset => 0}
              _ ->
                %{date |
                  :time_zone => <<"Etc/GMT", gmt_sign::utf8, hour::binary, ?:, minute::binary, ?:, second::binary>>,
                  :zone_abbr => <<"GMT", gmt_sign::utf8, hour::binary, ?:, minute::binary, ?:, second::binary>>,
                  :utc_offset => total_offset,
                  :std_offset => 0}
            end
          _ ->
            {:error, "invalid offset: #{inspect value}"}
        end
      :force_utc ->
        case date.time_zone do
          nil ->
            %{date | :time_zone => "Etc/UTC", :zone_abbr => "UTC", :utc_offset => 0, :std_offset => 0}
          _   ->
            Timezone.convert(date, "UTC")
        end
      :literal ->
        date
      _ ->
        case tokenizer.apply(date, token, value) do
          {:ok, date}       -> date
          {:error, _} = err -> err
          _ ->
            {:error, "Unrecognized token: #{token}"}
        end
    end
  end

end

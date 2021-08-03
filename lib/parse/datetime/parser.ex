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
  @spec parse(binary, binary) :: {:ok, DateTime.t() | NaiveDateTime.t()} | {:error, term}
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
      "Etc/UTC-2"

  """
  @spec parse(binary, binary, atom) :: {:ok, DateTime.t() | NaiveDateTime.t()} | {:error, term}
  def parse(date_string, format_string, tokenizer)
      when is_binary(date_string) and is_binary(format_string) do
    try do
      {:ok, parse!(date_string, format_string, tokenizer)}
    rescue
      err in [ParseError] ->
        {:error, err.message}
    end
  end

  def parse(_, _, _), do: {:error, :badarg}

  @doc """
  Same as `parse/2` and `parse/3`, but raises on error.
  """
  @spec parse!(String.t(), String.t(), atom | nil) :: DateTime.t() | NaiveDateTime.t() | no_return
  def parse!(date_string, format_string, tokenizer \\ Default)

  def parse!(date_string, format_string, :strftime),
    do: parse!(date_string, format_string, Strftime)

  def parse!(date_string, format_string, tokenizer)
      when is_binary(date_string) and is_binary(format_string) and is_atom(tokenizer) do
    case tokenizer.tokenize(format_string) do
      {:error, err} when is_binary(err) ->
        raise ParseError, message: err

      {:error, err} ->
        raise ParseError, message: err

      {:ok, []} ->
        raise ParseError,
          message: "There were no parsing directives in the provided format string."

      {:ok, directives} ->
        case date_string do
          "" ->
            raise ParseError, message: "Input datetime string cannot be empty!"

          _ ->
            case do_parse(date_string, directives, tokenizer) do
              {:ok, dt} ->
                dt

              {:error, reason} when is_binary(reason) ->
                raise ParseError, message: reason

              {:error, reason} ->
                raise ParseError, message: reason
            end
        end
    end
  end

  # Special case iso8601/rfc3339 for performance
  defp do_parse(str, [%Directive{:type => type}], _tokenizer)
       when type in [:iso_8601_extended, :iso_8601_extended_z, :rfc_3339, :rfc_3339z] do
    case Combine.parse(str, Timex.Parse.DateTime.Parsers.ISO8601Extended.parse()) do
      {:error, _} = err ->
        err

      [parts] when is_list(parts) ->
        case Enum.into(parts, %{}) do
          %{year4: y, month: m, day: d, hour24: h, zname: tzname} = mapped ->
            mm = Map.get(mapped, :min, 0)
            ss = Map.get(mapped, :sec, 0)
            us = Map.get(mapped, :sec_fractional, {0, 0})
            naive = Timex.NaiveDateTime.new!(y, m, d, h, mm, ss, us)

            with %DateTime{} = datetime <- Timex.Timezone.convert(naive, tzname) do
              {:ok, datetime}
            end

          %{year4: y, month: m, day: d, hour24: h} = mapped ->
            mm = Map.get(mapped, :min, 0)
            ss = Map.get(mapped, :sec, 0)
            us = Map.get(mapped, :sec_fractional, {0, 0})

            NaiveDateTime.new(y, m, d, h, mm, ss, us)
        end
    end
  end

  defp do_parse(str, directives, tokenizer) do
    parsers =
      directives
      |> Stream.map(fn %Directive{weight: weight, parser: parser} ->
        map(parser, &{&1, weight})
      end)
      |> Stream.filter(fn
        nil -> false
        _ -> true
      end)
      |> Enum.reverse()

    case Combine.parse(str, pipe([eof() | parsers] |> Enum.reverse(), & &1)) do
      [results] when is_list(results) ->
        results
        |> extract_parse_results
        |> Stream.with_index()
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

      {:error, _} = err ->
        err
    end
  end

  defp extract_parse_results(parse_results), do: extract_parse_results(parse_results, [])
  defp extract_parse_results([], acc), do: Enum.reverse(acc)

  defp extract_parse_results([{tokens, weight} | rest], acc) when is_list(tokens) do
    extracted =
      extract_parse_results(tokens)
      |> Enum.map(fn {{token, value}, _weight} -> {{token, value}, weight} end)
      |> Enum.reverse()

    extract_parse_results(rest, extracted ++ acc)
  end

  defp extract_parse_results([{{token, value}, weight} | rest], acc) when is_atom(token) do
    extract_parse_results(rest, [{{token, value}, weight} | acc])
  end

  defp extract_parse_results([{token, value} | rest], acc) when is_atom(token) do
    extract_parse_results(rest, [{{token, value}, 0} | acc])
  end

  defp extract_parse_results([[{token, value}] | rest], acc) when is_atom(token) do
    extract_parse_results(rest, [{{token, value}, 0} | acc])
  end

  defp extract_parse_results([h | rest], acc) when is_list(h) do
    extracted = Enum.reverse(extract_parse_results(h))
    extract_parse_results(rest, extracted ++ acc)
  end

  defp extract_parse_results([_ | rest], acc) do
    extract_parse_results(rest, acc)
  end

  # Constructs a DateTime from the parsed tokens
  defp apply_directives([], _),
    do: {:ok, Timex.DateTime.Helpers.empty()}

  defp apply_directives(tokens, tokenizer),
    do: apply_directives(tokens, Timex.DateTime.Helpers.empty(), tokenizer)

  defp apply_directives([], datetime, _) do
    with :ok <- validate_datetime(datetime) do
      {:ok, datetime}
    end
  end

  defp apply_directives([{token, value} | tokens], date, tokenizer) do
    case update_date(date, token, value, tokenizer) do
      {:error, _} = error ->
        error

      updated ->
        apply_directives(tokens, updated, tokenizer)
    end
  end

  defp validate_datetime(%{year: y, month: m, day: d} = datetime) do
    with {:date, true} <- {:date, :calendar.valid_date(y, m, d)},
         {:ok, %Time{}} <-
           Time.new(datetime.hour, datetime.minute, datetime.second, datetime.microsecond) do
      :ok
    else
      {:date, _} ->
        {:error, :invalid_date}

      {:error, _} = err ->
        err
    end
  end

  defp validate_datetime(%AmbiguousDateTime{before: before_dt, after: after_dt}) do
    with :ok <- validate_datetime(before_dt),
         :ok <- validate_datetime(after_dt) do
      :ok
    else
      {:error, _} = err ->
        err
    end
  end

  # Given a date, a token, and the value for that token, update the
  # date according to the rules for that token and the provided value
  defp update_date(%AmbiguousDateTime{} = adt, token, value, tokenizer) when is_atom(token) do
    bd = update_date(adt.before, token, value, tokenizer)
    ad = update_date(adt.after, token, value, tokenizer)
    %{adt | :before => bd, :after => ad}
  end

  defp update_date(%{year: year, hour: hh} = date, token, value, tokenizer) when is_atom(token) do
    case token do
      # Formats
      clock when clock in [:kitchen, :strftime_iso_kitchen] ->
        date =
          cond do
            date == Timex.DateTime.Helpers.empty() ->
              {{y, m, d}, _} = :calendar.universal_time()
              %{date | :year => y, :month => m, :day => d}

            true ->
              date
          end

        case apply_directives(value, date, tokenizer) do
          {:error, _} = err ->
            err

          {:ok, date} when clock == :kitchen ->
            %{date | :second => 0, :microsecond => {0, 0}}

          {:ok, date} ->
            %{date | :microsecond => {0, 0}}
        end

      # Years
      :century ->
        century = Timex.century(%{date | :year => year})
        year_shifted = year + (value - century) * 100
        %{date | :year => year_shifted}

      y when y in [:year2, :iso_year2] ->
        {{y, _, _}, _} = :calendar.universal_time()
        current_century = Timex.century(y)
        year_shifted = value + (current_century - 1) * 100
        %{date | :year => year_shifted}

      y when y in [:year4, :iso_year4] ->
        date = %{date | :year => value}
        # Special case for UNIX format dates, where the year is parsed after the timezone,
        # so we must lookup the timezone again to ensure it's properly set
        case Map.get(date, :time_zone) do
          time_zone when is_binary(time_zone) ->
            # Need to validate the date/time before doing timezone operations
            with :ok <- validate_datetime(date) do
              seconds_from_zeroyear = Timex.to_gregorian_seconds(date)

              case Timezone.resolve(time_zone, seconds_from_zeroyear) do
                %TimezoneInfo{} = tz ->
                  Timex.to_datetime(date, tz)

                %AmbiguousTimezoneInfo{before: b, after: a} ->
                  bd = Timex.to_datetime(date, b)
                  ad = Timex.to_datetime(date, a)

                  %AmbiguousDateTime{before: bd, after: ad}
              end
            end

          nil ->
            date
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
          current_day > value -> Timex.shift(date, days: current_day - value)
          current_day < value -> Timex.shift(date, days: value - current_day)
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

      :weekday ->
        current_dow = Timex.Date.day_of_week(date, :monday)

        if current_dow == value do
          date
        else
          Timex.shift(date, days: value - current_dow)
        end

      # Hours
      hour when hour in [:hour24, :hour12] ->
        %{date | :hour => value}

      :min ->
        %{date | :minute => value}

      :sec ->
        case value do
          60 ->
            Timex.shift(date, minutes: 1)

          value ->
            %{date | :second => value}
        end

      :sec_fractional ->
        case value do
          "" ->
            date

          n when is_number(n) ->
            %{date | :microsecond => Timex.DateTime.Helpers.construct_microseconds(n, -1)}

          {_n, _precision} = us ->
            %{date | :microsecond => us}
        end

      :us ->
        %{date | :microsecond => Timex.DateTime.Helpers.construct_microseconds(value, -1)}

      :ms ->
        %{date | :microsecond => Timex.DateTime.Helpers.construct_microseconds(value * 1_000, -1)}

      :sec_epoch ->
        DateTime.from_unix!(value)

      am_pm when am_pm in [:am, :AM] ->
        cond do
          hh == 24 ->
            %{date | :hour => 0}

          hh == 12 and String.downcase(value) == "am" ->
            %{date | :hour => 0}

          hh in 1..11 and String.downcase(value) == "pm" ->
            %{date | :hour => hh + 12}

          true ->
            date
        end

      # Timezones
      :zoffs ->
        with :ok <- validate_datetime(date) do
          case value do
            <<sign::utf8, _::binary-size(2)-unit(8)>> = zone when sign in [?+, ?-] ->
              Timex.to_datetime(date, zone)

            <<sign::utf8, _::binary-size(4)-unit(8)>> = zone when sign in [?+, ?-] ->
              Timex.to_datetime(date, zone)

            _ ->
              {:error, {:invalid_zoffs, value}}
          end
        end

      :zname ->
        with :ok <- validate_datetime(date) do
          Timex.to_datetime(date, value)
        end

      :zoffs_colon ->
        with :ok <- validate_datetime(date) do
          case value do
            <<sign::utf8, _::binary-size(2)-unit(8), ?:, _::binary-size(2)-unit(8)>> = zone
            when sign in [?+, ?-] ->
              Timex.to_datetime(date, zone)

            _ ->
              {:error, {:invalid_zoffs_colon, value}}
          end
        end

      :zoffs_sec ->
        with :ok <- validate_datetime(date) do
          case value do
            <<sign::utf8, _::binary-size(2)-unit(8), ?:, _::binary-size(2)-unit(8), ?:,
              _::binary-size(2)-unit(8)>> = zone
            when sign in [?+, ?-] ->
              Timex.to_datetime(date, zone)

            _ ->
              {:error, {:invalid_zoffs_sec, value}}
          end
        end

      :force_utc ->
        with :ok <- validate_datetime(date) do
          Timex.to_datetime(date, "Etc/UTC")
        end

      :literal ->
        date

      :week_of_year_iso ->
        shift_to_week_of_year(:iso, date, value)

      :week_of_year_mon ->
        shift_to_week_of_year(:monday, date, value)

      :week_of_year_sun ->
        shift_to_week_of_year(:sunday, date, value)

      _ ->
        case tokenizer.apply(date, token, value) do
          {:ok, date} ->
            date

          {:error, _} = err ->
            err

          _ ->
            {:error, "Unrecognized token: #{token}"}
        end
    end
  end

  defp shift_to_week_of_year(:iso, %{year: y} = datetime, value) when is_integer(value) do
    {dow11, _, _} = Timex.Date.day_of_week(y, 1, 1, :monday)
    {dow14, _, _} = Timex.Date.day_of_week(y, 1, 4, :monday)

    # See https://en.wikipedia.org/wiki/ISO_week_date#Calculating_an_ordinal_or_month_date_from_a_week_date
    ordinal = value * 7 + dow11 - (dow14 + 3)
    {year, month, day} = Timex.Helpers.iso_day_to_date_tuple(y, ordinal)

    %Date{year: year, month: month, day: day} =
      Timex.Date.beginning_of_week(Timex.Date.new!(year, month, day))

    %{datetime | year: year, month: month, day: day}
  end

  defp shift_to_week_of_year(weekstart, %{year: y} = datetime, value) when is_integer(value) do
    new_year = Timex.Date.new!(y, 1, 1)
    week_start = Timex.Date.beginning_of_week(new_year, weekstart)

    # This date can be calculated by taking the day number of the year,
    # shifting the day number of the year down by the number of days which
    # occurred in the previous year, then dividing by 7
    day_num =
      if Date.compare(week_start, new_year) == :lt do
        prev_year_day_start = Date.day_of_year(week_start)
        prev_year_day_end = Date.day_of_year(Timex.Date.new!(week_start.year, 12, 31))
        shift = prev_year_day_end - prev_year_day_start
        shift + value * 7
      else
        value * 7
      end

    datetime = Timex.to_naive_datetime(datetime)
    Timex.shift(%{datetime | month: 1, day: 1}, days: day_num)
  end
end

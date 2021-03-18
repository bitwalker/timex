defmodule Timex.Parse.DateTime.Helpers do
  @moduledoc false
  import Combine.Parsers.Base
  import Combine.Parsers.Text, except: [integer: 0, integer: 1]
  alias Combine.Parsers.Text
  use Timex.Constants

  def months do
    @month_names ++ Map.values(Timex.Translator.get_months(Timex.Translator.current_locale()))
  end

  def months_abbr do
    @month_abbrs ++
      Map.values(Timex.Translator.get_months_abbreviated(Timex.Translator.current_locale()))
  end

  def to_month(month) when is_integer(month), do: [month: month]

  def to_month_num(m) when m in ["January", "Jan"], do: to_month(1)
  def to_month_num(m) when m in ["February", "Feb"], do: to_month(2)
  def to_month_num(m) when m in ["March", "Mar"], do: to_month(3)
  def to_month_num(m) when m in ["April", "Apr"], do: to_month(4)
  def to_month_num(m) when m in ["May", "May"], do: to_month(5)
  def to_month_num(m) when m in ["June", "Jun"], do: to_month(6)
  def to_month_num(m) when m in ["July", "Jul"], do: to_month(7)
  def to_month_num(m) when m in ["August", "Aug"], do: to_month(8)
  def to_month_num(m) when m in ["September", "Sep"], do: to_month(9)
  def to_month_num(m) when m in ["October", "Oct"], do: to_month(10)
  def to_month_num(m) when m in ["November", "Nov"], do: to_month(11)
  def to_month_num(m) when m in ["December", "Dec"], do: to_month(12)

  def to_month_num(m) when is_binary(m) do
    Map.fetch!(Timex.Translator.get_months_lookup(Timex.Translator.current_locale()), m)
  end

  def is_weekday(name) do
    n = String.downcase(name)

    cond do
      n in @weekday_abbrs_lower ->
        true

      n in @weekday_names_lower ->
        true

      Map.has_key?(Timex.Translator.get_weekdays_lookup(Timex.Translator.current_locale()), name) ->
        true

      :else ->
        false
    end
  end

  def to_weekday(name) do
    n = String.downcase(name)

    case n do
      n when n in ["mon", "monday"] ->
        1

      n when n in ["tue", "tuesday"] ->
        2

      n when n in ["wed", "wednesday"] ->
        3

      n when n in ["thu", "thursday"] ->
        4

      n when n in ["fri", "friday"] ->
        5

      n when n in ["sat", "saturday"] ->
        6

      n when n in ["sun", "sunday"] ->
        7

      _ ->
        Map.fetch!(Timex.Translator.get_weekdays_lookup(Timex.Translator.current_locale()), name)
    end
  end

  def to_sec_ms(fraction) do
    precision = byte_size(fraction)
    n = String.to_integer(fraction)
    n = n * div(1_000_000, trunc(:math.pow(10, precision)))

    case n do
      0 -> [sec_fractional: {0, 0}]
      _ -> [sec_fractional: {n, precision}]
    end
  end

  def parse_milliseconds(ms) do
    n = ms |> String.trim_leading("0")
    n = if n == "", do: 0, else: String.to_integer(n)
    n = n * 1_000
    [sec_fractional: Timex.DateTime.Helpers.construct_microseconds(n, -1)]
  end

  def parse_microseconds(us) do
    n_width = byte_size(us)
    trailing = n_width - byte_size(String.trim_trailing(us, "0"))

    cond do
      n_width == trailing ->
        [sec_fractional: {0, n_width}]

      :else ->
        p = n_width - trailing
        p = if p > 6, do: 6, else: p
        n = us |> String.trim("0") |> String.to_integer()
        [sec_fractional: {n * trunc(:math.pow(10, 6 - p)), p}]
    end
  end

  def ampm_lower do
    ["am", "pm"] ++
      Timex.Translator.get_day_periods_lower(Timex.Translator.current_locale())
  end

  def ampm_upper do
    ["AM", "PM"] ++
      Timex.Translator.get_day_periods_upper(Timex.Translator.current_locale())
  end

  def ampm_any do
    ampm_lower() ++ ampm_upper()
  end

  def to_ampm("am"), do: [am: "am"]
  def to_ampm("AM"), do: [AM: "AM"]
  def to_ampm("pm"), do: [am: "pm"]
  def to_ampm("PM"), do: [AM: "PM"]

  def to_ampm(value) when is_binary(value) do
    type =
      Map.fetch!(
        Timex.Translator.get_day_periods_lookup(Timex.Translator.current_locale()),
        value
      )

    [{type, value}]
  end

  def integer(opts \\ []) do
    min_width =
      case Keyword.get(opts, :padding) do
        :none ->
          1

        _ ->
          get_in(opts, [:min]) || 1
      end

    max_width = get_in(opts, [:max])
    padding = get_in(opts, [:padding])

    case {padding, min_width, max_width} do
      {:zeroes, _, nil} -> Text.integer()
      {:zeroes, min, max} -> choice(Enum.map(max..min, &fixed_integer(&1)))
      {:spaces, -1, nil} -> skip(spaces()) |> Text.integer()
      {:spaces, min, nil} -> skip(spaces()) |> fixed_integer(min)
      {:spaces, _, max} -> skip(spaces()) |> choice(Enum.map(max..1, &fixed_integer(&1)))
      {_, -1, nil} -> Text.integer()
      {_, min, nil} -> fixed_integer(min)
      {_, min, max} -> choice(Enum.map(max..min, &fixed_integer(&1)))
    end
  end
end

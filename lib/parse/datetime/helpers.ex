defmodule Timex.Parse.DateTime.Helpers do
  @moduledoc false
  import Combine.Parsers.Base
  import Combine.Parsers.Text, except: [integer: 0, integer: 1]
  alias Combine.Parsers.Text

  @weekdays_abbr ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]
  @weekdays      ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]

  @months [
    "January", "February", "March", "April",
    "May", "June", "July", "August",
    "September", "October", "November", "December"
  ]
  def months, do: @months

  def to_month(month) when is_integer(month), do: [month: month]

  def to_month_num(nil), do: fail("Invalid month value.")
  def to_month_num(m) when m in ["January", "Jan"],   do: to_month(1)
  def to_month_num(m) when m in ["February", "Feb"],  do: to_month(2)
  def to_month_num(m) when m in ["March", "Mar"],     do: to_month(3)
  def to_month_num(m) when m in ["April", "Apr"],     do: to_month(4)
  def to_month_num(m) when m in ["May", "May"],       do: to_month(5)
  def to_month_num(m) when m in ["June", "Jun"],      do: to_month(6)
  def to_month_num(m) when m in ["July", "Jul"],      do: to_month(7)
  def to_month_num(m) when m in ["August", "Aug"],    do: to_month(8)
  def to_month_num(m) when m in ["September", "Sep"], do: to_month(9)
  def to_month_num(m) when m in ["October", "Oct"],   do: to_month(10)
  def to_month_num(m) when m in ["November", "Nov"],  do: to_month(11)
  def to_month_num(m) when m in ["December", "Dec"],  do: to_month(12)

  def is_weekday(name) do
    n = String.downcase(name)
    cond do
      n in @weekdays_abbr -> true
      n in @weekdays      -> true
      true                -> false
    end
  end

  def to_weekday(name) do
    n = String.downcase(name)
    case n do
      n when n in ["mon", "monday"]    -> 1
      n when n in ["tue", "tuesday"]   -> 2
      n when n in ["wed", "wednesday"] -> 3
      n when n in ["thu", "thursday"]  -> 4
      n when n in ["fri", "friday"]    -> 5
      n when n in ["sat", "saturday"]  -> 6
      n when n in ["sun", "sunday"]    -> 7
    end
  end

  def to_sec_ms(sec, fraction) do
    {n, _} = Float.parse("0.#{fraction}")
    [sec: sec, sec_fractional: (1_000*n) |> Float.round |> trunc]
  end

  def to_ampm("am"), do: [am: "am"]
  def to_ampm("AM"), do: [AM: "AM"]
  def to_ampm("pm"), do: [am: "pm"]
  def to_ampm("PM"), do: [AM: "PM"]

  def integer(opts \\ []) do
    min_width = get_in(opts, [:min]) || 1
    max_width = get_in(opts, [:max])
    padding   = get_in(opts, [:padding])
    case {padding, min_width, max_width} do
      {:zeroes, _, nil}   -> Text.integer
      {:zeroes, min, max} -> choice(Enum.map(max..min, &(fixed_integer(&1))))
      {:spaces, -1, nil}  -> skip(spaces) |> Text.integer
      {:spaces, min, nil} -> skip(spaces) |> fixed_integer(min)
      {:spaces, _, max}   -> skip(spaces) |> choice(Enum.map(max..1, &(fixed_integer(&1))))
      {_, -1, nil}        -> Text.integer
      {_, min, nil}       -> fixed_integer(min)
      {_, min, max}       -> choice(Enum.map(max..min, &(fixed_integer(&1))))
    end
  end
end

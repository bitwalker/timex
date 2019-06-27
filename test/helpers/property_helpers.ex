defmodule PropertyHelpers do
  @moduledoc """
  Custom data generators to be used in property tests
  """

  def date_time_generator(:struct) do
    [
      date_time_generator(:tuple),
      microsecond_generator()
    ]
    |> StreamData.fixed_list()
    |> StreamData.map(fn [{{y, m, d}, {h, mm, s}}, {us, p}] ->
      {:ok, nd} = NaiveDateTime.new(y, m, d, h, mm, s, {us, p})
      DateTime.from_naive!(nd, "Etc/UTC")
    end)
  end

  def date_time_generator(:tuple) do
    [
      StreamData.integer(2000..2030),
      StreamData.integer(1..12),
      StreamData.integer(1..28),
      StreamData.integer(0..23),
      StreamData.integer(0..59),
      StreamData.integer(0..59)
    ]
    |> StreamData.fixed_list()
    |> StreamData.filter(fn [year, month, day, _hour, _minute, _second] ->
      :calendar.valid_date(year, month, day)
    end)
    |> StreamData.map(fn [year, month, day, hour, minute, second] ->
      {{year, month, day}, {hour, minute, second}}
    end)
  end

  def timezone_generator() do
    Timex.timezones()
    |> StreamData.member_of()
  end

  def microsecond_generator() do
    [
      StreamData.integer(0..999_999),
      StreamData.integer(1..6)
    ]
    |> StreamData.fixed_list()
    |> StreamData.map(fn [us, precision] ->
      {us, precision}
    end)
  end
end

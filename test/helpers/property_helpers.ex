defmodule PropertyHelpers do
  @moduledoc """
  Custom data generators to be used in property tests
  """

  def date_time_generator(:struct) do
    date_time_generator(:tupple)
    |> StreamData.map(&Timex.to_datetime/1)
  end

  def date_time_generator(:tupple) do
    [
      StreamData.integer(2000..2030),
      StreamData.integer(1..12),
      StreamData.integer(1..28),
      StreamData.integer(0..23),
      StreamData.integer(0..59),
      StreamData.integer(0..59)
    ]
    |> StreamData.fixed_list()
    |> StreamData.map(fn [year, month, day, hour, minute, second] ->
      {{year, month, day}, {hour, minute, second}}
    end)
  end

  def timezone_generator() do
    Timex.timezones()
    |> StreamData.member_of()
  end
end
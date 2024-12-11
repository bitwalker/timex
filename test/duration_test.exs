defmodule DurationTests do
  use ExUnit.Case, async: true
  use Timex
  doctest Timex.Duration, except: [{:now, 0}, {:now, 1}]
  doctest Timex.Format.Duration.Formatter
  doctest Timex.Parse.Duration.Parsers.ISO8601Parser

  describe "to_clock" do
    test "when microseconds are greater than a second" do
      d = %Timex.Duration{megaseconds: 0, seconds: 1, microseconds: 1_000_050}
      assert Timex.Duration.to_clock(d) == {0, 0, 2, 50}
    end

    test "when seconds are greater than a megaseconds" do
      d = %Timex.Duration{megaseconds: 0, seconds: 1_000_001, microseconds: 0}
      assert Timex.Duration.to_clock(d) == {277, 46, 41, 0}
    end
  end

  test "to_12hour_clock" do
    assert Timex.Time.to_12hour_clock(0) == {12, :am}
    assert Timex.Time.to_12hour_clock(2) == {2, :am}
    assert Timex.Time.to_12hour_clock(12) == {12, :pm}
    assert Timex.Time.to_12hour_clock(17) == {5, :pm}
    assert Timex.Time.to_12hour_clock(24) == {12, :am}
  end

  test "to_24hour_clock" do
    assert Timex.Time.to_24hour_clock(12, :am) == 0
    assert Timex.Time.to_24hour_clock(3, :am) == 3
    assert Timex.Time.to_24hour_clock(12, :pm) == 12
    assert Timex.Time.to_24hour_clock(1, :pm) == 13
  end

  test "diff" do
    timestamp1 = Duration.from_erl({1362, 568_903, 363_960})
    timestamp2 = Duration.from_erl({1362, 568_958, 951_099})
    assert Duration.diff(timestamp2, timestamp1) == Duration.from_erl({0, 55, 587_139})
    assert Duration.diff(timestamp2, timestamp1, :microseconds) == 55_587_139
    assert Duration.diff(timestamp2, timestamp1, :milliseconds) == 55587
    assert Duration.diff(timestamp2, timestamp1, :seconds) == 55
    assert Duration.diff(timestamp2, timestamp1, :minutes) == 0
    assert Duration.diff(timestamp2, timestamp1, :hours) == 0
  end

  test "diff fix" do
    timestamp1 = Duration.from_erl({1450, 746_582, 000_000})
    timestamp2 = Duration.from_erl({1451, 981_376, 368_306})
    assert Duration.diff(timestamp2, timestamp1) == Duration.from_erl({1, 234_794, 368_306})
    assert Duration.diff(timestamp2, timestamp1, :microseconds) == 1_234_794_368_306
    assert Duration.diff(timestamp2, timestamp1, :milliseconds) == 1_234_794_368
    assert Duration.diff(timestamp2, timestamp1, :seconds) == 1_234_794
    assert Duration.diff(timestamp2, timestamp1, :minutes) == 20579
    assert Duration.diff(timestamp2, timestamp1, :hours) == 342
  end

  test "measure/2" do
    {%Duration{}, result} = Duration.measure(fn x -> x end, [:nothing])
    assert result == :nothing
  end

  test "measure/3" do
    {%Duration{}, result} = Duration.measure(__MODULE__, :something_to_measure, [:nothing])
    assert result == :nothing
  end

  test "to_microseconds" do
    assert Duration.to_microseconds(Duration.from_erl({1362, 568_903, 363_960})) ==
             1_362_568_903_363_960

    assert Duration.to_microseconds(13, :microseconds) == 13
    assert Duration.to_microseconds(13, :milliseconds) == 13000
    assert Duration.to_microseconds(13, :seconds) == 13_000_000
    assert Duration.to_microseconds(13, :minutes) == 13_000_000 * 60
    assert Duration.to_microseconds(13, :hours) == 13_000_000 * 3600
  end

  test "to_milliseconds" do
    assert Duration.to_milliseconds(Duration.from_erl({1362, 568_903, 363_960})) ==
             1_362_568_903_363.960

    assert Duration.to_milliseconds(13, :microseconds) == 0.013
    assert Duration.to_milliseconds(13, :milliseconds) == 13
    assert Duration.to_milliseconds(13, :seconds) == 13000
    assert Duration.to_milliseconds(13, :minutes) == 13000 * 60
    assert Duration.to_milliseconds(13, :hours) == 13000 * 3600
  end

  test "to_seconds" do
    assert Duration.to_seconds(Duration.from_erl({1362, 568_903, 363_960})) ==
             1_362_568_903.363960

    assert Duration.to_seconds(13, :microseconds) == 0.000013
    assert Duration.to_seconds(13, :milliseconds) == 0.013
    assert Duration.to_seconds(13, :seconds) == 13
    assert Duration.to_seconds(13, :minutes) == 13 * 60
    assert Duration.to_seconds(13, :hours) == 13 * 3600
  end

  test "from_*" do
    assert Duration.to_erl(Duration.from_microseconds(1)) == {0, 0, 1}
    assert Duration.to_erl(Duration.from_milliseconds(1)) == {0, 0, 1000}
    assert Duration.to_erl(Duration.from_seconds(1)) == {0, 1, 0}
    assert Duration.to_erl(Duration.from_minutes(1)) == {0, 60, 0}
    assert Duration.to_erl(Duration.from_hours(1)) == {0, 3600, 0}
    assert Duration.to_erl(Duration.from_days(1)) == {0, 86400, 0}
    assert Duration.to_erl(Duration.from_weeks(1)) == {0, 604_800, 0}
  end

  test "elapsed" do
    previous_time = Duration.from_erl({1362, 568_902, 363_960})
    now = Duration.from_erl({1362, 568_903, 363_960})
    time_in_millis = Duration.to_milliseconds(previous_time)

    assert Duration.elapsed(now, previous_time, :microseconds) == 1_000_000
    assert Duration.elapsed(now, previous_time, :milliseconds) == 1000
    assert Duration.elapsed(now, previous_time, :seconds) == 1
    assert Duration.elapsed(now, previous_time, :minutes) == 0
    assert Duration.elapsed(now, previous_time, :hours) == 0

    assert_raise FunctionClauseError, fn ->
      Duration.elapsed(time_in_millis, :milliseconds)
    end
  end

  # Just make sure that Timex.Duration.measure is called at least once in the tests
  test "measure/1" do
    reversed_list = Enum.to_list(100_000..1//-1)

    assert {%Duration{} = d, ^reversed_list} =
             Duration.measure(fn -> Enum.reverse(1..100_000) end)

    assert d.megaseconds + d.seconds + d.microseconds > 0
  end

  describe "now" do
    test "now/0 returns the duration since epoch" do
      erlang_now_microseconds = div(:os.system_time(), 1000)
      timex_now_microseconds = Timex.Duration.now() |> Timex.Duration.to_microseconds()
      difference_microseconds = timex_now_microseconds - erlang_now_microseconds
      assert_in_delta(difference_microseconds, 500_000, 500_001)
    end

    test "now(:seconds) is correct" do
      erlang_now_seconds =
        :calendar.datetime_to_gregorian_seconds(:calendar.universal_time()) -
          :calendar.datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}})

      timex_now_seconds = Timex.Duration.now(:seconds)
      difference_seconds = timex_now_seconds - erlang_now_seconds
      assert_in_delta(difference_seconds, 0.5, 1)
    end
  end

  def something_to_measure(x), do: x
end

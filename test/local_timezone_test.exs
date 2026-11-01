defmodule LocalTimezoneTest do
  use ExUnit.Case, async: false

  alias Timex.{Timezone, TimezoneInfo}

  setup do
    original = Application.fetch_env(:timex, :local_timezone)
    Application.put_env(:timex, :local_timezone, "Europe/London")

    on_exit(fn ->
      case original do
        {:ok, timezone} -> Application.put_env(:timex, :local_timezone, timezone)
        :error -> Application.delete_env(:timex, :local_timezone)
      end
    end)
  end

  test "local aware instants use the correct period across the spring gap" do
    for {instant, offset, abbreviation} <- [
          {~U[2024-03-31 00:59:59Z], 0, "GMT"},
          {~U[2024-03-31 01:13:41.097331Z], 3600, "BST"},
          {~U[2024-03-31 02:00:00Z], 3600, "BST"}
        ] do
      assert %TimezoneInfo{full_name: "Europe/London"} = info = Timezone.local(instant)
      assert Timezone.total_offset(info) == offset
      assert info.abbreviation == abbreviation
      assert Timezone.get(:local, instant) == info
      assert Timex.timezone(:local, instant) == info
      assert %DateTime{time_zone: "Europe/London"} = converted = Timex.local(instant)
      assert DateTime.compare(converted, instant) == :eq
      assert converted.utc_offset + converted.std_offset == offset
    end
  end

  test "explicit local UTC lookups do not interpret tuples as wall time" do
    date = {{2024, 3, 31}, {1, 13, 41}}

    assert %TimezoneInfo{abbreviation: "BST", offset_std: 3600} =
             Timezone.get(:local, date, :utc)

    assert {:error, {:could_not_resolve_timezone, "Europe/London", _, :wall}} =
             Timezone.get(:local, date, :wall)

    assert {:error, {:could_not_resolve_timezone, "Europe/London", _, :wall}} =
             Timezone.local(~N[2024-03-31 01:13:41])

    assert {:error, {:could_not_resolve_timezone, "Europe/London", _, :wall}} =
             Timezone.local(date)
  end

  test "local aware lookups preserve the instant when the input has a different zone" do
    instant =
      DateTime.shift_zone!(~U[2024-03-31 01:13:41Z], "Europe/Rome", Tzdata.TimeZoneDatabase)

    assert %TimezoneInfo{abbreviation: "BST", offset_std: 3600} = Timezone.local(instant)
  end

  test "local naive conversion exposes the gap without pre-resolving a period" do
    for convert <- [&Timezone.convert/2, &Timex.to_datetime/2] do
      assert %Timex.AmbiguousDateTime{type: :gap, before: earlier, after: later} =
               convert.(~N[2024-03-31 01:13:41], :local)

      assert earlier.time_zone == "Europe/London"
      assert later.time_zone == "Europe/London"
      assert DateTime.to_naive(earlier) == ~N[2024-03-31 00:59:59.999999]
      assert DateTime.to_naive(later) == ~N[2024-03-31 02:00:00]
      assert earlier.std_offset == 0
      assert later.std_offset == 3600
    end
  end

  test "the two autumn overlap instants identify their distinct periods" do
    assert %TimezoneInfo{abbreviation: "BST", offset_std: 3600} =
             Timezone.local(~U[2024-10-27 00:30:00Z])

    assert %TimezoneInfo{abbreviation: "GMT", offset_std: 0} =
             Timezone.local(~U[2024-10-27 01:30:00Z])

    assert %TimezoneInfo{abbreviation: "BST", offset_std: 3600} =
             Timezone.local(~N[2024-10-27 00:30:00])
  end
end

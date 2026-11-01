defmodule TimezoneDatabaseTest do
  use ExUnit.Case, async: true

  test "far-future gaps use dynamic transition boundaries rather than finite period history" do
    for {zone, naive, before_gap, after_gap, before_offset, after_offset} <- [
          {"America/Toronto", ~N[2100-03-14 02:30:00], ~N[2100-03-14 01:59:59.999999],
           ~N[2100-03-14 03:00:00], -18_000, -14_400},
          {"Australia/Lord_Howe", ~N[2100-10-03 02:15:00], ~N[2100-10-03 01:59:59.999999],
           ~N[2100-10-03 02:30:00], 37_800, 39_600}
        ] do
      assert {:gap, earlier, later} =
               DateTime.from_naive(naive, zone, Timex.Timezone.Database)

      assert DateTime.to_naive(earlier) == before_gap
      assert DateTime.to_naive(later) == after_gap
      assert earlier.utc_offset + earlier.std_offset == before_offset
      assert later.utc_offset + later.std_offset == after_offset
      assert DateTime.diff(later, earlier, :microsecond) == 1
    end
  end
end

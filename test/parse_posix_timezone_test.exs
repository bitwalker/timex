defmodule PosixTimezoneParsing.Tests do
  use ExUnit.Case, async: true
  alias Timex.Parse.Timezones.Posix
  alias Timex.Parse.Timezones.Posix.PosixTimezone, as: TZ

  test "can parse simple POSIX timezone" do
    tz = "CST6CDT"
    res = %TZ{:name => "CST6CDT", :diff => 6, :std_name => "CST", :dst_name => "CDT"}
    assert {:ok, ^res} = Posix.parse(tz)
  end

  test "can parse full POSIX timezone" do
    tz = "CST6CDT,M3.2.0/2:00:00,M11.1.0/2:00:00"

    res = %TZ{
      :name => "CST6CDT",
      :diff => 6,
      :std_name => "CST",
      :dst_name => "CDT",
      :dst_start => %{:month => 3, :week => 2, :day_of_week => 0, :time => {2, 0, 0}},
      :dst_end => %{:month => 11, :week => 1, :day_of_week => 0, :time => {2, 0, 0}}
    }

    assert {:ok, ^res} = Posix.parse(tz)
  end

  test "non-POSIX timezone formats are rejected with an error tuple describing the reason" do
    base = "CST6CDT,M3.2.0/2:00:00,M11.1.0/2:00:00"
    mutations = 1..(String.length(base) - 1)

    for variant <- mutations do
      {head, tail} = String.split_at(base, variant)
      {new_head, _} = String.split_at(head, String.length(head) - 1)
      tz = new_head <> tail

      result =
        case Posix.parse(tz) do
          {:ok, _} ->
            true

          res ->
            assert {:error, _} = res
            true
        end

      assert true === result
    end
  end
end

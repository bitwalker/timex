defmodule Timex.Format.DateTime.Formatters.RelativeTest do
  use ExUnit.Case, async: true
  alias Timex.Format.DateTime.Formatters.Relative
  doctest Relative

  test "unsupported targets and references return conversion errors before formatting" do
    reference = ~N[2026-01-01 12:00:00]

    for invalid <- [~T[12:00:00], :invalid, {}, {2026, 13, 1}] do
      assert {:error, _} = Relative.format(invalid, "{relative}")
      assert {:error, _} = Relative.lformat(invalid, "{relative}", "en")
      assert {:error, _} = Relative.relative_to(invalid, reference, "{relative}")
      assert {:error, _} = Relative.relative_to(reference, invalid, "{relative}")
      assert {:error, _} = Timex.format(invalid, "{relative}", :relative)
      assert {:error, _} = Timex.lformat(invalid, "{relative}", "en", :relative)
      assert_raise Timex.Format.FormatError, fn -> Relative.format!(invalid, "{relative}") end
    end

    assert_raise Timex.Format.FormatError, fn ->
      Timex.format!(~T[12:00:00], "{relative}", :relative)
    end

    assert Timex.format!(~T[12:00:00], "{h24}:{m}:{s}") == "12:00:00"
  end

  test "invalid date structs return errors rather than raising in conversion or arithmetic" do
    invalid_date = %{~D[2026-01-01] | month: 13}
    invalid_datetime = %{~N[2026-01-01 12:00:00] | month: 13}

    for invalid <- [
          invalid_date,
          invalid_datetime,
          %{~U[2026-01-01 12:00:00Z] | month: 13},
          %{~D[2026-01-01] | year: nil},
          %{~N[2026-01-01 12:00:00] | month: :bad},
          %{~U[2026-01-01 12:00:00Z] | utc_offset: nil}
        ] do
      assert {:error, _} = Relative.relative_to(invalid, ~N[2026-01-01 12:00:00], "{relative}")
    end
  end
end

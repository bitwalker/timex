defmodule TzdataIntegrationTest do
  use ExUnit.Case, async: false

  test "IANA end-of-day transitions normalize to the next midnight" do
    end_of_day = {{2024, 3, 31}, {24, 0, 0}}
    midnight = :calendar.datetime_to_gregorian_seconds({{2024, 4, 1}, {0, 0, 0}})

    assert Tzdata.PeriodBuilder.datetime_to_utc({end_of_day, :utc}, 3600, 3600) == midnight

    assert Tzdata.PeriodBuilder.datetime_to_utc({end_of_day, :standard}, 3600, 3600) ==
             midnight - 3600

    assert Tzdata.PeriodBuilder.datetime_to_utc({end_of_day, :wall}, 3600, 3600) ==
             midnight - 7200

    assert Tzdata.Util.datetime_to_utc({end_of_day, :wall}, 3600, 3600) == midnight - 7200
  end

  @tag :tzdata_update
  @tag timeout: 120_000
  test "current IANA data can be downloaded, built and loaded" do
    data_dir =
      Path.join(
        System.tmp_dir!(),
        "timex-tzdata-#{System.pid()}-#{System.unique_integer([:positive])}"
      )

    original_data_dir = Application.get_env(:tzdata, :data_dir)

    on_exit(fn ->
      Application.stop(:tzdata)
      Application.put_env(:tzdata, :data_dir, original_data_dir)
      File.rm_rf!(data_dir)
      {:ok, _} = Application.ensure_all_started(:tzdata)
    end)

    :ok = Application.stop(:tzdata)
    Application.put_env(:tzdata, :data_dir, data_dir)
    {:ok, _} = Application.ensure_all_started(:tzdata)

    # Unlike poll_for_update/0, the builder reports download failures instead of
    # treating an unsuccessful update check as "nothing to do".
    version =
      case Tzdata.DataBuilder.load_and_save_table() do
        {:ok, size, version} ->
          assert size > 0
          version

        {:error, :downloaded_version_same_as_current_version} ->
          # An up-to-date bundled release needs no rebuild. The offline test
          # above still exercises 24:00 normalization on every run.
          Tzdata.tzdata_version()
      end

    :ok = Application.stop(:tzdata)
    {:ok, _} = Application.ensure_all_started(:tzdata)
    assert Tzdata.tzdata_version() == version

    cairo = Timex.Timezone.convert(~U[2024-10-31 21:00:00Z], "Africa/Cairo")
    assert cairo.hour == 23
    assert cairo.utc_offset + cairo.std_offset == 7200

    assert %Timex.AmbiguousDateTime{type: :ambiguous} =
             Timex.Timezone.convert(~N[2024-10-31 23:30:00], "Africa/Cairo")

    assert {:error, _} = Timex.to_datetime(~N[2024-04-26 00:30:00], "Africa/Cairo")
  end
end

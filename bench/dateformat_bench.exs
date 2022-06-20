defmodule Timex.Timex.Bench do
    use Benchfella
    use Timex
    alias Timex.Parse.DateTime.Tokenizers.Strftime
    alias Timex.Parse.DateTime.Tokenizers.Default

    @datetime "2014-07-22T12:30:05Z"
    @datetime_zoned "2014-07-22T12:30:05+02:00"
    @duration "P15Y3M2DT1H14M37.25S"

    setup_all do
      Application.ensure_all_started(:tzdata)
      {:ok, nil}
    end

    bench "(default) parse ISO 8601 datetime" do
      datetime = Timex.parse(@datetime, "{ISO:Extended}")
      datetime_zoned = Timex.parse(@datetime_zoned, "{ISO:Extended}")
      {:ok, _} = datetime
      {:ok, _} = datetime_zoned
    end

    bench "(strftime) parse ISO 8601 datetime" do
      datetime = Timex.parse(@datetime, "%FT%TZ", :strftime)
      datetime_zoned = Timex.parse(@datetime_zoned, "%FT%T%:z", :strftime)
      {:ok, _} = datetime
      {:ok, _} = datetime_zoned
    end

    bench "(default) format ISO 8601 datetime" do
      date = Timex.epoch
      {:ok, _} = Timex.format(date, "{ISO:Extended:Z}")
      {:ok, _} = Timex.format(date, "{ISO:Extended}")
    end

    bench "(strftime) format ISO 8601 datetime" do
      date = Timex.epoch
      {:ok, _} = Timex.format(date, "%FT%TZ", :strftime)
      {:ok, _} = Timex.format(date, "%FT%Tz", :strftime)
    end

    bench "(strftime) tokenize ISO 8601" do
      {:ok, _} = Strftime.tokenize("%FT%TZ")
      {:ok, _} = Strftime.tokenize("%FT%T%z")
    end

    bench "(default) tokenize ISO 8601" do
      {:ok, _} = Default.tokenize("{YYYY}-{M}-{D}T{h24}:{m}:{s}Z")
      {:ok, _} = Default.tokenize("{YYYY}-{M}-{D}T{h24}:{m}:{s}{Z}")
    end

    bench "Timex.local" do
      _ = Timex.local
      :ok
    end

    bench "Timex.Duration.parse" do
      {:ok, _} = Timex.Duration.parse(@duration)
    end
end

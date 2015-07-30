defmodule Timex.DateFormat.Bench do
    use Benchfella
    use Timex
    alias Timex.Parse.DateTime.Tokenizers.Strftime
    alias Timex.Parse.DateTime.Tokenizers.Default

    @datetime "2014-07-22T12:30:05Z"
    @datetime_zoned "2014-07-22T12:30:05+0200"

    bench "(default) parse ISO 8601 datetime" do
      datetime = DateFormat.parse(@datetime, "{ISOz}")
      datetime_zoned = DateFormat.parse(@datetime_zoned, "{ISO}")
      {:ok, _} = datetime
      {:ok, _} = datetime_zoned
    end

    bench "(strftime) parse ISO 8601 datetime" do
      datetime = DateFormat.parse(@datetime, "%FT%TZ", :strftime)
      datetime_zoned = DateFormat.parse(@datetime_zoned, "%FT%T%z", :strftime)
      {:ok, _} = datetime
      {:ok, _} = datetime_zoned
    end

    bench "(default) format ISO 8601 datetime" do
      date = Date.epoch
      {:ok, _} = DateFormat.format(date, "{ISOz}")
      {:ok, _} = DateFormat.format(date, "{ISO}")
    end

    bench "(strftime) format ISO 8601 datetime" do
      date = Date.epoch
      {:ok, _} = DateFormat.format(date, "%FT%TZ", :strftime)
      {:ok, _} = DateFormat.format(date, "%FT%Tz", :strftime)
    end

    bench "(strftime) tokenize ISO 8601" do
      {:ok, _} = Strftime.tokenize("%FT%TZ")
      {:ok, _} = Strftime.tokenize("%FT%T%z")
    end

    bench "(default) tokenize ISO 8601" do
      {:ok, _} = Default.tokenize("{YYYY}-{M}-{D}T{h24}:{m}:{s}Z")
      {:ok, _} = Default.tokenize("{YYYY}-{M}-{D}T{h24}:{m}:{s}{Z}")
    end
end

defmodule Timex do
  defmacro __using__(_) do
    quote do
      alias Timex.DateTime
      alias Timex.Date
      alias Timex.DateFormat
      alias Timex.Time
      alias Timex.TimezoneInfo
      alias Timex.Timezone
      alias Timex.Date.Convert,          as: DateConvert
      alias Timex.DateFormat.Formatters, as: TimexFormatters
      alias Timex.Parsers.DateFormat,    as: TimexParsers
    end
  end
  @moduledoc File.read!("README.md")
end

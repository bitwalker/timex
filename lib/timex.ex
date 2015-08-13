defmodule Timex do
  defmacro __using__(_) do
    quote do
      alias Timex.DateTime
      alias Timex.Date
      alias Timex.Time
      alias Timex.TimezoneInfo
      alias Timex.Timezone
      alias Timex.DateFormat
      alias Timex.Date.Convert, as: DateConvert
      alias Timex.Format.Time.Formatter, as: TimeFormat
    end
  end
  @moduledoc File.read!("README.md")
end

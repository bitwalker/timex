defmodule Timex do
  defmacro __using__(_) do
    quote do
      alias Timex.DateTime,     as: DateTime
      alias Timex.Date,         as: Date
      alias Timex.Date.Convert, as: DateConvert
      alias Timex.DateFormat,   as: DateFormat
      alias Timex.Time,         as: Time
      alias Timex.TimezoneInfo, as: TimezoneInfo
      alias Timex.Timezone,     as: Timezone
    end
  end
end
defmodule Timex do
  defmacro __using__(_) do
    quote do
      alias Timex.DateTime
      alias Timex.Date
      alias Timex.Time
      alias Timex.TimezoneInfo
      alias Timex.Timezone
      alias Timex.Format.DateTime.DateFormat
      alias Timex.Date.Convert, as: DateConvert
      alias Timex.Format.Time.TimeFormatter, as: TimeFormat
    end
  end
  @moduledoc File.read!("README.md")
end

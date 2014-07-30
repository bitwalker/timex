defmodule Timex.DateTime do
  alias Timex.DateTime
  alias Timex.Timezone

  @derive Access
  defstruct day:      1,
            month:    1,
            year:     0,
            hour:     0,
            minute:   0,
            second:   0,
            ms:       0,
            timezone: nil,
            calendar: :gregorian

  def new do
    %{%DateTime{} | :timezone => Timezone.get(:utc)}
  end
end

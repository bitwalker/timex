defmodule Timex.AmbiguousTimezoneInfo do
  @moduledoc """
  Represents a choice of two possible timezone periods for a given
  point in time.
  """
  alias Timex.TimezoneInfo

  @type t :: %__MODULE__{before: TimezoneInfo.t(), after: TimezoneInfo.t()}

  defstruct before: nil,
            after: nil

  @spec new(before_tz :: TimezoneInfo.t(), after_tz :: TimezoneInfo.t()) :: t
  def new(%TimezoneInfo{} = before_tz, %TimezoneInfo{} = after_tz) do
    %__MODULE__{before: before_tz, after: after_tz}
  end
end

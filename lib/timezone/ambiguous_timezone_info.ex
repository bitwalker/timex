defmodule Timex.AmbiguousTimezoneInfo do
  @moduledoc """
  Represents a choice of two possible timezone periods for a given
  point in time.
  """
  alias Timex.TimezoneInfo
  defstruct before: nil,
            after: nil

  def new(%TimezoneInfo{} = before_tz, %TimezoneInfo{} = after_tz) do
    %__MODULE__{before: before_tz, after: after_tz}
  end
end

# WIP. Nothing interesting here
defmodule Timex.TimeFormatter do
  defmacrop _MINUTE, do: 60
  defmacrop _HOUR, do: _MINUTE * 60
  defmacrop _DAY, do: _HOUR * 24
  defmacrop _WEEK, do: _DAY * 7
  defmacrop _MONTH, do: _DAY * 30
  defmacrop _YEAR, do: _DAY * 365
  defmacrop _DECADE, do: _YEAR * 10
  defmacrop _CENTURY, do: _DECADE * 10
  defmacrop _MILLENNIUM, do: _CENTURY * 10

  @doc """
  Return a binary containing human readable representation of the time interval.

  Note that if you'd like to format a point in time rather than time interval,
  you should use Date.format.
  """
  def format({mega, seconds, _micro}) do
    components = []
    seconds = mega * 1000000 + seconds
    if seconds >= _MILLENNIUM do
      components = [{div(seconds, _MILLENNIUM), :millennium}|components]
      seconds = rem(seconds, _MILLENNIUM)
    end
    if seconds >= _CENTURY do
      components = [{div(seconds, _CENTURY), :century}|components]
      seconds = rem(seconds, _CENTURY)
    end
    if seconds >= _DECADE do
      components = [{div(seconds, _DECADE), :decade}|components]
      seconds = rem(seconds, _DECADE)
    end
    if seconds >= _YEAR do
      components = [{div(seconds, _YEAR), :year}|components]
      seconds = rem(seconds, _YEAR)
    end
    if seconds >= _MONTH do
      components = [{div(seconds, _MONTH), :month}|components]
      seconds = rem(seconds, _MONTH)
    end
    if seconds >= _WEEK do
      components = [{div(seconds, _WEEK), :week}|components]
      seconds = rem(seconds, _WEEK)
    end
    if seconds >= _DAY do
      components = [{div(seconds, _DAY), :day}|components]
      seconds = rem(seconds, _DAY)
    end
    if seconds >= _HOUR do
      components = [{div(seconds, _HOUR), :hour}|components]
      seconds = rem(seconds, _HOUR)
    end
    if seconds >= _MINUTE do
      components = [{div(seconds, _MINUTE), :minute}|components]
      seconds = rem(seconds, _MINUTE)
    end
    if seconds > 0 do
      components = [{seconds, :second}|components]
    end
    components
  end
end

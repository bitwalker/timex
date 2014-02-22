defmodule Date.Helpers do
  @moduledoc false
  
  def from(date, time, tz) do
    Date.Gregorian[date: date, time: time, tz: tz]
  end

  def from({date, time}, tz) do
    Date.Gregorian[date: date, time: time, tz: tz]
  end

  defmacro def_set(arg) do
    body(arg, :set, :set_priv)
  end

  defmacro def_rawset(arg) do
    body(arg, :rawset, :rawset_priv)
  end

  defp body(arg, name, priv) do
    quote do
      def unquote(name)(date, [{unquote(arg), value}]) do
        greg_date = Date.Conversions.to_gregorian(date)
        { date, time, tz } = unquote(priv)(greg_date, unquote(arg), value)
        make_date(date, time, tz)
      end
    end
  end
end



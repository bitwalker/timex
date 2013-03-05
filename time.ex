defmodule Time.Helpers do
  @moduledoc false

  defmacro gen_conversions do
    lc {name, coef} inlist [{:to_microsecs, 1000000}, {:to_millisecs, 1000}, {:to_seconds, 1}] do
      quote do
        def unquote(name)({mega, secs, micro}) do
          (mega * 1000000 + secs) * unquote(coef) + micro * unquote(coef) / 1000000
        end

        def unquote(name)(value, :microsecs) do
          value * unquote(coef) / 1000000
        end

        def unquote(name)(value, :millisecs) do
          value * unquote(coef) / 1000
        end

        def unquote(name)(value, :seconds) do
          value * unquote(coef)
        end

        def unquote(name)(value, :minutes) do
          value * 60 * unquote(coef)
        end

        def unquote(name)(value, :hours) do
          value * 60 * 60 * unquote(coef)
        end

        def unquote(name)({hours, minutes, seconds}, :hms) do
          unquote(name)(hours, :hours) + unquote(name)(minutes, :minutes) + unquote(name)(seconds, :seconds)
        end
      end
    end
  end
end

defmodule Time do
  import Time.Helpers, only: [gen_conversions: 0]
  gen_conversions()

  def now do
    :os.timestamp
  end

  def now_us do
    to_microsecs(now)
  end

  def now_ms do
    to_millisecs(now)
  end

  def now_secs do
    to_seconds(now)
  end

  def elapsed({mega, secs, micro}) do
    {mega_now, secs_now, micro_now} = now
    {mega_now - mega, secs_now - secs, micro_now - micro}
  end

  def elapsed_us(timestamp) do
    to_microsecs(elapsed(timestamp))
  end

  def elapsed_ms(timestamp) do
    to_millisecs(elapsed(timestamp))
  end

  def elapsed_secs(timestamp) do
    to_seconds(elapsed(timestamp))
  end
end

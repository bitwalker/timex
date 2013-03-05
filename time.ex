defmodule Time do
  def to_microsecs({mega, secs, micro}) do
    (mega * 1000000 + secs) * 1000000 + micro
  end

  def to_millisecs({mega, secs, micro}) do
    (mega * 1000000 + secs) * 1000 + micro / 1000
  end

  def to_seconds({mega, secs, micro}) do
    mega * 1000000 + secs + micro / 1000000
  end

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

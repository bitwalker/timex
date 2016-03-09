defimpl Timex.Convertable, for: Atom do
  alias Timex.Time
  alias Timex.DateTime
  alias Timex.Convertable

  def to_gregorian(:epoch),         do: Convertable.to_gregorian(DateTime.epoch)
  def to_gregorian(:zero),          do: Convertable.to_gregorian(DateTime.zero)
  def to_julian(:epoch),            do: Convertable.to_julian(DateTime.epoch)
  def to_julian(:zero),             do: Convertable.to_julian(DateTime.zero)
  def to_gregorian_seconds(:epoch), do: Convertable.to_gregorian_seconds(DateTime.epoch)
  def to_gregorian_seconds(:zero),  do: Convertable.to_gregorian_seconds(DateTime.zero)
  def to_erlang_datetime(:epoch),   do: Convertable.to_erlang_datetime(DateTime.epoch)
  def to_erlang_datetime(:zero),    do: Convertable.to_erlang_datetime(DateTime.zero)

  def to_date(:epoch),      do: Convertable.to_date(DateTime.epoch)
  def to_date(:zero),       do: Convertable.to_date(DateTime.zero)
  def to_datetime(:epoch),  do: DateTime.epoch
  def to_datetime(:zero),   do: DateTime.zero
  def to_unix(:epoch),      do: Convertable.to_unix(DateTime.epoch)
  def to_unix(:zero),       do: Time.abs(Time.epoch)
  def to_timestamp(:epoch), do: Convertable.to_timestamp(DateTime.epoch)
  def to_timestamp(:zero),  do: Convertable.to_timestamp(DateTime.zero)

end

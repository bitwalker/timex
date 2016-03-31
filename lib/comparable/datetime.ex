defimpl Timex.Comparable, for: Timex.DateTime do
  alias Timex.Time
  alias Timex.DateTime
  alias Timex.AmbiguousDateTime
  alias Timex.Comparable
  alias Timex.Convertable
  alias Timex.Types
  import Timex.Macros

  @units [:years, :months, :weeks, :calendar_weeks, :days, :hours, :minutes, :seconds, :timestamp]


  @doc """
  See docs for `Timex.compare/3`
  """
  @spec compare(DateTime.t, Comparable.comparable, Comparable.granularity) :: Comparable.compare_result
  def compare(a, :epoch, granularity),           do: compare(a, DateTime.epoch(), granularity)
  def compare(a, :zero, granularity),            do: compare(a, DateTime.zero(), granularity)
  def compare(_, :distant_past, _granularity),   do: +1
  def compare(_, :distant_future, _granularity), do: -1
  def compare(a, a, _granularity),                do: 0
  def compare(_, %AmbiguousDateTime{} = b, _granularity),
    do: {:error, {:ambiguous_comparison, b}}
  def compare(%DateTime{} = this, %DateTime{} = other, granularity) when granularity in @units do
    case {ok!(DateTime.to_seconds(this, :zero)), ok!(DateTime.to_seconds(other, :zero))} do
      {{:error, _} = err, _} ->
        err
      {_, {:error, _} = err} ->
        err
      {{:ok, this_secs}, {:ok, other_secs}} ->
        case ok!(diff(this, other, granularity)) do
          {:error, _} = err ->
            err
          {:ok, delta} ->
            occurs_after? = cond do
              other_secs < this_secs -> true
              :else -> false
            end
            cond do
              delta == 0 -> 0
              delta > 0 && occurs_after? -> 1
              :else -> -1
            end
        end
    end
  end
  def compare(_, _, granularity) when not granularity in @units,
    do: {:error, {:invalid_granularity, granularity}}
  def compare(a, b, granularity) do
    case Convertable.to_datetime(b) do
      {:error, _} = err ->
        err
      %DateTime{} = datetime ->
        compare(a, datetime, granularity)
      %AmbiguousDateTime{} = ambiguous ->
        {:error, {:ambiguous_comparison, ambiguous}}
    end
  end

  @doc """
  See docs for `Timex.compare/3`
  """
  @spec diff(DateTime.t, Comparable.comparable, Comparable.granularity) :: Types.timestamp | integer | {:error, term}
  def diff(a, b, :secs) do
    IO.write :stderr, "warning: :secs is a deprecated unit name, use :seconds instead\n"
    diff(a, b, :seconds)
  end
  def diff(a, b, :mins) do
    IO.write :stderr, "warning: :mins is a deprecated unit name, use :minutes instead\n"
    diff(a, b, :minutes)
  end
  def diff(_, %AmbiguousDateTime{} = b, _granularity),
    do: {:error, {:ambiguous_comparison, b}}
  def diff(%DateTime{} = this, %DateTime{} = other, type) do
    case {ok!(DateTime.to_seconds(this, :zero)), ok!(DateTime.to_seconds(other, :zero))} do
      {{:error, _} = err, _} ->
        err
      {_, {:error, _} = err} ->
        err
      {{:ok, this_secs}, {:ok, other_secs}} ->
        diff_secs = this_secs - other_secs
        cond do
          diff_secs == 0 -> zero(type)
          diff_secs > 0  -> do_diff(this, this_secs, other, other_secs, type)
          diff_secs < 0  -> do_diff(other, other_secs, this, this_secs, type)
        end
    end
  end
  # Handle custom conversions
  def diff(a, b, granularity) do
    case Convertable.to_datetime(b) do
      {:error, _} = err ->
        err
      %DateTime{} = datetime ->
        diff(a, datetime, granularity)
      %AmbiguousDateTime{} = ambiguous ->
        {:error, {:ambiguous_comparison, ambiguous}}
    end
  end
  defp do_diff(_, a, _, a, type), do: zero(type)
  defp do_diff(_adate, a, _bdate, b, :timestamp) do
    seconds = a - b
    case ok!(Time.from(seconds, :seconds)) do
      {:error, _} = err -> err
      {:ok, timestamp} -> timestamp
    end
  end
  defp do_diff(_adate, a, _bdate, b, :seconds), do: a - b
  defp do_diff(_adate, a, _bdate, b, :minutes), do: div(a - b, 60)
  defp do_diff(adate, a, bdate, b, :hours) do
    minutes = do_diff(adate, a, bdate, b, :minutes)
    div(minutes, 60)
  end
  defp do_diff(%DateTime{:year => ay, :month => am, :day => ad}, _, %DateTime{:year => by, :month => bm, :day => bd}, _, :days) do
    a_days = :calendar.date_to_gregorian_days({ay,am,ad})
    b_days = :calendar.date_to_gregorian_days({by,bm,bd})
    a_days - b_days
  end
  defp do_diff(adate, a, bdate, b, :weeks) do
    days = do_diff(adate, a, bdate, b, :days)
    weeks = div(days, 7)
    extra_days = rem(days, 7)
    actual_weeks = (if extra_days == 0, do: weeks, else: weeks + 1)
    cond do
      actual_weeks == 1 && extra_days < 7 -> 0
      :else -> actual_weeks
    end
  end
  defp do_diff(adate, _, bdate, _, :calendar_weeks) do
    case {ok!(Timex.end_of_week(adate)), ok!(Timex.beginning_of_week(bdate))} do
      {{:error, _} = err, _} -> err
      {_, {:error, _} = err} -> err
      {{:ok, ending}, {:ok, start}} ->
        end_secs = DateTime.to_seconds(ending, :zero)
        start_secs = DateTime.to_seconds(start, :zero)
        days = do_diff(ending, end_secs, start, start_secs, :days)
        weeks = div(days, 7)
        extra_days = rem(days, 7)
        actual_weeks = (if extra_days == 0, do: weeks, else: weeks + 1)
        result = cond do
          actual_weeks == 1 && extra_days < 7 -> 0
          :else -> actual_weeks
        end
        result
    end
  end
  defp do_diff(%DateTime{:year => ly, :month => lm, :day => ld}, _, %DateTime{:year => ey, :month => em, :day => ed}, _, :months) do
    x = cond do
      ld >= ed -> 0
      :else -> -1
    end
    y = ly - ey
    z = lm - em
    x+y*12+z
  end
  defp do_diff(adate, a, bdate, b, :years) do
    months = do_diff(adate, a, bdate, b, :months)
    years = div(months, 12)
    years
  end
  defp do_diff(_, _, _, _, unit) when not unit in @units,
    do: {:error, {:invalid_granularity, unit}}
  defp zero(:timestamp), do: Time.zero
  defp zero(_type), do: 0
end

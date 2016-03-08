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
    case {ok!(DateTime.to_seconds(this)), ok!(DateTime.to_seconds(other))} do
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
          diff_secs == 0 -> 0
          diff_secs > 0  -> do_diff(other, this, type)
          diff_secs < 0  -> do_diff(this, other, type)
        end
    end
  end
  # Handle custom conversions
  def diff(a, b, granularity) do
    case Convertable.to_datetime(b) do
      {:error, _} = err ->
        err
      %DateTime{} = datetime ->
        compare(a, datetime, granularity)
      %AmbiguousDateTime{} = ambiguous ->
        {:error, {:ambiguous_comparison, ambiguous}}
    end
  end
  defp do_diff(this, other, :timestamp) do
    case ok!(do_diff(this, other, :seconds)) do
      {:error, _} = err -> err
      {:ok, seconds} ->
        case ok!(Time.from(seconds, :seconds)) do
          {:error, _} = err -> err
          {:ok, timestamp} -> timestamp
        end
    end
  end
  defp do_diff(this, other, :seconds) do
    case {ok!(DateTime.to_seconds(this, :zero)), ok!(DateTime.to_seconds(other, :zero))} do
      {{:error, _} = err, _} -> err
      {_, {:error, _} = err} -> err
      {{:ok, this_secs}, {:ok, other_secs}} ->
        other_secs - this_secs
    end
  end
  defp do_diff(this, other, :minutes) do
    case ok!(do_diff(this, other, :seconds)) do
      {:ok, seconds}    -> div(seconds, 60)
      {:error, _} = err -> err
    end
  end
  defp do_diff(this, other, :hours) do
    case ok!(do_diff(this, other, :minutes)) do
      {:ok, minutes}    -> div(minutes, 60)
      {:error, _} = err -> err
    end
  end
  defp do_diff(this, other, :days) do
    case {ok!(DateTime.to_days(this, :zero)), ok!(DateTime.to_days(other, :zero))} do
      {{:error, _} = err, _} -> err
      {_, {:error, _} = err} -> err
      {{:ok, this_days}, {:ok, other_days}} ->
        other_days - this_days
    end
  end
  defp do_diff(this, other, :weeks) do
    case ok!(do_diff(this, other, :days)) do
      {:error, _} = err -> err
      {:ok, days} ->
        weeks = div(days, 7)
        extra_days = rem(days, 7)
        actual_weeks = (if extra_days == 0, do: weeks, else: weeks + 1)
        cond do
          actual_weeks == 1 && extra_days < 7 -> 0
          :else -> actual_weeks
        end
    end
  end
  defp do_diff(this, other, :calendar_weeks) do
    case {ok!(Timex.beginning_of_week(this)), ok!(Timex.end_of_week(other))} do
      {{:error, _} = err, _} -> err
      {_, {:error, _} = err} -> err
      {{:ok, start}, {:ok, ending}} ->
        case ok!(do_diff(start, ending, :days)) do
          {:error, _} = err -> err
          {:ok, days} ->
            weeks = div(days, 7)
            extra_days = rem(days, 7)
            actual_weeks = (if extra_days == 0, do: weeks, else: weeks + 1)
            cond do
              actual_weeks == 1 && extra_days < 7 -> 0
              :else -> actual_weeks
            end
        end
    end
  end
  defp do_diff(this, other, :months) do
    result = case compare(this, other, :seconds) do
      0  -> 0
      -1 -> {this, other}
      1  -> {other, this}
      {:error, _} = err -> err
    end
    case result do
      {:error, _} = err -> err
      0 -> 0
      {%DateTime{year: eyear, month: emonth, day: eday}, %DateTime{year: lyear, month: lmonth, day: lday}} ->
        x = cond do
          lday >= eday -> 0
          :else -> -1
        end
        y = lyear - eyear
        z = lmonth - emonth
        x+y*12+z
    end
  end
  defp do_diff(this, other, :years) do
    case ok!(do_diff(this, other, :months)) do
      {:error, _} = err -> err
      {:ok, months} ->
        years = div(months, 12)
        years
    end
  end
  defp do_diff(_, _, unit) when not unit in @units,
    do: {:error, {:invalid_granularity, unit}}

end

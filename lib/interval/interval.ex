defmodule Timex.Interval do
  @moduledoc """
  This module is used for creating and manipulating date/time intervals.

  ## Examples

      iex> use Timex
      ...> Interval.new(from: ~D[2016-03-03], until: [days: 3])
      %#{__MODULE__}{from: ~N[2016-03-03 00:00:00], left_open: false, right_open: true, step: [days: 1], until: ~N[2016-03-06 00:00:00]}

      iex> use Timex
      ...> Interval.new(from: ~D[2016-03-03], until: ~N[2016-03-10 01:23:45])
      %Timex.Interval{from: ~N[2016-03-03 00:00:00], left_open: false, right_open: true, step: [days: 1], until: ~N[2016-03-10 01:23:45]}

      iex> use Timex
      ...> ~N[2016-03-04 12:34:56] in Interval.new(from: ~D[2016-03-03], until: [days: 3])
      true

      iex> use Timex
      ...> ~D[2016-03-01] in Interval.new(from: ~D[2016-03-03], until: [days: 3])
      false

      iex> use Timex
      ...> Interval.overlaps?(Interval.new(from: ~D[2016-03-01], until: [days: 5]),  Interval.new(from: ~D[2016-03-03], until: [days: 3]))
      true

      iex> use Timex
      ...> Interval.overlaps?(Interval.new(from: ~D[2016-03-01], until: [days: 1]),  Interval.new(from: ~D[2016-03-03], until: [days: 3]))
      false
  """
  alias Timex.Duration

  defmodule FormatError do
    @moduledoc """
    Thrown when an error occurs with formatting an Interval
    """
    defexception message: "Unable to format interval!"

    def exception(message: message) do
      %FormatError{message: message}
    end
  end

  @type t :: %__MODULE__{}
  @type valid_step_unit ::
          :microseconds
          | :milliseconds
          | :seconds
          | :minutes
          | :hours
          | :days
          | :weeks
          | :months
          | :years
  @type valid_interval_step :: {valid_step_unit, integer}
  @type valid_interval_steps :: [valid_interval_step]

  @enforce_keys [:from, :until]
  defstruct from: nil,
            until: nil,
            left_open: false,
            right_open: true,
            step: [days: 1]

  @valid_step_units [
    :microseconds,
    :milliseconds,
    :seconds,
    :minutes,
    :hours,
    :days,
    :weeks,
    :months,
    :years
  ]

  @doc """
  Create a new Interval struct.

  **Note:** By default intervals are left closed, i.e. they include the `from` date/time,
  and exclude the `until` date/time. Put another way, `from <= x < until`. This behavior
  matches that of other popular date/time libraries, such as Joda Time, as well as the SQL
  behavior of the `overlaps` keyword.

  Options:

  - `from`: The date the interval starts at. Should be a `(Naive)DateTime`.
  - `until`: Either a `(Naive)DateTime`, or a time shift that will be applied to the `from` date.
    This value _must_ be greater than `from`, otherwise an error will be returned.
  - `left_open`: Whether the interval is left open. See explanation below.
  - `right_open`: Whether the interval is right open. See explanation below.
  - `step`: The step to use when iterating the interval, defaults to `[days: 1]`

  The terms `left_open` and `right_open` come from the mathematical concept of intervals. You
  can see more detail on the theory [on Wikipedia](https://en.wikipedia.org/wiki/Interval_(mathematics)),
  but it can be more intuitively thought of like so:

  - An "open" bound is exclusive, and a "closed" bound is inclusive
  - So a left-closed interval includes the `from` value, and a left-open interval does not.
  - Likewise, a right-closed interval includes the `until` value, and a right-open interval does not.
  - An open interval is both left and right open, conversely, a closed interval is both left and right closed.

  **Note:** `until` shifts delegate to `Timex.shift`, so the options provided should match its valid options.

  ## Examples

      iex> use Timex
      ...> Interval.new(from: ~D[2014-09-22], until: ~D[2014-09-29])
      ...> |> Interval.format!("%Y-%m-%d", :strftime)
      "[2014-09-22, 2014-09-29)"

      iex> use Timex
      ...> Interval.new(from: ~D[2014-09-22], until: [days: 7])
      ...> |> Interval.format!("%Y-%m-%d", :strftime)
      "[2014-09-22, 2014-09-29)"

      iex> use Timex
      ...> Interval.new(from: ~D[2014-09-22], until: [days: 7], left_open: true, right_open: false)
      ...> |> Interval.format!("%Y-%m-%d", :strftime)
      "(2014-09-22, 2014-09-29]"

      iex> use Timex
      ...> Interval.new(from: ~N[2014-09-22T15:30:00], until: [minutes: 20], right_open: false)
      ...> |> Interval.format!("%H:%M", :strftime)
      "[15:30, 15:50]"

  """
  @spec new(Keyword.t()) ::
          t
          | {:error, :invalid_until}
          | {:error, :invalid_step}
  def new(options \\ []) do
    from =
      case Keyword.get(options, :from) do
        nil ->
          Timex.Protocol.NaiveDateTime.now()

        %NaiveDateTime{} = d ->
          d

        d ->
          Timex.to_naive_datetime(d)
      end

    left_open = Keyword.get(options, :left_open, false)
    right_open = Keyword.get(options, :right_open, true)
    step = Keyword.get(options, :step, days: 1)

    until =
      case Keyword.get(options, :until, days: 1) do
        {:error, _} = err ->
          err

        x when is_list(x) ->
          Timex.shift(from, x)

        %NaiveDateTime{} = d ->
          d

        d ->
          Timex.to_naive_datetime(d)
      end

    cond do
      invalid_step?(step) ->
        {:error, :invalid_step}

      invalid_until?(until) ->
        {:error, :invalid_until}

      Timex.compare(until, from) <= 0 ->
        {:error, :invalid_until}

      :else ->
        %__MODULE__{
          from: from,
          until: until,
          step: step,
          left_open: left_open,
          right_open: right_open
        }
    end
  end

  defp invalid_until?({:error, _}), do: true
  defp invalid_until?(_), do: false

  defp invalid_step?([]), do: false

  defp invalid_step?([{unit, n} | rest]) when unit in @valid_step_units and is_integer(n) do
    invalid_step?(rest)
  end

  defp invalid_step?(_), do: true

  @doc """
  Return the interval duration, given a unit.

  When the unit is one of `:seconds`, `:minutes`, `:hours`, `:days`, `:weeks`, `:months`, `:years`, the result is an `integer`.

  When the unit is `:duration`, the result is a `Duration` struct.

  ## Example

      iex> use Timex
      ...> Interval.new(from: ~D[2014-09-22], until: [months: 5])
      ...> |> Interval.duration(:months)
      5

      iex> use Timex
      ...> Interval.new(from: ~N[2014-09-22T15:30:00], until: [minutes: 20])
      ...> |> Interval.duration(:duration)
      Duration.from_minutes(20)

  """
  def duration(%__MODULE__{until: until, from: from}, :duration) do
    Timex.diff(until, from, :microseconds) |> Duration.from_microseconds()
  end

  def duration(%__MODULE__{until: until, from: from}, unit) do
    Timex.diff(until, from, unit)
  end

  @doc """
  Change the step value for the provided interval.

  The step should be a keyword list valid for use with `Timex.Date.shift`.

  ## Examples

      iex> use Timex
      ...> Interval.new(from: ~D[2014-09-22], until: [days: 3], right_open: true)
      ...> |> Interval.with_step([days: 1]) |> Enum.map(&Timex.format!(&1, "%Y-%m-%d", :strftime))
      ["2014-09-22", "2014-09-23", "2014-09-24"]

      iex> use Timex
      ...> Interval.new(from: ~D[2014-09-22], until: [days: 3], right_open: false)
      ...> |> Interval.with_step([days: 1]) |> Enum.map(&Timex.format!(&1, "%Y-%m-%d", :strftime))
      ["2014-09-22", "2014-09-23", "2014-09-24", "2014-09-25"]

      iex> use Timex
      ...> Interval.new(from: ~D[2014-09-22], until: [days: 3], right_open: false)
      ...> |> Interval.with_step([days: 2]) |> Enum.map(&Timex.format!(&1, "%Y-%m-%d", :strftime))
      ["2014-09-22", "2014-09-24"]

      iex> use Timex
      ...> Interval.new(from: ~D[2014-09-22], until: [days: 3], right_open: false)
      ...> |> Interval.with_step([days: 3]) |> Enum.map(&Timex.format!(&1, "%Y-%m-%d", :strftime))
      ["2014-09-22", "2014-09-25"]

  """
  @spec with_step(t, valid_interval_steps) :: t | {:error, :invalid_step}
  def with_step(%__MODULE__{} = interval, step) do
    if invalid_step?(step) do
      {:error, :invalid_step}
    else
      %__MODULE__{interval | step: step}
    end
  end

  @doc """
  Formats the interval as a human readable string.

  ## Examples

      iex> use Timex
      ...> Interval.new(from: ~D[2014-09-22], until: [days: 3])
      ...> |> Interval.format!("%Y-%m-%d %H:%M", :strftime)
      "[2014-09-22 00:00, 2014-09-25 00:00)"

      iex> use Timex
      ...> Interval.new(from: ~D[2014-09-22], until: [days: 3])
      ...> |> Interval.format!("%Y-%m-%d", :strftime)
      "[2014-09-22, 2014-09-25)"
  """
  def format(%__MODULE__{} = interval, format, formatter \\ nil) do
    case Timex.format(interval.from, format, formatter) do
      {:error, _} = err ->
        err

      {:ok, from} ->
        case Timex.format(interval.until, format, formatter) do
          {:error, _} = err ->
            err

          {:ok, until} ->
            lopen = if interval.left_open, do: "(", else: "["
            ropen = if interval.right_open, do: ")", else: "]"
            {:ok, "#{lopen}#{from}, #{until}#{ropen}"}
        end
    end
  end

  @doc """
  Same as `format/3`, but raises a `Timex.Interval.FormatError` on failure.
  """
  def format!(%__MODULE__{} = interval, format, formatter \\ nil) do
    case format(interval, format, formatter) do
      {:ok, str} ->
        str

      {:error, e} ->
        raise FormatError, message: "#{inspect(e)}"
    end
  end

  @doc """
  Returns true if the first interval includes every point in time the second includes.

  ## Examples

      iex> #{__MODULE__}.contains?(#{__MODULE__}.new(from: ~D[2018-01-01], until: ~D[2018-01-31]), #{
    __MODULE__
  }.new(from: ~D[2018-01-01], until: ~D[2018-01-30]))
      true

      iex> #{__MODULE__}.contains?(#{__MODULE__}.new(from: ~D[2018-01-01], until: ~D[2018-01-30]), #{
    __MODULE__
  }.new(from: ~D[2018-01-01], until: ~D[2018-01-31]))
      false

      iex> #{__MODULE__}.contains?(#{__MODULE__}.new(from: ~D[2018-01-01], until: ~D[2018-01-10]), #{
    __MODULE__
  }.new(from: ~D[2018-01-05], until: ~D[2018-01-15]))
      false
  """
  @spec contains?(__MODULE__.t(), __MODULE__.t()) :: boolean()
  def contains?(%__MODULE__{} = a, %__MODULE__{} = b) do
    Timex.compare(min(a), min(b)) <= 0 && Timex.compare(max(a), max(b)) >= 0
  end

  @doc """
  Returns true if the first interval shares any point(s) in time with the second.

  ## Examples

      iex> #{__MODULE__}.overlaps?(#{__MODULE__}.new(from: ~D[2016-03-04], until: [days: 1]), #{
    __MODULE__
  }.new(from: ~D[2016-03-03], until: [days: 3]))
      true

      iex> #{__MODULE__}.overlaps?(#{__MODULE__}.new(from: ~D[2016-03-07], until: [days: 1]), #{
    __MODULE__
  }.new(from: ~D[2016-03-03], until: [days: 3]))
      false
  """
  @spec overlaps?(__MODULE__.t(), __MODULE__.t()) :: boolean()
  def overlaps?(%__MODULE__{} = a, %__MODULE__{} = b) do
    cond do
      Timex.compare(max(a), min(b)) < 0 ->
        # a is completely before b
        false

      Timex.compare(max(b), min(a)) < 0 ->
        # b is completely before a
        false

      :else ->
        # a and b have overlapping elements
        true
    end
  end

  @doc """
  Removes one interval from another which may reduce, split, or
  eliminate the original interval. Returns a (possibly empty) list
  of intervals representing the remaining time.

  ## Graphs

  The following textual graphs show all the ways that the original interval and
  the removal can relate to each other, and the action that `difference/2` will
  take in each case.
  The original interval is drawn with `O`s and the removal interval with `X`s.

      # return original
      OO
          XX

      # trim end
      OOO
        XXX

      # trim end
      OOOOO
        XXX

      # split
      OOOOOOO
        XXX

      # eliminate
      OO
      XX

      # eliminate
      OO
      XXXX

      # trim beginning
      OOOO
      XX

      # eliminate
        OO
      XXXXXX

      # eliminate
          OO
      XXXXXX

      # trim beginning
        OOO
      XXX

      # return original
           OO
      XX

  ## Examples

      iex> #{__MODULE__}.difference(#{__MODULE__}.new(from: ~N[2018-01-01 02:00:00.000], until: ~N[2018-01-01 04:00:00.000]), #{
    __MODULE__
  }.new(from: ~N[2018-01-01 03:00:00.000], until: ~N[2018-01-01 05:00:00.000]))
      [%#{__MODULE__}{from: ~N[2018-01-01 02:00:00.000], left_open: false, right_open: true, step: [days: 1], until: ~N[2018-01-01 03:00:00.000]}]

      iex> #{__MODULE__}.difference(#{__MODULE__}.new(from: ~N[2018-01-01 01:00:00.000], until: ~N[2018-01-01 05:00:00.000]), #{
    __MODULE__
  }.new(from: ~N[2018-01-01 02:00:00.000], until: ~N[2018-01-01 03:00:00.000]))
      [%#{__MODULE__}{from: ~N[2018-01-01 01:00:00.000], left_open: false, right_open: true, step: [days: 1], until: ~N[2018-01-01 02:00:00.000]}, %#{
    __MODULE__
  }{from: ~N[2018-01-01 03:00:00.000], left_open: false, right_open: true, step: [days: 1], until: ~N[2018-01-01 05:00:00.000]}]

      iex> #{__MODULE__}.difference(#{__MODULE__}.new(from: ~N[2018-01-01 02:00:00.000], until: ~N[2018-01-01 04:00:00.000]), #{
    __MODULE__
  }.new(from: ~N[2018-01-01 01:00:00.000], until: ~N[2018-01-01 05:00:00.000]))
      []
  """
  @spec difference(__MODULE__.t(), __MODULE__.t()) :: [__MODULE__.t()]
  def difference(%__MODULE__{} = original, %__MODULE__{} = removal) do
    cond do
      contains?(removal, original) ->
        # eliminate
        []

      !overlaps?(removal, original) ->
        # return original
        [original]

      Timex.compare(min(removal), min(original)) <= 0 ->
        # trim start
        [Map.put(original, :from, Map.get(removal, :until))]

      Timex.compare(max(original), max(removal)) <= 0 ->
        # trim end
        [Map.put(original, :until, Map.get(removal, :from))]

      true ->
        # split
        part_before = Map.put(original, :until, Map.get(removal, :from))
        part_after = Map.put(original, :from, Map.get(removal, :until))
        [part_before, part_after]
    end
  end

  @doc false
  def min(interval)

  def min(%__MODULE__{from: from, left_open: false}), do: from

  def min(%__MODULE__{from: from, step: step}) do
    case Timex.shift(from, step) do
      {:error, {:unknown_shift_unit, unit}} ->
        raise FormatError, message: "Invalid step unit for interval: #{inspect(unit)}"

      d ->
        d
    end
  end

  @doc false
  def max(interval)

  def max(%__MODULE__{until: until, right_open: false}), do: until
  def max(%__MODULE__{until: until}), do: Timex.shift(until, microseconds: -1)

  defimpl Enumerable, for: Timex.Interval do
    alias Timex.Interval

    def reduce(%Interval{until: until, right_open: open?, step: step} = i, acc, fun) do
      do_reduce({Interval.min(i), until, open?, step}, acc, fun)
    end

    defp do_reduce(_state, {:halt, acc}, _fun),
      do: {:halted, acc}

    defp do_reduce(state, {:suspend, acc}, fun),
      do: {:suspended, acc, &do_reduce(state, &1, fun)}

    defp do_reduce({current_date, end_date, right_open, step}, {:cont, acc}, fun) do
      if has_interval_ended?(current_date, end_date, right_open) do
        {:done, acc}
      else
        case Timex.shift(current_date, step) do
          {:error, {:unknown_shift_unit, unit}} ->
            raise FormatError, message: "Invalid step unit for interval: #{inspect(unit)}"

          {:error, err} ->
            raise FormatError,
              message: "Failed to shift to next element in interval: #{inspect(err)}"

          next_date ->
            do_reduce({next_date, end_date, right_open, step}, fun.(current_date, acc), fun)
        end
      end
    end

    defp has_interval_ended?(current_date, end_date, _right_open = true),
      do: Timex.compare(current_date, end_date) >= 0

    defp has_interval_ended?(current_date, end_date, _right_open = false),
      do: Timex.compare(current_date, end_date) > 0

    def member?(%Interval{} = interval, value) do
      result =
        cond do
          before?(interval, value) ->
            false

          after?(interval, value) ->
            false

          :else ->
            true
        end

      {:ok, result}
    end

    defp before?(%Interval{from: from, left_open: true}, value),
      do: Timex.compare(value, from) <= 0

    defp before?(%Interval{from: from, left_open: false}, value),
      do: Timex.compare(value, from) < 0

    defp after?(%Interval{until: until, right_open: true}, value),
      do: Timex.compare(value, until) >= 0

    defp after?(%Interval{until: until, right_open: false}, value),
      do: Timex.compare(value, until) > 0

    def count(_interval) do
      {:error, __MODULE__}
    end

    def slice(_interval) do
      {:error, __MODULE__}
    end
  end
end

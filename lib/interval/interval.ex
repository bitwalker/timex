defmodule Timex.Interval do
  @moduledoc """
  This module is used for creating and manipulating DateTime intervals.

  ## Examples

    iex> Timex.Interval.new(from: ~D[2016-03-03], until: [days: 3])
    %Timex.Interval{from: ~N[2016-03-03 00:00:00], left_open: false, right_open: true, step: [days: 1], until: ~N[2016-03-06 00:00:00]}

    iex> Timex.Interval.new(from: ~D[2016-03-03], until: ~N[2016-03-10 01:23:45])
    %Timex.Interval{from: ~N[2016-03-03 00:00:00], left_open: false, right_open: true, step: [days: 1], until: ~N[2016-03-10 01:23:45]}

    iex> ~N[2016-03-04 12:34:56] in Timex.Interval.new(from: ~D[2016-03-03], until: [days: 3])
    true

    iex> ~D[2016-03-01] in Timex.Interval.new(from: ~D[2016-03-03], until: [days: 3])
    false

    iex> Timex.Interval.overlaps?(Timex.Interval.new(from: ~D[2016-03-01], until: [days: 5]),  Timex.Interval.new(from: ~D[2016-03-03], until: [days: 3]))
    true

    iex> Timex.Interval.overlaps?(Timex.Interval.new(from: ~D[2016-03-01], until: [days: 1]),  Timex.Interval.new(from: ~D[2016-03-03], until: [days: 3]))
    false

  """
  alias Timex.Duration

  defmodule FormatError do
    @moduledoc """
    Thrown when an error occurs with formatting an Interval
    """
    defexception message: "Unable to format interval!"

    def exception([message: message]) do
      %FormatError{message: message}
    end
  end

  @type t :: %__MODULE__{}
  @type valid_interval_step :: [microseconds: integer()] |
                               [milliseconds: integer()] |
                               [seconds:      integer()] |
                               [minutes:      integer()] |
                               [hours:        integer()] |
                               [days:         integer()] |
                               [weeks:        integer()] |
                               [months:       integer()] |
                               [years:        integer()]

  @enforce_keys [:from, :until]
  defstruct from:       nil,
            until:      nil,
            left_open:  false,
            right_open: true,
            step:       [days: 1]

  @doc """
  Create a new Interval struct.

  Note: By default intervals are right open.

  Valid keywords:
  - `from`: The date the interval starts at. Should be a DateTime.
  - `until`: Either a DateTime, or a time shift that will be applied to the `from` date.
  - `left_open`: Whether the interval is left open. See explanation below.
  - `right_open`: Whether the interval is right open. See explanation below.
  - `step`: The step to use when iterating the interval, defaults to `[days: 1]`

  The terms`left_open` and `right_open` come from the mathematical concept of intervals, the following
  excerpt from Wikipedia gives a good explanation of their meaning:

      "An interval is said to be left-open if and only if it has no minimum
      (an element that is smaller than all other elements); right-open if it has no maximum;
      and open if it has both properties. The interval [0,1) = {x | 0 ≤ x < 1}, for example,
      is left-closed and right-open. The empty set and the set of all reals are open intervals,
      while the set of non-negative reals, for example, is a right-open but not left-open interval.
      The open intervals coincide with the open sets of the real line in its standard topology."

  Note: `until` shifts delegate to `Timex.shift`, so the options provided should match its valid options.

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
  @spec new(Keyword.t) :: Interval.t | {:error, :invalid_until} | {:error, :invalid_step}
  def new(options \\ []) do
    from = case Keyword.get(options, :from) do
      nil -> Timex.Protocol.NaiveDateTime.now()
      %NaiveDateTime{} = d -> d
      d -> Timex.to_naive_datetime(d)
    end
    left_open  = Keyword.get(options, :left_open,  false)
    right_open = Keyword.get(options, :right_open, true)
    step       = Keyword.get(options, :step,       [days: 1])
    until = case Keyword.get(options, :until, [days: 1]) do
              {:error, _} = err    -> err
              x when is_list(x)    -> Timex.shift(from, x)
              %NaiveDateTime{} = d -> d
              %DateTime{} = d      -> Timex.to_naive_datetime(d)
              %Date{} = d          -> Timex.to_naive_datetime(d)
              _ -> {:error, :invalid_until}
            end

    attrs = %{from: from,
              until: until,
              left_open: left_open,
              right_open: right_open,
              step: valid_step_or_error(step)}
    build_struct_or_error(attrs)
  end

  @spec build_struct_or_error(map()) :: Interval.t | {:error, atom()}
  defp build_struct_or_error(%{until: err = {:error, _}}), do: err
  defp build_struct_or_error(%{step:  err = {:error, _}}), do: err
  defp build_struct_or_error(valid_attrs),                 do: struct(__MODULE__, valid_attrs)

  @spec valid_step_or_error(any()) :: valid_interval_step | {:error, :invalid_step}
  defp valid_step_or_error(step = [milliseconds: _]), do: step
  defp valid_step_or_error(step = [microseconds: _]), do: step
  defp valid_step_or_error(step = [seconds: _]),      do: step
  defp valid_step_or_error(step = [minutes: _]),      do: step
  defp valid_step_or_error(step = [hours: _]),        do: step
  defp valid_step_or_error(step = [days: _]),         do: step
  defp valid_step_or_error(step = [weeks: _]),        do: step
  defp valid_step_or_error(step = [months: _]),       do: step
  defp valid_step_or_error(step = [years: _]),       do: step
  defp valid_step_or_error(_),                        do: {:error, :invalid_step}

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
  def duration(%__MODULE__{from: from, until: until}, :duration) do
    Timex.diff(until, from, :microseconds) |> Duration.from_microseconds
  end
  def duration(%__MODULE__{from: from, until: until}, unit) do
    Timex.diff(until, from, unit)
  end

  @doc """
  Change the step value for the provided interval.

  The step should be a keyword list valid for use with `Timex.Date.shift`.

  ## Examples

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
  @spec with_step(Interval.t, any()) :: Interval.t | {:error, :invalid_step}
  def with_step(%__MODULE__{} = interval, step) do
    case valid_step_or_error(step) do
      error = {:error, _} -> error
      step                -> %__MODULE__{interval | step: step}
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
      {:error, _} = err -> err
      {:ok, from} ->
        case Timex.format(interval.until, format, formatter) do
          {:error, _} = err -> err
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
      {:ok, str} -> str
      {:error, e} -> raise FormatError, message: "#{inspect e}"
    end
  end

  @doc """
  Returns true if the first interval shares any point(s) in time with the second.

  ## Examples

      iex> Timex.Interval.overlaps?(Timex.Interval.new(from: ~D[2016-03-04], until: [days: 1]), Timex.Interval.new(from: ~D[2016-03-03], until: [days: 3]))
      true

      iex> Timex.Interval.overlaps?(Timex.Interval.new(from: ~D[2016-03-07], until: [days: 1]), Timex.Interval.new(from: ~D[2016-03-03], until: [days: 3]))
      false
  """
  @spec overlaps?(__MODULE__.t, __MODULE__.t) :: boolean()
  def overlaps?(interval_a, interval_b) do
    interval_a.from in interval_b ||
      interval_a.until in interval_b ||
      interval_b.from in interval_a
  end

  defimpl Enumerable do

    def reduce(interval, acc, fun) do
      do_reduce({get_starting_date(interval), interval.until, interval.right_open, interval.step}, acc, fun)
    end

    def member?(%Timex.Interval{} = interval, value) do
      result = cond do
        before?(interval, value) -> false
        after?(interval, value) -> false
        :else -> true
      end
      {:ok, result}
    end

    defp before?(%Timex.Interval{from: from, left_open: true}, value), do: Timex.compare(value, from) <= 0
    defp before?(%Timex.Interval{from: from, left_open: false}, value), do: Timex.compare(value, from) < 0

    defp after?(%Timex.Interval{until: until, right_open: true}, value), do: Timex.compare(value, until) >= 0
    defp after?(%Timex.Interval{until: until, right_open: false}, value), do: Timex.compare(value, until) > 0

    def count(_interval) do
      {:error, __MODULE__}
    end

    def slice(_interval) do
      {:error, __MODULE__}
    end

    defp do_reduce(_state, {:halt,    acc}, _fun), do: {:halted, acc}
    defp do_reduce( state, {:suspend, acc},  fun), do: {:suspended, acc, &do_reduce(state, &1, fun)}

    defp do_reduce({current_date, end_date, right_open, keywords}, {:cont, acc}, fun) do
      if has_recursion_ended?(current_date, end_date, right_open) do
        {:done, acc}
      else
        case Timex.shift(current_date, keywords) do
          {:error, {:unknown_shift_unit, _}} ->
            raise FormatError, message: "Invalid step unit for %Timex.Interval{}"
          {:error, e} ->
            raise FormatError, message: "Timex.shift error during reduce of %Timex.Interval{}: #{inspect e}"
          next_date ->
            do_reduce({next_date, end_date, right_open, keywords}, fun.(current_date, acc), fun)
        end
      end
    end

    defp get_starting_date(%Timex.Interval{from: from, step: step, left_open: true}), do: Timex.shift(from, step)
    defp get_starting_date(%Timex.Interval{from: from}),                              do: from

    defp has_recursion_ended?(current_date, end_date,  true), do: Timex.compare(end_date, current_date) < 1
    defp has_recursion_ended?(current_date, end_date, false), do: Timex.compare(end_date, current_date) < 0
  end
end

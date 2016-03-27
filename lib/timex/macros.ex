defmodule Timex.Macros do
  @moduledoc false

  @doc """
  Wraps a function definition in a warning at runtime on :stderr that the wrapped function has been deprecated.
  The message parameter should be used to communicate the action needed to move to supported behaviour.
  """
  defmacro defdeprecated({name, _env, args} = head, message, do: body) do
    caller = Enum.join(Module.split(__CALLER__.module), ".")
    {name, len} = case {name, args} do
      {:when, [{name, _, args} | _]} -> {name, Enum.count(args)}
      _ -> {name, Enum.count(args)}
    end
    quote do
      def unquote(head) do
        IO.write :stderr, "warning: #{unquote(caller)}.#{unquote(name)}/#{unquote(len)} is deprecated, #{unquote(message)}\n"
        unquote(body)
      end
    end
  end

  @doc """
  This macro evaluates an expression safely, and ensures the result is always
  either an error tuple or an ok tuple, but does not catch or rescue exceptions.

  The call is similar to a monadic bind, in that if the result is already an error
  or ok tuple, they will not be wrapped in another tuple, but will be returned directly,
  while an unwrapped value will be wrapped in an ok tuple.

  ## Examples

      iex> import Timex.Macros
      ...> ok!(1 + 2)
      {:ok, 3}

      iex> import Timex.Macros
      ...> ok!({:error, :badarg})
      {:error, :badarg}

      iex> import Timex.Macros
      ...> ok!((fn -> "hello" end).())
      {:ok, "hello"}
  """
  defmacro ok!(call) do
    quote bind_quoted: [call: call] do
      case call do
        {:error, _} = err -> err
        {:ok, _} = res -> res
        result -> {:ok, result}
      end
    end
  end

  @doc """
  This macro evaluates an expression safely, and ensures the result is always
  either an error tuple or an ok tuple, even if exceptions are thrown.

  The call is similar to a monadic bind, in that if the result is already an error
  or ok tuple, they will not be wrapped in another tuple, but will be returned directly,
  while an unwrapped value will be wrapped in an ok tuple. Exceptions will be caught or
  rescued and wrapped in an error tuple.

  ## Examples

      iex> import Timex.Macros
      ...> try!(1 + 2)
      {:ok, 3}

      iex> import Timex.Macros
      ...> try!({:error, :badarg})
      {:error, :badarg}

      iex> import Timex.Macros
      ...> try!((fn -> "hello" end).())
      {:ok, "hello"}

  """
  defmacro try!(call) do
    quote bind_quoted: [call: call] do
      try do
        case call do
          {:error, _} = err -> err
          {:ok, _} = res -> res
          result -> {:ok, result}
        end
      catch
        _, reason ->
          {:error, reason}
      end
    end
  end

  @doc """
  A guard macro which asserts that the given value is an integer >= 0
  """
  defmacro is_positive_integer(n) do
    quote do
      (is_integer(unquote(n)) and unquote(n) >= 0)
    end
  end

  @doc """
  A guard macro which asserts that the given value is an integer or float >= 0
  """
  defmacro is_positive_number(n) do
    quote do
      (is_number(unquote(n))) and unquote(n) >= 0
    end
  end

  @doc """
  A guard macro which assert that the given value is an integer in between the values min and max
  """
  defmacro is_integer_in_range(n, min, max) do
    quote do
      (is_integer(unquote(n)) and unquote(n) >= unquote(min) and unquote(n) <= unquote(max))
    end
  end

  @doc """
  A guard macro which asserts that the given value is a float in between the values min and max,
  where max is not included in the range (this is to account for fractions which can be arbitrarily precise)
  """
  defmacro is_float_in_range(n, min, max) do
    quote do
      (is_float(unquote(n)) and unquote(n) >= unquote(min) and unquote(n) < unquote(max))
    end
  end

  @doc """
  A guard macro which asserts that the given value is an integer in the range of 0-999
  """
  defmacro is_millisecond(ms) do
    quote do
      (is_integer_in_range(unquote(ms), 0, 999) or is_float_in_range(unquote(ms), 0, 1000))
    end
  end

  @doc """
  A guard macro which asserts that the given value is an integer in the range of 0-59
  """
  defmacro is_second(s) do
    quote do
      is_integer_in_range(unquote(s), 0, 59)
    end
  end

  @doc """
  A guard macro which asserts that the given value is an integer in the range of 0-59
  """
  defmacro is_minute(m) do
    quote do
      is_integer_in_range(unquote(m), 0, 59)
    end
  end

  @doc """
  A guard macro which asserts that the given value is an integer in the range of 0-24
  """
  defmacro is_hour(h, :exclusive) do
    quote do
      is_integer_in_range(unquote(h), 0, 23)
    end
  end
  defmacro is_hour(h, :inclusive) do
    quote do
      is_integer_in_range(unquote(h), 0, 23)
    end
  end

  @doc """
  A guard macro which asserts that the given values forms a valid Erlang timestamp
  """
  defmacro is_timestamp(mega,sec,micro) do
    quote do
      (is_integer(unquote(mega)) and
       is_integer(unquote(sec)) and
       is_integer(unquote(micro)))
    end
  end

  @doc """
  A guard macro which asserts that the given value is an integer in the range of -12-12
  """
  defmacro is_tz_offset(offset) do
    quote do
      is_integer_in_range(unquote(offset), -12, 12)
    end
  end

  @doc """
  A guard macro which asserts that the given value is a valid Gregorian year value
  """
  defmacro is_year(y) do
    quote do
      is_positive_integer(unquote(y))
    end
  end

  @doc """
  A guard macro which asserts that the given value is an integer in the range of 1-12
  """
  defmacro is_month(m) do
    quote do
      is_integer_in_range(unquote(m), 1, 12)
    end
  end

  @doc """
  A guard macro which asserts that the given value is an integer in the range of 0-6
  """
  defmacro is_day_of_week(d, :sun) do
    quote do
      is_integer_in_range(unquote(d), 0, 6)
    end
  end
  @doc """
  A guard macro which asserts that the given value is an integer in the range of 1-7
  """
  defmacro is_day_of_week(d, :mon) do
    quote do
      is_integer_in_range(unquote(d), 1, 7)
    end
  end

  @doc """
  A guard macro which asserts that the given value is an integer in the range of 1-31
  """
  defmacro is_day_of_month(d) do
    quote do
      is_integer_in_range(unquote(d), 1, 31)
    end
  end

  @doc """
  A guard macro which asserts that the given value is an integer in the range of 1-366
  """
  defmacro is_day_of_year(d) do
    quote do
      is_integer_in_range(unquote(d), 1, 366)
    end
  end

  @doc """
  A guard macro which asserts that the given value is an integer in the range of 1-53
  """
  defmacro is_week_of_year(w) do
    quote do
      is_integer_in_range(unquote(w), 1, 53)
    end
  end

  @doc """
  A guard macro which asserts that the given values are a valid year, month, and day of month
  """
  defmacro is_date(y,m,d) do
    quote do
      (is_year(unquote(y)) and is_month(unquote(m)) and is_day_of_month(unquote(d)))
    end
  end

  @doc """
  A guard macro which asserts that the given values are a valid hour, minute, second, and optional millisecond
  """
  defmacro is_time(h,m,s,ms\\0) do
    quote do
      (is_hour(unquote(h), :exclusive) and is_minute(unquote(m)) and is_second(unquote(s)) and is_millisecond(unquote(ms)))
    end
  end

  @doc """
  A guard macro which asserts that the given values are a valid hour, minute,
  second, and timezone composed of an offset and an abbrevation.

  This reflects the gregorian type as returned by the to_gregorian conversion
  """
  defmacro is_gregorian(y,m,d,h,mm,s,offset,tz) do
    quote do
      (is_datetime(unquote(y),unquote(m),unquote(d),unquote(h),unquote(mm),unquote(s)) and
       is_gregorian_tz(unquote(offset), unquote(tz)))
    end
  end

  @doc """
  A guard macro which asserts that the given values are a valid timezone offset and name string
  """
  defmacro is_gregorian_tz(offset, tz) do
    quote do
      (is_tz_offset(unquote(offset)) and is_binary(unquote(tz)))
    end
  end

  @doc """
  A guard macro which asserts that the given values are a valid year, month, day, hour,
  minute, second, and optional millisecond
  """
  defmacro is_datetime(y,m,d,h,mm,s,ms\\0) do
    quote do
      (is_date(unquote(y),unquote(m),unquote(d)) and is_time(unquote(h),unquote(mm),unquote(s),unquote(ms)))
    end
  end

  @doc """
  A guard macro which asserts that the given values compose a timestamp which is representable
  by a Date or DateTime, relative to year zero
  """
  defmacro is_date_timestamp(mega,secs,micro) do
    quote do
      (is_positive_integer(unquote(mega)) and
       is_positive_integer(unquote(secs)) and
       is_positive_integer(unquote(micro)))
    end
  end

  @doc """
  A guard macro which asserts that the given value is either a string, a valid offset, :utc, or :local
  """
  defmacro is_tz_value(tz) do
    quote do
      (is_binary(unquote(tz)) or is_tz_offset(unquote(tz)) or unquote(tz) in [:utc, :local])
    end
  end

end

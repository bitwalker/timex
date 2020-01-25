defmodule Timex.Parse.Duration.Parsers.ISO8601Parser do
  @moduledoc """
  This module parses ISO-8601 duration strings into Duration structs.
  """
  use Timex.Parse.Duration.Parser

  @numeric '.0123456789'

  @doc """
  Parses an ISO-8601 formatted duration string into a Duration struct.
  The parse result is wrapped in a :ok/:error tuple.

  ## Examples

      iex> {:ok, d} = #{__MODULE__}.parse("P15Y3M2DT1H14M37.25S")
      ...> Timex.Format.Duration.Formatter.format(d)
      "P15Y3M2DT1H14M37.25S"

      iex> {:ok, d} = #{__MODULE__}.parse("P15Y3M2D")
      ...> Timex.Format.Duration.Formatter.format(d)
      "P15Y3M2D"

      iex> {:ok, d} = #{__MODULE__}.parse("PT3H12M25.001S")
      ...> Timex.Format.Duration.Formatter.format(d)
      "PT3H12M25.001S"

      iex> {:ok, d} = #{__MODULE__}.parse("P2W")
      ...> Timex.Format.Duration.Formatter.format(d)
      "P14D"

      iex> #{__MODULE__}.parse("P15YT3D")
      {:error, "invalid use of date component after time separator"}

  """
  @spec parse(String.t()) :: {:ok, Duration.t()} | {:error, term}
  def parse(<<>>), do: {:error, "input string cannot be empty"}

  def parse(<<?P, rest::binary>>) do
    case parse_components(rest, []) do
      {:error, _} = err ->
        err

      [{?W, w}] ->
        {:ok, Duration.from_days(7 * w)}

      components when is_list(components) ->
        result =
          Enum.reduce(components, {false, Duration.zero()}, fn
            _, {:error, _} = err ->
              err

            {?Y, y}, {false, d} ->
              {false, Duration.add(d, Duration.from_days(365 * y))}

            {?M, m}, {false, d} ->
              {false, Duration.add(d, Duration.from_days(30 * m))}

            {?D, dd}, {false, d} ->
              {false, Duration.add(d, Duration.from_days(dd))}

            ?T, {false, d} ->
              {true, d}

            ?T, {true, _d} ->
              {:error, "encountered duplicate time separator T"}

            {?H, h}, {true, d} ->
              {true, Duration.add(d, Duration.from_hours(h))}

            {?M, m}, {true, d} ->
              {true, Duration.add(d, Duration.from_minutes(m))}

            {?S, s}, {true, d} ->
              {true, Duration.add(d, Duration.from_seconds(s))}

            {?W, _w}, {_, _} ->
              {:error,
               "Found 'W', a basic format designator, but the parse indicates " <>
                 "this is an extended format, mixing the two formats is disallowed"}

            {unit, _}, {true, _d} when unit in [?Y, ?D] ->
              {:error, "invalid use of date component after time separator"}

            {unit, _}, {false, _d} when unit in [?H, ?S] ->
              {:error, "missing T separator between date and time components"}
          end)

        case result do
          {:error, _} = err -> err
          {_, duration} -> {:ok, duration}
        end
    end
  end

  def parse(<<c::utf8, _::binary>>), do: {:error, "expected P, got #{<<c::utf8>>}"}
  def parse(s) when is_binary(s), do: {:error, "unexpected end of input"}

  @spec parse_components(binary, [{integer, number}]) ::
          [{integer, number}] | {:error, String.t()}
  defp parse_components(<<>>, acc),
    do: Enum.reverse(acc)

  defp parse_components(<<?T>>, _acc),
    do: {:error, "unexpected end of input at T"}

  defp parse_components(<<?T, rest::binary>>, acc),
    do: parse_components(rest, [?T | acc])

  defp parse_components(<<c::utf8>>, _acc) when c in @numeric,
    do: {:error, "unexpected end of input at #{<<c::utf8>>}"}

  defp parse_components(<<c::utf8, rest::binary>>, acc) when c in @numeric do
    case parse_component(rest, <<c::utf8>>) do
      {:error, _} = err -> err
      {u, n, rest} -> parse_components(rest, [{u, n} | acc])
    end
  end

  defp parse_components(<<c::utf8>>, _acc),
    do: {:error, "unexpected end of input at #{<<c::utf8>>}"}

  defp parse_components(<<c::utf8, _::binary>>, _acc),
    do: {:error, "expected numeric, but got #{<<c::utf8>>}"}

  @spec parse_component(binary, binary) :: {integer, number, binary}
  defp parse_component(<<c::utf8>>, _acc) when c in @numeric,
    do: {:error, "unexpected end of input at #{<<c::utf8>>}"}

  defp parse_component(<<c::utf8>>, acc) when c in 'WYMDHS' do
    cond do
      String.contains?(acc, ".") ->
        case Float.parse(acc) do
          {n, _} -> {c, n, <<>>}
          :error -> {:error, "invalid number `#{acc}`"}
        end

      :else ->
        case Integer.parse(acc) do
          {n, _} -> {c, n, <<>>}
          :error -> {:error, "invalid number `#{acc}`"}
        end
    end
  end

  defp parse_component(<<c::utf8, rest::binary>>, acc) when c in @numeric do
    parse_component(rest, <<acc::binary, c::utf8>>)
  end

  defp parse_component(<<c::utf8, rest::binary>>, acc) when c in 'WYMDHS' do
    cond do
      String.contains?(acc, ".") ->
        case Float.parse(acc) do
          {n, _} -> {c, n, rest}
          :error -> {:error, "invalid number `#{acc}`"}
        end

      :else ->
        case Integer.parse(acc) do
          {n, _} -> {c, n, rest}
          :error -> {:error, "invalid number `#{acc}`"}
        end
    end
  end

  defp parse_component(<<c::utf8>>, _acc), do: {:error, "unexpected token #{<<c::utf8>>}"}

  defp parse_component(<<c::utf8, _::binary>>, _acc),
    do: {:error, "unexpected token #{<<c::utf8>>}"}
end

defmodule Timex.Parse.Duration.Parser do
  @moduledoc """
  This module is responsible for parsing input strings into Duration structs.
  The actual parsing is delegated to specific parser modules, but this module
  provides a unified API for all of them.
  """
  alias Timex.Duration
  alias Timex.Parse.ParseError
  alias Timex.Parse.Duration.Parsers.ISO8601Parser

  defmacro __using__(_) do
    quote do
      @behaviour Timex.Parse.Duration.Parser
      alias Timex.Duration
    end
  end

  @callback parse(String.t()) :: {:ok, Duration.t()} | {:error, term}

  @doc """
  Parses the given input using the ISO-8601 duration parser,
  and returns either an :ok, or :error tuple.
  """
  @spec parse(String.t()) :: {:ok, Duration.t()} | {:error, term}
  def parse(str) when is_binary(str) do
    parse(str, ISO8601Parser)
  end

  @doc """
  Parses the given input using the provided parser module,
  and returns either an :ok, or :error tuple.
  """
  @spec parse(String.t(), module()) :: {:ok, Duration.t()} | {:error, term}
  def parse(str, parser) when is_binary(str) and is_atom(parser) do
    case parser.parse(str) do
      %Duration{} = d -> {:ok, d}
      {:ok, d} -> {:ok, d}
      {:error, term} -> {:error, term}
    end
  end

  @doc """
  Parses the given input using the ISO-8601 duration parser,
  and either returns a Duration, or raises an error.
  """
  @spec parse!(String.t()) :: Duration.t() | no_return
  def parse!(str) when is_binary(str) do
    parse!(str, ISO8601Parser)
  end

  @doc """
  Parses the given input using the provided parser module,
  and either returns a Duration, or raises an error.
  """
  @spec parse!(String.t(), module()) :: Duration.t() | no_return
  def parse!(str, parser) when is_binary(str) and is_atom(parser) do
    case parse(str) do
      {:ok, d} -> d
      {:error, reason} when is_binary(reason) -> raise ParseError, message: reason
      {:error, term} -> raise ParseError, message: "#{inspect(term)}"
    end
  end
end

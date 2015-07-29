defmodule Timex.Parse.DateTime.Tokenizer do
  @moduledoc """
  Defines the API for a custom tokenizer which can extend Timex's datetime parsing facilities.
  """
  use Behaviour
  alias Timex.Parse.DateTime.Tokenizers.Directive

  defcallback tokenize(format_string :: String.t) :: [%Directive{}] | {:error, term}

  defmacro __using__(_) do
    quote do
      @behaviour Timex.Parse.DateTime.Tokenizer

      import Timex.Parse.DateTime.Tokenizer
      alias Timex.Parse.DateTime.Tokenizers.Directive
    end
  end
end

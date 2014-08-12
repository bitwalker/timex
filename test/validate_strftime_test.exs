defmodule DateFormatTest.ValidateStrftime do
  use ExUnit.Case
  use Timex

  test :validate do
    assert {:error, "Format string cannot be nil or empty!"} = validate ""
    assert {:error, "Invalid strftime format string"} = validate "abc"
    assert {:error, "There were no formatting directives in the provided string."} = validate "Use {{ as oft%%%%en as you like{{"
    assert :ok = validate "%%Same go}}es for }}%%"

    assert {:error, "Invalid strftime format string"} = validate "%"
    assert {:error, "Invalid strftime format string"} = validate "%^"
    assert {:error, "Invalid strftime format string"} = validate "%%%"
    assert {:error, "Invalid directive used starting at column 0"} = validate "%0X"
  end

  defp validate(fmt) do
    DateFormat.validate(fmt, :strftime)
  end
end
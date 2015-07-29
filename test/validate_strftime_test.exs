defmodule DateFormatTest.ValidateStrftime do
  use ExUnit.Case, async: true
  use Timex

  test :validate do
    assert {:error, "Format string cannot be empty."} = validate ""
    assert {:error, _} = validate "abc"
    assert {:error, _} = validate "Use {{ as oft%%%%en as you like{{"
    assert {:error, "Invalid format string, must contain at least one directive."} = validate "%%Same go}}es for }}%%"

    assert {:error, _} = validate "%"
    assert {:error, _} = validate "%^"
    assert {:error, _} = validate "%%%"
    assert {:error, _} = validate "%0X"
  end

  defp validate(fmt) do
    DateFormat.validate(fmt, :strftime)
  end
end

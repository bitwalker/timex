defmodule DateFormatTest.ValidateDefault do
  use ExUnit.Case, async: true
  use Timex

  test :validate do
    assert {:error, "Format string cannot be empty."} = validate ""
    assert {:error, _} = validate "abc"
    assert {:error, _} = validate "Use {{ as oft{{en as you like{{"
    assert {:error, _} = validate "Same go}}es for }}"
    assert {:error, _} = validate "{{abc}}"
    assert {:error, _} = validate "abc } def"

    assert {:error, _} = validate "{"
    assert {:error, _} = validate "abc { def"
    assert {:error, _} = validate "abc { { def"
    assert {:error, _} = validate "abc {} def"
    assert {:error, _} = validate "abc {non-existent} def"
  end

  defp validate(fmt) do
    DateFormat.validate(fmt)
  end
end

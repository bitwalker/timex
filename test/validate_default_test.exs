defmodule DateFormatTest.ValidateDefault do
  use ExUnit.Case
  use Timex

  test :validate do
    assert {:error, "Format string cannot be nil or empty!"} = validate ""
    assert {:error, "There were no formatting directives in the provided string."} = validate "abc"
    assert {:error, "Invalid nesting of directives at column 5:  as oft{{en as you like{{"} = validate "Use {{ as oft{{en as you like{{"
    assert {:error, "Missing open brace for closing brace at column 7!"} = validate "Same go}}es for }}"
    assert {:error, "Invalid nesting of directives at column 1: abc}}"} = validate "{{abc}}"
    assert {:error, "Missing open brace for closing brace at column 4!"} = validate "abc } def"

    assert {:error, "Unclosed directive starting at column 0"} = validate "{"
    assert {:error, "Unclosed directive starting at column 4"} = validate "abc { def"
    assert {:error, "Invalid nesting of directives at column 6:  def"} = validate "abc { { def"
    assert {:error, "Missing open brace for closing brace at column 5!"} = validate "abc {} def"
    assert {:error, "Invalid token beginning at column 4!"} = validate "abc {non-existent} def"
  end

  defp validate(fmt) do
    DateFormat.validate(fmt)
  end
end

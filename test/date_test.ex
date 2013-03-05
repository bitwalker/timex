defmodule DateTest do
  use ExUnit.Case, async: true

  test :rfc1123 do
    date = {{2013,3,5},{23,25,19}}
    assert Date.rfc1123(date) == "Tue, 05 Mar 2013 21:25:19 GMT"
  end
end

defmodule Timex.NonEnglishParser.Test do
  use ExUnit.Case, async: true
  doctest Timex.Parse.DateTime.Parser

  use Combine
  import Timex.Parse.DateTime.Parsers
  require Timex.Translator
  alias Timex.Translator

  test "helpers: to_month_num" do
    Translator.with_locale("fr") do
      assert [[month: 1]] = Combine.parse("janvier", month_full([]))
      assert [[month: 1]] = Combine.parse("janv.", month_short([]))
      assert [[month: 2]] = Combine.parse("février", month_full([]))
      assert [[month: 2]] = Combine.parse("févr.", month_short([]))
      assert [[month: 3]] = Combine.parse("mars", month_full([]))
      assert [[month: 3]] = Combine.parse("mars", month_short([]))
      assert [[month: 4]] = Combine.parse("avril", month_full([]))
      assert [[month: 4]] = Combine.parse("avr.", month_short([]))
      assert [[month: 5]] = Combine.parse("mai", month_full([]))
      assert [[month: 6]] = Combine.parse("juin", month_short([]))
      assert [[month: 6]] = Combine.parse("juin", month_short([]))
      assert [[month: 7]] = Combine.parse("juillet", month_full([]))
      assert [[month: 7]] = Combine.parse("juil.", month_short([]))
      assert [[month: 8]] = Combine.parse("août", month_full([]))
      assert [[month: 8]] = Combine.parse("août", month_short([]))
      assert [[month: 9]] = Combine.parse("septembre", month_full([]))
      assert [[month: 9]] = Combine.parse("sept.", month_short([]))
      assert [[month: 10]] = Combine.parse("octobre", month_full([]))
      assert [[month: 10]] = Combine.parse("oct.", month_short([]))
      assert [[month: 11]] = Combine.parse("novembre", month_full([]))
      assert [[month: 11]] = Combine.parse("nov.", month_short([]))
      assert [[month: 12]] = Combine.parse("décembre", month_full([]))
      assert [[month: 12]] = Combine.parse("déc.", month_short([]))
      assert {:error, "Expected `full month name` at line 1, column 10."} = Combine.parse("Something", month_full([]))
    end
  end

  test "helpers: is_weekday" do
    Translator.with_locale("fr") do
      assert [1] = Combine.parse("lundi", weekday_full([]))
      assert [2] = Combine.parse("mardi", weekday_full([]))
      assert [3] = Combine.parse("mercredi", weekday_full([]))
      assert [4] = Combine.parse("jeudi", weekday_full([]))
      assert [5] = Combine.parse("vendredi", weekday_full([]))
      assert [6] = Combine.parse("samedi", weekday_full([]))
      assert [7] = Combine.parse("dimanche", weekday_full([]))
      assert {:error, _} = Combine.parse("Whatday", weekday_full([]))
    end
  end

  test "parsers: am/pm lower" do
    Translator.with_locale("ru") do
      assert [[am: "pm"]] = Combine.parse("пп", ampm_lower([]))
      assert [[am: "am"]] = Combine.parse("дп", ampm_lower([]))
      assert {:error, _} = Combine.parse("fm", ampm_lower([]))
    end
  end
end

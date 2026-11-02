defmodule LocalizedMonthParserTest do
  use ExUnit.Case, async: true

  test "translated full and abbreviated months preserve the actual month in both formats" do
    for {locale, full, abbreviated, expected} <- [
          {"ru", "октября", "окт", ~N[2017-10-28 00:00:00]},
          {"fr", "juin", "juin", ~N[2017-06-28 00:00:00]},
          {"fr", "août", "août", ~N[2017-08-28 00:00:00]}
        ] do
      Gettext.with_locale(Timex.Gettext, locale, fn ->
        for {month, default_format, strftime_format} <- [
              {full, "{D} {Mfull} {YYYY}", "%d %B %Y"},
              {abbreviated, "{D} {Mshort} {YYYY}", "%d %b %Y"}
            ] do
          input = "28 " <> month <> " 2017"
          assert {:ok, ^expected} = Timex.parse(input, default_format)
          assert {:ok, ^expected} = Timex.parse(input, strftime_format, :strftime)
        end
      end)
    end
  end

  test "English month names remain available under another process locale" do
    Gettext.with_locale(Timex.Gettext, "ru", fn ->
      assert {:ok, ~N[2017-06-28 00:00:00]} =
               Timex.parse("28 June 2017", "{D} {Mfull} {YYYY}")

      assert {:ok, ~N[2017-10-28 00:00:00]} =
               Timex.parse("28 Oct 2017", "%d %b %Y", :strftime)
    end)
  end

  test "concurrent parsing uses each process's locale and restores the caller's locale" do
    original_locale = Timex.Translator.current_locale()

    tasks =
      for {locale, input, expected} <- [
            {"ru", "28 июня 2017", ~N[2017-06-28 00:00:00]},
            {"fr", "28 août 2017", ~N[2017-08-28 00:00:00]}
          ] do
        task =
          Task.async(fn ->
            Gettext.with_locale(Timex.Gettext, locale, fn ->
              Timex.parse(input, "{D} {Mfull} {YYYY}")
            end)
          end)

        {task, expected}
      end

    for {task, expected} <- tasks do
      assert {:ok, ^expected} = Task.await(task)
    end

    assert Timex.Translator.current_locale() == original_locale
  end
end

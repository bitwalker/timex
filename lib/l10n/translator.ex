defmodule Timex.Translator do
  import Timex.Gettext

  defmacro with_locale(locale, do: block) do
    quote do
      Gettext.with_locale(Timex.Gettext, unquote(locale), fn -> unquote(block) end)
    end
  end

  @doc """
  Translates a string for a given locale and domain.

  ## Examples

      iex> Timex.Translator.translate("ru", "weekdays", "Saturday")
      "суббота"

      iex> Timex.Translator.translate("it", "weekdays", "Saturday")
      "Sabato"

      iex> Timex.Translator.translate("invalid_locale", "weekdays", "Saturday")
      "Saturday"

  """
  @spec translate(locale :: String.t(), domain :: String.t(), msgid :: String.t()) :: String.t()
  def translate(locale, domain, msgid) do
    get_domain_text(locale, domain, msgid)
  end

  @doc """
  Translates a string for a given locale and domain, following the pluralization rules of that
  language.

  ## Examples

      iex> Timex.Translator.translate_plural("ru", "relative_time", "in %{count} second", "in %{count} seconds", 5)
      "через 5 секунд"

      iex> Timex.Translator.translate_plural("it", "relative_time", "in %{count} second", "in %{count} seconds", 5)
      "in 5 secondi"

      iex> Timex.Translator.translate_plural("invalid_locale", "relative_time", "in %{count} second", "in %{count} seconds", 5)
      "in 5 seconds"
  """
  @spec translate_plural(
          locale :: String.t(),
          domain :: String.t(),
          msgid :: String.t(),
          msgid_plural :: String.t(),
          n :: integer
        ) :: String.t()
  def translate_plural(locale, domain, msgid, msgid_plural, n) do
    get_plural_domain_text(locale, domain, msgid, msgid_plural, n)
  end

  @doc """
  Returns the active locale for the process in which this function is called
  """
  @spec current_locale() :: String.t()
  def current_locale, do: Gettext.get_locale(Timex.Gettext)

  @doc """
  Returns a map of ordinal weekdays to weekday names, where Monday = 1,
  translated in the given locale
  """
  @spec get_weekdays(locale :: String.t()) :: %{integer() => String.t()}
  def get_weekdays(locale) do
    %{
      1 => get_domain_text(locale, "weekdays", "Monday"),
      2 => get_domain_text(locale, "weekdays", "Tuesday"),
      3 => get_domain_text(locale, "weekdays", "Wednesday"),
      4 => get_domain_text(locale, "weekdays", "Thursday"),
      5 => get_domain_text(locale, "weekdays", "Friday"),
      6 => get_domain_text(locale, "weekdays", "Saturday"),
      7 => get_domain_text(locale, "weekdays", "Sunday")
    }
  end

  @doc """
  Returns a map of ordinal weekdays to weekday abbreviations, where Mon = 1
  """
  @spec get_weekdays_abbreviated(locale :: String.t()) :: %{integer() => String.t()}
  def get_weekdays_abbreviated(locale) do
    %{
      1 => get_domain_text(locale, "weekdays", "Mon"),
      2 => get_domain_text(locale, "weekdays", "Tue"),
      3 => get_domain_text(locale, "weekdays", "Wed"),
      4 => get_domain_text(locale, "weekdays", "Thu"),
      5 => get_domain_text(locale, "weekdays", "Fri"),
      6 => get_domain_text(locale, "weekdays", "Sat"),
      7 => get_domain_text(locale, "weekdays", "Sun")
    }
  end

  @doc false
  def get_weekdays_lookup(locale) do
    %{
      get_domain_text(locale, "weekdays", "Mon") => 1,
      get_domain_text(locale, "weekdays", "Tue") => 2,
      get_domain_text(locale, "weekdays", "Wed") => 3,
      get_domain_text(locale, "weekdays", "Thu") => 4,
      get_domain_text(locale, "weekdays", "Fri") => 5,
      get_domain_text(locale, "weekdays", "Sat") => 6,
      get_domain_text(locale, "weekdays", "Sun") => 7,
      get_domain_text(locale, "weekdays", "Monday") => 1,
      get_domain_text(locale, "weekdays", "Tuesday") => 2,
      get_domain_text(locale, "weekdays", "Wednesday") => 3,
      get_domain_text(locale, "weekdays", "Thursday") => 4,
      get_domain_text(locale, "weekdays", "Friday") => 5,
      get_domain_text(locale, "weekdays", "Saturday") => 6,
      get_domain_text(locale, "weekdays", "Sunday") => 7
    }
  end

  @doc """
  Returns a map of ordinal months to month names
  """
  @spec get_months(locale :: String.t()) :: %{integer() => String.t()}
  def get_months(locale) do
    %{
      1 => get_domain_text(locale, "months", "January"),
      2 => get_domain_text(locale, "months", "February"),
      3 => get_domain_text(locale, "months", "March"),
      4 => get_domain_text(locale, "months", "April"),
      5 => get_domain_text(locale, "months", "May"),
      6 => get_domain_text(locale, "months", "June"),
      7 => get_domain_text(locale, "months", "July"),
      8 => get_domain_text(locale, "months", "August"),
      9 => get_domain_text(locale, "months", "September"),
      10 => get_domain_text(locale, "months", "October"),
      11 => get_domain_text(locale, "months", "November"),
      12 => get_domain_text(locale, "months", "December")
    }
  end

  @doc """
  Returns a map of ordinal months to month abbreviations
  """
  @spec get_months_abbreviated(locale :: String.t()) :: %{integer() => String.t()}
  def get_months_abbreviated(locale) do
    %{
      1 => get_domain_text(locale, "months_abbr", "Jan"),
      2 => get_domain_text(locale, "months_abbr", "Feb"),
      3 => get_domain_text(locale, "months_abbr", "Mar"),
      4 => get_domain_text(locale, "months_abbr", "Apr"),
      5 => get_domain_text(locale, "months_abbr", "May"),
      6 => get_domain_text(locale, "months_abbr", "Jun"),
      7 => get_domain_text(locale, "months_abbr", "Jul"),
      8 => get_domain_text(locale, "months_abbr", "Aug"),
      9 => get_domain_text(locale, "months_abbr", "Sep"),
      10 => get_domain_text(locale, "months_abbr", "Oct"),
      11 => get_domain_text(locale, "months_abbr", "Nov"),
      12 => get_domain_text(locale, "months_abbr", "Dec")
    }
  end

  @doc false
  def get_months_lookup(locale) do
    %{
      get_domain_text(locale, "months", "January") => 1,
      get_domain_text(locale, "months", "February") => 2,
      get_domain_text(locale, "months", "March") => 3,
      get_domain_text(locale, "months", "April") => 4,
      get_domain_text(locale, "months", "May") => 5,
      get_domain_text(locale, "months", "June") => 6,
      get_domain_text(locale, "months", "July") => 7,
      get_domain_text(locale, "months", "August") => 8,
      get_domain_text(locale, "months", "September") => 9,
      get_domain_text(locale, "months", "October") => 10,
      get_domain_text(locale, "months", "November") => 11,
      get_domain_text(locale, "months", "December") => 12,
      get_domain_text(locale, "months_abbr", "Jan") => 1,
      get_domain_text(locale, "months_abbr", "Feb") => 2,
      get_domain_text(locale, "months_abbr", "Mar") => 3,
      get_domain_text(locale, "months_abbr", "Apr") => 4,
      get_domain_text(locale, "months_abbr", "May") => 5,
      get_domain_text(locale, "months_abbr", "Jun") => 6,
      get_domain_text(locale, "months_abbr", "Jul") => 7,
      get_domain_text(locale, "months_abbr", "Aug") => 8,
      get_domain_text(locale, "months_abbr", "Sep") => 9,
      get_domain_text(locale, "months_abbr", "Oct") => 10,
      get_domain_text(locale, "months_abbr", "Nov") => 11,
      get_domain_text(locale, "months_abbr", "Dec") => 12
    }
  end

  @doc """
  Returns a map of day period types to translated day period names

  ## Examples

      iex> day_periods = Timex.Translator.get_day_periods("en")
      ...> {day_periods[:am], day_periods[:AM]}
      {"am", "AM"}
  """
  @spec get_day_periods(locale :: String.t()) :: %{atom() => String.t()}
  def get_day_periods(locale) do
    %{
      :AM => get_domain_text(locale, "day_periods", "AM"),
      :am => get_domain_text(locale, "day_periods", "am"),
      :PM => get_domain_text(locale, "day_periods", "PM"),
      :pm => get_domain_text(locale, "day_periods", "pm")
    }
  end

  @doc false
  def get_day_periods_lower(locale) do
    [
      get_domain_text(locale, "day_periods", "am"),
      get_domain_text(locale, "day_periods", "pm")
    ]
  end

  @doc false
  def get_day_periods_upper(locale) do
    [
      get_domain_text(locale, "day_periods", "AM"),
      get_domain_text(locale, "day_periods", "PM")
    ]
  end

  @doc false
  def get_day_periods_lookup(locale) do
    %{
      get_domain_text(locale, "day_periods", "AM") => :AM,
      get_domain_text(locale, "day_periods", "am") => :am,
      get_domain_text(locale, "day_periods", "PM") => :PM,
      get_domain_text(locale, "day_periods", "pm") => :pm
    }
  end

  @spec get_domain_text(locale :: String.t(), domain :: String.t(), msgid :: String.t()) ::
          String.t()
  defp get_domain_text(locale, domain, msgid) do
    Gettext.with_locale(Timex.Gettext, locale, fn ->
      Gettext.dgettext(Timex.Gettext, domain, msgid, %{})
    end)
  end

  @spec get_plural_domain_text(
          locale :: String.t(),
          domain :: String.t(),
          msgid :: String.t(),
          msgid_plural :: String.t(),
          n :: integer
        ) :: String.t()
  defp get_plural_domain_text(locale, domain, msgid, msgid_plural, n) do
    Gettext.with_locale(Timex.Gettext, locale, fn ->
      Gettext.dngettext(Timex.Gettext, domain, msgid, msgid_plural, n, %{})
    end)
  end

  ### After this point, all gettext calls are here for use with compile-time tooling

  dngettext("units", "%{count} nanosecond", "%{count} nanoseconds", 0)
  dngettext("units", "%{count} microsecond", "%{count} microseconds", 0)
  dngettext("units", "%{count} millisecond", "%{count} milliseconds", 0)
  dngettext("units", "%{count} second", "%{count} seconds", 0)
  dngettext("units", "%{count} minute", "%{count} minutes", 0)
  dngettext("units", "%{count} hour", "%{count} hours", 0)
  dngettext("units", "%{count} day", "%{count} days", 0)
  dngettext("units", "%{count} week", "%{count} weeks", 0)
  dngettext("units", "%{count} month", "%{count} months", 0)
  dngettext("units", "%{count} year", "%{count} years", 0)

  dgettext("day_periods", "AM")
  dgettext("day_periods", "am")
  dgettext("day_periods", "PM")
  dgettext("day_periods", "pm")

  dgettext("weekdays", "Mon")
  dgettext("weekdays", "Tue")
  dgettext("weekdays", "Wed")
  dgettext("weekdays", "Thu")
  dgettext("weekdays", "Fri")
  dgettext("weekdays", "Sat")
  dgettext("weekdays", "Sun")

  dgettext("weekdays", "Monday")
  dgettext("weekdays", "Tuesday")
  dgettext("weekdays", "Wednesday")
  dgettext("weekdays", "Thursday")
  dgettext("weekdays", "Friday")
  dgettext("weekdays", "Saturday")
  dgettext("weekdays", "Sunday")

  dgettext("months_abbr", "Jan")
  dgettext("months_abbr", "Feb")
  dgettext("months_abbr", "Mar")
  dgettext("months_abbr", "Apr")
  dgettext("months_abbr", "May")
  dgettext("months_abbr", "Jun")
  dgettext("months_abbr", "Jul")
  dgettext("months_abbr", "Aug")
  dgettext("months_abbr", "Sep")
  dgettext("months_abbr", "Oct")
  dgettext("months_abbr", "Nov")
  dgettext("months_abbr", "Dec")

  dgettext("months", "January")
  dgettext("months", "February")
  dgettext("months", "March")
  dgettext("months", "April")
  dgettext("months", "May")
  dgettext("months", "June")
  dgettext("months", "July")
  dgettext("months", "August")
  dgettext("months", "September")
  dgettext("months", "October")
  dgettext("months", "November")
  dgettext("months", "December")

  # relative years
  dgettext("relative_time", "last year")
  dgettext("relative_time", "this year")
  dgettext("relative_time", "next year")
  dngettext("relative_time", "in %{count} year", "in %{count} years", 0)
  dngettext("relative_time", "%{count} year ago", "%{count} years ago", 0)
  # relative months
  dgettext("relative_time", "last month")
  dgettext("relative_time", "this month")
  dgettext("relative_time", "next month")
  dngettext("relative_time", "in %{count} month", "in %{count} months", 0)
  dngettext("relative_time", "%{count} month ago", "%{count} months ago", 0)
  # relative weeks
  dgettext("relative_time", "last week")
  dgettext("relative_time", "this week")
  dgettext("relative_time", "next week")
  dngettext("relative_time", "in %{count} week", "in %{count} weeks", 0)
  dngettext("relative_time", "%{count} week ago", "%{count} weeks ago", 0)
  # relative days
  dgettext("relative_time", "yesterday")
  dgettext("relative_time", "today")
  dgettext("relative_time", "tomorrow")
  dngettext("relative_time", "in %{count} day", "in %{count} days", 0)
  dngettext("relative_time", "%{count} day ago", "%{count} days ago", 0)
  # relative weekdays
  dgettext("relative_time", "last monday")
  dgettext("relative_time", "this monday")
  dgettext("relative_time", "next monday")
  dgettext("relative_time", "last tuesday")
  dgettext("relative_time", "this tuesday")
  dgettext("relative_time", "next tuesday")
  dgettext("relative_time", "last wednesday")
  dgettext("relative_time", "this wednesday")
  dgettext("relative_time", "next wednesday")
  dgettext("relative_time", "last thursday")
  dgettext("relative_time", "this thursday")
  dgettext("relative_time", "next thursday")
  dgettext("relative_time", "last friday")
  dgettext("relative_time", "this friday")
  dgettext("relative_time", "next friday")
  dgettext("relative_time", "last saturday")
  dgettext("relative_time", "this saturday")
  dgettext("relative_time", "next saturday")
  dgettext("relative_time", "last sunday")
  dgettext("relative_time", "this sunday")
  dgettext("relative_time", "next sunday")
  # relative hours
  dngettext("relative_time", "in %{count} hour", "in %{count} hours", 0)
  dngettext("relative_time", "%{count} hour ago", "%{count} hours ago", 0)
  # relative minutes
  dngettext("relative_time", "in %{count} minute", "in %{count} minutes", 0)
  dngettext("relative_time", "%{count} minute ago", "%{count} minutes ago", 0)
  # relative seconds
  dngettext("relative_time", "in %{count} second", "in %{count} seconds", 0)
  dngettext("relative_time", "%{count} second ago", "%{count} seconds ago", 0)
  # relative now
  dgettext("relative_time", "now")

  # symbols
  # decimal
  dgettext("symbols", ".")
  # group
  dgettext("symbols", ",")
  # list
  dgettext("symbols", ";")
  # plus
  dgettext("symbols", "+")
  # minus
  dgettext("symbols", "-")
  # exponent
  dgettext("symbols", "E")
  # time separator
  dgettext("symbols", ":")

  # numbers
  # decimal format
  dgettext("numbers", "#,##0.###")
end

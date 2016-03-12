defmodule Timex.Translator do
  import Timex.Gettext

  @doc """
  This macro sets the locale during execution of a given block of code.
  """
  defmacro with_locale(locale, do: block) do
    quote do
      old_locale = Gettext.get_locale(Timex.Gettext)
      Gettext.put_locale(Timex.Gettext, unquote(locale))
      result = unquote(block)
      Gettext.put_locale(Timex.Gettext, old_locale)
      result
    end
  end

  @doc """
  Translates a string for a given locale and domain.

  ## Examples

  iex> Timex.Translator.translate("ru_RU", "units", "year")
  "год"

  iex> Timex.Translator.translate("invalid_locale", "units", "year")
  "year"

  """
  @spec translate(locale :: String.t, domain :: String.t, msgid :: String.t) :: String.t
  def translate(locale, domain, msgid) do
    get_domain_text(locale, domain, msgid)
  end

  @doc """
  Same as translate/3, except takes bindings for use in an interpolated translation

  ## Examples

  iex> Timex.Translator.translate("ru_RU", "relative_time", "in %{n} seconds", n: 5)
  "через 5 секунды"

  iex> Timex.Translator.translate("invalid_locale", "relative_time", "in %{n} seconds", n: 5)
  "in 5 seconds"
  """
  @spec translate(locale :: String.t, domain :: String.t, msgid :: String.t, bindings :: Map.t) :: String.t
  def translate(locale, domain, msgid, bindings) do
    get_domain_text(locale, domain, msgid, bindings)
  end

  @doc """
  Returns the active locale for the process in which this function is called
  """
  @spec current_locale() :: String.t
  def current_locale, do: Gettext.get_locale(Timex.Gettext)

  @doc """
  Returns the currently configured default locale. If not set, "en" is used.
  """
  @spec default_locale() :: String.t
  def default_locale, do: Application.get_env(:timex, :default_locale, "en")

  @doc """
  Returns a map of ordinal weekdays to weekday names, where Monday = 1,
  translated in the given locale
  """
  @spec get_weekdays(locale :: String.t) :: %{integer() => String.t}
  def get_weekdays(locale) do
    %{1 => get_domain_text(locale, "weekdays", "Monday"),
      2 => get_domain_text(locale, "weekdays", "Tuesday"),
      3 => get_domain_text(locale, "weekdays", "Wednesday"),
      4 => get_domain_text(locale, "weekdays", "Thursday"),
      5 => get_domain_text(locale, "weekdays", "Friday"),
      6 => get_domain_text(locale, "weekdays", "Saturday"),
      7 => get_domain_text(locale, "weekdays", "Sunday")}
  end

  @doc """
  Returns a map of ordinal weekdays to weekday abbreviations, where Mon = 1
  """
  @spec get_weekdays_abbreviated(locale :: String.t) :: %{integer() => String.t}
  def get_weekdays_abbreviated(locale) do
    %{1 => get_domain_text(locale, "weekdays", "Mon"),
      2 => get_domain_text(locale, "weekdays", "Tue"),
      3 => get_domain_text(locale, "weekdays", "Wed"),
      4 => get_domain_text(locale, "weekdays", "Thu"),
      5 => get_domain_text(locale, "weekdays", "Fri"),
      6 => get_domain_text(locale, "weekdays", "Sat"),
      7 => get_domain_text(locale, "weekdays", "Sun")}
  end

  @doc """
  Returns a map of ordinal months to month names
  """
  @spec get_months(locale :: String.t) :: %{integer() => String.t}
  def get_months(locale) do
    %{1 => get_domain_text(locale, "months", "January"),
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
      12 => get_domain_text(locale, "months", "December")}
  end


  @doc """
  Returns a map of ordinal months to month abbreviations
  """
  @spec get_months_abbreviated(locale :: String.t) :: %{integer() => String.t}
  def get_months_abbreviated(locale) do
    %{1 => get_domain_text(locale, "months", "Jan"),
      2 => get_domain_text(locale, "months", "Feb"),
      3 => get_domain_text(locale, "months", "Mar"),
      4 => get_domain_text(locale, "months", "Apr"),
      5 => get_domain_text(locale, "months", "May"),
      6 => get_domain_text(locale, "months", "Jun"),
      7 => get_domain_text(locale, "months", "Jul"),
      8 => get_domain_text(locale, "months", "Aug"),
      9 => get_domain_text(locale, "months", "Sep"),
      10 => get_domain_text(locale, "months", "Oct"),
      11 => get_domain_text(locale, "months", "Nov"),
      12 => get_domain_text(locale, "months", "Dec")}
  end

  @doc """
  Returns a map of day period types to translated day period names

  ## Examples

      iex> day_periods = Timex.Translator.get_day_periods("en")
      ...> {day_periods[:am], day_periods[:AM]}
      {"am", "AM"}
  """
  @spec get_day_periods(locale :: String.t) :: %{atom() => String.t}
  def get_day_periods(locale) do
    %{:AM => get_domain_text(locale, "day_periods", "AM"),
      :am => get_domain_text(locale, "day_periods", "am"),
      :PM => get_domain_text(locale, "day_periods", "PM"),
      :pm => get_domain_text(locale, "day_periods", "pm")}
  end

  @doc """
  Returns a map of unit types to translated unit names

  ## Examples

      iex> units = Timex.Translator.get_units("en")
      ...> {units[:second], units[:years]}
      {"second", "years"}
  """
  @spec get_units(locale :: String.t) :: %{atom() => String.t}
  def get_units(locale) do
    %{:nanosecond => get_domain_text(locale, "units", "nanosecond"),
      :nanoseconds => get_domain_text(locale, "units", "nanoseconds"),
      :microsecond => get_domain_text(locale, "units", "microsecond"),
      :microseconds => get_domain_text(locale, "units", "microseconds"),
      :millisecond => get_domain_text(locale, "units", "millisecond"),
      :milliseconds => get_domain_text(locale, "units", "milliseconds"),
      :second => get_domain_text(locale, "units", "second"),
      :seconds => get_domain_text(locale, "units", "seconds"),
      :minute => get_domain_text(locale, "units", "minute"),
      :minutes => get_domain_text(locale, "units", "minutes"),
      :hour => get_domain_text(locale, "units", "hour"),
      :hours => get_domain_text(locale, "units", "hours"),
      :day => get_domain_text(locale, "units", "day"),
      :days => get_domain_text(locale, "units", "days"),
      :week => get_domain_text(locale, "units", "week"),
      :weeks => get_domain_text(locale, "units", "weeks"),
      :month => get_domain_text(locale, "units", "month"),
      :months => get_domain_text(locale, "units", "months"),
      :year => get_domain_text(locale, "units", "year"),
      :years => get_domain_text(locale, "units", "years")}
  end

  @doc """
  Returns a map of symbol names to symbol strings for the given locale
  """
  @spec get_symbols(String.t) :: %{atom() => String.t}
  def get_symbols(locale) do
    %{:decimal        => get_domain_text(locale, "symbols", "."),
      :group          => get_domain_text(locale, "symbols", ","),
      :list           => get_domain_text(locale, "symbols", ";"),
      :plus           => get_domain_text(locale, "symbols", "+"),
      :minus          => get_domain_text(locale, "symbols", "-"),
      :exponent       => get_domain_text(locale, "symbols", "E"),
      :time_separator => get_domain_text(locale, "symbols", ":")}
  end

  @spec get_domain_text(locale :: String.t, domain :: String.t, msgid :: String.t) :: String.t
  defp get_domain_text(locale, domain, msgid) do
    case Timex.Gettext.lgettext(locale, domain, msgid) do
      {:ok, translated}   -> translated
      {:default, default} -> default
    end
  end
  @spec get_domain_text(locale :: String.t, domain :: String.t, msgid :: String.t, Map.t) :: String.t
  defp get_domain_text(locale, domain, msgid, bindings) do
    case Timex.Gettext.lgettext(locale, domain, msgid, Enum.into(bindings, %{})) do
      {:ok, translated}   -> translated
      {:default, default} -> default
    end
  end

  ### After this point, all gettext calls are here for use with compile-time tooling

  dgettext "units", "nanosecond"
  dgettext "units", "nanoseconds"
  dgettext "units", "microsecond"
  dgettext "units", "microseconds"
  dgettext "units", "millisecond"
  dgettext "units", "milliseconds"
  dgettext "units", "second"
  dgettext "units", "seconds"
  dgettext "units", "minute"
  dgettext "units", "minutes"
  dgettext "units", "hour"
  dgettext "units", "hours"
  dgettext "units", "day"
  dgettext "units", "days"
  dgettext "units", "week"
  dgettext "units", "weeks"
  dgettext "units", "month"
  dgettext "units", "months"
  dgettext "units", "year"
  dgettext "units", "years"

  dgettext "day_periods", "AM"
  dgettext "day_periods", "am"
  dgettext "day_periods", "PM"
  dgettext "day_periods", "pm"

  dgettext "weekdays", "Mon"
  dgettext "weekdays", "Tue"
  dgettext "weekdays", "Wed"
  dgettext "weekdays", "Thu"
  dgettext "weekdays", "Fri"
  dgettext "weekdays", "Sat"
  dgettext "weekdays", "Sun"

  dgettext "weekdays", "Monday"
  dgettext "weekdays", "Tuesday"
  dgettext "weekdays", "Wednesday"
  dgettext "weekdays", "Thursday"
  dgettext "weekdays", "Friday"
  dgettext "weekdays", "Saturday"
  dgettext "weekdays", "Sunday"

  dgettext "months", "Jan"
  dgettext "months", "Feb"
  dgettext "months", "Mar"
  dgettext "months", "Apr"
  dgettext "months", "May"
  dgettext "months", "Jun"
  dgettext "months", "Jul"
  dgettext "months", "Aug"
  dgettext "months", "Sep"
  dgettext "months", "Oct"
  dgettext "months", "Nov"
  dgettext "months", "Dec"

  dgettext "months", "January"
  dgettext "months", "February"
  dgettext "months", "March"
  dgettext "months", "April"
  dgettext "months", "May"
  dgettext "months", "June"
  dgettext "months", "July"
  dgettext "months", "August"
  dgettext "months", "September"
  dgettext "months", "October"
  dgettext "months", "November"
  dgettext "months", "December"

  # relative years
  dgettext"relative_time", "last year"
  dgettext"relative_time", "this year"
  dgettext"relative_time", "next year"
  dgettext"relative_time", "in %{n} year", n: 0
  dgettext"relative_time", "in %{n} years", n: 0
  dgettext"relative_time", "%{n} year ago", n: 0
  dgettext"relative_time", "%{n} years ago", n: 0
  # relative months
  dgettext "relative_time", "last month", n: 0
  dgettext "relative_time", "this month", n: 0
  dgettext "relative_time", "next month", n: 0
  dgettext "relative_time", "in %{n} month", n: 0
  dgettext "relative_time", "in %{n} months", n: 0
  dgettext "relative_time", "%{n} month ago", n: 0
  dgettext "relative_time", "%{n} months ago", n: 0
  # relative weeks
  dgettext "relative_time", "last week"
  dgettext "relative_time", "this week"
  dgettext "relative_time", "next week"
  dgettext "relative_time", "in %{n} week", n: 0
  dgettext "relative_time", "in %{n} weeks", n: 0
  dgettext "relative_time", "%{n} week ago", n: 0
  dgettext "relative_time", "%{n} weeks ago", n: 0
  # relative days
  dgettext "relative_time", "yesterday"
  dgettext "relative_time", "today"
  dgettext "relative_time", "tomorrow"
  dgettext "relative_time", "in %{n} day", n: 0
  dgettext "relative_time", "in %{n} days", n: 0
  dgettext "relative_time", "%{n} day ago", n: 0
  dgettext "relative_time", "%{n} days ago", n: 0
  # relative weekdays
  dgettext "relative_time", "last monday"
  dgettext "relative_time", "this monday"
  dgettext "relative_time", "next monday"
  dgettext "relative_time", "last tuesday"
  dgettext "relative_time", "this tuesday"
  dgettext "relative_time", "next tuesday"
  dgettext "relative_time", "last wednesday"
  dgettext "relative_time", "this wednesday"
  dgettext "relative_time", "next wednesday"
  dgettext "relative_time", "last thursday"
  dgettext "relative_time", "this thursday"
  dgettext "relative_time", "next thursday"
  dgettext "relative_time", "last friday"
  dgettext "relative_time", "this friday"
  dgettext "relative_time", "next friday"
  dgettext "relative_time", "last saturday"
  dgettext "relative_time", "this saturday"
  dgettext "relative_time", "next saturday"
  dgettext "relative_time", "last sunday"
  dgettext "relative_time", "this sunday"
  dgettext "relative_time", "next sunday"
  # relative hours
  dgettext "relative_time", "in %{n} hour", n: 0
  dgettext "relative_time", "in %{n} hours", n: 0
  dgettext "relative_time", "%{n} hour ago", n: 0
  dgettext "relative_time", "%{n} hours ago", n: 0
  # relative minutes
  dgettext "relative_time", "in %{n} minute", n: 0
  dgettext "relative_time", "in %{n} minutes", n: 0
  dgettext "relative_time", "%{n} minute ago", n: 0
  dgettext "relative_time", "%{n} minutes ago", n: 0
  # relative seconds
  dgettext "relative_time", "in %{n} second", n: 0
  dgettext "relative_time", "in %{n} seconds", n: 0
  dgettext "relative_time", "%{n} second ago", n: 0
  dgettext "relative_time", "%{n} seconds ago", n: 0

  # symbols
  dgettext "symbols", "." # decimal
  dgettext "symbols", "," # group
  dgettext "symbols", ";" # list
  dgettext "symbols", "+" # plus
  dgettext "symbols", "-" # minus
  dgettext "symbols", "E" # exponent
  dgettext "symbols", ":" # time separator

  # numbers
  dgettext "numbers", "#,##0.###" # decimal format


end

defmodule Timex.DateFormat.Formatters.Formatter do
  use Behaviour

  alias Timex.Date
  alias Timex.Time
  alias Timex.DateTime
  alias Timex.Timezone
  alias Timex.DateFormat.FormatError
  alias Timex.DateFormat.Formatters.DefaultFormatter
  alias Timex.Parsers.DateFormat.Directive

  defcallback tokenize(format_string :: String.t) :: {:ok, [%Directive{}]} | {:error, term}
  defcallback format(date :: %DateTime{}, format_string :: String.t)  :: {:ok, String.t} | {:error, term}
  defcallback format!(date :: %DateTime{}, format_string :: String.t) :: String.t | no_return

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Timex.DateFormat.Formatters.Formatter

      import Timex.DateFormat.Formatters.Formatter, only: [format_token: 2]
    end
  end

  @doc """
  Formats a DateTime struct as a string, using the provided format
  string and formatter. If a formatter is not provided, the formatter
  used is `Timex.DateFormat.Formatters.DefaultFormatter`.

  If an error is encountered during formatting, `format!` will raise.
  """
  @spec format!(%DateTime{}, String.t, __MODULE__ | nil) :: String.t | no_return
  def format!(%DateTime{} = date, format_string, formatter \\ DefaultFormatter)
    when is_binary(format_string) and is_atom(formatter)
    do
      case format(date, format_string, formatter) do
        {:ok, result}    -> result
        {:error, reason} -> raise FormatError, message: reason
      end
  end

  @doc """
  Formats a DateTime struct as a string, using the provided format
  string and formatter. If a formatter is not provided, the formatter
  used is `Timex.DateFormat.Formatters.DefaultFormatter`.
  """
  @spec format(%DateTime{}, String.t, __MODULE__ | nil) :: {:ok, String.t} | {:error, term}
  def format(%DateTime{} = date, format_string, formatter \\ DefaultFormatter)
    when is_binary(format_string) and is_atom(formatter),
    do: formatter.format(date, format_string)

  @doc """
  Validates the provided format string, using the provided formatter,
  or if none is provided, the default formatter. Returns `:ok` when valid, 
  or `{:error, reason}` if not valid.
  """
  @spec validate(String.t, __MODULE__ | nil) :: :ok | {:error, term}
  def validate(format_string, formatter \\ DefaultFormatter) when is_binary(format_string) do
    try do
      case formatter.tokenize(format_string) do
        {:error, _} = error ->
          error
        directives when is_list(directives) ->
          if Enum.any?(directives, fn dir -> dir.type != :char end) do
            :ok
          else
            {:error, "There were no formatting directives in the provided string."}
          end
        _ ->
          raise FormatError, message: "Invalid tokenization result!"
      end
    rescue
      x -> {:error, x}
    end
  end

  @doc """
  Given a token (as found in `Timex.Parsers.Directive`), and a DateTime struct,
  produce a string representation of the token using values from the struct.
  """
  @spec format_token(atom, %DateTime{}) :: String.t
  def format_token(token, date)

  # Years
  def format_token(:year4,      %DateTime{year: year}), do: "#{year}"
  def format_token(:year2,      %DateTime{year: year}), do: "#{rem(year, 100)}"
  def format_token(:century,    %DateTime{year: year}), do: "#{div(year, 100)}"
  def format_token(:iso_year4,  %DateTime{} = date) do
    {iso_year, _} = date |> Date.iso_week
    "#{iso_year}"
  end
  def format_token(:iso_year2,  %DateTime{} = date) do
    {iso_year, _} = date |> Date.iso_week
    "#{rem(iso_year, 100)}"
  end
  # Months
  def format_token(:month,      %DateTime{month: month}), do: "#{month}"
  def format_token(:mshort,     %DateTime{month: month}), do: Date.month_shortname(month)
  def format_token(:mfull,      %DateTime{month: month}), do: Date.month_name(month)
  # Days
  def format_token(:day,        %DateTime{day: day}), do: "#{day}"
  def format_token(:oday,       %DateTime{} = date),  do: "#{Date.day(date)}"
  # Weeks
  def format_token(:iso_weeknum, %DateTime{} = date), do: "#{{_, week} = Date.iso_week(date); week}"
  def format_token(:week_mon, %DateTime{} = date),    do: "#{{_, week} = Date.iso_week(date); week}"
  def format_token(:week_sun, %DateTime{year: year} = date) do
    jan1_weekday = Date.from({year, 1, 1}) |> Date.weekday |> rem(7)
    first_monday = rem(7 - jan1_weekday, 7) + 1
    week_num     = div(Date.day(date) - first_monday + 7, 7)
    "#{week_num}"
  end
  def format_token(:wday_mon, %DateTime{} = date), do: "#{Date.weekday(date)}"
  def format_token(:wday_sun, %DateTime{} = date), do: "#{Date.weekday(date) - 1}"
  def format_token(:wdshort, %DateTime{} = date),  do: "#{Date.weekday(date) |> Date.day_shortname}"
  def format_token(:wdfull, %DateTime{} = date),   do: "#{Date.weekday(date) |> Date.day_name}"
  # Hours
  def format_token(:hour24, %DateTime{hour: hour}),     do: "#{hour}"
  def format_token(:hour12, %DateTime{hour: hour}),     do: "#{{h, _} = Time.to_12hour_clock(hour); h}"
  def format_token(:min, %DateTime{minute: min}),       do: "#{min}"
  def format_token(:sec, %DateTime{second: sec}),       do: "#{sec}"
  def format_token(:sec_fractional, %DateTime{ms: 0}),  do: <<>>
  def format_token(:sec_fractional, %DateTime{ms: ms})
    when ms < 10, do: ".00#{ms}"
  def format_token(:sec_fractional, %DateTime{ms: ms})
    when ms < 100, do: ".0#{ms}"
  def format_token(:sec_fractional, %DateTime{ms: ms}),
    do: ".#{ms}"
  def format_token(:sec_epoch, %DateTime{} = date),     do: "#{Date.to_secs(date, :epoch)}"
  def format_token(:am, %DateTime{hour: hour}),         do: "#{{_, am_pm} = Time.to_12hour_clock(hour); Atom.to_string(am_pm)}"
  def format_token(:AM, %DateTime{} = date),            do: format_token(:am, date) |> String.upcase
  # Timezones
  def format_token(:zname, %DateTime{timezone: tz} = date) do
    case Timezone.Dst.is_dst?(date) do
      true -> tz.dst_abbreviation
      _    -> tz.standard_abbreviation
    end
  end
  def format_token(:zoffs, %DateTime{timezone: tz} = date) do
    offset = case Timezone.Dst.is_dst?(date) do
      true -> ((tz.gmt_offset_std + tz.gmt_offset_dst) / 60) |> trunc
      _    -> (tz.gmt_offset_std / 60) |> trunc
    end
    cond do
      offset < 0 and offset > -10   -> "-0#{offset * -1}00"
      offset < 0 and offset > -100  -> "-#{offset * -1}00"
      offset < 0 and offset > -1000 -> "-#{offset * -1}0"
      offset == 0                   -> "+0000"
      offset < 0                    -> "#{offset}"
      offset > 0 and offset < 10    -> "+0#{offset}00"
      offset > 0 and offset < 100   -> "+#{offset}00"
      offset > 0 and offset < 1000  -> "+#{offset}0"
      true                          -> "+#{offset}"
    end
  end
  def format_token(:zoffs_colon, %DateTime{} = date) do
    offset = format_token(:zoffs, date) |> String.split("", [trim: true, parts: 2])
    [qualifier, <<hour::binary-size(2), min::binary-size(2)>>] = offset
    <<qualifier::binary, hour::binary, ?:, min::binary>>
  end
  def format_token(:zoffs_sec, %DateTime{} = date) do
    offset = format_token(:zoffs, date) |> String.split("", [trim: true, parts: 2])
    [qualifier, <<hour::binary-size(2), min::binary-size(2)>>] = offset
    <<qualifier::binary, hour::binary, ?:, min::binary, ?:, ?0, ?0>>
  end
  def format_token(token, %DateTime{}) do
    {:error, "Unsupported token: #{token}"}
  end
  def format_token(_, _) do
    {:error, "Date provided to format_token must be of type %Timex.DateTime{}!"}
  end
end
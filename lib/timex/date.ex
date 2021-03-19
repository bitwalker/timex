defmodule Timex.Date do
  if Version.compare(System.version(), "1.11.0") == :lt do
    @doc false
    def new!(year, month, day, calendar \\ Calendar.ISO) do
      case Date.new(year, month, day, calendar) do
        {:ok, value} ->
          value

        {:error, reason} ->
          raise ArgumentError, "cannot build date, reason: #{inspect(reason)}"
      end
    end

    @doc false
    def beginning_of_week(date, starting_on \\ :default)

    def beginning_of_week(%{calendar: Calendar.ISO} = date, starting_on) do
      %{year: year, month: month, day: day} = date
      iso_days = Calendar.ISO.date_to_iso_days(year, month, day)

      {year, month, day} =
        case iso_days_to_day_of_week(iso_days, starting_on) do
          1 ->
            {year, month, day}

          day_of_week ->
            Calendar.ISO.date_from_iso_days(iso_days - day_of_week + 1)
        end

      %Date{calendar: Calendar.ISO, year: year, month: month, day: day}
    end

    def beginning_of_week(%{calendar: calendar} = date, starting_on) do
      %{year: year, month: month, day: day} = date

      case calendar.day_of_week(year, month, day, starting_on) do
        {day_of_week, day_of_week, _} ->
          %Date{calendar: calendar, year: year, month: month, day: day}

        {day_of_week, first_day_of_week, _} ->
          Date.add(date, -(day_of_week - first_day_of_week))
      end
    end

    @doc false
    def end_of_week(date, starting_on \\ :default)

    def end_of_week(%{calendar: Calendar.ISO} = date, starting_on) do
      %{year: year, month: month, day: day} = date
      iso_days = Calendar.ISO.date_to_iso_days(year, month, day)

      {year, month, day} =
        case iso_days_to_day_of_week(iso_days, starting_on) do
          7 ->
            {year, month, day}

          day_of_week ->
            Calendar.ISO.date_from_iso_days(iso_days + 7 - day_of_week)
        end

      %Date{calendar: Calendar.ISO, year: year, month: month, day: day}
    end

    def end_of_week(%{calendar: calendar} = date, starting_on) do
      %{year: year, month: month, day: day} = date

      case calendar.day_of_week(year, month, day, starting_on) do
        {day_of_week, _, day_of_week} ->
          %Date{calendar: calendar, year: year, month: month, day: day}

        {day_of_week, _, last_day_of_week} ->
          Date.add(date, last_day_of_week - day_of_week)
      end
    end

    @doc false
    def end_of_month(%{year: year, month: month, calendar: calendar} = date) do
      day = Date.days_in_month(date)
      %Date{year: year, month: month, day: day, calendar: calendar}
    end

    @doc false
    def day_of_week(%{year: y, month: m, day: d}, starting_on \\ :default) do
      with {dow, _, _} <- day_of_week(y, m, d, starting_on), do: dow
    end

    @doc false
    def day_of_week(year, month, day, starting_on) do
      iso_days = Calendar.ISO.date_to_iso_days(year, month, day)
      {iso_days_to_day_of_week(iso_days, starting_on), 1, 7}
    end

    @doc false
    def iso_days_to_day_of_week(iso_days, starting_on) do
      Integer.mod(iso_days + day_of_week_offset(starting_on), 7) + 1
    end

    defp day_of_week_offset(:default), do: 5
    defp day_of_week_offset(:wednesday), do: 3
    defp day_of_week_offset(:thursday), do: 2
    defp day_of_week_offset(:friday), do: 1
    defp day_of_week_offset(:saturday), do: 0
    defp day_of_week_offset(:sunday), do: 6
    defp day_of_week_offset(:monday), do: 5
    defp day_of_week_offset(:tuesday), do: 4
  else
    @doc false
    defdelegate new!(year, month, day, calendar \\ Calendar.ISO), to: Date

    @doc false
    defdelegate beginning_of_week(date, starting_on \\ :default), to: Date

    @doc false
    defdelegate end_of_week(date, starting_on \\ :default), to: Date

    @doc false
    defdelegate end_of_month(date), to: Date

    @doc false
    defdelegate day_of_week(date, starting_on \\ :default), to: Date

    @doc false
    defdelegate day_of_week(year, month, day, starting_on), to: Calendar.ISO
  end
end

defmodule Timex.Timezone.Dst do
  @moduledoc """
  Rules for determining if a datetime falls within a daylight savings period.
  """

  alias Timex.Date,         as: Date
  alias Timex.DateTime,     as: DateTime
  alias Timex.TimezoneInfo, as: TimezoneInfo

  @doc """
  Check if the provided datetime is in daylight savings time
  """
  @spec is_dst?(DateTime.t) :: true | false | :ambiguous_time | :doesnt_exist
  def is_dst?(%DateTime{:timezone => %TimezoneInfo{:dst_start_day => :undef}}), do: false
  def is_dst?(%DateTime{:year => year, :month => month, :day => day, :hour => hour, :minute => min, :second => sec, :timezone => tz}) do
    %TimezoneInfo{
      :gmt_offset_dst => dst_shift,
      :dst_start_day => dst_start_rule, :dst_start_time => dst_start_time, 
      :dst_end_day => dst_end_rule, :dst_end_time => dst_end_time 
    } = tz

    dst_start_day = get_dst_day_of_year(dst_start_rule, year)
    dst_end_day   = get_dst_day_of_year(dst_end_rule, year)
    current_day   = get_day_of_year({year, month, day})
    case is_dst_date(dst_start_day, dst_end_day, current_day) do
      :equal_to_start ->
        is_dst_start_time(time_to_minutes({hour, min, sec}), time_to_minutes(dst_start_time), dst_shift)
      :equal_to_end ->
        is_dst_end_time(time_to_minutes({hour, min, sec}), time_to_minutes(dst_end_time), dst_shift)
      result ->
        cond do
          # If DST ends the next day at 00:00, then after 23:00 the day before, we're ambiguous
          dst_end_day - 1 === current_day and time_to_minutes(dst_end_time) == 0 ->
            cond do
              time_to_minutes({hour, min, sec}) >= (23 * 60) -> :ambiguous_time
              true -> result
            end
          # Likewise, if DST started the night before at midnight (24:00), then before 01:00 of the current day, the time doesn't exist
          dst_start_day + 1 === current_day and time_to_minutes(dst_start_time) == (24 * 60) ->
            cond do
              time_to_minutes({hour, min, sec}) < 60 -> :doesnt_exist
              true -> result
            end
          true ->
            result
        end
    end
   end

  defp is_dst_start_time(current_time, start_time, _shift) when current_time < start_time, do: false
  defp is_dst_start_time(current_time, start_time, shift) do
      case (start_time + shift) do
        # When start time is late, say 2400, it rolls over in to the next day with the shift
        shifted when shifted < start_time and current_time < start_time ->
          (current_time + shift) >= shifted
        # When it doesn't roll over, normal checks apply
        shifted when shifted > start_time and current_time >= shifted ->
          true
        shifted when shifted > start_time and current_time < shifted and current_time >= start_time ->
          :doesnt_exist
        _ ->
          :doesnt_exist
      end
  end

  defp is_dst_end_time(current_time, end_time, shift) do
    # Ambigous for the hour before it ends
    case (end_time - shift) do
      # When the end is at 0:00 and the current is >= 0:00, we're out of DST
      shifted when shifted < 0 and current_time >= 0 -> false
      # When the end is at any other point in the day, and the current time is between the shifted and end time, ambigous
      shifted when current_time >= shifted and current_time < end_time ->
        :ambiguous_time
      # When the end is at any other point in the day, and we're less than the shifted time, we're in dst
      shifted when current_time < shifted ->
        true
      # When the end is at any other point in the day, and we're greater than the end_time, we're out of dst
      _ ->
        false
    end
  end

  defp is_dst_date(start_day, _, current_day) when current_day == start_day, do: :equal_to_start
  defp is_dst_date(_, end_day, current_day)   when current_day == end_day,   do: :equal_to_end
  defp is_dst_date(start_day, end_day, current_day) when start_day < end_day and (current_day > start_day and current_day < end_day), do: true
  defp is_dst_date(start_day, end_day, current_day) when start_day < end_day and (current_day < start_day or current_day > end_day),  do: false
  defp is_dst_date(start_day, end_day, current_day) when start_day > end_day and (current_day < start_day and current_day > end_day), do: false
  defp is_dst_date(start_day, end_day, current_day) when start_day > end_day and (current_day > start_day or current_day < end_day),  do: true

  defp get_dst_day_of_year({weekday, day, month}, year) when (weekday == :last) or (weekday == 5) do
    month_num = Date.month_to_num(month)
    day_num   = Date.day_to_num(day)
    get_last_dst(day_num, month_num, year)
  end
  defp get_dst_day_of_year({weekday, day, month}, year) when (weekday > 0) and (weekday <= 4) do
    month_num = Date.month_to_num(month)
    day_num   = Date.day_to_num(day)
    dst_days  = get_day_of_year({year, month_num, 1})
    dst_day   = :calendar.day_of_the_week({year, month_num, 1})
    case (dst_day === day_num) and (weekday === 1) do
      true -> dst_days
      false ->
        adjusted_dst_days = case day_num >= dst_day do
          true ->
            dst_days + (day_num - dst_day)
          false ->
            dst_days + (7 - dst_day) + day_num
        end
        adjusted_dst_days + (weekday - 1) * 7
    end
  end
  defp get_dst_day_of_year(_, _), do: raise(:error, "Invalid weekday")

  defp get_last_dst(day_num, month_num, year) do
    month_last_days      = :calendar.date_to_gregorian_days(year, month_num, 1) + :calendar.last_day_of_the_month(year, month_num)
    month_last_date      = :calendar.gregorian_days_to_date(month_last_days)
    month_last_dayofweek = :calendar.day_of_the_week(month_last_date)
    case month_last_dayofweek > day_num do
      true ->
        month_last_days - (month_last_dayofweek - day_num) - :calendar.date_to_gregorian_days(if year == 0 do 0 else year - 1 end, 12, 31)
      false ->
        month_last_days - month_last_dayofweek - (7 - day_num) - :calendar.date_to_gregorian_days(if year == 0 do 0 else year - 1 end, 12, 31)
    end
  end

  defp get_day_of_year({year, _, _} = date) do
    :calendar.date_to_gregorian_days(date) - :calendar.date_to_gregorian_days(if year == 0 do 0 else year - 1 end, 12, 31)
  end

  defp time_to_minutes({hours, minutes}), do: (hours * 60) + minutes
  defp time_to_minutes({hours, minutes, _}), do: (hours * 60) + minutes

end
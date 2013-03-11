defmodule DateTest do
  use ExUnit.Case, async: true

  test :epoch do
    assert Date.epoch == { {1970,1,1}, {0,0,0} }
    assert Date.to_sec(Date.epoch) == 0
    assert Date.to_days(Date.epoch) == 0
    assert Date.to_sec(Date.epoch, 0) == Date.epoch(:sec)
    assert Date.to_days(Date.epoch, 0) == Date.epoch(:days)
    assert Date.to_timestamp(Date.epoch) == Date.epoch(:timestamp)
  end

  test :iso8601 do
    date = {{2013,3,5},{23,25,19}}
    assert Date.iso_format(date) == "2013-03-05 23:25:19"
  end

  test :rfc1123 do
    date = {{2013,3,5},{23,25,19}}
    assert Date.rfc_format(date) == "Tue, 05 Mar 2013 21:25:19 GMT"
  end

  test :shift_seconds do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = {date,time}

    assert Date.shift(datetime, 0, :sec) == datetime

    assert Date.shift(datetime, 1, :sec) == {date,{23,23,24}}
    assert Date.shift(datetime, 36, :sec) == {date,{23,23,59}}
    assert Date.shift(datetime, 37, :sec) == {date,{23,24,0}}
    assert Date.shift(datetime, 38, :sec) == {date,{23,24,1}}
    assert Date.shift(datetime, 38+60, :sec) == {date,{23,25,1}}
    assert Date.shift(datetime, 38+60*35+58, :sec) == {date,{23,59,59}}
    assert Date.shift(datetime, 38+60*35+59, :sec) == {{2013,3,6},{0,0,0}}
    assert Date.shift(datetime, 38+60*36, :sec) == {{2013,3,6},{0,0,1}}
    assert Date.shift(datetime, 24*3600, :sec) == {{2013,3,6},{23,23,23}}
    assert Date.shift(datetime, 24*3600*365, :sec) == {{2014,3,5},{23,23,23}}

    assert Date.shift(datetime, -1, :sec) == {date,{23,23,22}}
    assert Date.shift(datetime, -23, :sec) == {date,{23,23,0}}
    assert Date.shift(datetime, -24, :sec) == {date,{23,22,59}}
    assert Date.shift(datetime, -23*60, :sec) == {date,{23,0,23}}
    assert Date.shift(datetime, -24*60, :sec) == {date,{22,59,23}}
    assert Date.shift(datetime, -23*3600-23*60-23, :sec) == {date,{0,0,0}}
    assert Date.shift(datetime, -23*3600-23*60-24, :sec) == {{2013,3,4},{23,59,59}}
    assert Date.shift(datetime, -24*3600, :sec) == {{2013,3,4},{23,23,23}}
    assert Date.shift(datetime, -24*3600*365, :sec) == {{2012,3,5},{23,23,23}}
    assert Date.shift(datetime, -24*3600*(365*2 + 1), :sec) == {{2011,3,5},{23,23,23}}   # +1 day for leap year 2012
  end

  test :shift_minutes do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = {date,time}

    assert Date.shift(datetime, 0, :min) == datetime

    assert Date.shift(datetime, 1, :min) == {date,{23,24,23}}
    assert Date.shift(datetime, 36, :min) == {date,{23,59,23}}
    assert Date.shift(datetime, 37, :min) == {{2013,3,6},{0,0,23}}
    assert Date.shift(datetime, 38, :min) == {{2013,3,6},{0,1,23}}
    assert Date.shift(datetime, 60*24*365, :min) == {{2014,3,5},{23,23,23}}

    assert Date.shift(datetime, -1, :min) == {date,{23,22,23}}
    assert Date.shift(datetime, -23, :min) == {date,{23,0,23}}
    assert Date.shift(datetime, -24, :min) == {date,{22,59,23}}
    assert Date.shift(datetime, -23*60-24, :min) == {{2013,3,4},{23,59,23}}
    assert Date.shift(datetime, -60*24*(365*2 + 1), :min) == {{2011,3,5},{23,23,23}}
  end

  test :shift_days do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = { date, time }
    assert Date.shift(datetime, 1, :days) == { {2013,3,6}, time }
  end

  test :shift_months do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = { date, time }
    assert Date.shift(datetime, 3, :months) == { {2013,6,5}, time }
  end

  test :arbitrary_shifts do
    datetime = { {2013,3,5}, {23,23,23} }
    assert Date.shift(datetime, [{3, :months}, {1, :days}]) == { {2013,6,6}, {23,23,23} }

    datetime = { {2012,2,29}, {23,23,23} }
    assert Date.shift(datetime, [{12, :months}]) == { {2013,2,28}, {23,23,23} }
    assert Date.shift(datetime, [{12, :months}, {1, :days}]) == { {2013,3,1}, {23,23,23} }
    assert Date.shift(datetime, [{12, :months}, {36, :min}, {36, :sec}]) == { {2013,2,28}, {23,59,59} }
    assert Date.shift(datetime, [{12, :months}, {36, :min}, {37, :sec}]) == { {2013,3,1}, {0,0,0} }
  end
end

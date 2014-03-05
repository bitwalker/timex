defmodule TimezoneDstTests do
  use ExUnit.Case, async: true
  use Timex

  import Timex.Timezone.Dst, only: [is_dst?: 1]

  test :is_dst? do
    #{"America/Chicago", {"CST", "CST"}, {"CDT", "CDT"}, -360, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    cst = Timezone.get("America/Chicago")

    assert false === Date.from({{2014,1,1}, {10,10,0}}, cst)        |> is_dst?
    assert true  === Date.from({{2014,7,8}, {10,10,0}}, cst)        |> is_dst?
    assert false === Date.from({{2014,3,9}, {1,59,0}}, cst)         |> is_dst?
    assert :doesnt_exist === Date.from({{2014,3,9}, {2,0,0}}, cst)  |> is_dst?
    assert :doesnt_exist === Date.from({{2014,3,9}, {2,15,0}}, cst) |> is_dst?
    assert :doesnt_exist === Date.from({{2014,3,9}, {2,30,0}}, cst) |> is_dst?
    assert :doesnt_exist === Date.from({{2014,3,9}, {2,59,0}}, cst) |> is_dst?
    assert true === Date.from({{2014,3,9}, {3,0,0}}, cst)           |> is_dst?

    assert true === Date.from({{2014,11,2}, {0,59,0}}, cst)            |> is_dst?
    assert :ambiguous_time === Date.from({{2014,11,2}, {1,0,0}}, cst)  |> is_dst?
    assert :ambiguous_time === Date.from({{2014,11,2}, {1,10,0}}, cst) |> is_dst?
    assert :ambiguous_time === Date.from({{2014,11,2}, {1,30,0}}, cst) |> is_dst?
    assert :ambiguous_time === Date.from({{2014,11,2}, {1,59,0}}, cst) |> is_dst?
    assert false === Date.from({{2014,11,2}, {3,0,0}}, cst)            |> is_dst?
  end

  test "when DST starts at hour 24, and ends at hour 0" do
    # DST starts at hour 24, DST ends at hour 0
    #{"Asia/Gaza", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :thu, :mar}, {24, 0}, {4, :fri, :sep}, {0, 0}}, 
    gaza = Timezone.get("Asia/Gaza")
    assert false === Date.from({{2014,3,27}, {23,59,59}}, gaza)           |> is_dst?
    assert :doesnt_exist === Date.from({{2014,3,28}, {0,0,0}}, gaza)      |> is_dst?
    assert :doesnt_exist === Date.from({{2014,3,28}, {0,59,59}}, gaza)    |> is_dst?
    assert :doesnt_exist === Date.from({{2014,3,28}, {0,59,59}}, gaza)    |> is_dst?
    assert true === Date.from({{2014,3,28}, {1,0,0}}, gaza)               |> is_dst?
    assert true === Date.from({{2014,9,25}, {22,59,59}}, gaza)            |> is_dst?
    assert :ambiguous_time === Date.from({{2014,9,25}, {23,0,0}}, gaza)   |> is_dst?
    assert :ambiguous_time === Date.from({{2014,9,25}, {23,59,0}}, gaza)  |> is_dst?
    assert :ambiguous_time === Date.from({{2014,9,25}, {23,59,59}}, gaza) |> is_dst?
    assert false === Date.from({{2014,9,26}, {0,0,0}}, gaza)              |> is_dst?
  end

  test "when DST starts at hour 0, and ends at hour 0" do
    # DST starts at hour 0; DST ends at hour 0.
    # {"Asia/Damascus", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :fri, :mar}, {0, 0}, {:last, :fri, :oct}, {0, 0}}, 
    damascus = Timezone.get("Asia/Damascus")
    assert false === Date.from({{2014,3,27}, {23,59,59}}, damascus)            |> is_dst?
    assert :doesnt_exist === Date.from({{2014,3,28}, {0,0,0}}, damascus)       |> is_dst?
    assert :doesnt_exist === Date.from({{2014,3,28}, {0,59,59}}, damascus)     |> is_dst?
    assert true === Date.from({{2014,3,28}, {1,0,0}}, damascus)                |> is_dst?
    assert true === Date.from({{2014,10,30}, {22,59,59}}, damascus)            |> is_dst?
    assert :ambiguous_time === Date.from({{2014,10,30}, {23,0,0}}, damascus)   |> is_dst?
    assert :ambiguous_time === Date.from({{2014,10,30}, {23,59,59}}, damascus) |> is_dst?
    assert false === Date.from({{2014,10,31}, {0,0,0}}, damascus)              |> is_dst?
  end

  test "inverted DST (starts in fall, ends in spring)" do
    # DST ends before starts (southern hemisphere):
    # {"America/Montevideo", {"UYT", "UYT"}, {"UYST", "UYST"}, -180, 60, {1, :sun, :oct}, {2, 0}, {2, :sun, :mar}, {2, 0}}, 
    montevideo = Timezone.get("America/Montevideo")
    assert true === Date.from({{2014,3,9}, {0,59,59}}, montevideo)            |> is_dst?
    assert :ambiguous_time === Date.from({{2014,3,9}, {1,0,0}}, montevideo)   |> is_dst?
    assert :ambiguous_time === Date.from({{2014,3,9}, {1,59,59}}, montevideo) |> is_dst?
    assert false === Date.from({{2014,3,9}, {2,0,0}}, montevideo)             |> is_dst?
    assert false === Date.from({{2014,10,5}, {1,59,59}}, montevideo)          |> is_dst?
    assert :doesnt_exist === Date.from({{2014,10,5}, {2,0,0}}, montevideo)    |> is_dst?
    assert :doesnt_exist === Date.from({{2014,10,5}, {2,59,59}}, montevideo)  |> is_dst?
    assert true === Date.from({{2014,10,5}, {3,0,0}}, montevideo)             |> is_dst?
   end
end
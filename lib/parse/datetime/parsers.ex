defmodule Timex.Parse.DateTime.Parsers do
  @moduledoc false
  alias Timex.Parse.DateTime.Helpers
  use Combine

  def year4(opts \\ []) do
    min_digits =
      case Keyword.get(opts, :padding) do
        :none ->
          1

        _ ->
          get_in(opts, [:min]) || 1
      end

    max_digits = get_in(opts, [:max]) || 4

    expected_digits =
      case {min_digits, max_digits} do
        {min, min} -> "#{min} digit year"
        {min, max} -> "#{min}-#{max} digit year"
      end

    Helpers.integer(Keyword.put(opts, :max, max_digits))
    |> satisfy(fn year -> year > 0 end)
    |> map(fn year -> [year4: year] end)
    |> label(expected_digits)
  end

  def year2(opts \\ []) do
    min_digits =
      case Keyword.get(opts, :padding) do
        :none ->
          1

        _ ->
          get_in(opts, [:min]) || 1
      end

    max_digits = get_in(opts, [:max]) || 2

    expected_digits =
      case {min_digits, max_digits} do
        {min, min} -> "#{min} digit year"
        {min, max} -> "#{min}-#{max} digit year"
      end

    Helpers.integer(Keyword.put(opts, :max, max_digits))
    |> satisfy(fn year -> year >= 0 end)
    |> map(fn year -> [year2: year] end)
    |> label(expected_digits)
  end

  def century(opts \\ []) do
    Helpers.integer(opts)
    |> map(fn c -> [century: c] end)
    |> label("2 digit century")
  end

  def month2(opts \\ []) do
    min_digits =
      case Keyword.get(opts, :padding) do
        :none ->
          # This may be a one digit month
          1

        _ ->
          get_in(opts, [:min]) || 1
      end

    max_digits = get_in(opts, [:max]) || 2

    expected_digits =
      case {min_digits, max_digits} do
        {min, min} -> "#{min} digit month"
        {min, max} -> "#{min}-#{max} digit month"
      end

    Helpers.integer(Keyword.put(opts, :max, max_digits))
    |> satisfy(fn month -> month in 0..12 end)
    |> map(&Helpers.to_month/1)
    |> label(expected_digits)
  end

  def month_full(_) do
    one_of(word_of(~r/[[:alpha:]]/u), Helpers.months())
    |> map(&Helpers.to_month_num/1)
    |> label("full month name")
  end

  def month_short(_) do
    one_of(word_of(~r/[[:alpha:]]/u), Helpers.months_abbr())
    |> map(&Helpers.to_month_num/1)
    |> label("month abbreviation")
  end

  def day_of_month(opts \\ []) do
    Helpers.integer(opts)
    |> satisfy(fn day -> day >= 1 && day <= 31 end)
    |> map(fn n -> [day: n] end)
    |> label("day of month")
  end

  def day_of_year(opts \\ []) do
    Helpers.integer(opts)
    |> satisfy(fn day -> day >= 1 && day <= 366 end)
    |> map(fn n -> [day_of_year: n] end)
    |> label("day of year")
  end

  def week_of_year_mon(opts \\ []) do
    Helpers.integer(opts)
    |> satisfy(fn week -> week >= 0 && week <= 52 end)
    |> map(fn n -> [week_of_year_mon: n] end)
    |> label("week of year (mon)")
  end

  def week_of_year_sun(opts \\ []) do
    Helpers.integer(opts)
    |> satisfy(fn week -> week >= 0 && week <= 52 end)
    |> map(fn n -> [week_of_year_sun: n] end)
    |> label("week of year (sun)")
  end

  def week_of_year_iso(opts \\ []) do
    Helpers.integer(opts)
    |> satisfy(fn week -> week >= 0 && week <= 53 end)
    |> map(fn n -> [week_of_year_iso: n] end)
    |> label("ISO week of year")
  end

  def weekday(_) do
    fixed_integer(1)
    |> satisfy(fn day -> day >= 1 && day <= 7 end)
    |> map(fn n -> [weekday: n] end)
    |> label("ordinal weekday")
  end

  def weekday_short(_) do
    word_of(~r/[[:alpha:]]/u)
    |> satisfy(&Helpers.is_weekday/1)
    |> map(fn name -> Helpers.to_weekday(name) end)
    |> label("weekday abbreviation")
  end

  def weekday_full(_) do
    word_of(~r/[[:alpha:]]/u)
    |> satisfy(&Helpers.is_weekday/1)
    |> map(fn name -> Helpers.to_weekday(name) end)
    |> label("weekday name")
  end

  def hour24(opts \\ []) do
    Helpers.integer(opts)
    |> satisfy(fn hour -> hour >= 0 && hour <= 24 end)
    |> map(fn hour -> [hour24: hour] end)
    |> label("hour between 0 and 24")
  end

  def hour12(opts \\ []) do
    Helpers.integer(opts)
    |> satisfy(fn hour -> hour >= 1 && hour <= 12 end)
    |> map(fn hour -> [hour12: hour] end)
    |> label("hour between 1 and 12")
  end

  def ampm_lower(_) do
    one_of(word(), Helpers.ampm_lower())
    |> map(&Helpers.to_ampm/1)
    |> label("am/pm")
  end

  def ampm_upper(_) do
    one_of(word(), Helpers.ampm_upper())
    |> map(&Helpers.to_ampm/1)
    |> label("AM/PM")
  end

  def ampm(_) do
    one_of(word(), Helpers.ampm_any())
    |> map(&Helpers.to_ampm/1)
    |> label("am/pm or AM/PM")
  end

  def minute(opts \\ []) do
    Helpers.integer(opts)
    |> satisfy(fn min -> min >= 0 && min <= 59 end)
    |> map(fn min -> [min: min] end)
    |> label("minute")
  end

  def second(opts \\ []) do
    Helpers.integer(opts)
    |> satisfy(fn sec -> sec >= 0 && sec <= 60 end)
    |> map(fn sec -> [sec: sec] end)
    |> label("second")
  end

  def second_fractional(_) do
    map(pair_right(char("."), word_of(~r/\d{1,6}/)), &Helpers.to_sec_ms/1)
    |> label("fractional second")
  end

  def seconds_epoch(opts \\ []) do
    parser =
      case get_in(opts, [:padding]) do
        :spaces -> skip(spaces()) |> integer
        _ -> integer()
      end

    parser
    |> map(fn secs -> [sec_epoch: secs] end)
    |> label("seconds since epoch")
  end

  def microseconds(_) do
    label(map(word_of(~r/\d{1,6}/), &Helpers.parse_microseconds/1), "microseconds")
  end

  def milliseconds(_) do
    label(map(word_of(~r/\d{1,3}/), &Helpers.parse_milliseconds/1), "milliseconds")
  end

  def zname(_) do
    word_of(~r/[\/\w_\-\:]/)
    |> map(fn name -> [zname: name] end)
    |> label("timezone name")
  end

  def zoffs(_) do
    pipe(
      [
        one_of(char(), ["-", "+"]),
        digit(),
        option(digit()),
        option(digit()),
        option(digit())
      ],
      fn xs -> [zoffs: Enum.join(Enum.reject(xs, &is_nil/1))] end
    )
    |> label("timezone offset (+/-hhmm)")
  end

  def zoffs_colon(_) do
    pipe(
      [
        one_of(char(), ["-", "+"]),
        digit(),
        option(digit()),
        char(":"),
        digit(),
        digit()
      ],
      fn xs -> [zoffs_colon: Enum.join(Enum.reject(xs, &is_nil/1))] end
    )
    |> label("timezone offset (+/-hh:mm)")
  end

  def zoffs_sec(_) do
    pipe(
      [
        one_of(char(), ["-", "+"]),
        digit(),
        option(digit()),
        char(":"),
        digit(),
        digit(),
        char(":"),
        digit(),
        digit()
      ],
      fn xs -> [zoffs_sec: Enum.join(Enum.reject(xs, &is_nil/1))] end
    )
    |> label("timezone offset (+/-hh:mm:ss)")
  end

  def iso_date(_) do
    sequence([
      year4(padding: :zeroes, min: 4, max: 4),
      ignore(char("-")),
      month2(padding: :zeroes, min: 2, max: 2),
      ignore(char("-")),
      day_of_month(padding: :zeroes, min: 2, max: 2)
    ])
  end

  def iso_time(_) do
    sequence([
      hour24(padding: :zeroes, min: 2, max: 2),
      ignore(char(":")),
      minute(padding: :zeroes, min: 2, max: 2),
      ignore(char(":")),
      both(
        second(padding: :zeroes, min: 2, max: 2),
        option(second_fractional(padding: :zeroes)),
        fn
          [{:sec, _sec}] = res, nil -> res
          [{:sec, _} = sec], [{:sec_fractional, _} = frac] -> [sec, frac]
        end
      )
    ])
  end

  def iso_week(_) do
    sequence([
      year4(padding: :zeroes),
      ignore(char("-")),
      ignore(char("W")),
      week_of_year_iso(padding: :zeroes)
    ])
  end

  def iso_weekday(opts \\ []) do
    sequence([
      iso_week(opts),
      ignore(char("-")),
      weekday(opts)
    ])
  end

  def iso_ordinal(_) do
    sequence([
      year4(padding: :zeros),
      ignore(char("-")),
      day_of_year(padding: :zeroes)
    ])
  end

  @doc """
  ISO 8601 date/time format with timezone information.

  NOTE: Deprecated. See iso8601_extended for documentation
  """
  def iso8601(_opts \\ []), do: Timex.Parse.DateTime.Parsers.ISO8601Extended.parse()

  @doc """
  ISO 8601 date/time (extended) format with timezone information.
  With zulu: true, assumes UTC timezone.
  Examples:
    2007-08-13T16:48:01+03:00
    2007-08-13T13:48:01Z
  """
  def iso8601_extended(_opts \\ []), do: Timex.Parse.DateTime.Parsers.ISO8601Extended.parse()

  @doc """
  ISO 8601 date/time (basic) format with timezone information.
  With zulu: true, assumes UTC timezone.
  Examples:
    20070813T164801+0300
    20070813T134801Z
  """
  def iso8601_basic(opts \\ []) do
    is_zulu? = get_in(opts, [:zulu])

    parts = [
      sequence([
        year4(padding: :zeroes, min: 4, max: 4),
        month2(padding: :zeroes, min: 2, max: 2),
        day_of_month(padding: :zeroes, min: 2, max: 2)
      ]),
      either(literal(char("T")), literal(space())),
      choice([
        sequence([
          hour24(padding: :zeroes, min: 2, max: 2),
          minute(padding: :zeroes, min: 2, max: 2),
          both(
            second(padding: :zeroes, min: 2, max: 2),
            option(second_fractional(padding: :zeroes)),
            fn
              [{:sec, _sec}] = res, nil -> res
              [{:sec, _} = sec], [{:sec_fractional, _} = frac] -> [sec, frac]
            end
          )
        ]),
        sequence([
          hour24(padding: :zeroes, min: 2, max: 2),
          minute(padding: :zeroes, min: 2, max: 2)
        ]),
        sequence([
          hour24(padding: :zeroes, min: 2, max: 2)
        ])
      ])
    ]

    case is_zulu? do
      true ->
        sequence(parts ++ [map(char("Z"), fn _ -> [zname: "Etc/UTC"] end)])

      _ ->
        sequence(
          parts ++
            [
              choice([
                map(char("Z"), fn _ -> [zname: "Etc/UTC"] end),
                zoffs_sec(opts),
                zoffs(opts)
              ])
            ]
        )
    end
  end

  @doc """
  RFC 822 date/time format with timezone information.
  Examples: `Mon, 05 Jun 14 23:20:59 Y`

  ## From the specification (RE: timezones):

  Time zone may be indicated in several ways.  "UT" is Univer-
  sal  Time  (formerly called "Greenwich Mean Time"); "GMT" is per-
  mitted as a reference to Universal Time.  The  military  standard
  uses  a  single  character for each zone.  "Z" is Universal Time.
  "A" indicates one hour earlier, and "M" indicates 12  hours  ear-
  lier;  "N"  is  one  hour  later, and "Y" is 12 hours later.  The
  letter "J" is not used.  The other remaining two forms are  taken
  from ANSI standard X3.51-1975.  One allows explicit indication of
  the amount of offset from UT; the other uses  common  3-character
  strings for indicating time zones in North America.
  """
  def rfc822(opts \\ []) do
    is_zulu? = get_in(opts, [:zulu])

    parts = [
      option(
        sequence([
          weekday_short(opts),
          literal(string(", "))
        ])
      ),
      day_of_month(padding: :zeroes, min: 1, max: 2),
      literal(space()),
      month_short(opts),
      literal(space()),
      year2(padding: :zeroes),
      literal(space()),
      iso_time(opts)
    ]

    case is_zulu? do
      true ->
        zone_parts = [
          literal(space()),
          map(one_of(word(), ["UT", "GMT", "Z"]), fn _ -> [zname: "Etc/UTC"] end)
        ]

        sequence(parts ++ zone_parts)

      _ ->
        zone_parts = [
          literal(space()),
          choice([
            zname(opts),
            zoffs(opts),
            map(one_of(word(), ["UT", "GMT", "Z"]), fn _ -> [zname: "Etc/UTC"] end),
            map(one_of(char(), ["A", "M", "N", "Y", "J"]), fn
              "A" -> [zoffs: "-0100"]
              "M" -> [zoffs: "-1200"]
              "N" -> [zoffs: "+0100"]
              "Y" -> [zoffs: "+1200"]
              "J" -> []
            end)
          ])
        ]

        sequence(parts ++ zone_parts)
    end
  end

  @doc """
  RFC 1123 date/time format with timezone information.
  With zulu: true, assumes GMT
  Examples:
    Tue, 05 Mar 2013 23:25:19 GMT
    Tue, 05 Mar 2013 23:25:19 +0200
  """
  def rfc1123(opts \\ []) do
    is_zulu? = get_in(opts, [:zulu])

    parts = [
      weekday_short(opts),
      literal(string(", ")),
      day_of_month(padding: :zeroes, min: 1, max: 2),
      literal(space()),
      month_short(opts),
      literal(space()),
      year4(padding: :zeroes),
      literal(space()),
      iso_time(opts)
    ]

    case is_zulu? do
      true ->
        zone_parts = [
          literal(space()),
          map(char("Z"), fn _ -> [zname: "Etc/UTC"] end)
        ]

        sequence(parts ++ zone_parts)

      _ ->
        zone_parts = [
          literal(space()),
          either(zname(opts), zoffs(opts))
        ]

        sequence(parts ++ zone_parts)
    end
  end

  @doc """
  RFC 3339 date/time format with timezone information.
  Example: `2013-03-05T23:25:19+02:00`
  """
  def rfc3339(_opts \\ []), do: Timex.Parse.DateTime.Parsers.ISO8601Extended.parse()

  @doc """
  UNIX standard date/time format.
  Example: `Tue Mar  5 23:25:19 PST 2013`
  """
  def unix(opts \\ []) do
    sequence([
      weekday_short(opts),
      literal(space()),
      month_short(opts),
      literal(space()),
      day_of_month(padding: :spaces, min: 1, max: 2),
      literal(space()),
      iso_time(opts),
      literal(space()),
      zname(opts),
      literal(space()),
      year4(padding: :spaces, min: 4, max: 4)
    ])
  end

  @doc """
  ANSI C standard date/time format.
  Example: `Tue Mar  5 23:25:19 2013`
  """
  def ansic(opts \\ []) do
    sequence([
      weekday_short(opts),
      literal(space()),
      month_short(opts),
      literal(space()),
      day_of_month(padding: :spaces, min: 1, max: 2),
      literal(space()),
      iso_time(opts),
      literal(space()),
      year4(padding: :spaces, min: 4, max: 4)
    ])
  end

  @doc """
  ASN.1 UTCTime standard date/time format.
  Example: `130305232519Z`
  """
  def asn1_utc_time(_) do
    parts = [
      sequence([
        year2(padding: :zeroes, min: 2, max: 2),
        month2(padding: :zeroes, min: 2, max: 2),
        day_of_month(padding: :zeroes, min: 2, max: 2)
      ]),
      choice([
        sequence([
          hour24(padding: :zeroes, min: 2, max: 2),
          minute(padding: :zeroes, min: 2, max: 2),
          second(padding: :zeroes, min: 2, max: 2)
        ]),
        sequence([
          hour24(padding: :zeroes, min: 2, max: 2),
          minute(padding: :zeroes, min: 2, max: 2)
        ])
      ])
    ]

    sequence(parts ++ [map(char("Z"), fn _ -> [zname: "Etc/UTC"] end)])
  end

  @doc """
  ASN.1 GeneralizedTime standard date/time format.
  Example: `20130305232519`
  asn1_generalized_time(zulu: true)
  Example: `20130305232519Z`
  asn1_generalized_time(zoffs: true)
  Example: `20130305232519-0700`
  """
  def asn1_generalized_time(opts \\ []) do
    is_zulu? = get_in(opts, [:zulu])
    is_zoffs? = get_in(opts, [:zoffs])

    parts = [
      sequence([
        year4(padding: :zeroes, min: 4, max: 4),
        month2(padding: :zeroes, min: 2, max: 2),
        day_of_month(padding: :zeroes, min: 2, max: 2)
      ]),
      choice([
        sequence([
          hour24(padding: :zeroes, min: 2, max: 2),
          minute(padding: :zeroes, min: 2, max: 2),
          both(
            second(padding: :zeroes, min: 2, max: 2),
            option(second_fractional(padding: :zeroes)),
            fn
              [{:sec, _sec}] = res, nil -> res
              [{:sec, _} = sec], [{:sec_fractional, _} = frac] -> [sec, frac]
            end
          )
        ]),
        sequence([
          hour24(padding: :zeroes, min: 2, max: 2),
          minute(padding: :zeroes, min: 2, max: 2),
          second(padding: :zeroes, min: 2, max: 2)
        ]),
        sequence([
          hour24(padding: :zeroes, min: 2, max: 2),
          minute(padding: :zeroes, min: 2, max: 2)
        ]),
        sequence([
          hour24(padding: :zeroes, min: 2, max: 2)
        ])
      ])
    ]

    cond do
      is_zulu? -> sequence(parts ++ [map(char("Z"), fn _ -> [zname: "Etc/UTC"] end)])
      is_zoffs? -> sequence(parts ++ [zoffs(opts)])
      true -> sequence(parts)
    end
  end

  @doc """
  Kitchen clock time format.
  Example: `3:25PM`
  """
  def kitchen(opts) do
    sequence([
      hour12(padding: :zeroes),
      literal(char(":")),
      minute(padding: :zeroes),
      ampm(opts)
    ])
    |> map(fn parts -> [kitchen: List.flatten(parts)] end)
  end

  @doc """
  Month, day, and year sans century, in slashed style.
  Example: `04/12/87`
  """
  def slashed(_) do
    opts = [padding: :zeroes, min: 2, max: 2]

    sequence([
      month2(opts),
      day_of_month(opts),
      year2(opts)
    ])
  end

  @doc """
  Wall clock in strftime (%R) format.
  Example: `23:30`
  """
  def strftime_iso_clock(_) do
    opts = [padding: :zeroes]

    sequence([
      hour24(opts),
      literal(char(":")),
      minute(opts)
    ])
  end

  @doc """
  Wall clock in strftime (%T) format.
  Example: `23:30:05`
  """
  def strftime_iso_clock_full(_) do
    opts = [padding: :zeroes]

    sequence([
      hour24(opts),
      literal(char(":")),
      minute(opts),
      literal(char(":")),
      second(opts)
    ])
  end

  @doc """
  Kitchen clock in strftime (%r) format.
  Example: `4:30:01 PM`
  """
  def strftime_kitchen(opts \\ [padding: :zeroes]) do
    sequence([
      hour12(opts),
      literal(char(":")),
      minute(opts),
      literal(char(":")),
      second(opts),
      literal(space()),
      ampm_upper(opts)
    ])
    |> map(fn parts -> [strftime_iso_kitchen: List.flatten(parts)] end)
  end

  @doc """
  Friendly short date format. Uses spaces for padding on the day.
  Example: ` 5-Jan-2014`
  """
  def strftime_iso_shortdate(_) do
    sequence([
      day_of_month(padding: :spaces, min: 1, max: 2),
      literal(char("-")),
      month_short([]),
      literal(char("-")),
      year4(padding: :zeroes)
    ])
  end

  defp literal(parser), do: map(parser, fn x -> [literal: x] end)
end

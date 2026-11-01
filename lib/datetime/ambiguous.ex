defmodule Timex.AmbiguousDateTime do
  @moduledoc """
  Represents a DateTime which is ambiguous due to timezone rules.

  ## Ambiguity #1 - Non-existent times

  Let's use American daylight savings time rules as our example here,
  using America/Chicago as our example. Central Standard Time for that
  zone ends at 2:00 AM, but Central Daylight Time does not begin until
  3:00 AM, this is because at 2:00 AM, our clocks "spring forward" - which
  is just an easy way of remembering that the offset goes from -6 from UTC,
  to -5 from UTC. Since there is no timezone period associated with the hours
  of 2-3 AM in the America/Chicago zone (it's neither CST nor CDT during that hour),
  one has to decide what the intent is.

  Converting a naive datetime in an IANA timezone gap with `Timex.to_datetime/2`
  or `Timex.Timezone.convert/2` returns this struct with `type: :gap`. Its `before`
  field contains the last valid instant before the gap, and `after` contains the
  first valid instant after it. For 2 AM on March 13, 2016 in America/Chicago,
  those boundaries are 01:59:59.999999 CST and 03:00:00 CDT. Neither boundary
  represents the nonexistent requested wall time; the caller decides whether to
  reject the input or select a replacement.

  Date-only `%Date{}` conversion has a separate midnight policy and selects the
  later result if midnight is skipped or repeated. Operations such as beginning
  or end of day also have their own boundary-selection rules.

  ## Ambiguity #2 - Times with more than one valid zone period

  There are times, though rare, where more
  than one zone applies to a given date and time. For example, Asia/Taipei, on December 31st,
  1895, from 23:54:00 to 23:59:59, two timezone periods are active LMT, and JWST, because that
  locale was switching to JWST from LMT. Because of this, it's impossible to know programmatically
  which zone is desired. The programmer must make a choice on which zone they want to use.

  For this use case, Timex will return an AmbiguousDateTime any time you try to create a DateTime,
  or shift a DateTime, to an ambiguous time period. It has two fields, :before, containing a DateTime
  configured in the timezone occurring before the ambiguous period, and :after, containing a DateTime
  configured in the timezone occurring after the ambiguous period. It is up to you as the programmer to
  decide which DateTime is the one to use, but my recommendation is to choose :after, unless you have a
  specific reason to use :before.
  """

  defstruct before: nil,
            after: nil,
            type: :ambiguous

  @type t :: %__MODULE__{
          :before => DateTime.t(),
          :after => DateTime.t(),
          :type => :ambiguous | :gap
        }

  defimpl Inspect do
    alias Timex.AmbiguousDateTime

    def inspect(datetime, %{:structs => false} = opts) do
      Inspect.Algebra.to_doc(datetime, opts)
    end

    def inspect(%AmbiguousDateTime{before: before, after: aft, type: :gap}, _opts) do
      "#<Gap(#{inspect(before)} ~ #{inspect(aft)})>"
    end

    def inspect(%AmbiguousDateTime{before: before, after: aft}, _opts) do
      "#<Ambiguous(#{inspect(before)} ~ #{inspect(aft)})>"
    end
  end
end

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
  one has to decide what the intent is. Timex makes the call that shifting to the
  next period (i.e. "spring forward" using our example above) makes the most logical
  sense when working with non-existent time periods.

  TL;DR - Timex will "spring forward" or "fall back", depending on what the zone change
  happens to be for the non-existent time. Using America/Chicago as an example, if you
  try to create a DateTime for 2 AM on March 13, 2016, Timex will give you back 3 AM on
  March 13, 2016, because the zone is in the middle of changing from CST to CDT, and the
  earliest representable time in CDT is 3 AM.

  ## Ambiguity #2 - Times with more than one valid zone period

  This one is the reason why this module exists. There are times, though rare, where more
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

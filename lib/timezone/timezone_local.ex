defmodule Timex.Timezone.Local do
  @moduledoc """
  This module is responsible for determining the timezone configuration of the
  local machine. It determines this from a number of sources, depending on platform,
  but the order of precedence is as follows:

  ALL:
  - TZ environment variable. Ignored if nil/empty

  OSX:
  - /etc/localtime
  - systemsetup -gettimezone (if admin rights are present)

  UNIX:
  - /etc/timezone
  - /etc/sysconfig/clock
  - /etc/conf.d/clock
  - /etc/localtime
  - /usr/local/etc/localtime

  Windows:
  - SYSTEM registry for the currently configured TimeZoneInformation

  Each location is tried, and if an error is encountered, the next is attempted,
  until either a successful lookup is performed, or we run out of locations to check.
  """
  alias Timex.DateTime,              as: DateTime
  alias Timex.Date,                  as: Date
  alias Timex.Timezone.Database,     as: ZoneDatabase
  alias Timex.Parse.ZoneInfo.Parser, as: ZoneParser
  alias Timex.Parse.ZoneInfo.Parser.TransitionInfo
  alias Timex.Parse.ZoneInfo.Parser.Zone

  @_ETC_TIMEZONE      "/etc/timezone"
  @_ETC_SYS_CLOCK     "/etc/sysconfig/clock"
  @_ETC_CONF_CLOCK    "/etc/conf.d/clock"
  @_ETC_LOCALTIME     "/etc/localtime"
  @_USR_ETC_LOCALTIME "/usr/local/etc/localtime"

  @doc """
  Looks up the local timezone configuration. Returns the name of a timezone
  in the Olson database.
  """
  @spec lookup(DateTime.t | nil) :: String.t

  def lookup(), do: Date.now |> lookup
  def lookup(%DateTime{} = date) do
    tz = Application.get_env(:timex, :local_timezone)
    if tz == nil do
      tz = case :os.type() do
        {:unix, :darwin} -> localtz(:osx, date)
        {:unix, _}       -> localtz(:unix, date)
        {:win32, :nt}    -> localtz(:win, date)
        _                -> raise "Unsupported operating system!"
      end
      Application.put_env(:timex, :local_timezone, tz)
    end
    tz
  end

  # Get the locally configured timezone on OSX systems
  @spec localtz(:osx | :unix | :win, DateTime.t) :: String.t | no_return
  defp localtz(:osx, date) do
    # Allow TZ environment variable to override lookup
    case System.get_env("TZ") do
      nil ->
        # Most accurate local timezone will come from /etc/localtime,
        # since we can lookup proper timezones for arbitrary dates
        case read_timezone_data(nil, @_ETC_LOCALTIME, date) do
          {:ok, tz} -> tz
          _ ->
            # Fallback and ask systemsetup
            {tz, 0} = System.cmd("systemsetup", ["-gettimezone"])
            tz = tz
            |> String.strip(?\n)
            |> String.replace("Time Zone: ", "")
            if String.length(tz) > 0 do
              tz
            else
              raise("Unable to find local timezone.")
            end
        end
      tz -> tz
    end
  end

  # Get the locally configured timezone on *NIX systems
  defp localtz(:unix, date) do
    case System.get_env("TZ") do
      # Not found
      nil ->
        # Since that failed, check distro specific config files
        # containing the timezone name. To clean up the code here
        # we're using pipes, even though we may find the value we
        # are looking for on the first try. The way the function
        # defs are set up, if we find a value, it's just passed
        # along through the pipe until we're done. If we don't,
        # this will try each fallback location in order.
        {:ok, tz} = read_timezone_data(@_ETC_TIMEZONE, date)
        |> read_timezone_data(@_ETC_SYS_CLOCK, date)
        |> read_timezone_data(@_ETC_CONF_CLOCK, date)
        |> read_timezone_data(@_ETC_LOCALTIME, date)
        |> read_timezone_data(@_USR_ETC_LOCALTIME, date)
        tz
      tz  -> tz
    end
  end

  # Get the locally configured timezone on Windows systems
  @local_tz_key 'SYSTEM\\CurrentControlSet\\Control\\TimeZoneInformation'
  @sys_tz_key   'SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Time Zones'
  @tz_key_name  'TimeZoneKeyName'
  # We ignore the reference date here, since there is no way to lookup
  # transition times for historical/future dates
  defp localtz(:win, _date) do
    # Windows has many of it's own unique time zone names, which can
    # also be translated to the OS's language.
    {:ok, handle} = :win32reg.open([:read])
    :ok           = :win32reg.change_key(handle, '\\local_machine\\#{@local_tz_key}')
    {:ok, values} = :win32reg.values(handle)
    if List.keymember?(values, @tz_key_name, 0) do
      #Extract the time zone name that windows has recorded
      {@tz_key_name,time_zone_name} = List.keyfind(values, @tz_key_name, 0)
      # Windows 7/Vista
      # On some systems the string value might be padded with excessive \0 bytes, trim them
      time_zone_name
      |> IO.iodata_to_binary
      |> String.strip(?\0)
      |> ZoneDatabase.to_olson
    else
     # Windows 2000 or XP
      # This is the localized name:
      localized = List.keyfind(values, 'StandardName', 0)
      # Open the list of timezones to look up the real name:
      :ok            = :win32reg.change_key(handle, @sys_tz_key)
      {:ok, subkeys} = :win32reg.sub_keys(handle)
      # Iterate over each subkey (timezone), and match against the localized name
      tzone = Enum.find subkeys, fn subkey ->
        :ok           = :win32reg.change_key(handle, subkey)
        {:ok, values} = :win32reg.values(handle)
        case List.keyfind(values, 'Std', 0) do
          {_, zone} when zone == localized -> zone
          _ -> nil
        end
      end
      # If we don't have a timezone yet, we've failed,
      # Otherwise, we need to lookup the final timezone name
      # in the dictionary of unique Windows timezone names
      cond do
        tzone == nil -> raise "Could not find Windows time zone configuration!"
        tzone ->
          timezone = tzone |> IO.iodata_to_binary
          case ZoneDatabase.to_olson(timezone) do
            nil ->
              # Try appending "Standard Time"
              case ZoneDatabase.to_olson("#{timezone} Standard Time") do
                nil   -> raise "Could not find Windows time zone configuration!"
                final -> final
              end
            final -> final
          end
      end
    end
  end

  # Attempt to read timezone data from /etc/timezone
  @spec read_timezone_data({:ok, String.t} | nil, String.t, DateTime.t) :: {:ok, String.t} | nil | no_return
  defp read_timezone_data(result \\ nil, file, date)

  # If we've found a timezone, just keep on piping it through
  defp read_timezone_data({:ok, _} = result, _, _), do: result
  # Otherwise, read the next fallback location
  defp read_timezone_data(_, @_ETC_TIMEZONE, date) do
    case File.read(@_ETC_TIMEZONE) do
      {:ok, etctz} ->
        cond do
          String.starts_with?(etctz, "TZif2") ->
            case parse_tzfile(etctz, date) do
              {:error, m}    -> raise m
              {:ok, _} = res -> res
            end
          true ->
            [no_hostdefs | _] = String.split(etctz, " ", [global: false, trim: true])
            [no_comments | _] = String.split(no_hostdefs, "#", [global: false, trim: true])
            {:ok, no_comments |> String.replace(" ", "_") |> String.strip(?\n)}
        end
      {:error, _} ->
        nil
    end
  end
  defp read_timezone_data(_, file, _date) when file == @_ETC_SYS_CLOCK or file == @_ETC_CONF_CLOCK do
    case File.exists?(file) do
      true ->
        match = file
        |> File.stream!
        |> Stream.filter(fn line -> Regex.match?(~r/(^ZONE=)|(^TIMEZONE=)/, line) end)
        |> Enum.to_list
        |> List.first
        case match do
          nil -> nil
          m   ->
            [_, tz, _] = String.split(m, "\"")
            {:ok, String.replace(tz, " ", "_")}
        end
      _ ->
        nil
    end
  end
  defp read_timezone_data(_, file, date) when file == @_ETC_LOCALTIME or file == @_USR_ETC_LOCALTIME do
    case File.read(file) do
      {:ok, contents} ->
        case parse_tzfile(contents, date) do
          {:ok, tz} ->
            # We have a valid timezone, so get symlinked zone name, since `tz` here is an abbreviation
            zone_file = file |> get_real_path |> String.replace(~r(^.*/zoneinfo/), "")
            cond do
              zone_file == "" -> {:ok, tz}
              true            -> {:ok, zone_file}
            end
          {:error, err} ->
            raise err
        end
      {:error, _} ->
        nil
    end
  end

  @spec get_real_path(String.t) :: String.t
  defp get_real_path(path) do
    case path |> String.to_char_list |> :file.read_link_info do
      {:ok, {:file_info, _, :regular, _, _, _, _, _, _, _, _, _, _, _}} ->
        path
      {:ok, {:file_info, _, :symlink, _, _, _, _, _, _, _, _, _, _, _}} ->
        {:ok, sym} = path |> String.to_char_list |> :file.read_link
        case sym |> :filename.pathtype do
          :absolute ->
            sym |> IO.iodata_to_binary
          :relative ->
            symlink = sym |> IO.iodata_to_binary
            path |> Path.dirname |> Path.join(symlink) |> Path.expand
        end
    end
  end

  @doc """
  Given a binary representing the data from a tzfile (not the source version),
  parses out the timezone for the provided reference date
  """
  @spec parse_tzfile(binary) :: {:ok, String.t} | {:error, term}
  def parse_tzfile(tzdata), do: parse_tzfile(tzdata, Date.now)

  @doc """
  Given a binary representing the data from a tzfile (not the source version),
  parses out the timezone for the current UTC date/time.
  """
  @spec parse_tzfile(binary, DateTime.t) :: {:ok, String.t} | {:error, term}
  def parse_tzfile(tzdata, %DateTime{} = reference_date) when tzdata != nil do
    # Parse file to Zone{}
    {:ok, %Zone{transitions: transitions}} = ZoneParser.parse(tzdata)
    # Get the zone for the current time
    timestamp  = reference_date |> Date.to_secs
    transition = transitions
      |> Enum.sort(fn %TransitionInfo{starts_at: utime1}, %TransitionInfo{starts_at: utime2} -> utime1 > utime2 end)
      |> Enum.reject(fn %TransitionInfo{starts_at: unix_time} -> unix_time > timestamp end)
      |> List.first
    # We'll need these handy
    # Attempt to get the proper timezone for the current transition we're in
    cond do
      # Success
      transition != nil -> {:ok, transition.abbreviation}
      # Fallback to the first standard-time zone available
      true ->
        fallback = transitions
          |> Enum.filter(fn zone -> zone.is_std? end)
          |> List.last
        case fallback do
          # Well, there are no standard-time zones then, just take the first zone available
          nil  ->
            case transitions |> List.last do
              nil             -> {:error, "Unable to locate the current timezone!"}
              last_transition -> {:ok, last_transition.abbreviation}
            end
          # Found a reasonable fallback zone, success?
          %TransitionInfo{abbreviation: abbreviation} ->
            {:ok, abbreviation}
        end
    end
  end
end

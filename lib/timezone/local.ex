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
  alias Timex.Timezone.Utils
  alias Timex.Parse.ZoneInfo.Parser

  @_ETC_TIMEZONE "/etc/timezone"
  @_ETC_SYS_CLOCK "/etc/sysconfig/clock"
  @_ETC_CONF_CLOCK "/etc/conf.d/clock"
  @_ETC_LOCALTIME "/etc/localtime"
  @_USR_ETC_LOCALTIME "/usr/local/etc/localtime"

  @type gregorian_seconds :: non_neg_integer

  @doc """
  Looks up the local timezone configuration. Returns the name of a timezone
  in the Olson database.

  If no reference time is provided (in gregorian seconds), the current time in UTC will be used.
  If one is provided, the reference time will be used to find the local timezone for that reference time,
  if it exists.
  """
  @spec lookup() :: String.t() | {:error, term}

  def lookup() do
    case Application.get_env(:timex, :local_timezone) do
      nil ->
        tz =
          case :os.type() do
            {:unix, :darwin} -> localtz(:osx)
            {:unix, _} -> localtz(:unix)
            {:win32, :nt} -> localtz(:win)
            _ -> {:error, :time_zone_not_found}
          end

        with tz when is_binary(tz) <- tz do
          Application.put_env(:timex, :local_timezone, tz)
          tz
        else
          {:error, _} ->
            {:error, :time_zone_not_found}
        end

      tz when is_binary(tz) ->
        tz
    end
  end

  # Get the locally configured timezone on OSX systems
  @spec localtz(:osx | :unix | :win) :: String.t() | no_return
  defp localtz(:osx) do
    # Allow TZ environment variable to override lookup
    tz =
      case System.get_env("TZ") do
        nil ->
          # Most accurate local timezone will come from /etc/localtime,
          # since we can lookup proper timezones for arbitrary dates
          read_timezone_data(nil, @_ETC_LOCALTIME)

        ":" <> path ->
          read_timezone_data(nil, path)

        tz ->
          {:ok, tz}
      end

    case tz do
      {:ok, tz} ->
        tz

      _ ->
        # Fallback and ask systemsetup
        {tz, 0} = System.cmd("systemsetup", ["-gettimezone"])

        tz =
          tz
          |> String.trim("\n")
          |> String.replace("Time Zone: ", "")

        if String.length(tz) > 0 do
          tz
        else
          {:error, :time_zone_not_found}
        end
    end
  end

  # Get the locally configured timezone on *NIX systems
  defp localtz(:unix) do
    tz =
      case System.get_env("TZ") do
        # Not found
        nil ->
          nil

        ":" <> path ->
          read_timezone_data(nil, path)

        tz ->
          {:ok, tz}
      end

    case tz do
      {:ok, tz} ->
        tz

      _ ->
        # Since that failed, check distro specific config files
        # containing the timezone name. To clean up the code here
        # we're using pipes, even though we may find the value we
        # are looking for on the first try. The way the function
        # defs are set up, if we find a value, it's just passed
        # along through the pipe until we're done. If we don't,
        # this will try each fallback location in order.
        with {:ok, tz} <-
               read_timezone_data(nil, @_ETC_LOCALTIME)
               |> read_timezone_data(@_USR_ETC_LOCALTIME)
               |> read_timezone_data(@_ETC_SYS_CLOCK)
               |> read_timezone_data(@_ETC_CONF_CLOCK)
               |> read_timezone_data(@_ETC_TIMEZONE) do
          tz
        else
          _ ->
            {:error, :time_zone_not_found}
        end
    end
  end

  # Get the locally configured timezone on Windows systems
  @local_tz_key 'SYSTEM\\CurrentControlSet\\Control\\TimeZoneInformation'
  @sys_tz_key 'SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Time Zones'
  @tz_key_name 'TimeZoneKeyName'
  # We ignore the reference date here, since there is no way to lookup
  # transition times for historical/future dates
  defp localtz(:win) do
    # Windows has many of its own unique time zone names, which can
    # also be translated to the OS's language.
    {:ok, handle} = :win32reg.open([:read])
    :ok = :win32reg.change_key(handle, '\\local_machine\\#{@local_tz_key}')
    {:ok, values} = :win32reg.values(handle)

    if List.keymember?(values, @tz_key_name, 0) do
      # Extract the time zone name that windows has recorded
      {@tz_key_name, time_zone_name} = List.keyfind(values, @tz_key_name, 0)
      # Windows 7/Vista
      # On some systems the string value might be padded with excessive \0 bytes, trim them
      time_zone_name
      |> Enum.take_while(fn
        ?\0 -> false
        _ -> true
      end)
      |> IO.iodata_to_binary()
      |> Utils.to_olson()
    else
      # Windows 2000 or XP
      # This is the localized name:
      localized = List.keyfind(values, 'StandardName', 0)
      # Open the list of timezones to look up the real name:
      :ok = :win32reg.change_key(handle, @sys_tz_key)
      {:ok, subkeys} = :win32reg.sub_keys(handle)
      # Iterate over each subkey (timezone), and match against the localized name
      tzone =
        Enum.find(subkeys, fn subkey ->
          :ok = :win32reg.change_key(handle, subkey)
          {:ok, values} = :win32reg.values(handle)

          case List.keyfind(values, 'Std', 0) do
            {_, zone} when zone == localized -> zone
            _ -> nil
          end
        end)

      # If we don't have a timezone yet, we've failed,
      # Otherwise, we need to lookup the final timezone name
      # in the dictionary of unique Windows timezone names
      cond do
        tzone == nil ->
          raise "Could not find Windows time zone configuration!"

        tzone ->
          timezone = tzone |> IO.iodata_to_binary()

          case Utils.to_olson(timezone) do
            nil ->
              # Try appending "Standard Time"
              case Utils.to_olson("#{timezone} Standard Time") do
                nil -> {:error, :time_zone_not_found}
                final -> final
              end

            final ->
              final
          end
      end
    end
  end

  # Attempt to read timezone data from /etc/timezone
  @spec read_timezone_data({:ok, String.t()} | nil, String.t()) ::
          {:ok, String.t()} | nil | no_return
  defp read_timezone_data(result, file)

  # If we've found a timezone, just keep on piping it through
  defp read_timezone_data({:ok, _} = result, _),
    do: result

  # Otherwise, read the next fallback location
  defp read_timezone_data(_, @_ETC_TIMEZONE) do
    case File.read(@_ETC_TIMEZONE) do
      {:ok, name} ->
        {:ok, String.trim(name)}

      {:error, _} ->
        nil
    end
  end

  defp read_timezone_data(_, file)
       when file == @_ETC_SYS_CLOCK or file == @_ETC_CONF_CLOCK do
    if File.exists?(file) do
      match =
        file
        |> File.stream!()
        |> Stream.filter(fn line -> Regex.match?(~r/(^ZONE=)|(^TIMEZONE=)/, line) end)
        |> Enum.to_list()
        |> List.first()

      case match do
        nil ->
          nil

        m ->
          with [tz | _] <-
                 String.split(m, :binary.compile_pattern(["ZONE=", "TIMEZONE=", "\"", "'"]),
                   trim: true
                 ) do
            {:ok, String.replace(tz, " ", "_")}
          else
            _ ->
              nil
          end
      end
    else
      nil
    end
  end

  defp read_timezone_data(_, file)
       when file == @_ETC_LOCALTIME or file == @_USR_ETC_LOCALTIME do
    if File.exists?(file) do
      name =
        file
        |> get_real_path()
        |> String.replace(~r(^.*/zoneinfo/), "")

      case name do
        ^file ->
          nil

        _ ->
          {:ok, name}
      end
    end
  end

  defp get_real_path(path) do
    case File.lstat!(path) do
      %File.Stat{type: :symlink} ->
        File.read_link!(path)

      %File.Stat{type: :regular} ->
        path
    end
  end

  @doc """
  Given a binary representing the data from a tzfile (not the source version),
  parses out the timezone for the current date/time in UTC.
  """
  @spec parse_tzfile(binary) :: {:ok, String.t()} | {:error, term}
  def parse_tzfile(tzdata) do
    Parser.parse(tzdata)
  end
end

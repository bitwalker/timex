defmodule Timex.Utils do
  @moduledoc false

  @doc """
  Determines the current version of OTP running this node. The result is
  cached for fast lookups in performance-sensitive functions.

  ## Example

      iex> rel = Timex.Utils.get_otp_release
      ...> '\#{rel}' == :erlang.system_info(:otp_release)
      true
  """
  def get_otp_release do
    case Process.get(:current_otp_release) do
      nil ->
        case ("#{:erlang.system_info(:otp_release)}" |> Integer.parse) do
          {ver, _} when is_integer(ver) ->
            Process.put(:current_otp_release, ver)
            ver
          _ ->
        end
      ver -> ver
    end
  end

  @doc """
  Loads all modules that extend a given module in the current code path.

  The convention is that it will fetch modules with the same root namespace,
  and that are suffixed with the name of the module they are extending.

  ## Example

      iex> Timex.Utils.get_plugins(Timex.Parse.DateTime.Tokenizer) |> Enum.sort
      [Timex.Parse.DateTime.Tokenizers.Default, Timex.Parse.DateTime.Tokenizers.Strftime]

  """
  @spec get_plugins(atom) :: list(atom)
  def get_plugins(plugin_type) when is_atom(plugin_type) do
    case Process.get(:timex_plugins) do
      plugins when is_list(plugins) ->
        plugins
      _ ->
        plugins = available_modules(plugin_type) |> Enum.reduce([], &load_plugin/2)
        Process.put(:timex_plugins, plugins)
        plugins
    end
  end

  @spec load_plugin(atom, list(atom)) :: list(atom) | no_return
  defp load_plugin(module, modules) do
    if Code.ensure_loaded?(module), do: [module | modules], else: modules
  end

  @spec available_modules(atom) :: Enumerable.t
  defp available_modules(plugin_type) do
    apps_path = Mix.Project.build_path |> Path.join("lib")
    case apps_path |> File.ls do
      {:ok, apps} ->
        apps
        |> Stream.map(&(Path.join([apps_path, &1, "ebin"])))
        |> Stream.map(fn app_path ->
          case app_path |> File.ls do
            {:ok, files} -> files |> Enum.map(&(Path.join(app_path, &1)))
            _ -> []
          end
        end)
        |> Stream.flat_map(&(&1))
        |> Stream.filter(&(String.ends_with?(&1, ".beam")))
        |> Stream.map(fn path ->
          {:ok, {module, chunks}} = :beam_lib.chunks('#{path}', [:attributes])
          {module, get_in(chunks, [:attributes, :behaviour])}
        end)
        |> Stream.filter(fn {_module, behaviours} ->
          is_list(behaviours) && plugin_type in behaviours
        end)
        |> Enum.map(fn {module, _} -> module end)
      _ ->
        []
    end
  end
end

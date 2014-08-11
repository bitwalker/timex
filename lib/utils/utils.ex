defmodule Timex.Utils do
  @moduledoc false

  @doc """
  Loads all modules that extend a given module in the current code path.

  The convention is that it will fetch modules with the same root namespace,
  and that are suffixed with the name of the module they are extending.

  ## Example

    > get_plugins(Timex.Parsers.DateFormat.Parser)
    [Timex.Parsers.DateFormat.DefaultParser]

  """
  @spec get_plugins(atom) :: [] | [atom]
  def get_plugins(plugin_type) when is_atom(plugin_type) do
    type_str   = plugin_type |> Atom.to_char_list
    namespace  = type_str |> Enum.reverse |> Enum.drop_while(fn c -> c != ?. end) |> Enum.reverse
    suffix     = (type_str -- namespace) |> List.to_string
    re         = ~r"#{namespace |> List.to_string |> String.replace(".", "\\.")}[\w\d]+#{suffix}"
    available_modules |> Enum.reduce([], &load_plugin(re, &1, &2))
  end

  defp load_plugin(re, module_name, modules) do
    case Regex.match?(re, module_name) do
      true  -> do_load_plugin(module_name, modules)
      false -> modules
    end
  end

  defp do_load_plugin(module, modules) when is_binary(module) do
    do_load_plugin(module |> String.to_atom, modules)
  end
  defp do_load_plugin(module, modules) when is_atom(module) do
    if Code.ensure_loaded?(module), do: [module | modules], else: modules
  end

  defp available_modules do
    apps_path = Mix.Project.build_path |> Path.join("lib")
    apps      = apps_path |> File.ls!
    apps
    |> Enum.map(&(Path.join([apps_path, &1, "ebin"])))
    |> Enum.filter(&File.exists?/1)
    |> Enum.map(&File.ls!/1)
    |> List.flatten
    |> Enum.map(&String.replace(&1, ".beam", ""))
  end
end
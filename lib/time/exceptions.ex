defmodule Timex.Time.InvalidUnitError do
  defexception [:unit, :message]

  def exception(opts) do
    unit = opts[:unit]
    %Timex.Time.InvalidUnitError{unit: unit, message: msg(to_string unit)}
  end

  defp msg(unit) do
    msg = "The unit #{unit} could not be found"
    case Version.compare(System.version, "1.1.0") in [:gt, :eq] && did_you_mean(unit) do
      {similar, score} when score > 0.8 ->
        msg <> ". Did you mean #{similar}?"
       _otherwise -> msg
     end
   end
   

   defp did_you_mean(unknown_unit) do
    Enum.map(Timex.Time.all_units, &to_string/1)
    |> Enum.reduce({nil, 0}, &max_similar(&1, unknown_unit, &2))
  end

  defp max_similar(source, target, {_, current} = best) do
    score = String.jaro_distance(source, target)
    if score < current, do: best, else: {source, score}
  end

end
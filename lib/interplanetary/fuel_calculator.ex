defmodule Interplanetary.FuelCalculator do
  @moduledoc """
  Calculates required fuel for interplanetary travel.
  """

  @gravity %{
    earth: 9.807,
    moon: 1.62,
    mars: 3.711
  }

  @doc """
  Calculates the total fuel required for a given mass and a flight path.
  A flight path is a list of maps, e.g.:
  `[%{action: :launch, planet: :earth}, %{action: :land, planet: :moon}]`
  """
  def calculate_total_fuel(mass, path) when is_integer(mass) and mass > 0 and is_list(path) do
    # Process from the last step to the first step, because fuel needed for step N
    # adds weight that needs to be carried in step N-1.
    path
    |> Enum.reverse()
    |> Enum.reduce(0, fn step, acc_fuel ->
      current_mass = mass + acc_fuel
      step_fuel = calculate_step_fuel(current_mass, step.action, step.planet)
      acc_fuel + step_fuel
    end)
  end

  def calculate_total_fuel(_mass, _path), do: 0

  # Calculate the fuel required for a single step, including the fuel needed to carry the fuel.
  defp calculate_step_fuel(mass, action, planet) do
    gravity = Map.fetch!(@gravity, planet)
    initial_fuel = formula(mass, gravity, action)

    # Calculate additional fuel to carry the fuel
    calculate_additional_fuel(initial_fuel, gravity, action, initial_fuel)
  end

  # Tail-recursive function to calculate cascading fuel weight
  defp calculate_additional_fuel(mass, gravity, action, total_acc) do
    additional_fuel = formula(mass, gravity, action)

    if additional_fuel > 0 do
      calculate_additional_fuel(additional_fuel, gravity, action, total_acc + additional_fuel)
    else
      total_acc
    end
  end

  defp formula(mass, gravity, :launch) do
    Float.floor(mass * gravity * 0.042 - 33) |> trunc()
  end

  defp formula(mass, gravity, :land) do
    Float.floor(mass * gravity * 0.033 - 42) |> trunc()
  end
end

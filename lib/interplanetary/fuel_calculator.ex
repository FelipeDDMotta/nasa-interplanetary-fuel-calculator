defmodule Interplanetary.FuelCalculator do
  @moduledoc """
  Pure fuel calculations for interplanetary flight.

  The fuel for a single manoeuvre is derived from the spacecraft mass and the
  planet's surface gravity:

    * launch — `floor(mass * gravity * 0.042 - 33)`
    * land   — `floor(mass * gravity * 0.033 - 42)`

  Fuel itself has mass, so every manoeuvre needs extra fuel to carry the fuel it
  just added — recursively, until the extra amount reaches zero. A manoeuvre can
  never require *negative* fuel, so each contribution is clamped at zero (this is
  what keeps low-mass spacecraft from producing nonsensical negative totals).

  A flight path is evaluated from the **last** manoeuvre back to the **first**,
  because fuel loaded for a later step is dead weight that every earlier step
  must also lift.

  ## Examples

      iex> path = [
      ...>   %{action: :launch, planet: :earth},
      ...>   %{action: :land, planet: :moon},
      ...>   %{action: :launch, planet: :moon},
      ...>   %{action: :land, planet: :earth}
      ...> ]
      iex> Interplanetary.FuelCalculator.calculate_total_fuel(28_801, path)
      51898

  """

  alias Interplanetary.Planet

  @launch_factor 0.042
  @launch_offset 33
  @land_factor 0.033
  @land_offset 42

  @typedoc "A manoeuvre performed during a flight."
  @type action :: :launch | :land

  @typedoc "A single manoeuvre at a given planet."
  @type step :: %{action: action(), planet: Planet.id()}

  @typedoc "An ordered sequence of manoeuvres."
  @type flight_path :: [step()]

  @typedoc "A manoeuvre annotated with the fuel it requires, returned by `calculate/2`."
  @type breakdown_step :: %{action: action(), planet: Planet.id(), fuel: non_neg_integer()}

  @typedoc "The full result of a calculation: the total and the per-step breakdown."
  @type result :: %{total: non_neg_integer(), steps: [breakdown_step()]}

  @doc """
  Returns the total fuel (kg) required to fly `path` with a spacecraft of `mass` kg.

  Equivalent to `calculate(mass, path).total`. An empty path requires no fuel.

  ## Examples

      iex> Interplanetary.FuelCalculator.calculate_total_fuel(14_606, [
      ...>   %{action: :launch, planet: :earth},
      ...>   %{action: :land, planet: :mars},
      ...>   %{action: :launch, planet: :mars},
      ...>   %{action: :land, planet: :earth}
      ...> ])
      33388

      iex> Interplanetary.FuelCalculator.calculate_total_fuel(28_801, [])
      0
  """
  @spec calculate_total_fuel(pos_integer(), flight_path()) :: non_neg_integer()
  def calculate_total_fuel(mass, path) when is_integer(mass) and mass > 0 and is_list(path) do
    calculate(mass, path).total
  end

  @doc """
  Calculates the total fuel and the fuel attributed to each manoeuvre.

  Steps are returned in flight order. Because each step's fuel accounts for the
  weight of fuel loaded by later steps, the per-step values always sum to
  `:total`.

  ## Examples

      iex> result = Interplanetary.FuelCalculator.calculate(28_801, [
      ...>   %{action: :launch, planet: :earth},
      ...>   %{action: :land, planet: :moon}
      ...> ])
      iex> result.total
      22380
      iex> Enum.map(result.steps, &{&1.action, &1.fuel})
      [launch: 20845, land: 1535]
  """
  @spec calculate(pos_integer(), flight_path()) :: result()
  def calculate(mass, path) when is_integer(mass) and mass > 0 and is_list(path) do
    {steps, total} =
      path
      |> Enum.reverse()
      |> Enum.reduce({[], 0}, fn step, {acc_steps, fuel_above} ->
        step_fuel = fuel_for_step(mass + fuel_above, step.action, step.planet)
        entry = %{action: step.action, planet: step.planet, fuel: step_fuel}
        {[entry | acc_steps], fuel_above + step_fuel}
      end)

    %{total: total, steps: steps}
  end

  @doc """
  Returns the fuel (kg) for a single manoeuvre, including the cascading fuel
  needed to carry that fuel, clamped at zero.

  ## Examples

      iex> Interplanetary.FuelCalculator.fuel_for_step(28_801, :land, :earth)
      13447

      iex> Interplanetary.FuelCalculator.fuel_for_step(1, :launch, :moon)
      0
  """
  @spec fuel_for_step(pos_integer(), action(), Planet.id()) :: non_neg_integer()
  def fuel_for_step(mass, action, planet)
      when is_integer(mass) and mass > 0 and action in [:launch, :land] do
    gravity = Planet.gravity!(planet)
    accumulate_fuel(mass, gravity, action, 0)
  end

  # Adds the fuel for `mass`, then the fuel to carry that fuel, and so on, until
  # a manoeuvre needs no more fuel. Each increment is clamped at zero by the
  # `> 0` guard, so the accumulator is always a non-negative integer.
  @spec accumulate_fuel(number(), float(), action(), non_neg_integer()) :: non_neg_integer()
  defp accumulate_fuel(mass, gravity, action, acc) do
    case formula(mass, gravity, action) do
      increment when increment > 0 ->
        accumulate_fuel(increment, gravity, action, acc + increment)

      _non_positive ->
        acc
    end
  end

  @spec formula(number(), float(), action()) :: integer()
  defp formula(mass, gravity, :launch),
    do: floor(mass * gravity * @launch_factor - @launch_offset)

  defp formula(mass, gravity, :land), do: floor(mass * gravity * @land_factor - @land_offset)
end

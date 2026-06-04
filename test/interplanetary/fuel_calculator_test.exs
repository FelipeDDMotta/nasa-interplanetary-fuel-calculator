defmodule Interplanetary.FuelCalculatorTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Interplanetary.{FuelCalculator, Planet}

  doctest FuelCalculator

  describe "calculate_total_fuel/2 — official mission scenarios" do
    test "Apollo 11: launch Earth, land Moon, launch Moon, land Earth (28801 kg)" do
      path = [
        %{action: :launch, planet: :earth},
        %{action: :land, planet: :moon},
        %{action: :launch, planet: :moon},
        %{action: :land, planet: :earth}
      ]

      assert FuelCalculator.calculate_total_fuel(28_801, path) == 51_898
    end

    test "Mars mission: launch Earth, land Mars, launch Mars, land Earth (14606 kg)" do
      path = [
        %{action: :launch, planet: :earth},
        %{action: :land, planet: :mars},
        %{action: :launch, planet: :mars},
        %{action: :land, planet: :earth}
      ]

      assert FuelCalculator.calculate_total_fuel(14_606, path) == 33_388
    end

    test "Passenger ship: Earth, Moon, Mars round trip (75432 kg)" do
      path = [
        %{action: :launch, planet: :earth},
        %{action: :land, planet: :moon},
        %{action: :launch, planet: :moon},
        %{action: :land, planet: :mars},
        %{action: :launch, planet: :mars},
        %{action: :land, planet: :earth}
      ]

      assert FuelCalculator.calculate_total_fuel(75_432, path) == 212_161
    end
  end

  describe "calculate_total_fuel/2 — edge cases" do
    test "an empty path requires no fuel" do
      assert FuelCalculator.calculate_total_fuel(28_801, []) == 0
    end

    test "raises on non-positive mass (validation is the caller's responsibility)" do
      assert_raise FunctionClauseError, fn ->
        FuelCalculator.calculate_total_fuel(0, [%{action: :launch, planet: :earth}])
      end

      assert_raise FunctionClauseError, fn ->
        FuelCalculator.calculate_total_fuel(-10, [%{action: :launch, planet: :earth}])
      end
    end

    test "handles a very large mass without overflow" do
      total =
        FuelCalculator.calculate_total_fuel(1_000_000_000, [%{action: :launch, planet: :earth}])

      assert is_integer(total) and total > 0
    end
  end

  describe "fuel_for_step/3" do
    test "matches the documented Apollo landing cascade (9278 + 2960 + 915 + 254 + 40)" do
      assert FuelCalculator.fuel_for_step(28_801, :land, :earth) == 13_447
    end

    test "is clamped to zero when the base formula is already non-positive (low mass)" do
      # mass * gravity * factor - offset is negative for a 1 kg craft, so no fuel is needed.
      assert FuelCalculator.fuel_for_step(1, :launch, :moon) == 0
      assert FuelCalculator.fuel_for_step(1, :land, :earth) == 0
    end

    test "respects the floor (rounding down) of the formula" do
      # land on Earth: floor(28801 * 9.807 * 0.033 - 42) = floor(9278.9...) = 9278 for the base step.
      gravity = Planet.gravity!(:earth)
      base = Kernel.floor(28_801 * gravity * 0.033 - 42)
      assert base == 9278
    end

    test "raises for an action that is not :launch or :land" do
      assert_raise FunctionClauseError, fn ->
        FuelCalculator.fuel_for_step(28_801, :orbit, :earth)
      end
    end

    test "raises (via the registry) for an unknown planet" do
      assert_raise ArgumentError, fn ->
        FuelCalculator.fuel_for_step(28_801, :launch, :pluto)
      end
    end
  end

  describe "calculate/2 — breakdown" do
    test "returns per-step fuel in flight order that sums to the total" do
      path = [
        %{action: :launch, planet: :earth},
        %{action: :land, planet: :moon},
        %{action: :launch, planet: :moon},
        %{action: :land, planet: :earth}
      ]

      result = FuelCalculator.calculate(28_801, path)

      assert result.total == 51_898
      assert Enum.map(result.steps, & &1.action) == [:launch, :land, :launch, :land]
      assert Enum.map(result.steps, & &1.planet) == [:earth, :moon, :moon, :earth]
      assert Enum.sum(Enum.map(result.steps, & &1.fuel)) == result.total
    end

    test "an empty path yields a zero total and no steps" do
      assert FuelCalculator.calculate(28_801, []) == %{total: 0, steps: []}
    end
  end

  # --- Property-based tests -------------------------------------------------

  defp planet_gen, do: member_of(Planet.ids())
  defp action_gen, do: member_of([:launch, :land])

  defp step_gen do
    gen all(action <- action_gen(), planet <- planet_gen()) do
      %{action: action, planet: planet}
    end
  end

  property "fuel is always a non-negative integer" do
    check all(
            mass <- integer(1..5_000_000),
            action <- action_gen(),
            planet <- planet_gen()
          ) do
      fuel = FuelCalculator.fuel_for_step(mass, action, planet)
      assert is_integer(fuel) and fuel >= 0
    end
  end

  property "the breakdown always sums to the reported total" do
    check all(
            mass <- integer(1..5_000_000),
            path <- list_of(step_gen(), max_length: 8)
          ) do
      result = FuelCalculator.calculate(mass, path)
      assert result.total >= 0
      assert Enum.sum(Enum.map(result.steps, & &1.fuel)) == result.total
    end
  end

  property "fuel for a step never decreases as mass increases" do
    check all(
            base <- integer(1..1_000_000),
            extra <- integer(0..1_000_000),
            action <- action_gen(),
            planet <- planet_gen()
          ) do
      lighter = FuelCalculator.fuel_for_step(base, action, planet)
      heavier = FuelCalculator.fuel_for_step(base + extra, action, planet)
      assert heavier >= lighter
    end
  end
end

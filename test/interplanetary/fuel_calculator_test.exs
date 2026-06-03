defmodule Interplanetary.FuelCalculatorTest do
  use ExUnit.Case
  alias Interplanetary.FuelCalculator

  describe "calculate_total_fuel/2" do
    test "Apollo 11 Mission" do
      mass = 28801

      path = [
        %{action: :launch, planet: :earth},
        %{action: :land, planet: :moon},
        %{action: :launch, planet: :moon},
        %{action: :land, planet: :earth}
      ]

      assert FuelCalculator.calculate_total_fuel(mass, path) == 51898
    end

    test "Mars Mission" do
      mass = 14606

      path = [
        %{action: :launch, planet: :earth},
        %{action: :land, planet: :mars},
        %{action: :launch, planet: :mars},
        %{action: :land, planet: :earth}
      ]

      assert FuelCalculator.calculate_total_fuel(mass, path) == 33388
    end

    test "Passenger Ship Mission" do
      mass = 75432

      path = [
        %{action: :launch, planet: :earth},
        %{action: :land, planet: :moon},
        %{action: :launch, planet: :moon},
        %{action: :land, planet: :mars},
        %{action: :launch, planet: :mars},
        %{action: :land, planet: :earth}
      ]

      assert FuelCalculator.calculate_total_fuel(mass, path) == 212_161
    end
  end
end

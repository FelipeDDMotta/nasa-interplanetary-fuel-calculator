defmodule FuelCalculatorWeb.CalculatorComponentsTest do
  use ExUnit.Case, async: true

  alias FuelCalculatorWeb.CalculatorComponents

  doctest CalculatorComponents

  describe "format_integer/1" do
    test "inserts thousands separators" do
      assert CalculatorComponents.format_integer(0) == "0"
      assert CalculatorComponents.format_integer(999) == "999"
      assert CalculatorComponents.format_integer(1_000) == "1,000"
      assert CalculatorComponents.format_integer(51_898) == "51,898"
      assert CalculatorComponents.format_integer(212_161) == "212,161"
    end
  end
end

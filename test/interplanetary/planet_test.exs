defmodule Interplanetary.PlanetTest do
  use ExUnit.Case, async: true

  alias Interplanetary.Planet

  doctest Planet

  describe "all/0 and ids/0" do
    test "expose the three supported planets in display order" do
      assert Enum.map(Planet.all(), & &1.id) == [:earth, :moon, :mars]
      assert Planet.ids() == [:earth, :moon, :mars]
    end

    test "each planet carries a display name and surface gravity" do
      for planet <- Planet.all() do
        assert is_binary(planet.name) and planet.name != ""
        assert is_float(planet.gravity) and planet.gravity > 0
      end
    end
  end

  describe "gravity/1" do
    test "returns the surface gravity for supported planets" do
      assert Planet.gravity(:earth) == {:ok, 9.807}
      assert Planet.gravity(:moon) == {:ok, 1.62}
      assert Planet.gravity(:mars) == {:ok, 3.711}
    end

    test "returns :error for an unknown planet" do
      assert Planet.gravity(:pluto) == :error
      assert Planet.gravity(:sun) == :error
    end
  end

  describe "gravity!/1" do
    test "returns the gravity for a supported planet" do
      assert Planet.gravity!(:mars) == 3.711
    end

    test "raises for an unknown planet" do
      assert_raise ArgumentError, ~r/unknown planet/, fn -> Planet.gravity!(:pluto) end
    end
  end

  describe "exists?/1" do
    test "is true only for supported planet ids" do
      assert Planet.exists?(:earth)
      refute Planet.exists?(:pluto)
      refute Planet.exists?("earth")
    end
  end
end

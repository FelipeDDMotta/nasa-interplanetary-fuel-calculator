defmodule Interplanetary.Flight.StepTest do
  use ExUnit.Case, async: true

  alias Ecto.Changeset
  alias Interplanetary.Flight.Step
  alias Interplanetary.Planet

  describe "changeset/2" do
    test "accepts every supported action/planet combination and casts to atoms" do
      for action <- [:launch, :land], planet <- Planet.ids() do
        changeset =
          Step.changeset(%{"action" => to_string(action), "planet" => to_string(planet)})

        assert changeset.valid?
        assert Changeset.apply_changes(changeset).action == action
        assert Changeset.apply_changes(changeset).planet == planet
      end
    end

    test "rejects an unknown action without creating an atom" do
      changeset = Step.changeset(%{"action" => "explode", "planet" => "earth"})

      refute changeset.valid?
      assert %{action: ["is invalid"]} = errors_on(changeset)
    end

    test "rejects an unknown planet without creating an atom" do
      changeset = Step.changeset(%{"action" => "launch", "planet" => "pluto"})

      refute changeset.valid?
      assert %{planet: ["is invalid"]} = errors_on(changeset)
    end

    test "requires both action and planet" do
      changeset = Step.changeset(%{})

      refute changeset.valid?
      assert %{action: ["can't be blank"], planet: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "schema / registry invariant" do
    test "the allowed planets match the Planet registry exactly" do
      # The schema derives its values from Planet.ids/0, so the two can never drift.
      allowed = Ecto.Enum.values(Step, :planet)
      assert allowed == Planet.ids()
    end
  end

  defp errors_on(changeset) do
    Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r/%{(\w+)}/, msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end

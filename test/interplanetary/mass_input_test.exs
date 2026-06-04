defmodule Interplanetary.MassInputTest do
  use ExUnit.Case, async: true

  alias Ecto.Changeset
  alias Interplanetary.MassInput

  doctest MassInput

  describe "changeset/1" do
    test "casts and accepts a positive integer string" do
      changeset = MassInput.changeset(%{"mass" => "28801"})

      assert changeset.valid?
      assert Changeset.get_field(changeset, :mass) == 28_801
    end

    test "rejects zero and negative values with a clear message" do
      assert %{mass: ["must be greater than 0"]} =
               errors_on(MassInput.changeset(%{"mass" => "0"}))

      assert %{mass: ["must be greater than 0"]} =
               errors_on(MassInput.changeset(%{"mass" => "-5"}))
    end

    test "rejects non-numeric input" do
      assert %{mass: ["is invalid"]} = errors_on(MassInput.changeset(%{"mass" => "heavy"}))
    end

    test "requires a value" do
      assert %{mass: ["can't be blank"]} = errors_on(MassInput.changeset(%{"mass" => ""}))
    end
  end

  describe "fetch/1" do
    test "returns {:ok, mass} for valid input" do
      assert MassInput.fetch(%{"mass" => "14606"}) == {:ok, 14_606}
    end

    test "returns :error for invalid input" do
      assert MassInput.fetch(%{"mass" => "0"}) == :error
      assert MassInput.fetch(%{"mass" => "abc"}) == :error
      assert MassInput.fetch(%{}) == :error
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

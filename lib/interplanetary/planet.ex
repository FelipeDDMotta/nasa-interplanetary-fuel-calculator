defmodule Interplanetary.Planet do
  @moduledoc """
  Registry of the celestial bodies supported by the fuel calculator.

  This module is the single source of truth for each body's surface gravity
  (consumed by `Interplanetary.FuelCalculator`) **and** for the options offered
  in the UI, so the calculation layer and the presentation layer can never drift
  apart.
  """

  @enforce_keys [:id, :name, :gravity]
  defstruct [:id, :name, :gravity]

  @typedoc "Identifier for a supported planet."
  @type id :: :earth | :moon | :mars

  @type t :: %__MODULE__{id: id(), name: String.t(), gravity: float()}

  # Raw data kept as plain maps so it can live in a compile-time attribute
  # (a module cannot build its own struct while it is still being defined).
  @planets_data [
    %{id: :earth, name: "Earth", gravity: 9.807},
    %{id: :moon, name: "Moon", gravity: 1.62},
    %{id: :mars, name: "Mars", gravity: 3.711}
  ]

  @ids Enum.map(@planets_data, & &1.id)
  @gravity_by_id Map.new(@planets_data, &{&1.id, &1.gravity})

  @doc """
  Returns every supported planet, in display order.

  ## Examples

      iex> Interplanetary.Planet.all() |> Enum.map(& &1.id)
      [:earth, :moon, :mars]
  """
  @spec all() :: [t()]
  def all, do: Enum.map(@planets_data, &struct(__MODULE__, &1))

  @doc """
  Returns the ids of every supported planet, in display order.

  ## Examples

      iex> Interplanetary.Planet.ids()
      [:earth, :moon, :mars]
  """
  @spec ids() :: [id()]
  def ids, do: @ids

  @doc """
  Fetches the surface gravity (m/s²) for a planet id.

  Returns `{:ok, gravity}` for a supported planet and `:error` otherwise. Use
  this at trust boundaries, where the value may not yet be known to be valid.

  ## Examples

      iex> Interplanetary.Planet.gravity(:earth)
      {:ok, 9.807}

      iex> Interplanetary.Planet.gravity(:pluto)
      :error
  """
  @spec gravity(atom()) :: {:ok, float()} | :error
  def gravity(id) do
    case Map.fetch(@gravity_by_id, id) do
      {:ok, gravity} -> {:ok, gravity}
      :error -> :error
    end
  end

  @doc """
  Fetches the surface gravity (m/s²) for a planet id, raising if unsupported.

  Use this on the internal path, after the id has already been validated (for
  example by `Interplanetary.Flight.Step`'s changeset).
  """
  @spec gravity!(id()) :: float()
  def gravity!(id) do
    case gravity(id) do
      {:ok, gravity} -> gravity
      :error -> raise ArgumentError, "unknown planet: #{inspect(id)}"
    end
  end

  @doc """
  Returns `true` when `id` is a supported planet.

  ## Examples

      iex> Interplanetary.Planet.exists?(:mars)
      true

      iex> Interplanetary.Planet.exists?("mars")
      false
  """
  @spec exists?(term()) :: boolean()
  def exists?(id), do: Map.has_key?(@gravity_by_id, id)
end

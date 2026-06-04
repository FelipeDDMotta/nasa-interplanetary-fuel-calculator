defmodule Interplanetary.Flight.Step do
  @moduledoc """
  A single manoeuvre in a flight path: an `action` performed at a `planet`.

  Backed by an embedded `Ecto` schema so that user-supplied values are validated
  and **safely cast** through `Ecto.Enum`, instead of calling `String.to_atom/1`
  on untrusted input (which would expose the node to atom-table exhaustion).

  The list of allowed planets is taken directly from `Interplanetary.Planet`, so
  the schema and the registry can never disagree.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Interplanetary.{FuelCalculator, Planet}

  @type t :: %__MODULE__{
          id: integer() | nil,
          action: FuelCalculator.action() | nil,
          planet: Planet.id() | nil
        }

  @primary_key false
  embedded_schema do
    field(:id, :integer)
    field(:action, Ecto.Enum, values: [:launch, :land])
    field(:planet, Ecto.Enum, values: Planet.ids())
  end

  @doc """
  Builds a changeset validating that `action` and `planet` are present and among
  the supported values.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(step \\ %__MODULE__{}, attrs) do
    step
    |> cast(attrs, [:action, :planet])
    |> validate_required([:action, :planet])
  end
end

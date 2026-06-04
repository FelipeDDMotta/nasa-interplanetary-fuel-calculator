defmodule Interplanetary.MassInput do
  @moduledoc """
  Embedded schema validating the spacecraft mass entered in the UI.

  The mass must be a positive integer number of kilograms. Using a changeset
  here gives the LiveView form proper, translatable inline error messages
  instead of silently coercing bad input to zero.
  """
  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{mass: pos_integer() | nil}

  @primary_key false
  embedded_schema do
    field(:mass, :integer)
  end

  @doc """
  Builds a changeset requiring `mass` to be a positive integer.

  ## Examples

      iex> Interplanetary.MassInput.changeset(%{"mass" => "28801"}).valid?
      true

      iex> Interplanetary.MassInput.changeset(%{"mass" => "0"}).valid?
      false

      iex> Interplanetary.MassInput.changeset(%{"mass" => "abc"}).valid?
      false
  """
  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:mass])
    |> validate_required([:mass])
    |> validate_number(:mass, greater_than: 0, message: "must be greater than 0")
  end

  @doc """
  Returns `{:ok, mass}` when `attrs` describe a valid mass, or `:error` otherwise.
  """
  @spec fetch(map()) :: {:ok, pos_integer()} | :error
  def fetch(attrs) do
    case changeset(attrs) do
      %Ecto.Changeset{valid?: true} = changeset ->
        {:ok, Ecto.Changeset.get_field(changeset, :mass)}

      _invalid ->
        :error
    end
  end
end

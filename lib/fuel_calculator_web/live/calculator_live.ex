defmodule FuelCalculatorWeb.CalculatorLive do
  @moduledoc """
  Interactive console for planning an interplanetary flight and seeing the fuel
  it requires, recalculated in real time as the mass and flight path change.

  All user input flows through changesets (`Interplanetary.MassInput` and
  `Interplanetary.Flight.Step`), so values are validated and safely cast before
  they ever reach the calculation layer — in particular, no untrusted string is
  ever passed to `String.to_atom/1`.
  """
  use FuelCalculatorWeb, :live_view

  import FuelCalculatorWeb.CalculatorComponents

  alias Interplanetary.Flight.Step
  alias Interplanetary.FuelCalculator
  alias Interplanetary.MassInput
  alias Interplanetary.Planet

  @empty_result %{total: 0, steps: []}

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(mass: nil, steps: [], result: @empty_result)
      |> assign_mass_form(MassInput.changeset(%{}))
      |> assign_step_form(Step.changeset(%Step{}, %{}))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="mb-8">
        <h1 class="font-mono text-2xl font-bold tracking-tight sm:text-3xl">
          Interplanetary Fuel Calculator
        </h1>
        <p class="mt-1 text-sm text-base-content/60">
          Enter a spacecraft mass, build a flight path, and read the total fuel in real time.
        </p>
      </div>

      <div class="grid grid-cols-1 gap-6 lg:grid-cols-5">
        <div class="space-y-6 lg:col-span-3">
          <.panel title="Spacecraft" step="01">
            <.form for={@mass_form} phx-change="validate_mass" id="mass-form">
              <.input
                field={@mass_form[:mass]}
                type="number"
                min="1"
                label="Equipment mass (kg)"
                placeholder="e.g. 28801"
                phx-debounce="200"
                autocomplete="off"
              />
            </.form>
          </.panel>

          <.panel title="Flight path" step="02">
            <.form
              for={@step_form}
              phx-submit="add_step"
              id="step-form"
              class="flex flex-col gap-3 sm:flex-row sm:items-end"
            >
              <div class="flex-1">
                <.input
                  field={@step_form[:action]}
                  type="select"
                  label="Manoeuvre"
                  options={[{"Launch from", :launch}, {"Land on", :land}]}
                />
              </div>
              <div class="flex-1">
                <.input
                  field={@step_form[:planet]}
                  type="select"
                  label="Planet"
                  options={planet_options()}
                />
              </div>
              <div class="sm:mb-2">
                <.button variant="primary">
                  <.icon name="hero-plus" class="size-4" /> Add step
                </.button>
              </div>
            </.form>

            <div class="divider my-5 text-xs uppercase tracking-widest text-base-content/40">
              Current path
            </div>

            <ol :if={@steps != []} class="space-y-2">
              <.flight_step
                :for={{step, index} <- Enum.with_index(@steps, 1)}
                index={index}
                step={step}
              />
            </ol>

            <div
              :if={@steps == []}
              class="rounded-lg border border-dashed border-base-300 px-4 py-8 text-center text-sm text-base-content/50"
            >
              <.icon name="hero-paper-airplane" class="mx-auto mb-2 size-6 opacity-50" />
              No manoeuvres yet. Add a launch or landing above to begin.
            </div>
          </.panel>
        </div>

        <div class="lg:col-span-2">
          <div class="space-y-6 lg:sticky lg:top-6">
            <.fuel_readout total={@result.total} mass={@mass} step_count={length(@steps)} />

            <.panel title="Breakdown">
              <.breakdown steps={@result.steps} />
            </.panel>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("validate_mass", %{"mass_input" => params}, socket) do
    changeset = Map.put(MassInput.changeset(params), :action, :validate)
    mass = if changeset.valid?, do: Ecto.Changeset.get_field(changeset, :mass), else: nil

    socket =
      socket
      |> assign(:mass, mass)
      |> assign_mass_form(changeset)
      |> recalculate()

    {:noreply, socket}
  end

  @impl true
  def handle_event("add_step", %{"step" => params}, socket) do
    case Step.changeset(%Step{}, params) do
      %Ecto.Changeset{valid?: true} = changeset ->
        step =
          changeset
          |> Ecto.Changeset.apply_changes()
          |> Map.put(:id, System.unique_integer([:positive]))

        socket =
          socket
          |> update(:steps, &(&1 ++ [step]))
          |> assign_step_form(Step.changeset(%Step{}, %{}))
          |> recalculate()

        {:noreply, socket}

      changeset ->
        {:noreply, assign_step_form(socket, Map.put(changeset, :action, :validate))}
    end
  end

  @impl true
  def handle_event("remove_step", %{"id" => id_string}, socket) do
    case Integer.parse(id_string) do
      {id, _rest} ->
        socket =
          socket
          |> update(:steps, fn steps -> Enum.reject(steps, &(&1.id == id)) end)
          |> recalculate()

        {:noreply, socket}

      :error ->
        {:noreply, socket}
    end
  end

  # Recomputes the result from the current mass and steps. With no valid mass
  # there is nothing to compute, so we avoid calling the calculator (whose
  # contract requires a positive mass) and simply show zero.
  defp recalculate(%{assigns: %{mass: mass, steps: steps}} = socket)
       when is_integer(mass) and mass > 0 do
    path = Enum.map(steps, &%{action: &1.action, planet: &1.planet})
    assign(socket, :result, FuelCalculator.calculate(mass, path))
  end

  defp recalculate(socket), do: assign(socket, :result, @empty_result)

  defp assign_mass_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :mass_form, to_form(changeset, as: :mass_input))
  end

  defp assign_step_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :step_form, to_form(changeset, as: :step))
  end

  defp planet_options do
    Enum.map(Planet.all(), &{&1.name, &1.id})
  end
end

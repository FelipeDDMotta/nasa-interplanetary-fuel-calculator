defmodule FuelCalculatorWeb.CalculatorComponents do
  @moduledoc """
  Presentational function components for the fuel calculator console.

  These components are intentionally stateless: they receive plain data and emit
  the `phx-click` events that `FuelCalculatorWeb.CalculatorLive` handles, which
  keeps the LiveView focused on state and makes the UI pieces easy to test.
  """
  use Phoenix.Component

  import FuelCalculatorWeb.CoreComponents, only: [icon: 1]

  alias Interplanetary.FuelCalculator

  @doc """
  A titled console panel used to group a section of the interface.
  """
  attr :title, :string, required: true
  attr :step, :string, default: nil, doc: "optional step number badge, e.g. \"01\""
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def panel(assigns) do
    ~H"""
    <section class={["rounded-box border border-base-300 bg-base-100/80 backdrop-blur", @class]}>
      <header class="flex items-center gap-3 border-b border-base-300 px-5 py-3">
        <span :if={@step} class="font-mono text-xs font-bold text-primary">{@step}</span>
        <h2 class="font-mono text-xs uppercase tracking-[0.2em] text-base-content/70">{@title}</h2>
      </header>
      <div class="p-5">
        {render_slot(@inner_block)}
      </div>
    </section>
    """
  end

  @doc """
  The primary total-fuel readout, with the base mass and step count beneath it.
  """
  attr :total, :integer, required: true
  attr :mass, :any, required: true, doc: "a positive integer, or nil when unset"
  attr :step_count, :integer, required: true

  def fuel_readout(assigns) do
    ~H"""
    <div class="rounded-box border border-primary/30 bg-gradient-to-b from-primary/10 to-base-100 p-6 text-center">
      <p class="font-mono text-xs uppercase tracking-[0.2em] text-base-content/60">
        Total fuel required
      </p>
      <p class="mt-3 font-mono text-5xl font-black tabular-nums text-primary drop-shadow">
        {format_integer(@total)}
      </p>
      <p class="mt-1 font-mono text-sm text-base-content/60">kilograms</p>

      <dl class="mt-6 grid grid-cols-2 gap-px overflow-hidden rounded-lg border border-base-300 bg-base-300 font-mono text-sm">
        <div class="bg-base-100 px-3 py-2 text-left">
          <dt class="text-xs uppercase tracking-wider text-base-content/50">Mass</dt>
          <dd class="tabular-nums">{mass_label(@mass)} kg</dd>
        </div>
        <div class="bg-base-100 px-3 py-2 text-left">
          <dt class="text-xs uppercase tracking-wider text-base-content/50">Steps</dt>
          <dd class="tabular-nums">{@step_count}</dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  A single, removable manoeuvre in the editable flight path.
  """
  attr :index, :integer, required: true
  attr :step, :map, required: true, doc: "an `Interplanetary.Flight.Step` struct"

  def flight_step(assigns) do
    ~H"""
    <li class="flex items-center gap-3 rounded-lg border border-base-300 bg-base-200/40 px-3 py-2">
      <span class="flex size-7 shrink-0 items-center justify-center rounded-full border border-primary/40 bg-primary/10 font-mono text-xs font-bold tabular-nums text-primary">
        {@index}
      </span>
      <.icon name={action_icon(@step.action)} class="size-5 text-base-content/60" />
      <div class="flex-1">
        <p class="font-mono text-sm font-semibold uppercase tracking-wide">
          {action_label(@step.action)}
        </p>
        <p class="text-xs text-base-content/60">{planet_label(@step.planet)}</p>
      </div>
      <button
        type="button"
        phx-click="remove_step"
        phx-value-id={@step.id}
        class="btn btn-circle btn-ghost btn-sm text-base-content/40 hover:text-error"
        aria-label={"Remove step #{@index}"}
      >
        <.icon name="hero-trash" class="size-4" />
      </button>
    </li>
    """
  end

  @doc """
  Per-manoeuvre fuel breakdown. The values always sum to the total.
  """
  attr :steps, :list, required: true, doc: "the `:steps` from `FuelCalculator.calculate/2`"

  def breakdown(assigns) do
    ~H"""
    <ul :if={@steps != []} class="divide-y divide-base-300 font-mono text-sm">
      <li :for={step <- @steps} class="flex items-center justify-between gap-3 py-2">
        <span class="flex items-center gap-2 truncate">
          <.icon name={action_icon(step.action)} class="size-4 shrink-0 text-base-content/50" />
          <span class="truncate">
            {action_label(step.action)}
            <span class="text-base-content/40">·</span>
            {planet_label(step.planet)}
          </span>
        </span>
        <span class="shrink-0 tabular-nums text-base-content/80">{format_integer(step.fuel)} kg</span>
      </li>
    </ul>
    <p :if={@steps == []} class="font-mono text-sm text-base-content/50">
      Add manoeuvres to see the fuel breakdown.
    </p>
    """
  end

  @doc """
  Formats a non-negative integer with thousands separators.

  ## Examples

      iex> FuelCalculatorWeb.CalculatorComponents.format_integer(51898)
      "51,898"

      iex> FuelCalculatorWeb.CalculatorComponents.format_integer(0)
      "0"
  """
  @spec format_integer(integer()) :: String.t()
  def format_integer(number) when is_integer(number) do
    number
    |> Integer.to_string()
    |> String.replace(~r/\B(?=(\d{3})+(?!\d))/, ",")
  end

  @spec mass_label(pos_integer() | nil) :: String.t()
  defp mass_label(nil), do: "—"
  defp mass_label(mass) when is_integer(mass), do: format_integer(mass)

  @spec action_label(FuelCalculator.action()) :: String.t()
  defp action_label(:launch), do: "Launch"
  defp action_label(:land), do: "Land"

  @spec action_icon(FuelCalculator.action()) :: String.t()
  defp action_icon(:launch), do: "hero-rocket-launch"
  defp action_icon(:land), do: "hero-arrow-down-tray"

  @spec planet_label(atom()) :: String.t()
  defp planet_label(planet), do: planet |> Atom.to_string() |> String.capitalize()
end

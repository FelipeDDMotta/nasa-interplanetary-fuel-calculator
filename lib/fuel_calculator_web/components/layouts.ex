defmodule FuelCalculatorWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is rendered as component
  in regular views and live views.
  """
  use FuelCalculatorWeb, :html

  embed_templates "layouts/*"

  @doc """
  Renders the application shell: a mission-control header and the page content.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <header class="border-b border-base-300 bg-base-100/60 backdrop-blur">
        <div class="flex w-full items-center justify-between px-4 py-3 sm:px-6 lg:px-10">
          <div class="flex items-center gap-2">
            <.icon name="hero-rocket-launch" class="size-5 text-primary" />
            <span class="font-mono text-sm font-bold uppercase tracking-[0.25em]">
              Mission Fuel Computer
            </span>
          </div>

          <span class="flex items-center gap-2 font-mono text-xs text-success" title="Live connection">
            <span class="size-2 animate-pulse rounded-full bg-success"></span> ONLINE
          </span>
        </div>
      </header>

      <main class="w-full px-4 py-8 sm:px-6 lg:px-10">{render_slot(@inner_block)}</main>
    </div>
    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} /> <.flash kind={:error} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end
end

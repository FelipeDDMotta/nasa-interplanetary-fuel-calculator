defmodule FuelCalculatorWeb.CalculatorLive do
  use FuelCalculatorWeb, :live_view
  alias Interplanetary.FuelCalculator

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        mass: 0,
        path: [],
        total_fuel: 0
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200 py-10 px-4 sm:px-6 lg:px-8">
      <div class="max-w-5xl mx-auto space-y-8">
        
    <!-- Header -->
        <div class="text-center">
          <h1 class="text-4xl font-extrabold text-primary mb-2 tracking-tight">
            🚀 Interplanetary Fuel Calculator
          </h1>
          <p class="text-base-content/70 text-lg">
            Calculate required fuel to launch and land safely across the solar system.
          </p>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
          
    <!-- Left Column: Controls -->
          <div class="lg:col-span-2 space-y-6">
            
    <!-- Mass Input -->
            <div class="card bg-base-100 shadow-xl">
              <div class="card-body">
                <h2 class="card-title text-xl">1. Spacecraft Configuration</h2>
                <form phx-change="update_mass" class="form-control w-full mt-2">
                  <label class="label">
                    <span class="label-text font-semibold">Equipment Mass (kg)</span>
                  </label>
                  <input 
                    type="number" 
                    name="mass"
                    min="0"
                    placeholder="Enter mass in kg (e.g. 28801)" 
                    class="input input-bordered input-primary w-full text-lg"
                    phx-debounce="300"
                    value={if @mass > 0, do: @mass, else: nil} />
                </form>
                </div>
              </div>
            
    <!-- Path Builder -->
            <div class="card bg-base-100 shadow-xl">
              <div class="card-body">
                <h2 class="card-title text-xl">2. Flight Path Builder</h2>

                <form phx-submit="add_step" class="flex flex-col sm:flex-row gap-4 mt-4">
                  <div class="form-control w-full sm:w-2/5">
                    <select name="action" class="select select-bordered w-full font-medium">
                      <option value="launch">Launch From</option>
                      <option value="land">Land On</option>
                    </select>
                  </div>

                  <div class="form-control w-full sm:w-2/5">
                    <select name="planet" class="select select-bordered w-full font-medium">
                      <option value="earth">Earth</option>
                      <option value="moon">Moon</option>
                      <option value="mars">Mars</option>
                    </select>
                  </div>

                  <button type="submit" class="btn btn-primary sm:w-1/5">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-5 w-5 mr-1"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z"
                        clip-rule="evenodd"
                      />
                    </svg>
                    Add
                  </button>
                </form>

                <div class="divider my-6">Current Flight Path</div>

                <%= if Enum.empty?(@path) do %>
                  <div class="alert alert-info shadow-sm rounded-lg">
                    <div>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                        class="stroke-current flex-shrink-0 w-6 h-6"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                        >
                        </path>
                      </svg>
                      <span>No steps added yet. Build your flight path above!</span>
                    </div>
                  </div>
                <% else %>
                  <ul class="steps steps-vertical w-full mt-2">
                    <%= for {step, index} <- Enum.with_index(@path) do %>
                      <li class="step step-primary">
                        <div class="flex items-center justify-between w-full p-4 bg-base-200/50 hover:bg-base-200 transition-colors rounded-xl ml-4 shadow-sm border border-base-300">
                          <div class="flex items-center gap-3">
                            <div class="avatar placeholder">
                              <div class="bg-primary text-primary-content rounded-full w-10">
                                <span>{index + 1}</span>
                              </div>
                            </div>
                            <div class="flex flex-col text-left">
                              <span class="font-bold text-lg uppercase">{step.action}</span>
                              <span class="text-base-content/70 text-sm capitalize">
                                {step.planet}
                              </span>
                            </div>
                          </div>

                          <button
                            class="btn btn-ghost btn-sm btn-circle text-error hover:bg-error/20"
                            phx-click="remove_step"
                            phx-value-id={step.id}
                          >
                            <svg
                              xmlns="http://www.w3.org/2000/svg"
                              class="h-5 w-5"
                              fill="none"
                              viewBox="0 0 24 24"
                              stroke="currentColor"
                            >
                              <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                              />
                            </svg>
                          </button>
                        </div>
                      </li>
                    <% end %>
                  </ul>
                <% end %>
              </div>
            </div>
          </div>
          
    <!-- Right Column: Result -->
          <div class="lg:col-span-1">
            <div class="card bg-gradient-to-br from-primary to-secondary text-primary-content shadow-2xl sticky top-8">
              <div class="card-body items-center text-center py-10">
                <div class="rounded-full bg-white/20 p-4 mb-2 shadow-inner">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-10 w-10 text-white"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M13 10V3L4 14h7v7l9-11h-7z"
                    />
                  </svg>
                </div>
                <h2 class="card-title text-2xl mb-1 font-bold">Total Fuel Required</h2>
                <div class="stat px-0">
                  <div class="stat-value text-5xl font-black drop-shadow-md">
                    {format_number(@total_fuel)}
                  </div>
                  <div class="stat-desc text-primary-content/80 text-lg mt-2 font-medium tracking-wide">
                    kilograms
                  </div>
                </div>

                <div class="divider bg-primary-content/20 h-px w-full my-6"></div>

                <div class="w-full text-left space-y-3 text-sm opacity-95 bg-black/10 p-4 rounded-xl">
                  <div class="flex justify-between">
                    <span class="font-semibold">Base Mass:</span>
                    <span>{format_number(@mass)} kg</span>
                  </div>
                  <div class="flex justify-between">
                    <span class="font-semibold">Mission Steps:</span>
                    <span>{length(@path)}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("update_mass", %{"mass" => value}, socket) do
    mass = case Integer.parse(value) do
        {num, _} when num > 0 -> num
        _ -> 0
      end

    socket =
      socket
      |> assign(:mass, mass)
      |> recalculate_fuel()

    {:noreply, socket}
  end

  def handle_event("add_step", %{"action" => action, "planet" => planet}, socket) do
    new_step = %{
      id: System.unique_integer([:positive]),
      action: String.to_atom(action),
      planet: String.to_atom(planet)
    }

    path = socket.assigns.path ++ [new_step]

    socket =
      socket
      |> assign(:path, path)
      |> recalculate_fuel()

    {:noreply, socket}
  end

  def handle_event("remove_step", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    path = Enum.reject(socket.assigns.path, fn step -> step.id == id end)

    socket =
      socket
      |> assign(:path, path)
      |> recalculate_fuel()

    {:noreply, socket}
  end

  defp recalculate_fuel(socket) do
    mass = socket.assigns.mass
    path = socket.assigns.path

    clean_path = Enum.map(path, fn step -> %{action: step.action, planet: step.planet} end)

    total_fuel = FuelCalculator.calculate_total_fuel(mass, clean_path)
    assign(socket, :total_fuel, total_fuel)
  end

  defp format_number(0), do: "0"

  defp format_number(number) do
    number
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/.{3}(?=.)/, "\\0,")
    |> String.reverse()
  end
end

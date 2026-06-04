defmodule FuelCalculator do
  @moduledoc """
  OTP application boundary for the fuel calculator.

  The interplanetary flight domain lives under the `Interplanetary` namespace:

    * `Interplanetary.Planet` — registry of supported planets and their gravity
    * `Interplanetary.FuelCalculator` — pure fuel calculations
    * `Interplanetary.Flight.Step` / `Interplanetary.MassInput` — validated user input

  The web layer (LiveView, endpoint, components) lives under `FuelCalculatorWeb`.
  """
end

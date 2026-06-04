defmodule FuelCalculatorWeb.CalculatorLiveTest do
  use FuelCalculatorWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  @apollo [
    {:launch, :earth},
    {:land, :moon},
    {:launch, :moon},
    {:land, :earth}
  ]

  @mars [
    {:launch, :earth},
    {:land, :mars},
    {:launch, :mars},
    {:land, :earth}
  ]

  @passenger [
    {:launch, :earth},
    {:land, :moon},
    {:launch, :moon},
    {:land, :mars},
    {:launch, :mars},
    {:land, :earth}
  ]

  describe "initial render" do
    test "shows an empty console with a zero total", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/")

      assert html =~ "Interplanetary Fuel Calculator"
      assert html =~ "Total fuel required"
      assert html =~ "No manoeuvres yet"
      assert has_element?(view, "#mass-form")
      assert has_element?(view, "#step-form")
    end
  end

  describe "official mission scenarios, end to end" do
    test "Apollo 11 totals 51,898 kg", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      assert build_mission(view, 28_801, @apollo) =~ "51,898"
    end

    test "Mars mission totals 33,388 kg", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      assert build_mission(view, 14_606, @mars) =~ "33,388"
    end

    test "Passenger ship totals 212,161 kg", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      assert build_mission(view, 75_432, @passenger) =~ "212,161"
    end
  end

  describe "reactivity" do
    test "a mass with no flight path still reports zero fuel", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html = set_mass(view, 28_801)
      assert html =~ "28,801 kg"
      # The big readout is still zero with no manoeuvres.
      assert html =~ "Add manoeuvres to see the fuel breakdown."
    end

    test "removing a step recalculates the total", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      build_mission(view, 28_801, @apollo)
      assert render(view) =~ "51,898"

      # Remove the last manoeuvre (land on Earth); the total must change.
      view |> element("button[aria-label='Remove step 4']") |> render_click()
      refute render(view) =~ "51,898"
    end

    test "removing every step returns to the empty state", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      add_step(view, :launch, :earth)

      assert render(view) =~ "Launch"
      view |> element("button[aria-label='Remove step 1']") |> render_click()
      assert render(view) =~ "No manoeuvres yet"
    end
  end

  describe "validation and hardening" do
    test "an invalid mass shows an inline error and does not crash", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html = set_mass(view, 0)
      assert html =~ "must be greater than 0"
      assert Process.alive?(view.pid)
    end

    test "a tampered manoeuvre is rejected without being added (no String.to_atom)", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Simulate a client that bypassed the <select> and posted arbitrary values.
      html =
        view
        |> element("#step-form")
        |> render_submit(%{"step" => %{"action" => "self_destruct", "planet" => "pluto"}})

      assert html =~ "is invalid"
      assert html =~ "No manoeuvres yet"
      assert Process.alive?(view.pid)
    end
  end

  # --- Helpers --------------------------------------------------------------

  defp set_mass(view, mass) do
    view
    |> form("#mass-form", %{"mass_input" => %{"mass" => to_string(mass)}})
    |> render_change()
  end

  defp add_step(view, action, planet) do
    view
    |> form("#step-form", %{
      "step" => %{"action" => to_string(action), "planet" => to_string(planet)}
    })
    |> render_submit()
  end

  defp build_mission(view, mass, steps) do
    set_mass(view, mass)
    Enum.each(steps, fn {action, planet} -> add_step(view, action, planet) end)
    render(view)
  end
end

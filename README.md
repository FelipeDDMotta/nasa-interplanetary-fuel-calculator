# 🚀 Interplanetary Fuel Calculator

[![CI](https://github.com/FelipeDDMotta/nasa-interplanetary-fuel-calculator/actions/workflows/ci.yml/badge.svg)](https://github.com/FelipeDDMotta/nasa-interplanetary-fuel-calculator/actions/workflows/ci.yml)
[![Elixir](https://img.shields.io/badge/elixir-~%3E%201.15-4B275F.svg)](https://elixir-lang.org)
[![Phoenix](https://img.shields.io/badge/phoenix-1.8--rc-FD4F00.svg)](https://www.phoenixframework.org)
[![Coverage](https://img.shields.io/badge/coverage-99%25-2ea44f.svg)](#testing--quality)

A Phoenix LiveView application that calculates the fuel required to launch from and
land on the planets of the Solar System, with a real-time **mission-control** console.

![Application preview](screenshot.png)

## ✨ Features

- **Dynamic flight-path builder** — add and remove `launch` / `land` manoeuvres for Earth,
  Moon and Mars, in any sequence.
- **Real-time calculation** — total fuel and a per-step breakdown update instantly over the
  LiveView socket as the mass or path changes.
- **Cascading fuel-of-fuel** — fuel has mass, so each manoeuvre recursively accounts for the
  fuel needed to carry its own fuel, until no more is required.
- **Validated, safe input** — mass and manoeuvres are validated through Ecto changesets;
  untrusted strings are never passed to `String.to_atom/1`.
- **Mission Control UI** — a focused dark console built with Tailwind CSS 4 and daisyUI 5.

## 🧮 The fuel math

Fuel for a single manoeuvre is a function of the spacecraft mass and the planet's surface
gravity (result rounded **down**):

| Manoeuvre | Formula |
| --------- | ------- |
| Launch    | `floor(mass * gravity * 0.042 - 33)` |
| Land      | `floor(mass * gravity * 0.033 - 42)` |

Because the fuel itself adds weight, each manoeuvre needs additional fuel to carry that fuel,
applying the same formula recursively until the extra amount is zero. Crucially, **a manoeuvre
can never require negative fuel** — each contribution is clamped to zero, which is what keeps
low-mass spacecraft from producing nonsensical negative totals.

Worked example — landing the Apollo 11 CSM (28 801 kg) on Earth:

```
9278 + 2960 + 915 + 254 + 40 = 13447 kg
```

Flight paths are evaluated from the **last** manoeuvre back to the **first**, since fuel loaded
for a later step is dead weight that every earlier step must also lift.

## 🏗️ Architecture

The domain logic is a pure, framework-free core under the `Interplanetary` namespace; the web
layer under `FuelCalculatorWeb` only orchestrates input and rendering.

| Module | Responsibility |
| ------ | -------------- |
| `Interplanetary.Planet` | Single source of truth for supported planets and their gravity — drives **both** the calculation and the UI dropdowns, so they can never drift. |
| `Interplanetary.FuelCalculator` | Pure fuel math (`calculate/2`, `calculate_total_fuel/2`, `fuel_for_step/3`), fully typed and doctested. |
| `Interplanetary.Flight.Step` | Embedded Ecto schema validating a manoeuvre. `Ecto.Enum` casts strings to atoms **safely**. |
| `Interplanetary.MassInput` | Embedded Ecto schema validating the spacecraft mass (positive integer). |
| `FuelCalculatorWeb.CalculatorLive` | LiveView holding the mass + path state and wiring the forms. |
| `FuelCalculatorWeb.CalculatorComponents` | Stateless presentational components (readout, breakdown, step). |

**Design decisions worth calling out:**

- **Ecto without a database.** Embedded schemas give changeset-based validation and inline form
  errors — the idiomatic Phoenix approach — without any persistence. `Ecto.Enum` also fixes a
  real security issue: it casts `"earth"` → `:earth` only for known values, replacing an unsafe
  `String.to_atom/1` on client input (which would expose the node to atom-table exhaustion).
- **Consistent error contracts.** The pure calculator assumes already-validated input (enforced
  by guards and `@spec`s); validation lives at the boundary (the changesets / LiveView). The
  `Planet` registry offers both a safe `gravity/1 :: {:ok, float} | :error` for boundaries and a
  `gravity!/1` for the internal, validated path.
- **No negative fuel.** `fuel_for_step/3` clamps every contribution to zero.

## 🛠️ Tech stack

- **Elixir** `~> 1.15` (developed and tested on 1.17) / **Erlang OTP** 25+
- **Phoenix** 1.8-rc and **Phoenix LiveView** 1.1
- **Ecto** 3.12 (embedded schemas, no database)
- **Tailwind CSS** 4 + **daisyUI** 5
- **Quality:** Credo, Dialyzer, ExCoveralls, StreamData, GitHub Actions CI

## 🚀 Getting started

### Prerequisites

- Elixir `~> 1.15` and a compatible Erlang/OTP (25+)

### Run it

```bash
mix setup          # fetch deps and build assets
mix phx.server     # start the server
```

Then open <http://localhost:4000>.

## 🧪 Testing & quality

```bash
mix test           # unit, doctest, property-based and LiveView tests
mix quality        # format check + unused-deps + Credo (strict) + coverage + Dialyzer
```

The test suite covers the domain to ~100% and the app to **99%** overall. It includes:

- the three official mission scenarios (unit **and** end-to-end through the LiveView);
- edge cases (empty path, low-mass clamping, floor boundaries, oversized mass);
- **property-based** invariants (fuel is always non-negative, monotonic in mass, and the
  per-step breakdown always sums to the total);
- security/validation tests (invalid mass shows an inline error; a tampered manoeuvre is
  rejected without creating an atom);
- `doctest`s on every domain module.

Coverage intentionally excludes Phoenix-generated boilerplate (endpoint, telemetry, error views,
generated components) — see `coveralls.json`.

## 📊 Example scenarios

| Mission | Path | Mass | Total fuel |
| ------- | ---- | ---- | ---------- |
| Apollo 11 | launch Earth, land Moon, launch Moon, land Earth | 28 801 kg | **51 898 kg** |
| Mars | launch Earth, land Mars, launch Mars, land Earth | 14 606 kg | **33 388 kg** |
| Passenger ship | Earth → Moon → Mars round trip | 75 432 kg | **212 161 kg** |

## 📁 Project layout

```
lib/
├── interplanetary/              # pure domain (no web dependencies)
│   ├── planet.ex
│   ├── fuel_calculator.ex
│   ├── mass_input.ex
│   └── flight/step.ex
└── fuel_calculator_web/
    ├── live/calculator_live.ex
    └── components/calculator_components.ex
test/                            # mirrors lib/, plus LiveView tests
.github/workflows/ci.yml         # format · credo · coverage · dialyzer
```

# abstract-device standard cells from SKY130

These are the converted standard cells from the 
open [SkyWater sky130](https://github.com/google/skywater-pdk)
standard-cell SPICE netlists into **process-portable** cells built from an
abstract transistor, so the same logic can be retargeted to a different process
by swapping a single device file.

These are basic netlists for standard cells that are modified from skywater130 
to only use a single transistor as the driver.  This is because advanced nodes, 
such as <14nm, do not allow gate scaling.  You need to put two devices in 
parallel if you want a 2x device.  

Go to bin and execute "source adddirtopath.sh" to add the path temporarily
 to the system $PATH.  This is needed fro any of the scripts in ./bin  All 
 of the nfets and pfets have been replaced with abnmos and abpmos that abstracts 
 away the devices so that you can easily replace the device with something else.

As an example, mine live here:
export SPICE_LIB="$HOME/private/projects/semi/skywater-pdk/libraries/sky130_fd_pr/latest/models"
export SPICE_DEVICES="$HOME/private/projects/semi/ngspicecells/basic/abstractdevice/sky130"
export SPICE_STDCELLS="$HOME/private/projects/semi/ngspicecells/basic"


The top of a spice deck usually starts with this: 
.lib "$SPICE_LIB/sky130.lib.spice" tt
.include "$SPICE_DEVICES/devices.cir"
This shows where the simulation devices are and where the abstracted device is.

Each device has two version for simulation purposes, one with the well tie and 
one that does not.  An inverter to illustrate this follows:


* INVD! gate subcircuit definition
.subckt INVD1 A VGND VPWR Y
XNAND2D1B A VGND VGND VPWR VPWR Y INVD1B
.ends INVD1
* NAND2 gate subcircuit definition with Bulk connections

.subckt INVD1B A VGND VNB VPB VPWR Y
X0 Y A VGND VNB abnmos
X1 Y A VPWR VPB abpmos
.ends



## Why

sky130 is open; many real processes are not. A standard cell from a vendor PDK
hard-codes that process's transistor sizes (`w=…`, `l=…`, threshold flavor),
which both ties the netlist to one process and can be NDA-encumbered.

This project rewrites every cell in terms of two abstract devices, `abnmos` and
`abpmos`, that carry **no explicit width**. Drive strength is expressed the way
a modern **FinFET** process expresses it — as **parallel minimum-width devices**
rather than one wide transistor:

```
planar (sky130):   one FET, w = 650 nm           ┌─┐
                                                 │ │   (a single wide device)
                                                 └─┘

FinFET-style:      N min-width FETs in parallel  ┌┐┌┐   (quantized width =
                                                 ││││    parallel fingers/fins)
                                                 └┘└┘
```

So a sky130 device of width `w` becomes `N = round(w / w_unit)` abstract devices
in parallel. Retargeting to another process is then just editing
`abstractdevice/<process>/devices.cir` to map `abnmos`/`abpmos` onto that
process's primitive — no cell netlists change.

## The abstract device

`abstractdevice/sky130/devices.cir` is the single swap point:

```spice
.subckt abnmos D G S B
X1 D G S B sky130_fd_pr__nfet_01v8 w=0.36 l=0.15
.ends abnmos
.subckt abpmos D G S B
X1 D G S B sky130_fd_pr__pfet_01v8 w=0.42 l=0.15
.ends abpmos
```

One abstract device = one **minimum-size** sky130 FET (the parallel-finger
unit). The sizes are each model's smallest `L=0.15 µm` bin (nfet 0.36 µm; the
non-hvt pfet's smallest bin is 0.42 µm). To target another process, replace the
body of these two subcircuits.

## Conversion rules

For each device in a source cell:

1. **Model map** — `sky130_fd_pr__nfet*` to `abnmos`, `sky130_fd_pr__pfet*` to
   `abpmos` (threshold flavor collapsed into one device); `w`/`l` dropped.
2. **Width to parallel fingers** — emit `N = max(1, round(w / 360 nm))` copies of
   the abstract device in parallel.
3. **Rail on the source pin** — pin order is `D G S B`; wherever a power rail
   (`VPWR`/`VGND`) sits on the drain, drain and source are swapped so the rail is
   always the source terminal (a MOSFET is symmetric, so this is identical).

Each cell is emitted as a two-tier subcircuit:

* inner `<NAME>B` — keeps all original ports, including body-bias rails
  (`VNB`/`VPB`) and any secondary power domain;
* outer `<NAME>` — drops `VNB`/`VPB` (tied internally to `VGND`/`VPWR`) and any
  secondary power domain (`KAPWR`/`LOWLVPWR`/`VPWRIN`, tied to `VPWR`), keeping
  every signal port in its original position. Cells are named `<FUNC>D<drive>`
  (e.g. `sky130_fd_sc_hd__nand2_4` → `NAND2D4`).

## Repository layout

```
abstractdevice/sky130/devices.cir   the swap point (abnmos / abpmos)

skyfin/
  <cell>/<cell>.cir                 converted cell (+ runcell.cir, plot.py)
  CELLS.csv                         per-cell description + verification status
  MANIFEST.csv                      per-cell name / source / status
```

## Coverage and verification (sky130_fd_sc_hd)

| category | count | verification |
|---|---:|---|
| combinational | 346 | equivalent to original (DC op, all input vectors) |
| sequential (flops/latches) | 68 | equivalent to original (clocked transient) |
| physical (fill/tap/decap/bleeder) | 20 | no signal I/O — not functionally tested |
| **converted total** | **434** | |
| skipped (non-FET) | 3 | `conb` (tie/`short`), `diode`, `macro_sparecell` |

Verification instantiates the abstract cell and the **original sky130 cell** in
one deck, drives identical inputs, and compares every output as a logic level —
the original is the golden reference, so any connectivity/conversion error shows
up as a mismatch. **All 414 functionally-testable cells match.** Per-cell status
is in `generated/CELLS.csv`.

## Caveats

* **Width is quantized and absolute size is abstracted away.** With unit = 360 nm,
  several nearby sky130 widths collapse to the same finger count. Logic is
  preserved exactly (static CMOS is geometry-independent), but **timing/drive on
  sky130 will not match the vendor cells** — the point is portability, not
  sky130-accurate timing.
* **Threshold flavors are merged.** All pfets map to one `abpmos`. The sky130 `hd`
  cells use the hvt pfet; the default `devices.cir` maps to the non-hvt
  `pfet_01v8` (smallest bin 0.42 µm). Switch to `pfet_01v8_hvt` if you want the
  hvt device or a 0.36 µm pfet finger.
* **`devices_test.cir` is for testing only** — minimum geometry so DC operating
  points converge quickly during equivalence checks. The shipped `devices.cir` is
  what cells use in normal simulation.

## Attribution / license

Source standard cells are from the SkyWater sky130 PDK, © The SkyWater PDK
Authors, licensed under Apache-2.0. The converted netlists are mechanical
transformations of those cells and carry the same provenance. 

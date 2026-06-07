# synesthesia — Cross-Sensory System Portraiture

```
   ╔══════════════════════════════════════╗
   ║  SYNESTHESIA — Sensory Portrait      ║
   ╚══════════════════════════════════════╝
```

**Synesthesia** converts a single moment of system state into a multi-sensory portrait. Your machine doesn't just compute — it sees color, hears rhythm, feels texture, and smells the world.

Each run produces a completely unique sensory fingerprint that will never recur.

## Concept

What if your computer could experience itself through every sense at once? Synesthesia maps four system metrics (CPU, RAM, disk, process count) onto four sensory domains simultaneously:

| Domain | Metric Mapping | Output |
|---|---|---|
| **Visual** | CPU→Hue, RAM→Saturation, Disk→Lightness | Color field with gradients |
| **Auditory** | CPU→BPM, RAM→Complexity, Procs→Harmony | Rhythm score in standard notation |
| **Tactile** | CPU→Texture, RAM→Pattern, Disk→Depth | ASCII texture grid (haptic map) |
| **Olfactory** | CPU→Top note, RAM→Heart, Procs→Base, Uptime→Longevity | Perfume profile with pricing |

## Usage

```powershell
.\synesthesia.ps1
```

## Output

A single screen contains everything:

- **Color Fields** — Two 40-character gradient bars + color swatches (HSL values)
- **Rhythm Score** — BPM, time signature, key, chord density, and a 16-beat note sequence
- **Texture Map** — Haptic description + 8x40 ASCII texture grid rendered from CPU/RAM interference patterns
- **Scent Profile** — Three-note perfume accord (top/heart/base) with longevity, projection, and market value

### Example

```
   ── Visual ──
   Color Field I   ████████████████████████████████████████
   Color Field II  ████████████████████████████████████████
   HSL: 210° 61% 48%

   ── Auditory ──
   BPM: 128  |  Time: 4/4  |  Key: C maj  |  Harmony: 3-voice

   C4(87) | ---(---) | E4(72) | ---(---) | A4(91) | ...

   ── Tactile ──
   Texture: grainy  |  Pattern: wave  |  Depth: 3.2mm

   ▓▒░▓▒░▓▒░▓▒░▓▒░▓▒░▓▒░▓▒░▓▒░▓▒░▓▒░▓▒░▓▒░
   ░▓▒░▓▒░▓▒░▓▒░▓▒░▓▒░▓▒░▓▒░▓▒░▓▒░▓▒░▓▒░▓▒░

   ── Olfactory ──
   Top note:    ozone
   Heart note:  cedar
   Base note:   copper
   Accord:      metallic
   Longevity:   moderate
   Projection:  soft
   Value:       $142 USD
```

Every millisecond of system state produces a different portrait. Run it while compiling, while idle, while gaming — each is a unique artifact.

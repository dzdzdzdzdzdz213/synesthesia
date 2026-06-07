# synesthesia — Cross-Sensory System Portraiture
# Converts a single moment of system state into a multi-sensory portrait:
# Visual (color field), Auditory (rhythm score), Tactile (texture map),
# and Olfactory (scent profile). Your machine experiences the world.
# Every run produces a unique sensory fingerprint.

$ESC = "$([char]27)"
$RESET = "${ESC}[0m"
$CLS = "${ESC}[2J${ESC}[H"

function Get-FG($r, $g, $b) { "${ESC}[38;2;$r;$g;${b}m" }
function Get-BG($r, $g, $b) { "${ESC}[48;2;$r;$g;${b}m" }

# ─── Capture system state ───
function Get-SystemState {
    $cpu = (Get-CimInstance Win32_Processor).LoadPercentage
    $os = Get-CimInstance Win32_OperatingSystem
    $ramTotal = $os.TotalVisibleMemorySize / 1MB
    $ramFree = $os.FreePhysicalMemory / 1MB
    $ramPct = [Math]::Round((1 - $ramFree / $ramTotal) * 100, 1)
    $procCount = (Get-Process).Count
    $procs = Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select-Object -First 1
    $diskPct = if ($disk) { [Math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1) } else { 0 }
    $uptimeHours = ((Get-Date) - $os.LastBootUpTime).TotalHours

    return @{
        cpu = $cpu
        ram = $ramPct
        disk = $diskPct
        proc = $procCount
        topProcs = $procs
        uptime = $uptimeHours
        timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    }
}

# ─── 1. VISUAL — Color Field ───
function Get-ColorField($s) {
    # CPU -> hue (red for high, blue for low)
    # RAM -> saturation
    # Disk -> lightness
    $cpuHue = 240 - [Math]::Round($s.cpu * 2.4)  # 240 (blue) -> 0 (red)
    $ramSat = [Math]::Round(30 + $s.ram * 0.7)
    $diskLight = [Math]::Round(60 - $s.disk * 0.2)
    if ($cpuHue -lt 0) { $cpuHue = 0 }
    if ($ramSat -gt 100) { $ramSat = 100 }
    if ($diskLight -lt 20) { $diskLight = 20 }

    # Secondary color from process composition
    $procHue = ($s.proc * 7) % 360
    $procSat = 50 + ($s.topProcs.Count * 5)
    if ($procSat -gt 100) { $procSat = 100 }

    return @{
        primary = @{h=$cpuHue; s=$ramSat; l=$diskLight}
        secondary = @{h=$procHue; s=$procSat; l=60}
        accent = @{h=(($cpuHue + $procHue) / 2) % 360; s=80; l=70}
    }
}

function HSL-to-RGB($h, $s, $l) {
    $s = $s / 100
    $l = $l / 100
    $c = (1 - [Math]::Abs(2 * $l - 1)) * $s
    $x = $c * (1 - [Math]::Abs(($h / 60) % 2 - 1))
    $m = $l - $c / 2

    if ($h -lt 60) { $r=$c; $g=$x; $b=0 }
    elseif ($h -lt 120) { $r=$x; $g=$c; $b=0 }
    elseif ($h -lt 180) { $r=0; $g=$c; $b=$x }
    elseif ($h -lt 240) { $r=0; $g=$x; $b=$c }
    elseif ($h -lt 300) { $r=$x; $g=0; $b=$c }
    else { $r=$c; $g=0; $b=$x }

    return @{
        r=[Math]::Round(($r+$m)*255)
        g=[Math]::Round(($g+$m)*255)
        b=[Math]::Round(($b+$m)*255)
    }
}

function Draw-ColorField($colors) {
    $p = HSL-to-RGB $colors.primary.h $colors.primary.s $colors.primary.l
    $s = HSL-to-RGB $colors.secondary.h $colors.secondary.s $colors.secondary.l
    $a = HSL-to-RGB $colors.accent.h $colors.accent.s $colors.accent.l

    $pfg = Get-FG $p.r $p.g $p.b
    $sfg = Get-FG $s.r $s.g $s.b
    $afg = Get-FG $a.r $a.g $a.b

    $blocks = @(
        "   ${pfg}██${RESET}${sfg}██${RESET}${afg}██${RESET}${pfg}██${RESET}${sfg}██${RESET}${afg}██${RESET}"
        "   ${sfg}██${RESET}${afg}██${RESET}${pfg}██${RESET}${sfg}██${RESET}${afg}██${RESET}${pfg}██${RESET}"
        "   ${afg}██${RESET}${pfg}██${RESET}${sfg}██${RESET}${afg}██${RESET}${pfg}██${RESET}${sfg}██${RESET}"
    )

    # Gradient bars
    $gradient = ""
    $gradient2 = ""
    for ($i = 0; $i -lt 40; $i++) {
        $t = $i / 40
        $rh = [Math]::Round($p.r + ($s.r - $p.r) * $t)
        $gh = [Math]::Round($p.g + ($s.g - $p.g) * $t)
        $bh = [Math]::Round($p.b + ($s.b - $p.b) * $t)
        $gradient += (Get-FG $rh $gh $bh) + "█" + $RESET

        $rt = [Math]::Round($s.r + ($a.r - $s.r) * $t)
        $gt = [Math]::Round($s.g + ($a.g - $s.g) * $t)
        $bt = [Math]::Round($s.b + ($a.b - $s.b) * $t)
        $gradient2 += (Get-FG $rt $gt $bt) + "█" + $RESET
    }

    return @(
        "   Color Field I   ${gradient}"
        "   Color Field II  ${gradient2}"
        $blocks[0]
        $blocks[1]
        $blocks[2]
        "   HSL: $($colors.primary.h)° $($colors.primary.s)% $($colors.primary.l)%"
    )
}

# ─── 2. AUDITORY — Rhythm Score ───
function Get-RhythmScore($s) {
    $bpm = 40 + [Math]::Round($s.cpu * 1.5)  # 40-190 BPM
    $notes = @('C4', 'D4', 'E4', 'G4', 'A4', 'C5', 'D5')
    # More processes = more complex harmony
    $chordSize = [Math]::Max(1, [Math]::Min(5, [Math]::Round($s.proc / 50)))

    $rhythm = @()
    for ($i = 0; $i -lt 16; $i++) {
        $hitCPU = ($s.cpu * [Math]::Sin($i * 0.5) + 50) / 100
        $hitRAM = ($s.ram * [Math]::Cos($i * 0.7) + 50) / 100
        $hitChance = ($hitCPU + $hitRAM) / 2
        if ((Get-Random -Maximum 100) -lt ($hitChance * 100)) {
            $noteIdx = $i % $notes.Count
            $note = $notes[$noteIdx]
            $vel = 40 + [Math]::Round(60 * $hitChance)
            $rhythm += "${note}(${vel})"
        } else {
            $rhythm += "---(---)"
        }
    }

    return @{
        bpm = $bpm
        timeSig = if ($s.uptime -gt 24) { '4/4' } else { '3/4' }
        key = if ($s.disk -gt 50) { 'D min' } else { 'C maj' }
        rhythm = $rhythm -join ' | '
        chordSize = $chordSize
    }
}

# ─── 3. TACTILE — Texture Map ───
function Get-TextureMap($s) {
    $textures = @(
        'smooth', 'grainy', 'fibrous', 'velvet', 'sandstone',
        'silken', 'cracked', 'woven', 'polished', 'rusted'
    )
    $patterns = @(
        'herringbone', 'spiral', 'grid', 'random', 'wave',
        'hexagonal', 'dendritic', 'striped', 'checkered', 'radial'
    )

    $cpuTex = [Math]::Round($s.cpu / 10) % $textures.Count
    $ramPat = [Math]::Round($s.ram * 2) % $patterns.Count

    # Build ASCII texture grid
    $grid = @()
    for ($y = 0; $y -lt 8; $y++) {
        $row = "   "
        for ($x = 0; $x -lt 40; $x++) {
            $v = [Math]::Sin($x * 0.3 + $y * 0.5 + $s.cpu * 0.01) * 0.5 + 0.5
            $v2 = [Math]::Cos($x * 0.7 + $y * 0.2 + $s.ram * 0.015) * 0.5 + 0.5
            $combined = ($v + $v2) / 2

            $fg = Get-FG (100+[Math]::Round(155*$combined)) (80+[Math]::Round(120*$v)) (120+[Math]::Round(100*$v2))

            if ($combined -gt 0.75) { $row += "${fg}▓${RESET}" }
            elseif ($combined -gt 0.5) { $row += "${fg}▒${RESET}" }
            elseif ($combined -gt 0.25) { $row += "${fg}░${RESET}" }
            else { $row += "${fg}·${RESET}" }
        }
        $grid += $row
    }

    return @{
        texture = $textures[$cpuTex]
        pattern = $patterns[$ramPat]
        depth = [Math]::Round(1 + $s.disk * 0.04, 1)
        grid = $grid
    }
}

# ─── 4. OLFACTORY — Scent Profile ───
function Get-ScentProfile($s) {
    $notes = @(
        'ozone', 'cedar', 'copper', 'petrichor', 'silicon',
        'ink', 'smoke', 'frost', 'amber', 'iron',
        'thyme', 'myrrh', 'salt', 'pine', 'ash'
    )
    $accords = @(
        'metallic', 'earthy', 'ethereal', 'sharp', 'warm',
        'cold', 'dry', 'sweet', 'bitter', 'bright'
    )

    $topNote = $notes[($s.cpu * 3) % $notes.Count]
    $heartNote = $notes[($s.ram * 5 + $s.disk) % $notes.Count]
    $baseNote = $notes[($s.proc * 7) % $notes.Count]
    $accord = $accords[($s.uptime * 2) % $accords.Count]

    # Longevity from uptime
    $longevity = if ($s.uptime -lt 1) { 'fleeting' }
        elseif ($s.uptime -lt 8) { 'moderate' }
        elseif ($s.uptime -lt 24) { 'long-lasting' }
        else { 'eternal' }

    return @{
        top = $topNote
        heart = $heartNote
        base = $baseNote
        accord = $accord
        longevity = $longevity
        projection = if ($s.cpu -gt 60) { 'intense' } elseif ($s.cpu -gt 30) { 'moderate' } else { 'soft' }
    }
}

# ─── Render full portrait ───
function New-Portrait($s) {
    $colors = Get-ColorField $s
    $rhythm = Get-RhythmScore $s
    $texture = Get-TextureMap $s
    $scent = Get-ScentProfile $s

    $tfg = Get-FG 200 180 160

    $lines = @()

    # Title
    $lines += "${tfg}   ╔══════════════════════════════════════╗"
    $lines += "${tfg}   ║  SYNESTHESIA — Sensory Portrait      ║"
    $lines += "${tfg}   ║  $($s.timestamp)     ║"
    $lines += "${tfg}   ╚══════════════════════════════════════╝"
    $lines += ""

    # System vitals
    $lines += "${tfg}   CPU: $($s.cpu)%  |  RAM: $($s.ram)%  |  Disk: $($s.disk)%  |  Procs: $($s.proc)${RESET}"
    $lines += ""

    # 1. Visual
    $lines += "${tfg}   ── Visual ──${RESET}"
    $lines += (Draw-ColorField $colors)
    $lines += ""

    # 2. Auditory
    $lines += "${tfg}   ── Auditory ──${RESET}"
    $lines += "   BPM: $($rhythm.bpm)  |  Time: $($rhythm.timeSig)  |  Key: $($rhythm.key)  |  Harmony: $($rhythm.chordSize)-voice"
    $lines += ""
    $lines += "   ${tfg}${rhythm.rhythm}${RESET}"
    $lines += ""

    # 3. Tactile
    $lines += "${tfg}   ── Tactile ──${RESET}"
    $lines += "   Texture: $($texture.texture)  |  Pattern: $($texture.pattern)  |  Depth: $($texture.depth)mm"
    $lines += ""
    $lines += $texture.grid
    $lines += ""

    # 4. Olfactory
    $lines += "${tfg}   ── Olfactory ──${RESET}"
    $pFG = Get-FG 180 140 120
    $lines += "   ${pFG}Top note:    $($scent.top)${RESET}"
    $lines += "   ${pFG}Heart note:  $($scent.heart)${RESET}"
    $lines += "   ${pFG}Base note:   $($scent.base)${RESET}"
    $lines += "   ${pFG}Accord:      $($scent.accord)${RESET}"
    $lines += "   ${pFG}Longevity:   $($scent.longevity)${RESET}"
    $lines += "   ${pFG}Projection:  $($scent.projection)${RESET}"

    # Bottle price
    $price = 80 + [Math]::Round($s.cpu + $s.ram + $s.disk)
    $lines += "   ${pFG}Value:       \$${price} USD${RESET}"
    $lines += ""

    # Caption
    $lines += "${tfg}   ══════════════════════════════════════${RESET}"
    $lines += ""
    $lines += "   A sensory portrait of $([Environment]::MachineName)"
    $lines += "   at $($s.timestamp). This moment will never recur."
    $lines += ""

    return $lines -join "`n"
}

# ─── Main ───
Write-Host $CLS -NoNewline
$state = Get-SystemState
$portrait = New-Portrait $state
Write-Host $portrait
Write-Host ""
Write-Host "  ${ESC}[38;2;120;120;120mRun again in any moment for a different portrait.${RESET}"
Write-Host ""

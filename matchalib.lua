--[[
    MatchaLib v2 — Roblox UI Library
    Layout  : Horizontal tabs (top) + two-column content
    Style   : Dark + Pink/Magenta — mejorado v2
    Nuevo   : Logger integrado, icono en título, diseño mejorado

    USO BÁSICO:
        local MatchaLib = loadstring(...)()
        local W = MatchaLib:CreateWindow({
            Title    = "Mi Script",
            Subtitle = "v2.0",
            Icon     = "rbxassetid://0",  -- ImageLabel icon  (opcional)
            IconEmoji= "⭐",              -- Emoji alternativo (opcional, se ignora si hay Icon)
        })
        local tab = W:CreateTab("Aiming")
        tab:AddToggle({ Name="Feature", Default=false, Callback=function(v) end })

        -- Logger (tab separado o ventana flotante)
        local log = MatchaLib:GetLogger()
        log:Info("Script cargado")
        log:Warn("Advertencia ejemplo")
        log:Error("Error ejemplo")
        log:Debug("Debug info")

        MatchaLib:Notify({ Title="Listo", Content="Script cargado", Type="success" })
]]

local MatchaLib  = {}
MatchaLib.__index = MatchaLib
MatchaLib.Flags   = {}

-- ─────────────────────────────────────────────────────────────
-- SERVICIOS
-- ─────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local RunService       = game:GetService("RunService")
local LP               = Players.LocalPlayer

-- ─────────────────────────────────────────────────────────────
-- TEMA
-- ─────────────────────────────────────────────────────────────
local T = {
    -- Fondos
    Bg           = Color3.fromRGB(10, 10, 13),
    BgAlt        = Color3.fromRGB(15, 15, 19),
    BgDeep       = Color3.fromRGB(7,  7,  9),
    Surface      = Color3.fromRGB(20, 20, 26),
    SurfaceHov   = Color3.fromRGB(26, 26, 34),
    SurfaceAct   = Color3.fromRGB(32, 32, 42),
    -- Bordes
    Border       = Color3.fromRGB(35, 35, 48),
    BorderBright = Color3.fromRGB(55, 55, 72),
    -- Accent (rosa principal)
    Accent       = Color3.fromRGB(255, 105, 180),
    AccentDim    = Color3.fromRGB(200,  70, 140),
    AccentGlow   = Color3.fromRGB(255, 140, 200),
    AccentBg     = Color3.fromRGB(50,  15,  38),
    -- Texto
    TextPri      = Color3.fromRGB(232, 232, 238),
    TextSec      = Color3.fromRGB(148, 148, 165),
    TextMuted    = Color3.fromRGB(72,  72,  90),
    -- Elementos
    SliderFill   = Color3.fromRGB(255, 105, 180),
    SliderBg     = Color3.fromRGB(28,  28,  38),
    ToggleOn     = Color3.fromRGB(255, 105, 180),
    ToggleOff    = Color3.fromRGB(35,  35,  48),
    -- Estado
    Success      = Color3.fromRGB(90,  210, 130),
    Warning      = Color3.fromRGB(255, 185,  60),
    Danger       = Color3.fromRGB(220,  70,  70),
    Info         = Color3.fromRGB(90,  170, 255),
    Debug        = Color3.fromRGB(170, 130, 255),
    -- Divisor columnas
    ColDivider   = Color3.fromRGB(30,  30,  42),
}

-- ─────────────────────────────────────────────────────────────
-- UTILIDADES
-- ─────────────────────────────────────────────────────────────
local function tween(obj, props, t, style, dir)
    TweenService:Create(
        obj,
        TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 5)
    c.Parent = parent
    return c
end

local function uiStroke(parent, color, thickness, transp)
    local s = Instance.new("UIStroke")
    s.Color = color or T.Border
    s.Thickness = thickness or 1
    s.Transparency = transp or 0
    s.Parent = parent
    return s
end

local function newFrame(props)
    local f = Instance.new("Frame")
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    for k, v in pairs(props or {}) do f[k] = v end
    return f
end

local function newLabel(props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.BorderSizePixel = 0
    l.Font = Enum.Font.Code
    l.TextSize = 12
    l.TextColor3 = T.TextSec
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.RichText = false
    for k, v in pairs(props or {}) do l[k] = v end
    return l
end

local function pad(parent, t, b, l, r)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft   = UDim.new(0, l or 0)
    p.PaddingRight  = UDim.new(0, r or 0)
    p.Parent = parent
    return p
end

local function timestamp()
    -- Retorna tiempo en segundos desde inicio como string HH:MM:SS
    local t = math.floor(os.clock())
    return string.format("%02d:%02d:%02d", math.floor(t/3600)%24, math.floor(t/60)%60, t%60)
end

-- Drag helper
local function makeDraggable(win, handle)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = i.Position
            startPos  = win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = i.Position - dragStart
            win.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ─────────────────────────────────────────────────────────────
-- NOTIFICACIONES  (mejoradas: icono de tipo, animación suave)
-- ─────────────────────────────────────────────────────────────
local notifGui = Instance.new("ScreenGui")
notifGui.Name           = "MatchaNotifs"
notifGui.ResetOnSpawn   = false
notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() notifGui.Parent = CoreGui end)
if not notifGui.Parent then notifGui.Parent = LP.PlayerGui end

local notifHolder = newFrame({
    Size     = UDim2.new(0, 290, 1, 0),
    Position = UDim2.new(1, -302, 0, 0),
    Parent   = notifGui,
})
local notifLayout = Instance.new("UIListLayout")
notifLayout.SortOrder         = Enum.SortOrder.LayoutOrder
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifLayout.Padding           = UDim.new(0, 6)
notifLayout.Parent            = notifHolder
local notifPad = Instance.new("UIPadding")
notifPad.PaddingBottom = UDim.new(0, 16)
notifPad.Parent        = notifHolder

function MatchaLib:Notify(opts)
    opts = opts or {}
    local typeData = {
        success = { color = T.Success, icon = "✓" },
        error   = { color = T.Danger,  icon = "✕" },
        warn    = { color = T.Warning, icon = "!" },
        info    = { color = T.Info,    icon = "i" },
    }
    local td = typeData[opts.Type] or { color = T.Accent, icon = "·" }

    local card = Instance.new("Frame")
    card.Size             = UDim2.new(1, 0, 0, 68)
    card.BackgroundColor3 = T.Surface
    card.BorderSizePixel  = 0
    card.ClipsDescendants = false
    card.Parent           = notifHolder
    corner(card, 7)
    uiStroke(card, T.Border, 1)

    -- Glow sutil al borde
    local glowStroke = uiStroke(card, td.color, 1, 0.75)

    -- Barra lateral de color
    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(0, 3, 0.72, 0)
    bar.Position         = UDim2.new(0, 0, 0.14, 0)
    bar.BackgroundColor3 = td.color
    bar.BorderSizePixel  = 0
    bar.Parent           = card
    corner(bar, 2)

    -- Badge de tipo (círculo con icono)
    local badge = Instance.new("Frame")
    badge.Size             = UDim2.new(0, 20, 0, 20)
    badge.Position         = UDim2.new(0, 12, 0.5, -10)
    badge.BackgroundColor3 = T.AccentBg
    badge.BorderSizePixel  = 0
    badge.ZIndex           = 2
    badge.Parent           = card
    corner(badge, 10)
    uiStroke(badge, td.color, 1)
    -- tint de color para el badge
    badge.BackgroundColor3 = Color3.fromRGB(
        math.floor(td.color.R * 255 * 0.15),
        math.floor(td.color.G * 255 * 0.15),
        math.floor(td.color.B * 255 * 0.15)
    )
    local badgeIcon = newLabel({
        Size             = UDim2.new(1, 0, 1, 0),
        Text             = td.icon,
        TextColor3       = td.color,
        Font             = Enum.Font.GothamBold,
        TextSize         = 11,
        TextXAlignment   = Enum.TextXAlignment.Center,
        ZIndex           = 3,
        Parent           = badge,
    })

    -- Título
    newLabel({
        Size       = UDim2.new(1, -52, 0, 22),
        Position   = UDim2.new(0, 40, 0, 10),
        Text       = opts.Title or "MatchaLib",
        TextColor3 = T.TextPri,
        Font       = Enum.Font.GothamBold,
        TextSize   = 12,
        ZIndex     = 2,
        Parent     = card,
    })
    -- Contenido
    newLabel({
        Size     = UDim2.new(1, -52, 0, 22),
        Position = UDim2.new(0, 40, 0, 32),
        Text     = opts.Content or "",
        TextSize = 11,
        ZIndex   = 2,
        Parent   = card,
    })

    -- Barra de progreso inferior
    local prog = Instance.new("Frame")
    prog.Size             = UDim2.new(1, -2, 0, 2)
    prog.Position         = UDim2.new(0, 1, 1, -3)
    prog.BackgroundColor3 = td.color
    prog.BorderSizePixel  = 0
    prog.ZIndex           = 2
    prog.Parent           = card
    corner(prog, 1)

    local dur = opts.Duration or 4
    card.Position = UDim2.new(1, 14, 0, 0)
    tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.3, Enum.EasingStyle.Back)
    tween(prog, { Size = UDim2.new(0, 0, 0, 2) }, dur, Enum.EasingStyle.Linear)

    task.delay(dur, function()
        tween(card, { Position = UDim2.new(1, 14, 0, 0) }, 0.22)
        task.wait(0.25)
        card:Destroy()
    end)
end

-- ─────────────────────────────────────────────────────────────
-- LOGGER  (ventana flotante independiente)
-- ─────────────────────────────────────────────────────────────
local loggerInstance = nil

function MatchaLib:GetLogger()
    if loggerInstance then return loggerInstance end

    local LW, LH = 480, 280
    local logEntries = {}
    local filterLevel = "ALL"
    local autoscroll  = true

    local lgui = Instance.new("ScreenGui")
    lgui.Name           = "MatchaLogger"
    lgui.ResetOnSpawn   = false
    lgui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    lgui.IgnoreGuiInset = true
    pcall(function() lgui.Parent = CoreGui end)
    if not lgui.Parent then lgui.Parent = LP.PlayerGui end

    -- Ventana
    local lmain = Instance.new("Frame")
    lmain.Size             = UDim2.new(0, LW, 0, LH)
    lmain.Position         = UDim2.new(0, 16, 0.5, -LH/2)
    lmain.BackgroundColor3 = T.BgDeep
    lmain.BorderSizePixel  = 0
    lmain.Parent           = lgui
    corner(lmain, 8)
    uiStroke(lmain, T.Border, 1)

    -- TitleBar del logger
    local ltb = Instance.new("Frame")
    ltb.Size             = UDim2.new(1, 0, 0, 32)
    ltb.BackgroundColor3 = T.BgAlt
    ltb.BorderSizePixel  = 0
    ltb.ZIndex           = 3
    ltb.Parent           = lmain
    corner(ltb, 8)
    newFrame({
        Size             = UDim2.new(1, 0, 0, 10),
        Position         = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = T.BgAlt,
        ZIndex           = 3,
        Parent           = ltb,
    })
    uiStroke(ltb, T.Border, 1)

    -- Pip accent
    local lpip = Instance.new("Frame")
    lpip.Size             = UDim2.new(0, 3, 0, 14)
    lpip.Position         = UDim2.new(0, 10, 0.5, -7)
    lpip.BackgroundColor3 = T.Debug
    lpip.BorderSizePixel  = 0
    lpip.ZIndex           = 4
    lpip.Parent           = ltb
    corner(lpip, 2)

    newLabel({
        Size       = UDim2.new(0.5, 0, 1, 0),
        Position   = UDim2.new(0, 22, 0, 0),
        Text       = "[ DEV LOGGER ]",
        TextColor3 = T.Debug,
        Font       = Enum.Font.Code,
        TextSize   = 11,
        ZIndex     = 4,
        Parent     = ltb,
    })

    -- Contador de entradas
    local countLbl = newLabel({
        Size             = UDim2.new(0, 80, 1, 0),
        Position         = UDim2.new(0.5, -40, 0, 0),
        Text             = "0 entries",
        TextColor3       = T.TextMuted,
        Font             = Enum.Font.Code,
        TextSize         = 10,
        TextXAlignment   = Enum.TextXAlignment.Center,
        ZIndex           = 4,
        Parent           = ltb,
    })

    -- Botón cerrar logger
    local lclose = Instance.new("TextButton")
    lclose.Size             = UDim2.new(0, 22, 0, 22)
    lclose.Position         = UDim2.new(1, -28, 0.5, -11)
    lclose.BackgroundColor3 = T.Surface
    lclose.BorderSizePixel  = 0
    lclose.Text             = "×"
    lclose.Font             = Enum.Font.GothamBold
    lclose.TextSize         = 13
    lclose.TextColor3       = T.TextSec
    lclose.ZIndex           = 5
    lclose.Parent           = ltb
    corner(lclose, 5)
    lclose.MouseEnter:Connect(function() tween(lclose, { BackgroundColor3 = Color3.fromRGB(180, 50, 50) }, 0.1) end)
    lclose.MouseLeave:Connect(function() tween(lclose, { BackgroundColor3 = T.Surface }, 0.1) end)
    lclose.MouseButton1Click:Connect(function() lmain.Visible = false end)

    makeDraggable(lmain, ltb)

    -- ── Barra de filtros ─────────────────────────────────────
    local filterBar = Instance.new("Frame")
    filterBar.Size             = UDim2.new(1, 0, 0, 26)
    filterBar.Position         = UDim2.new(0, 0, 0, 32)
    filterBar.BackgroundColor3 = T.Bg
    filterBar.BorderSizePixel  = 0
    filterBar.ZIndex           = 3
    filterBar.Parent           = lmain
    uiStroke(filterBar, T.Border, 1)

    local filterLayout = Instance.new("UIListLayout")
    filterLayout.FillDirection = Enum.FillDirection.Horizontal
    filterLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    filterLayout.Padding = UDim.new(0, 4)
    filterLayout.Parent = filterBar
    pad(filterBar, 0, 0, 8, 4)

    local filterLevels = {
        { id = "ALL",   label = "All",   color = T.TextSec  },
        { id = "INFO",  label = "Info",  color = T.Info     },
        { id = "WARN",  label = "Warn",  color = T.Warning  },
        { id = "ERROR", label = "Error", color = T.Danger   },
        { id = "DEBUG", label = "Debug", color = T.Debug    },
    }

    local filterBtns = {}
    local logScroll  -- forward ref

    local function applyFilter()
        if not logScroll then return end
        local count = 0
        for _, entry in ipairs(logEntries) do
            local show = filterLevel == "ALL" or entry.level == filterLevel
            if entry.frame then
                entry.frame.Visible = show
            end
            if show then count += 1 end
        end
        countLbl.Text = count .. " entries"
        if autoscroll then
            logScroll.CanvasPosition = Vector2.new(0, logScroll.AbsoluteCanvasSize.Y)
        end
    end

    for _, fd in ipairs(filterLevels) do
        local fb = Instance.new("TextButton")
        fb.Size             = UDim2.new(0, 46, 0, 18)
        fb.BackgroundColor3 = fd.id == filterLevel and T.SurfaceAct or T.Surface
        fb.BorderSizePixel  = 0
        fb.Text             = fd.label
        fb.Font             = Enum.Font.Code
        fb.TextSize         = 10
        fb.TextColor3       = fd.id == filterLevel and fd.color or T.TextMuted
        fb.AutoButtonColor  = false
        fb.ZIndex           = 4
        fb.Parent           = filterBar
        corner(fb, 4)
        uiStroke(fb, fd.id == filterLevel and fd.color or T.Border, 1)

        filterBtns[fd.id] = { btn = fb, color = fd.color }

        fb.MouseButton1Click:Connect(function()
            filterLevel = fd.id
            for lid, ldata in pairs(filterBtns) do
                local active = lid == filterLevel
                tween(ldata.btn, { BackgroundColor3 = active and T.SurfaceAct or T.Surface }, 0.1)
                ldata.btn.TextColor3 = active and ldata.color or T.TextMuted
                local st = ldata.btn:FindFirstChildOfClass("UIStroke")
                if st then st.Color = active and ldata.color or T.Border end
            end
            applyFilter()
        end)
    end

    -- Botón Clear
    local clearBtn = Instance.new("TextButton")
    clearBtn.Size             = UDim2.new(0, 44, 0, 18)
    clearBtn.BackgroundColor3 = T.Surface
    clearBtn.BorderSizePixel  = 0
    clearBtn.Text             = "Clear"
    clearBtn.Font             = Enum.Font.Code
    clearBtn.TextSize         = 10
    clearBtn.TextColor3       = T.Danger
    clearBtn.AutoButtonColor  = false
    clearBtn.ZIndex           = 4
    clearBtn.Parent           = filterBar
    corner(clearBtn, 4)
    uiStroke(clearBtn, T.Danger, 1)
    clearBtn.MouseEnter:Connect(function() tween(clearBtn, { BackgroundColor3 = Color3.fromRGB(40, 10, 10) }, 0.1) end)
    clearBtn.MouseLeave:Connect(function() tween(clearBtn, { BackgroundColor3 = T.Surface }, 0.1) end)
    clearBtn.MouseButton1Click:Connect(function()
        for _, entry in ipairs(logEntries) do
            if entry.frame then entry.frame:Destroy() end
        end
        logEntries = {}
        countLbl.Text = "0 entries"
    end)

    -- ── Área de scroll del log ───────────────────────────────
    logScroll = Instance.new("ScrollingFrame")
    logScroll.Size                   = UDim2.new(1, 0, 1, -58)
    logScroll.Position               = UDim2.new(0, 0, 0, 58)
    logScroll.BackgroundColor3       = T.BgDeep
    logScroll.BorderSizePixel        = 0
    logScroll.ScrollBarThickness     = 3
    logScroll.ScrollBarImageColor3   = T.Debug
    logScroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
    logScroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    logScroll.ZIndex                 = 2
    logScroll.Parent                 = lmain

    local logList = Instance.new("UIListLayout")
    logList.SortOrder = Enum.SortOrder.LayoutOrder
    logList.Padding   = UDim.new(0, 0)
    logList.Parent    = logScroll
    pad(logScroll, 4, 4, 0, 0)

    -- Línea divisora top del área
    local ldiv = Instance.new("Frame")
    ldiv.Size             = UDim2.new(1, 0, 0, 1)
    ldiv.Position         = UDim2.new(0, 0, 0, 57)
    ldiv.BackgroundColor3 = T.Border
    ldiv.BorderSizePixel  = 0
    ldiv.ZIndex           = 4
    ldiv.Parent           = lmain

    -- ── Función interna de añadir entrada ───────────────────
    local levelMeta = {
        INFO  = { tag = " INFO ", color = T.Info,    bg = Color3.fromRGB(8, 20, 40)   },
        WARN  = { tag = " WARN ", color = T.Warning, bg = Color3.fromRGB(38, 28, 5)   },
        ERROR = { tag = "ERROR!", color = T.Danger,  bg = Color3.fromRGB(38, 8,  8)   },
        DEBUG = { tag = "DEBUG", color = T.Debug,   bg = Color3.fromRGB(22, 12, 40)  },
    }

    local entryOrder = 0
    local function addEntry(level, msg)
        local meta = levelMeta[level] or levelMeta.INFO
        entryOrder += 1

        local row = Instance.new("Frame")
        row.Size             = UDim2.new(1, 0, 0, 22)
        row.BackgroundColor3 = entryOrder % 2 == 0 and T.Surface or T.Bg
        row.BorderSizePixel  = 0
        row.LayoutOrder      = entryOrder
        row.ZIndex           = 3
        row.Parent           = logScroll
        -- subtle left accent line
        local accent = Instance.new("Frame")
        accent.Size             = UDim2.new(0, 2, 1, 0)
        accent.BackgroundColor3 = meta.color
        accent.BackgroundTransparency = 0.6
        accent.BorderSizePixel  = 0
        accent.ZIndex           = 4
        accent.Parent           = row

        -- Timestamp
        newLabel({
            Size       = UDim2.new(0, 58, 1, 0),
            Position   = UDim2.new(0, 6, 0, 0),
            Text       = timestamp(),
            TextColor3 = T.TextMuted,
            Font       = Enum.Font.Code,
            TextSize   = 10,
            ZIndex     = 4,
            Parent     = row,
        })

        -- Badge de nivel
        local badge = Instance.new("Frame")
        badge.Size             = UDim2.new(0, 42, 0, 14)
        badge.Position         = UDim2.new(0, 66, 0.5, -7)
        badge.BackgroundColor3 = meta.bg
        badge.BorderSizePixel  = 0
        badge.ZIndex           = 5
        badge.Parent           = row
        corner(badge, 3)
        uiStroke(badge, meta.color, 1, 0.5)
        newLabel({
            Size             = UDim2.new(1, 0, 1, 0),
            Text             = meta.tag,
            TextColor3       = meta.color,
            Font             = Enum.Font.Code,
            TextSize         = 9,
            TextXAlignment   = Enum.TextXAlignment.Center,
            ZIndex           = 6,
            Parent           = badge,
        })

        -- Mensaje
        newLabel({
            Size       = UDim2.new(1, -118, 1, 0),
            Position   = UDim2.new(0, 114, 0, 0),
            Text       = tostring(msg),
            TextColor3 = T.TextPri,
            Font       = Enum.Font.Code,
            TextSize   = 11,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex     = 4,
            Parent     = row,
        })

        local entry = { level = level, frame = row, ts = timestamp(), msg = tostring(msg) }
        table.insert(logEntries, entry)

        local show = filterLevel == "ALL" or filterLevel == level
        row.Visible = show

        -- Actualizar contador
        local count = 0
        for _, e in ipairs(logEntries) do
            if filterLevel == "ALL" or e.level == filterLevel then count += 1 end
        end
        countLbl.Text = count .. " entries"

        if autoscroll and show then
            task.defer(function()
                logScroll.CanvasPosition = Vector2.new(0, logScroll.AbsoluteCanvasSize.Y)
            end)
        end
    end

    -- Objeto logger público
    local logger = {}
    function logger:Info(msg)  addEntry("INFO",  msg) end
    function logger:Warn(msg)  addEntry("WARN",  msg) end
    function logger:Error(msg) addEntry("ERROR", msg) end
    function logger:Debug(msg) addEntry("DEBUG", msg) end
    function logger:Log(level, msg)
        local l = string.upper(level or "INFO")
        addEntry(l, msg)
    end
    function logger:Clear()
        for _, entry in ipairs(logEntries) do
            if entry.frame then entry.frame:Destroy() end
        end
        logEntries = {}
        countLbl.Text = "0 entries"
    end
    function logger:SetVisible(v)
        lmain.Visible = v
    end
    function logger:Toggle()
        lmain.Visible = not lmain.Visible
    end

    loggerInstance = logger
    return logger
end

-- ─────────────────────────────────────────────────────────────
-- CONSTRUCTOR DE ELEMENTOS
-- ─────────────────────────────────────────────────────────────
local function buildElements(col)
    local el = {}

    -- ── SECTION ─────────────────────────────────────────────
    function el:AddSection(name)
        -- Separador visual mejorado: línea + texto
        local wrap = newFrame({ Size = UDim2.new(1, 0, 0, 22), Parent = col })

        local line = Instance.new("Frame")
        line.Size             = UDim2.new(1, 0, 0, 1)
        line.Position         = UDim2.new(0, 0, 0.5, 0)
        line.BackgroundColor3 = T.Border
        line.BorderSizePixel  = 0
        line.Parent           = wrap

        local bg = Instance.new("Frame")
        bg.Size             = UDim2.new(0, 0, 1, 0)
        bg.AnchorPoint      = Vector2.new(0, 0.5)
        bg.Position         = UDim2.new(0, 0, 0.5, 0)
        bg.AutomaticSize    = Enum.AutomaticSize.X
        bg.BackgroundColor3 = T.Bg
        bg.BorderSizePixel  = 0
        bg.ZIndex           = 2
        bg.Parent           = wrap

        local lbl = newLabel({
            Size             = UDim2.new(0, 0, 1, 0),
            AutomaticSize    = Enum.AutomaticSize.X,
            Text             = name,
            TextColor3       = T.Accent,
            Font             = Enum.Font.Code,
            TextSize         = 10,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 3,
            Parent           = bg,
        })
        pad(bg, 0, 0, 0, 6)

        return { Set = function(_, t) lbl.Text = t end }
    end

    -- ── LABEL ────────────────────────────────────────────────
    function el:AddLabel(text)
        local lbl = newLabel({
            Size       = UDim2.new(1, 0, 0, 16),
            Text       = text,
            TextSize   = 11,
            TextColor3 = T.TextMuted,
            Parent     = col,
        })
        return { Set = function(_, t) lbl.Text = t end }
    end

    -- ── TOGGLE ──────────────────────────────────────────────
    function el:AddToggle(opts)
        opts = opts or {}
        local val = opts.Default or false

        local row = Instance.new("Frame")
        row.Size             = UDim2.new(1, 0, 0, 26)
        row.BackgroundColor3 = T.Surface
        row.BorderSizePixel  = 0
        row.Parent           = col
        corner(row, 5)
        uiStroke(row, T.Border, 1)
        pad(row, 0, 0, 8, 8)

        local function rowColor()
            tween(row, { BackgroundColor3 = val and T.AccentBg or T.Surface }, 0.12)
            local st = row:FindFirstChildOfClass("UIStroke")
            if st then tween(st, { Color = val and T.AccentDim or T.Border }, 0.12) end
        end

        -- Toggle pill (estilo moderno)
        local pillW, pillH = 28, 14
        local pill = Instance.new("Frame")
        pill.Size             = UDim2.new(0, pillW, 0, pillH)
        pill.Position         = UDim2.new(0, 0, 0.5, -pillH/2)
        pill.BackgroundColor3 = val and T.ToggleOn or T.ToggleOff
        pill.BorderSizePixel  = 0
        pill.ZIndex           = 2
        pill.Parent           = row
        corner(pill, 7)
        uiStroke(pill, val and T.Accent or T.Border, 1)

        -- Knob que se desliza
        local knob = Instance.new("Frame")
        knob.Size             = UDim2.new(0, 10, 0, 10)
        knob.Position         = UDim2.new(0, val and (pillW - 12) or 2, 0.5, -5)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.BorderSizePixel  = 0
        knob.ZIndex           = 3
        knob.Parent           = pill
        corner(knob, 5)

        -- Nombre
        local nameLbl = newLabel({
            Size       = UDim2.new(1, -(pillW + 12 + (opts.Bind and 58 or 0)), 1, 0),
            Position   = UDim2.new(0, pillW + 8, 0, 0),
            Text       = opts.Name or "Toggle",
            TextColor3 = val and T.TextPri or T.TextSec,
            TextSize   = 12,
            ZIndex     = 2,
            Parent     = row,
        })

        -- Keybind
        local bindBtn
        if opts.Bind then
            bindBtn = Instance.new("TextButton")
            bindBtn.Size             = UDim2.new(0, 52, 0, 16)
            bindBtn.Position         = UDim2.new(1, -52, 0.5, -8)
            bindBtn.BackgroundColor3 = T.BgAlt
            bindBtn.BorderSizePixel  = 0
            bindBtn.Text             = opts.Bind
            bindBtn.Font             = Enum.Font.Code
            bindBtn.TextSize         = 10
            bindBtn.TextColor3       = T.TextSec
            bindBtn.ZIndex           = 4
            bindBtn.Parent           = row
            corner(bindBtn, 3)
            uiStroke(bindBtn, T.Border)
        end

        local btn = Instance.new("TextButton")
        btn.Size                   = UDim2.new(1, bindBtn and -62 or 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text                   = ""
        btn.ZIndex                 = 5
        btn.Parent                 = row

        local function update()
            tween(pill,  { BackgroundColor3 = val and T.ToggleOn or T.ToggleOff }, 0.12)
            tween(knob,  { Position = UDim2.new(0, val and (pillW - 12) or 2, 0.5, -5) }, 0.12)
            local pst = pill:FindFirstChildOfClass("UIStroke")
            if pst then pst.Color = val and T.Accent or T.Border end
            tween(nameLbl, { TextColor3 = val and T.TextPri or T.TextSec }, 0.12)
            rowColor()
            if opts.Flag then MatchaLib.Flags[opts.Flag] = { Value = val } end
            if opts.Callback then opts.Callback(val) end
        end

        btn.MouseButton1Click:Connect(function() val = not val; update() end)
        rowColor()
        if opts.Flag then MatchaLib.Flags[opts.Flag] = { Value = val } end

        return {
            Set      = function(_, v) val = v; update() end,
            GetValue = function() return val end,
        }
    end

    -- ── SLIDER ──────────────────────────────────────────────
    function el:AddSlider(opts)
        opts = opts or {}
        local minV = opts.Min       or 0
        local maxV = opts.Max       or 100
        local val  = opts.Default   or minV
        local inc  = opts.Increment or 1
        local suf  = opts.Suffix    or opts.ValueName or ""

        local wrap = Instance.new("Frame")
        wrap.Size             = UDim2.new(1, 0, 0, 44)
        wrap.BackgroundColor3 = T.Surface
        wrap.BorderSizePixel  = 0
        wrap.Parent           = col
        corner(wrap, 5)
        uiStroke(wrap, T.Border, 1)
        pad(wrap, 4, 4, 8, 8)

        -- Header: nombre + valor actual
        local header = newFrame({ Size = UDim2.new(1, 0, 0, 16), Parent = wrap })

        newLabel({
            Size       = UDim2.new(0.6, 0, 1, 0),
            Text       = opts.Name or "Slider",
            TextColor3 = T.TextSec,
            TextSize   = 11,
            Parent     = header,
        })

        local valDisplay = newLabel({
            Size             = UDim2.new(0.4, 0, 1, 0),
            Position         = UDim2.new(0.6, 0, 0, 0),
            Text             = tostring(val) .. (suf ~= "" and " " .. suf or ""),
            TextColor3       = T.Accent,
            Font             = Enum.Font.GothamBold,
            TextSize         = 11,
            TextXAlignment   = Enum.TextXAlignment.Right,
            Parent           = header,
        })

        -- Track
        local track = Instance.new("Frame")
        track.Size             = UDim2.new(1, 0, 0, 8)
        track.Position         = UDim2.new(0, 0, 0, 22)
        track.BackgroundColor3 = T.SliderBg
        track.BorderSizePixel  = 0
        track.Parent           = wrap
        corner(track, 4)
        uiStroke(track, T.Border)

        local fill = Instance.new("Frame")
        fill.Size             = UDim2.new((val - minV) / (maxV - minV), 0, 1, 0)
        fill.BackgroundColor3 = T.SliderFill
        fill.BorderSizePixel  = 0
        fill.ZIndex           = 2
        fill.Parent           = track
        corner(fill, 4)

        -- Knob del slider
        local slKnob = Instance.new("Frame")
        local kfrac = (val - minV) / (maxV - minV)
        slKnob.Size             = UDim2.new(0, 12, 0, 12)
        slKnob.AnchorPoint      = Vector2.new(0.5, 0.5)
        slKnob.Position         = UDim2.new(kfrac, 0, 0.5, 0)
        slKnob.BackgroundColor3 = T.AccentGlow
        slKnob.BorderSizePixel  = 0
        slKnob.ZIndex           = 4
        slKnob.Parent           = track
        corner(slKnob, 6)
        uiStroke(slKnob, T.Accent, 1.5)

        local hit = Instance.new("TextButton")
        hit.Size                   = UDim2.new(1, 0, 0, 20)
        hit.Position               = UDim2.new(0, 0, 0.5, -10)
        hit.BackgroundTransparency = 1
        hit.Text                   = ""
        hit.ZIndex                 = 5
        hit.Parent                 = track

        local dragging = false

        local function updateVal(x)
            local rel = math.clamp(
                (x - track.AbsolutePosition.X) / track.AbsoluteSize.X,
                0, 1
            )
            local raw = minV + (maxV - minV) * rel
            val = math.floor(raw / inc + 0.5) * inc
            val = math.clamp(math.floor(val * 10000 + 0.5) / 10000, minV, maxV)
            local frac = (val - minV) / (maxV - minV)
            fill.Size       = UDim2.new(frac, 0, 1, 0)
            slKnob.Position = UDim2.new(frac, 0, 0.5, 0)
            valDisplay.Text = tostring(val) .. (suf ~= "" and " " .. suf or "")
            if opts.Flag     then MatchaLib.Flags[opts.Flag] = { Value = val } end
            if opts.Callback then opts.Callback(val) end
        end

        hit.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true; updateVal(i.Position.X)
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                updateVal(i.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)

        if opts.Flag then MatchaLib.Flags[opts.Flag] = { Value = val } end

        return {
            Set = function(_, v)
                val = math.clamp(v, minV, maxV)
                local frac = (val - minV) / (maxV - minV)
                fill.Size       = UDim2.new(frac, 0, 1, 0)
                slKnob.Position = UDim2.new(frac, 0, 0.5, 0)
                valDisplay.Text = tostring(val) .. (suf ~= "" and " " .. suf or "")
            end,
            GetValue = function() return val end,
        }
    end

    -- ── DROPDOWN ────────────────────────────────────────────
    function el:AddDropdown(opts)
        opts = opts or {}
        local options = opts.Options or {}
        local val     = opts.Default or (options[1] or "")
        local open    = false

        local container = Instance.new("Frame")
        container.Size                   = UDim2.new(1, 0, 0, 42)
        container.BackgroundTransparency = 1
        container.ClipsDescendants       = false
        container.Parent                 = col

        newLabel({
            Size       = UDim2.new(1, 0, 0, 15),
            Text       = opts.Name or "Dropdown",
            TextColor3 = T.TextSec,
            TextSize   = 11,
            Parent     = container,
        })

        local box = Instance.new("Frame")
        box.Size             = UDim2.new(1, 0, 0, 22)
        box.Position         = UDim2.new(0, 0, 0, 17)
        box.BackgroundColor3 = T.Surface
        box.BorderSizePixel  = 0
        box.Parent           = container
        corner(box, 5)
        uiStroke(box, T.Border)

        local valLbl = newLabel({
            Size     = UDim2.new(1, -26, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            Text     = val,
            TextColor3 = T.TextPri,
            TextSize = 11,
            Parent   = box,
        })

        -- Chevron animado
        local chevron = newLabel({
            Size             = UDim2.new(0, 20, 1, 0),
            Position         = UDim2.new(1, -20, 0, 0),
            Text             = "▾",
            TextColor3       = T.Accent,
            TextXAlignment   = Enum.TextXAlignment.Center,
            TextSize         = 12,
            Parent           = box,
        })

        local ITEM_H = 22
        local panel = Instance.new("Frame")
        panel.Size             = UDim2.new(1, 0, 0, 0)
        panel.Position         = UDim2.new(0, 0, 0, 42)
        panel.BackgroundColor3 = T.Surface
        panel.BorderSizePixel  = 0
        panel.ClipsDescendants = true
        panel.ZIndex           = 20
        panel.Parent           = container
        corner(panel, 5)
        uiStroke(panel, T.Border)

        local pLayout = Instance.new("UIListLayout"); pLayout.Parent = panel
        pad(panel, 3, 3, 0, 0)

        local function rebuildOptions(list)
            for _, c in ipairs(panel:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            for _, opt in ipairs(list) do
                local ob = Instance.new("TextButton")
                ob.Size                   = UDim2.new(1, 0, 0, ITEM_H)
                ob.BackgroundTransparency = 1
                ob.Text                   = opt
                ob.Font                   = Enum.Font.Code
                ob.TextSize               = 11
                ob.TextColor3             = opt == val and T.Accent or T.TextPri
                ob.TextXAlignment         = Enum.TextXAlignment.Left
                ob.ZIndex                 = 21
                ob.Parent                 = panel
                local ip = Instance.new("UIPadding"); ip.PaddingLeft = UDim.new(0, 10); ip.Parent = ob

                -- Tick para opción activa
                local tick = newLabel({
                    Size             = UDim2.new(0, 16, 1, 0),
                    Position         = UDim2.new(1, -18, 0, 0),
                    Text             = opt == val and "✓" or "",
                    TextColor3       = T.Accent,
                    TextXAlignment   = Enum.TextXAlignment.Center,
                    TextSize         = 10,
                    ZIndex           = 22,
                    Parent           = ob,
                })

                ob.MouseEnter:Connect(function()
                    ob.BackgroundTransparency = 0
                    ob.BackgroundColor3 = T.SurfaceHov
                end)
                ob.MouseLeave:Connect(function() ob.BackgroundTransparency = 1 end)
                ob.MouseButton1Click:Connect(function()
                    val = opt
                    valLbl.Text = val
                    for _, c2 in ipairs(panel:GetChildren()) do
                        if c2:IsA("TextButton") then
                            local active = c2.Text == val
                            c2.TextColor3 = active and T.Accent or T.TextPri
                            local tk = c2:FindFirstChildOfClass("TextLabel")
                            if tk then tk.Text = active and "✓" or "" end
                        end
                    end
                    open = false
                    tween(panel,     { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                    tween(container, { Size = UDim2.new(1, 0, 0, 42) }, 0.15)
                    tween(chevron,   { Rotation = 0 }, 0.15)
                    if opts.Flag     then MatchaLib.Flags[opts.Flag] = { Value = val } end
                    if opts.Callback then opts.Callback(val) end
                end)
            end
        end
        rebuildOptions(options)

        local hitBtn = Instance.new("TextButton")
        hitBtn.Size                   = UDim2.new(1, 0, 0, 22)
        hitBtn.Position               = UDim2.new(0, 0, 0, 17)
        hitBtn.BackgroundTransparency = 1
        hitBtn.Text                   = ""
        hitBtn.ZIndex                 = 6
        hitBtn.Parent                 = container

        hitBtn.MouseButton1Click:Connect(function()
            open = not open
            local ph = math.min(#options, 7) * ITEM_H + 6
            if open then
                tween(panel,     { Size = UDim2.new(1, 0, 0, ph) }, 0.18)
                tween(container, { Size = UDim2.new(1, 0, 0, 42 + ph + 2) }, 0.18)
                tween(chevron,   { Rotation = 180 }, 0.15)
                tween(box,       { BackgroundColor3 = T.SurfaceHov }, 0.1)
            else
                tween(panel,     { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                tween(container, { Size = UDim2.new(1, 0, 0, 42) }, 0.15)
                tween(chevron,   { Rotation = 0 }, 0.15)
                tween(box,       { BackgroundColor3 = T.Surface }, 0.1)
            end
        end)

        if opts.Flag then MatchaLib.Flags[opts.Flag] = { Value = val } end

        return {
            Set     = function(_, v) val = v; valLbl.Text = v end,
            Refresh = function(_, list, clear)
                if clear then options = {} end
                for _, o in ipairs(list) do table.insert(options, o) end
                rebuildOptions(options)
            end,
            GetValue = function() return val end,
        }
    end

    -- ── COLORPICKER ─────────────────────────────────────────
    function el:AddColorpicker(opts)
        opts = opts or {}
        local val      = opts.Default or Color3.new(1, 1, 1)
        local open     = false
        local h, s, v2 = Color3.toHSV(val)

        local container = Instance.new("Frame")
        container.Size                   = UDim2.new(1, 0, 0, 26)
        container.BackgroundTransparency = 1
        container.ClipsDescendants       = false
        container.Parent                 = col

        local topRow = Instance.new("Frame")
        topRow.Size             = UDim2.new(1, 0, 0, 26)
        topRow.BackgroundColor3 = T.Surface
        topRow.BorderSizePixel  = 0
        topRow.Parent           = container
        corner(topRow, 5)
        uiStroke(topRow, T.Border)
        pad(topRow, 0, 0, 8, 8)

        newLabel({
            Size       = UDim2.new(1, -50, 1, 0),
            Text       = opts.Name or "Color",
            TextColor3 = T.TextSec,
            TextSize   = 11,
            Parent     = topRow,
        })

        -- Hex display
        local hexLbl = newLabel({
            Size             = UDim2.new(0, 58, 1, 0),
            Position         = UDim2.new(1, -78, 0, 0),
            Text             = "#FFAACC",
            TextColor3       = T.TextMuted,
            Font             = Enum.Font.Code,
            TextSize         = 9,
            TextXAlignment   = Enum.TextXAlignment.Right,
            Parent           = topRow,
        })

        local preview = Instance.new("Frame")
        preview.Size             = UDim2.new(0, 18, 0, 18)
        preview.Position         = UDim2.new(1, -18, 0.5, -9)
        preview.BackgroundColor3 = val
        preview.BorderSizePixel  = 0
        preview.ZIndex           = 3
        preview.Parent           = topRow
        corner(preview, 4)
        uiStroke(preview, T.Border)

        local hbtn = Instance.new("TextButton")
        hbtn.Size                   = UDim2.new(1, 0, 1, 0)
        hbtn.BackgroundTransparency = 1
        hbtn.Text                   = ""
        hbtn.ZIndex                 = 4
        hbtn.Parent                 = topRow

        local panel = Instance.new("Frame")
        panel.Size             = UDim2.new(1, 0, 0, 0)
        panel.Position         = UDim2.new(0, 0, 0, 28)
        panel.BackgroundColor3 = T.Surface
        panel.BorderSizePixel  = 0
        panel.ClipsDescendants = true
        panel.ZIndex           = 20
        panel.Parent           = container
        corner(panel, 5)
        uiStroke(panel, T.Border)

        local pLayout = Instance.new("UIListLayout"); pLayout.Padding = UDim.new(0, 5); pLayout.Parent = panel
        pad(panel, 8, 8, 10, 10)

        local function toHex(c)
            return string.format("#%02X%02X%02X",
                math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
        end

        local function commit()
            val = Color3.fromHSV(h, s, v2)
            preview.BackgroundColor3 = val
            hexLbl.Text = toHex(val)
            if opts.Flag     then MatchaLib.Flags[opts.Flag] = { Value = val } end
            if opts.Callback then opts.Callback(val) end
        end

        local function hsvRow(lText, initV, cb)
            local row = newFrame({ Size = UDim2.new(1, 0, 0, 18), ZIndex = 21, Parent = panel })
            newLabel({ Size=UDim2.new(0,10,1,0), Text=lText, TextColor3=T.TextMuted, TextSize=9, ZIndex=22, Parent=row })
            local bg = Instance.new("Frame")
            bg.Size             = UDim2.new(1, -16, 0, 6)
            bg.Position         = UDim2.new(0, 14, 0.5, -3)
            bg.BackgroundColor3 = T.SliderBg
            bg.BorderSizePixel  = 0; bg.ZIndex = 22
            bg.Parent           = row; corner(bg, 3)
            uiStroke(bg, T.Border)
            local kn = Instance.new("Frame")
            kn.Size             = UDim2.new(0, 10, 0, 10)
            kn.AnchorPoint      = Vector2.new(0.5, 0.5)
            kn.Position         = UDim2.new(initV, 0, 0.5, 0)
            kn.BackgroundColor3 = Color3.new(1, 1, 1)
            kn.BorderSizePixel  = 0; kn.ZIndex = 23
            kn.Parent           = bg; corner(kn, 5)
            uiStroke(kn, T.Border, 1)
            local hb = Instance.new("TextButton")
            hb.Size = UDim2.new(1, 0, 0, 18); hb.Position = UDim2.new(0, 0, 0.5, -9)
            hb.BackgroundTransparency = 1; hb.Text = ""; hb.ZIndex = 24; hb.Parent = bg
            local drag = false
            hb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true end end)
            UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
            UserInputService.InputChanged:Connect(function(i)
                if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
                    local r = math.clamp((i.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
                    kn.Position = UDim2.new(r, 0, 0.5, 0); cb(r); commit()
                end
            end)
        end

        hsvRow("H", h, function(r) h  = r end)
        hsvRow("S", s, function(r) s  = r end)
        hsvRow("V", v2, function(r) v2 = r end)

        hexLbl.Text = toHex(val)

        local PANEL_H = 96
        hbtn.MouseButton1Click:Connect(function()
            open = not open
            if open then
                tween(panel,     { Size = UDim2.new(1, 0, 0, PANEL_H) }, 0.18)
                tween(container, { Size = UDim2.new(1, 0, 0, 26 + PANEL_H + 4) }, 0.18)
            else
                tween(panel,     { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                tween(container, { Size = UDim2.new(1, 0, 0, 26) }, 0.15)
            end
        end)

        if opts.Flag then MatchaLib.Flags[opts.Flag] = { Value = val } end
        return {
            Set      = function(_, c) val=c; preview.BackgroundColor3=c; hexLbl.Text=toHex(c); h,s,v2=Color3.toHSV(c) end,
            GetValue = function() return val end,
        }
    end

    -- ── KEYBIND ─────────────────────────────────────────────
    function el:AddBind(opts)
        opts = opts or {}
        local key     = opts.Default or Enum.KeyCode.Unknown
        local waiting = false

        local row = Instance.new("Frame")
        row.Size             = UDim2.new(1, 0, 0, 26)
        row.BackgroundColor3 = T.Surface
        row.BorderSizePixel  = 0
        row.Parent           = col
        corner(row, 5)
        uiStroke(row, T.Border)
        pad(row, 0, 0, 8, 8)

        newLabel({
            Size       = UDim2.new(1, -72, 1, 0),
            Text       = opts.Name or "Bind",
            TextColor3 = T.TextSec,
            TextSize   = 12,
            Parent     = row,
        })

        local keyBox = Instance.new("TextButton")
        keyBox.Size             = UDim2.new(0, 60, 0, 18)
        keyBox.Position         = UDim2.new(1, -60, 0.5, -9)
        keyBox.BackgroundColor3 = T.AccentBg
        keyBox.BorderSizePixel  = 0
        keyBox.Text             = key == Enum.KeyCode.Unknown and "NONE" or key.Name
        keyBox.Font             = Enum.Font.Code
        keyBox.TextSize         = 10
        keyBox.TextColor3       = T.Accent
        keyBox.ZIndex           = 3
        keyBox.Parent           = row
        corner(keyBox, 4)
        uiStroke(keyBox, T.AccentDim)

        keyBox.MouseButton1Click:Connect(function()
            waiting = true
            keyBox.Text       = "..."
            keyBox.TextColor3 = T.TextMuted
        end)

        UserInputService.InputBegan:Connect(function(i, gp)
            if waiting and i.UserInputType == Enum.UserInputType.Keyboard then
                waiting = false
                key = i.KeyCode
                keyBox.Text       = key.Name
                keyBox.TextColor3 = T.Accent
                if opts.Flag then MatchaLib.Flags[opts.Flag] = { Value = key } end
            elseif not waiting and not gp and i.UserInputType == Enum.UserInputType.Keyboard then
                if i.KeyCode == key and opts.Callback then opts.Callback() end
            end
        end)

        if opts.Flag then MatchaLib.Flags[opts.Flag] = { Value = key } end
        return {
            Set      = function(_, k) key=k; keyBox.Text = k==Enum.KeyCode.Unknown and "NONE" or k.Name end,
            GetValue = function() return key end,
        }
    end

    -- ── BUTTON ──────────────────────────────────────────────
    function el:AddButton(opts)
        opts = opts or {}
        local wrap = Instance.new("Frame")
        wrap.Size             = UDim2.new(1, 0, 0, 26)
        wrap.BackgroundColor3 = T.Surface
        wrap.BorderSizePixel  = 0
        wrap.Parent           = col
        corner(wrap, 5)
        uiStroke(wrap, T.Border)

        local btn = Instance.new("TextButton")
        btn.Size                   = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text                   = opts.Name or "Button"
        btn.Font                   = Enum.Font.Code
        btn.TextSize               = 12
        btn.TextColor3             = T.TextSec
        btn.AutoButtonColor        = false
        btn.ZIndex                 = 2
        btn.Parent                 = wrap

        -- Accent line izquierda al hover
        local accent = Instance.new("Frame")
        accent.Size             = UDim2.new(0, 2, 0, 0)
        accent.BackgroundColor3 = T.Accent
        accent.BorderSizePixel  = 0
        accent.ZIndex           = 3
        accent.Parent           = wrap
        corner(accent, 1)

        btn.MouseEnter:Connect(function()
            tween(wrap,   { BackgroundColor3 = T.SurfaceHov }, 0.1)
            tween(btn,    { TextColor3 = T.TextPri }, 0.1)
            tween(accent, { Size = UDim2.new(0, 2, 1, 0) }, 0.15)
        end)
        btn.MouseLeave:Connect(function()
            tween(wrap,   { BackgroundColor3 = T.Surface }, 0.1)
            tween(btn,    { TextColor3 = T.TextSec }, 0.1)
            tween(accent, { Size = UDim2.new(0, 2, 0, 0) }, 0.12)
        end)
        btn.MouseButton1Click:Connect(function()
            tween(wrap, { BackgroundColor3 = T.AccentBg }, 0.07)
            tween(btn,  { TextColor3 = T.Accent }, 0.07)
            task.wait(0.12)
            tween(wrap, { BackgroundColor3 = T.Surface }, 0.15)
            tween(btn,  { TextColor3 = T.TextSec }, 0.15)
            if opts.Callback then opts.Callback() end
        end)
    end

    -- ── TEXTBOX ─────────────────────────────────────────────
    function el:AddTextbox(opts)
        opts = opts or {}
        local wrap = Instance.new("Frame")
        wrap.Size             = UDim2.new(1, 0, 0, 42)
        wrap.BackgroundTransparency = 1
        wrap.Parent           = col

        newLabel({
            Size       = UDim2.new(1, 0, 0, 15),
            Text       = opts.Name or "Input",
            TextColor3 = T.TextSec,
            TextSize   = 11,
            Parent     = wrap,
        })

        local boxWrap = Instance.new("Frame")
        boxWrap.Size             = UDim2.new(1, 0, 0, 22)
        boxWrap.Position         = UDim2.new(0, 0, 0, 18)
        boxWrap.BackgroundColor3 = T.Surface
        boxWrap.BorderSizePixel  = 0
        boxWrap.Parent           = wrap
        corner(boxWrap, 5)
        local boxStroke = uiStroke(boxWrap, T.Border)

        local box = Instance.new("TextBox")
        box.Size               = UDim2.new(1, -12, 1, 0)
        box.Position           = UDim2.new(0, 6, 0, 0)
        box.BackgroundTransparency = 1
        box.Text               = opts.Default or ""
        box.Font               = Enum.Font.Code
        box.TextSize           = 11
        box.TextColor3         = T.TextPri
        box.PlaceholderText    = opts.Placeholder or "..."
        box.PlaceholderColor3  = T.TextMuted
        box.ClearTextOnFocus   = false
        box.ZIndex             = 3
        box.Parent             = boxWrap

        box.Focused:Connect(function()
            tween(boxStroke, { Color = T.Accent }, 0.12)
        end)
        box.FocusLost:Connect(function()
            tween(boxStroke, { Color = T.Border }, 0.12)
            if opts.Callback    then opts.Callback(box.Text) end
            if opts.TextDisappear then box.Text = "" end
        end)

        return {
            Set      = function(_, t) box.Text = t end,
            GetValue = function() return box.Text end,
        }
    end

    return el
end

-- ─────────────────────────────────────────────────────────────
-- VENTANA PRINCIPAL
-- ─────────────────────────────────────────────────────────────
function MatchaLib:CreateWindow(opts)
    opts = opts or {}
    local W = opts.Width  or 600
    local H = opts.Height or 420

    local win         = {}
    local tabContents = {}
    local currentTab  = nil

    local gui = Instance.new("ScreenGui")
    gui.Name           = opts.Name or "MatchaLib"
    gui.ResetOnSpawn   = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then gui.Parent = LP.PlayerGui end

    -- ── Ventana base ─────────────────────────────────────────
    local main = Instance.new("Frame")
    main.Size             = UDim2.new(0, W, 0, 0)
    main.Position         = UDim2.new(0.5, -W/2, 0.5, -H/2)
    main.BackgroundColor3 = T.Bg
    main.BorderSizePixel  = 0
    main.ClipsDescendants = true
    main.Parent           = gui
    corner(main, 8)
    uiStroke(main, T.Border, 1)

    -- Sombra (frame ligeramente más grande detrás, negro transparente)
    local shadow = Instance.new("Frame")
    shadow.Size             = UDim2.new(1, 14, 1, 14)
    shadow.Position         = UDim2.new(0, -7, 0, -7)
    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    shadow.BackgroundTransparency = 0.6
    shadow.BorderSizePixel  = 0
    shadow.ZIndex           = 0
    shadow.Parent           = main
    corner(shadow, 12)

    tween(main, { Size = UDim2.new(0, W, 0, H) }, 0.32, Enum.EasingStyle.Back)

    -- ── TITLEBAR ─────────────────────────────────────────────
    local TB_H = 36
    local titleBar = Instance.new("Frame")
    titleBar.Size             = UDim2.new(1, 0, 0, TB_H)
    titleBar.BackgroundColor3 = T.BgAlt
    titleBar.BorderSizePixel  = 0
    titleBar.ZIndex           = 3
    titleBar.Parent           = main

    -- Fix corners planos abajo
    newFrame({
        Size             = UDim2.new(1, 0, 0, 10),
        Position         = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = T.BgAlt,
        ZIndex           = 3,
        Parent           = titleBar,
    })
    corner(titleBar, 8)

    -- Pip de acento
    local pip = Instance.new("Frame")
    pip.Size             = UDim2.new(0, 3, 0, 16)
    pip.Position         = UDim2.new(0, 10, 0.5, -8)
    pip.BackgroundColor3 = T.Accent
    pip.BorderSizePixel  = 0
    pip.ZIndex           = 5
    pip.Parent           = titleBar
    corner(pip, 2)

    -- ── ICONO (ImageLabel o Emoji) ───────────────────────────
    local iconOffset = 18   -- offset X inicial del texto
    if opts.Icon then
        -- Icono como ImageLabel (rbxassetid o url)
        local iconImg = Instance.new("ImageLabel")
        iconImg.Size               = UDim2.new(0, 18, 0, 18)
        iconImg.Position           = UDim2.new(0, 18, 0.5, -9)
        iconImg.BackgroundTransparency = 1
        iconImg.Image              = opts.Icon
        iconImg.ScaleType          = Enum.ScaleType.Fit
        iconImg.ZIndex             = 5
        iconImg.Parent             = titleBar
        iconOffset = 42
    elseif opts.IconEmoji then
        -- Emoji como TextLabel
        local iconEmoji = newLabel({
            Size       = UDim2.new(0, 20, 1, 0),
            Position   = UDim2.new(0, 18, 0, 0),
            Text       = opts.IconEmoji,
            TextSize   = 14,
            TextColor3 = T.TextPri,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex     = 5,
            Parent     = titleBar,
        })
        iconOffset = 44
    end

    -- Título
    local titleLbl = newLabel({
        Size       = UDim2.new(0.45, 0, 1, 0),
        Position   = UDim2.new(0, iconOffset, 0, 0),
        Text       = opts.Title or "MatchaLib",
        TextColor3 = T.TextPri,
        Font       = Enum.Font.GothamBold,
        TextSize   = 13,
        ZIndex     = 5,
        Parent     = titleBar,
    })

    -- Subtítulo (separado con pipe)
    if opts.Subtitle and opts.Subtitle ~= "" then
        newLabel({
            Size       = UDim2.new(0, 4, 1, 0),
            Position   = UDim2.new(0, iconOffset + 110, 0, 0),
            Text       = "│",
            TextColor3 = T.Border,
            TextSize   = 12,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex     = 5,
            Parent     = titleBar,
        })
        newLabel({
            Size       = UDim2.new(0.3, 0, 1, 0),
            Position   = UDim2.new(0, iconOffset + 118, 0, 0),
            Text       = opts.Subtitle,
            TextColor3 = T.TextMuted,
            TextSize   = 10,
            ZIndex     = 5,
            Parent     = titleBar,
        })
    end

    -- Botones de control (×  −  ⊡ logger)
    local function ctrlBtn(txt, xOff, hoverColor, textColor)
        local b = Instance.new("TextButton")
        b.Size             = UDim2.new(0, 24, 0, 24)
        b.Position         = UDim2.new(1, xOff, 0.5, -12)
        b.BackgroundColor3 = T.Surface
        b.BorderSizePixel  = 0
        b.Text             = txt
        b.Font             = Enum.Font.GothamBold
        b.TextSize         = 13
        b.TextColor3       = textColor or T.TextSec
        b.ZIndex           = 6
        b.Parent           = titleBar
        corner(b, 5)
        uiStroke(b, T.Border)
        b.MouseEnter:Connect(function() tween(b, { BackgroundColor3 = hoverColor or T.SurfaceHov }, 0.1) end)
        b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = T.Surface }, 0.1) end)
        return b
    end

    local closeBtn  = ctrlBtn("×", -30,  Color3.fromRGB(180, 50, 50), T.TextSec)
    local minBtn    = ctrlBtn("−", -58,  T.SurfaceHov)
    local logBtn    = ctrlBtn("⌨", -86, Color3.fromRGB(40, 22, 70), T.Debug)

    closeBtn.MouseButton1Click:Connect(function()
        tween(main, { Size = UDim2.new(0, W, 0, 0), BackgroundTransparency = 1 }, 0.2)
        task.wait(0.22); gui:Destroy()
    end)

    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        tween(main, { Size = UDim2.new(0, W, 0, minimized and TB_H or H) }, 0.2)
    end)

    logBtn.MouseButton1Click:Connect(function()
        local logger = MatchaLib:GetLogger()
        logger:Toggle()
    end)

    makeDraggable(main, titleBar)

    -- ── TAB BAR ──────────────────────────────────────────────
    local TAB_H = 28
    local tabBar = Instance.new("Frame")
    tabBar.Size             = UDim2.new(1, 0, 0, TAB_H)
    tabBar.Position         = UDim2.new(0, 0, 0, TB_H)
    tabBar.BackgroundColor3 = T.BgAlt
    tabBar.BorderSizePixel  = 0
    tabBar.ZIndex           = 3
    tabBar.Parent           = main

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection     = Enum.FillDirection.Horizontal
    tabLayout.SortOrder         = Enum.SortOrder.LayoutOrder
    tabLayout.Padding           = UDim.new(0, 0)
    tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tabLayout.Parent            = tabBar

    pad(tabBar, 0, 0, 8, 0)

    -- Línea inferior del tab bar
    local tabBorder = Instance.new("Frame")
    tabBorder.Size             = UDim2.new(1, 0, 0, 1)
    tabBorder.Position         = UDim2.new(0, 0, 0, TB_H + TAB_H)
    tabBorder.BackgroundColor3 = T.Border
    tabBorder.BorderSizePixel  = 0
    tabBorder.ZIndex           = 4
    tabBorder.Parent           = main

    -- ── ÁREA DE CONTENIDO ────────────────────────────────────
    local CONTENT_Y = TB_H + TAB_H + 1
    local contentArea = Instance.new("Frame")
    contentArea.Size              = UDim2.new(1, 0, 1, -CONTENT_Y)
    contentArea.Position          = UDim2.new(0, 0, 0, CONTENT_Y)
    contentArea.BackgroundTransparency = 1
    contentArea.ClipsDescendants  = true
    contentArea.Parent            = main

    -- ── CREAR TAB ────────────────────────────────────────────
    function win:CreateTab(name, icon)
        local tab = {}

        local tabBtn = Instance.new("TextButton")
        tabBtn.Size              = UDim2.new(0, 0, 1, 0)
        tabBtn.AutomaticSize     = Enum.AutomaticSize.X
        tabBtn.BackgroundTransparency = 1
        tabBtn.Text              = (icon and icon .. "  " or "") .. name
        tabBtn.Font              = Enum.Font.Code
        tabBtn.TextSize          = 11
        tabBtn.TextColor3        = T.TextMuted
        tabBtn.AutoButtonColor   = false
        tabBtn.ZIndex            = 4
        tabBtn.Parent            = tabBar

        local tbPad = Instance.new("UIPadding"); tbPad.Parent = tabBtn
        tbPad.PaddingLeft  = UDim.new(0, 12)
        tbPad.PaddingRight = UDim.new(0, 12)

        -- Subrayado activo
        local underline = Instance.new("Frame")
        underline.Size                   = UDim2.new(1, -24, 0, 2)
        underline.Position               = UDim2.new(0, 12, 1, -2)
        underline.BackgroundColor3       = T.Accent
        underline.BorderSizePixel        = 0
        underline.BackgroundTransparency = 1
        underline.ZIndex                 = 5
        underline.Parent                 = tabBtn
        corner(underline, 1)

        -- Scroll del tab
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size                    = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency  = 1
        scroll.BorderSizePixel         = 0
        scroll.ScrollBarThickness      = 3
        scroll.ScrollBarImageColor3    = T.Accent
        scroll.CanvasSize              = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize     = Enum.AutomaticSize.Y
        scroll.Visible                 = false
        scroll.ZIndex                  = 1
        scroll.Parent                  = contentArea

        -- Holder de dos columnas
        local colHolder = newFrame({
            Size     = UDim2.new(1, -20, 1, 0),
            Position = UDim2.new(0, 10, 0, 8),
            Parent   = scroll,
        })
        colHolder.AutomaticSize = Enum.AutomaticSize.Y

        local colList = Instance.new("UIListLayout")
        colList.FillDirection       = Enum.FillDirection.Horizontal
        colList.HorizontalAlignment = Enum.HorizontalAlignment.Left
        colList.Padding             = UDim.new(0, 0)
        colList.Parent              = colHolder

        -- Col izquierda
        local leftCol = Instance.new("Frame")
        leftCol.Size                  = UDim2.new(0.5, -1, 0, 0)
        leftCol.AutomaticSize         = Enum.AutomaticSize.Y
        leftCol.BackgroundTransparency = 1
        leftCol.Parent                = colHolder
        local leftList = Instance.new("UIListLayout")
        leftList.SortOrder = Enum.SortOrder.LayoutOrder
        leftList.Padding   = UDim.new(0, 5)
        leftList.Parent    = leftCol
        pad(leftCol, 0, 8, 0, 6)

        -- Divisor
        local divLine = Instance.new("Frame")
        divLine.Size             = UDim2.new(0, 1, 1, 0)
        divLine.BackgroundColor3 = T.ColDivider
        divLine.BorderSizePixel  = 0
        divLine.Parent           = colHolder

        -- Col derecha
        local rightCol = Instance.new("Frame")
        rightCol.Size                  = UDim2.new(0.5, -1, 0, 0)
        rightCol.AutomaticSize         = Enum.AutomaticSize.Y
        rightCol.BackgroundTransparency = 1
        rightCol.Parent                = colHolder
        local rightList = Instance.new("UIListLayout")
        rightList.SortOrder = Enum.SortOrder.LayoutOrder
        rightList.Padding   = UDim.new(0, 5)
        rightList.Parent    = rightCol
        pad(rightCol, 0, 8, 6, 0)

        local leftEl  = buildElements(leftCol)
        local rightEl = buildElements(rightCol)

        tab.Left  = leftEl
        tab.Right = rightEl

        function tab:AddSection(n)        return leftEl:AddSection(n) end
        function tab:AddLabel(t)          return leftEl:AddLabel(t) end
        function tab:AddToggle(o)         return leftEl:AddToggle(o) end
        function tab:AddSlider(o)         return leftEl:AddSlider(o) end
        function tab:AddDropdown(o)       return leftEl:AddDropdown(o) end
        function tab:AddColorpicker(o)    return leftEl:AddColorpicker(o) end
        function tab:AddBind(o)           return leftEl:AddBind(o) end
        function tab:AddButton(o)         return leftEl:AddButton(o) end
        function tab:AddTextbox(o)        return leftEl:AddTextbox(o) end

        tabBtn.MouseButton1Click:Connect(function()
            for _, entry in ipairs(tabContents) do
                entry.scroll.Visible = false
                tween(entry.btn,       { TextColor3 = T.TextMuted }, 0.12)
                tween(entry.underline, { BackgroundTransparency = 1 }, 0.12)
            end
            scroll.Visible = true
            tween(tabBtn,    { TextColor3 = T.TextPri }, 0.12)
            tween(underline, { BackgroundTransparency = 0 }, 0.12)
            currentTab = name
        end)

        table.insert(tabContents, { scroll = scroll, btn = tabBtn, underline = underline })

        if #tabContents == 1 then
            scroll.Visible                   = true
            tabBtn.TextColor3                = T.TextPri
            underline.BackgroundTransparency = 0
            currentTab                       = name
        end

        return tab
    end

    function win:Toggle()
        main.Visible = not main.Visible
    end

    function win:Destroy()
        gui:Destroy()
    end

    return win
end

function MatchaLib:Init() end

return MatchaLib

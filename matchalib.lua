--[[
    MatchaLib — Roblox UI Library
    Layout : Horizontal tabs (top) + two-column content
    Style  : Dark + Pink/Magenta  (fiel a la referencia visual)
    
    USO BÁSICO:
        local W = MatchaLib:CreateWindow({ Title="Mi Script", Subtitle="v1.0" })
        local tab = W:CreateTab("Aiming")
        tab:AddToggle({ Name="Aimbot", Default=false, Bind="rbutton", Callback=function(v) end })
        tab:AddSlider({ Name="Distance", Min=0, Max=2000, Default=1112, Callback=function(v) end })
        tab.Right:AddDropdown({ Name="Hit Part", Options={"Head","Body","Limbs"}, Default="Head" })
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
local LP               = Players.LocalPlayer

-- ─────────────────────────────────────────────────────────────
-- TEMA  (colores fieles a la foto)
-- ─────────────────────────────────────────────────────────────
local T = {
    Bg          = Color3.fromRGB(13, 13, 16),      -- fondo ventana
    BgAlt       = Color3.fromRGB(18, 18, 22),      -- titlebar / tabbar
    Surface     = Color3.fromRGB(22, 22, 28),      -- superficies elementos
    SurfaceHov  = Color3.fromRGB(28, 28, 36),      -- hover
    Border      = Color3.fromRGB(38, 38, 50),      -- bordes sutiles
    Accent      = Color3.fromRGB(255, 105, 180),   -- rosa principal
    AccentDim   = Color3.fromRGB(200, 70, 140),    -- rosa oscuro
    AccentBg    = Color3.fromRGB(60, 20, 45),      -- rosa fondo toggle ON
    TextPri     = Color3.fromRGB(230, 230, 235),   -- texto principal
    TextSec     = Color3.fromRGB(150, 150, 165),   -- texto secundario
    TextMuted   = Color3.fromRGB(80, 80, 95),      -- texto apagado
    SliderFill  = Color3.fromRGB(255, 105, 180),
    SliderBg    = Color3.fromRGB(35, 35, 45),
    ToggleOn    = Color3.fromRGB(255, 105, 180),
    ToggleOff   = Color3.fromRGB(38, 38, 50),
    Success     = Color3.fromRGB(100, 220, 140),
    Danger      = Color3.fromRGB(220, 80, 80),
    ColDivider  = Color3.fromRGB(35, 35, 48),      -- línea divisora columnas
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

local function uiStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or T.Border
    s.Thickness = thickness or 1
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
    l.Font = Enum.Font.Code          -- monospace fiel a la foto
    l.TextSize = 12
    l.TextColor3 = T.TextSec
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.RichText = false
    for k, v in pairs(props or {}) do l[k] = v end
    return l
end

-- Drag en cualquier frame
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
-- NOTIFICACIONES
-- ─────────────────────────────────────────────────────────────
local notifGui = Instance.new("ScreenGui")
notifGui.Name           = "MatchaNotifs"
notifGui.ResetOnSpawn   = false
notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() notifGui.Parent = CoreGui end)
if not notifGui.Parent then notifGui.Parent = LP.PlayerGui end

local notifHolder = newFrame({
    Size     = UDim2.new(0, 280, 1, 0),
    Position = UDim2.new(1, -292, 0, 0),
    Parent   = notifGui,
})

local notifLayout = Instance.new("UIListLayout")
notifLayout.SortOrder          = Enum.SortOrder.LayoutOrder
notifLayout.VerticalAlignment  = Enum.VerticalAlignment.Bottom
notifLayout.Padding            = UDim.new(0, 6)
notifLayout.Parent             = notifHolder

local notifPad = Instance.new("UIPadding")
notifPad.PaddingBottom = UDim.new(0, 16)
notifPad.Parent        = notifHolder

function MatchaLib:Notify(opts)
    opts = opts or {}
    local accent = opts.Type == "success" and T.Success
                or opts.Type == "error"   and T.Danger
                or T.Accent

    local card = Instance.new("Frame")
    card.Size             = UDim2.new(1, 0, 0, 62)
    card.BackgroundColor3 = T.Surface
    card.BorderSizePixel  = 0
    card.Parent           = notifHolder
    corner(card, 6)
    uiStroke(card, T.Border)

    -- barra de color izquierda
    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(0, 3, 1, 0)
    bar.BackgroundColor3 = accent
    bar.BorderSizePixel  = 0
    bar.Parent           = card
    corner(bar, 2)

    newLabel({
        Size       = UDim2.new(1, -20, 0, 22),
        Position   = UDim2.new(0, 14, 0, 8),
        Text       = opts.Title or "MatchaLib",
        TextColor3 = T.TextPri,
        Font       = Enum.Font.GothamBold,
        TextSize   = 12,
        Parent     = card,
    })
    newLabel({
        Size     = UDim2.new(1, -20, 0, 18),
        Position = UDim2.new(0, 14, 0, 30),
        Text     = opts.Content or "",
        TextSize = 11,
        Parent   = card,
    })

    -- barra de progreso inferior
    local prog = Instance.new("Frame")
    prog.Size             = UDim2.new(1, 0, 0, 2)
    prog.Position         = UDim2.new(0, 0, 1, -2)
    prog.BackgroundColor3 = accent
    prog.BorderSizePixel  = 0
    prog.Parent           = card

    card.Position = UDim2.new(1, 12, 0, 0)
    tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.28)
    tween(prog, { Size = UDim2.new(0, 0, 0, 2) }, opts.Duration or 4, Enum.EasingStyle.Linear)

    task.delay(opts.Duration or 4, function()
        tween(card, { Position = UDim2.new(1, 12, 0, 0) }, 0.22)
        task.wait(0.25)
        card:Destroy()
    end)
end

-- ─────────────────────────────────────────────────────────────
-- CONSTRUCTOR DE ELEMENTOS (recibe la columna Frame como parent)
-- ─────────────────────────────────────────────────────────────
local function buildElements(col)
    local el = {}

    -- ── SECTION ─────────────────────────────────────────────
    function el:AddSection(name)
        -- espaciador superior
        local spacer = newFrame({ Size = UDim2.new(1, 0, 0, 4), Parent = col })

        local lbl = newLabel({
            Size       = UDim2.new(1, 0, 0, 18),
            Text       = name,
            TextColor3 = T.TextSec,
            Font       = Enum.Font.Code,
            TextSize   = 11,
            Parent     = col,
        })
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
    --  Layout fiel a la foto:
    --  [●] Label                          [bind]
    function el:AddToggle(opts)
        opts = opts or {}
        local val = opts.Default or false

        local row = newFrame({ Size = UDim2.new(1, 0, 0, 24), Parent = col })

        -- Círculo toggle (estilo foto: ~14px, borde rosa cuando ON)
        local circle = Instance.new("Frame")
        circle.Size             = UDim2.new(0, 14, 0, 14)
        circle.Position         = UDim2.new(0, 0, 0.5, -7)
        circle.BackgroundColor3 = val and T.ToggleOn or T.ToggleOff
        circle.BorderSizePixel  = 0
        circle.Parent           = row
        corner(circle, 7)
        local circleStroke = uiStroke(circle, val and T.Accent or T.Border, 1)

        -- Punto interior blanco
        local dot = Instance.new("Frame")
        dot.Size                    = UDim2.new(0, 6, 0, 6)
        dot.Position                = UDim2.new(0.5, -3, 0.5, -3)
        dot.BackgroundColor3        = Color3.new(1, 1, 1)
        dot.BackgroundTransparency  = val and 0 or 1
        dot.BorderSizePixel         = 0
        dot.Parent                  = circle
        corner(dot, 3)

        -- Nombre
        newLabel({
            Size       = UDim2.new(1, -80, 1, 0),
            Position   = UDim2.new(0, 22, 0, 0),
            Text       = opts.Name or "Toggle",
            TextColor3 = val and T.TextPri or T.TextSec,
            TextSize   = 12,
            Parent     = row,
        })
        local nameLbl = row:FindFirstChildWhichIsA("TextLabel")

        -- Keybind opcional (fiel a la foto: cuadradinho gris derecha)
        local bindBtn
        if opts.Bind then
            bindBtn = Instance.new("TextButton")
            bindBtn.Size             = UDim2.new(0, 52, 0, 18)
            bindBtn.Position         = UDim2.new(1, -52, 0.5, -9)
            bindBtn.BackgroundColor3 = T.Surface
            bindBtn.BorderSizePixel  = 0
            bindBtn.Text             = opts.Bind
            bindBtn.Font             = Enum.Font.Code
            bindBtn.TextSize         = 10
            bindBtn.TextColor3       = T.TextSec
            bindBtn.ZIndex           = 3
            bindBtn.Parent           = row
            corner(bindBtn, 3)
            uiStroke(bindBtn, T.Border)
        end

        -- Hitbox invisible
        local btn = Instance.new("TextButton")
        btn.Size                = UDim2.new(1, bindBtn and -60 or 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text                = ""
        btn.ZIndex              = 4
        btn.Parent              = row

        local function update()
            tween(circle, { BackgroundColor3 = val and T.ToggleOn or T.ToggleOff }, 0.1)
            circleStroke.Color         = val and T.Accent or T.Border
            dot.BackgroundTransparency = val and 0 or 1
            if nameLbl then
                tween(nameLbl, { TextColor3 = val and T.TextPri or T.TextSec }, 0.1)
            end
            if opts.Flag then MatchaLib.Flags[opts.Flag] = { Value = val } end
            if opts.Callback then opts.Callback(val) end
        end

        btn.MouseButton1Click:Connect(function() val = not val; update() end)
        if opts.Flag then MatchaLib.Flags[opts.Flag] = { Value = val } end

        return {
            Set      = function(_, v) val = v; update() end,
            GetValue = function() return val end,
        }
    end

    -- ── SLIDER ──────────────────────────────────────────────
    --  Layout fiel a la foto:
    --  Label
    --  [██████████████  1112/2000  ████]   (barra ancho completo, valor centrado)
    function el:AddSlider(opts)
        opts = opts or {}
        local minV = opts.Min       or 0
        local maxV = opts.Max       or 100
        local val  = opts.Default   or minV
        local inc  = opts.Increment or 1
        local suf  = opts.Suffix    or opts.ValueName or ""

        local wrap = newFrame({ Size = UDim2.new(1, 0, 0, 40), Parent = col })

        -- Nombre arriba
        newLabel({
            Size       = UDim2.new(1, 0, 0, 16),
            Text       = opts.Name or "Slider",
            TextColor3 = T.TextSec,
            TextSize   = 12,
            Parent     = wrap,
        })

        -- Track (ancho completo, abajo del label)
        local track = Instance.new("Frame")
        track.Size             = UDim2.new(1, 0, 0, 18)
        track.Position         = UDim2.new(0, 0, 0, 20)
        track.BackgroundColor3 = T.SliderBg
        track.BorderSizePixel  = 0
        track.Parent           = wrap
        corner(track, 3)
        uiStroke(track, T.Border)

        -- Fill rosa
        local fill = Instance.new("Frame")
        fill.Size             = UDim2.new((val - minV) / (maxV - minV), 0, 1, 0)
        fill.BackgroundColor3 = T.SliderFill
        fill.BorderSizePixel  = 0
        fill.ZIndex           = 2
        fill.Parent           = track
        corner(fill, 3)

        -- Valor centrado sobre el track (fiel a foto: "1112/2000")
        local valLbl = newLabel({
            Size             = UDim2.new(1, 0, 1, 0),
            Text             = tostring(val) .. "/" .. tostring(maxV) .. (suf ~= "" and " " .. suf or ""),
            TextColor3       = T.TextPri,
            Font             = Enum.Font.Code,
            TextSize         = 10,
            TextXAlignment   = Enum.TextXAlignment.Center,
            ZIndex           = 3,
            Parent           = track,
        })

        -- Hitbox invisible sobre el track
        local hit = Instance.new("TextButton")
        hit.Size                   = UDim2.new(1, 0, 1, 0)
        hit.BackgroundTransparency = 1
        hit.Text                   = ""
        hit.ZIndex                 = 4
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
            fill.Size  = UDim2.new(frac, 0, 1, 0)
            valLbl.Text = tostring(val) .. "/" .. tostring(maxV) .. (suf ~= "" and " " .. suf or "")
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
                fill.Size   = UDim2.new(frac, 0, 1, 0)
                valLbl.Text = tostring(val) .. "/" .. tostring(maxV) .. (suf ~= "" and " " .. suf or "")
            end,
            GetValue = function() return val end,
        }
    end

    -- ── DROPDOWN ────────────────────────────────────────────
    --  Layout fiel a la foto: ancho completo, nombre arriba, caja abajo con ▼
    function el:AddDropdown(opts)
        opts = opts or {}
        local options = opts.Options or {}
        local val     = opts.Default or (options[1] or "")
        local open    = false

        -- contenedor que crece al abrir
        local container = Instance.new("Frame")
        container.Size                = UDim2.new(1, 0, 0, 38)
        container.BackgroundTransparency = 1
        container.ClipsDescendants    = false
        container.Parent              = col

        -- nombre
        newLabel({
            Size       = UDim2.new(1, 0, 0, 16),
            Text       = opts.Name or "Dropdown",
            TextColor3 = T.TextSec,
            TextSize   = 12,
            Parent     = container,
        })

        -- caja seleccionada (ancho completo, fiel a foto)
        local box = Instance.new("Frame")
        box.Size             = UDim2.new(1, 0, 0, 18)
        box.Position         = UDim2.new(0, 0, 0, 18)
        box.BackgroundColor3 = T.SliderBg
        box.BorderSizePixel  = 0
        box.Parent           = container
        corner(box, 3)
        uiStroke(box, T.Border)

        local valLbl = newLabel({
            Size     = UDim2.new(1, -22, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            Text     = val,
            TextColor3 = T.TextPri,
            TextSize = 11,
            Parent   = box,
        })

        newLabel({
            Size             = UDim2.new(0, 18, 1, 0),
            Position         = UDim2.new(1, -18, 0, 0),
            Text             = "▼",
            TextColor3       = T.TextMuted,
            TextXAlignment   = Enum.TextXAlignment.Center,
            TextSize         = 9,
            Parent           = box,
        })

        -- panel opciones
        local ITEM_H = 20
        local panel = Instance.new("Frame")
        panel.Size             = UDim2.new(1, 0, 0, 0)
        panel.Position         = UDim2.new(0, 0, 0, 38)
        panel.BackgroundColor3 = T.Surface
        panel.BorderSizePixel  = 0
        panel.ClipsDescendants = true
        panel.ZIndex           = 20
        panel.Parent           = container
        corner(panel, 3)
        uiStroke(panel, T.Border)

        local pLayout = Instance.new("UIListLayout"); pLayout.Parent = panel
        local pPad    = Instance.new("UIPadding")
        pPad.PaddingTop    = UDim.new(0, 2)
        pPad.PaddingBottom = UDim.new(0, 2)
        pPad.Parent        = panel

        local function rebuildOptions(list)
            for _, c in ipairs(panel:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            for _, opt in ipairs(list) do
                local ob = Instance.new("TextButton")
                ob.Size             = UDim2.new(1, 0, 0, ITEM_H)
                ob.BackgroundTransparency = 1
                ob.Text             = opt
                ob.Font             = Enum.Font.Code
                ob.TextSize         = 11
                ob.TextColor3       = opt == val and T.Accent or T.TextPri
                ob.TextXAlignment   = Enum.TextXAlignment.Left
                ob.ZIndex           = 21
                ob.Parent           = panel
                local ip = Instance.new("UIPadding"); ip.PaddingLeft = UDim.new(0, 8); ip.Parent = ob

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
                            c2.TextColor3 = c2.Text == val and T.Accent or T.TextPri
                        end
                    end
                    open = false
                    local ph = 0
                    tween(panel,     { Size = UDim2.new(1, 0, 0, ph) }, 0.15)
                    tween(container, { Size = UDim2.new(1, 0, 0, 38) }, 0.15)
                    if opts.Flag     then MatchaLib.Flags[opts.Flag] = { Value = val } end
                    if opts.Callback then opts.Callback(val) end
                end)
            end
        end
        rebuildOptions(options)

        local hitBtn = Instance.new("TextButton")
        hitBtn.Size                   = UDim2.new(1, 0, 0, 18)
        hitBtn.Position               = UDim2.new(0, 0, 0, 18)
        hitBtn.BackgroundTransparency = 1
        hitBtn.Text                   = ""
        hitBtn.ZIndex                 = 5
        hitBtn.Parent                 = container

        hitBtn.MouseButton1Click:Connect(function()
            open = not open
            local ph = math.min(#options, 7) * ITEM_H + 4
            if open then
                tween(panel,     { Size = UDim2.new(1, 0, 0, ph) }, 0.18)
                tween(container, { Size = UDim2.new(1, 0, 0, 38 + ph + 2) }, 0.18)
            else
                tween(panel,     { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                tween(container, { Size = UDim2.new(1, 0, 0, 38) }, 0.15)
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
    --  Nombre + preview cuadrado (fiel a foto: cuadradito + checker)
    function el:AddColorpicker(opts)
        opts = opts or {}
        local val        = opts.Default or Color3.new(1, 1, 1)
        local open       = false
        local h, s, v2   = Color3.toHSV(val)

        local container = Instance.new("Frame")
        container.Size                   = UDim2.new(1, 0, 0, 24)
        container.BackgroundTransparency = 1
        container.ClipsDescendants       = false
        container.Parent                 = col

        local topRow = newFrame({ Size = UDim2.new(1, 0, 0, 24), Parent = container })

        newLabel({
            Size       = UDim2.new(1, -50, 1, 0),
            Text       = opts.Name or "Color",
            TextColor3 = T.TextSec,
            TextSize   = 12,
            Parent     = topRow,
        })

        -- Preview (cuadradito fiel a foto)
        local preview = Instance.new("Frame")
        preview.Size             = UDim2.new(0, 16, 0, 16)
        preview.Position         = UDim2.new(1, -18, 0.5, -8)
        preview.BackgroundColor3 = val
        preview.BorderSizePixel  = 0
        preview.ZIndex           = 3
        preview.Parent           = topRow
        corner(preview, 3)
        uiStroke(preview, T.Border)

        local hbtn = Instance.new("TextButton")
        hbtn.Size                   = UDim2.new(1, 0, 1, 0)
        hbtn.BackgroundTransparency = 1
        hbtn.Text                   = ""
        hbtn.ZIndex                 = 4
        hbtn.Parent                 = topRow

        -- Panel HSV
        local panel = Instance.new("Frame")
        panel.Size             = UDim2.new(1, 0, 0, 0)
        panel.Position         = UDim2.new(0, 0, 0, 26)
        panel.BackgroundColor3 = T.Surface
        panel.BorderSizePixel  = 0
        panel.ClipsDescendants = true
        panel.ZIndex           = 20
        panel.Parent           = container
        corner(panel, 4)
        uiStroke(panel, T.Border)

        local pLayout = Instance.new("UIListLayout"); pLayout.Padding = UDim.new(0, 4); pLayout.Parent = panel
        local pp = Instance.new("UIPadding")
        pp.PaddingLeft   = UDim.new(0, 8); pp.PaddingRight  = UDim.new(0, 8)
        pp.PaddingTop    = UDim.new(0, 6); pp.PaddingBottom = UDim.new(0, 6)
        pp.Parent        = panel

        local function commit()
            val = Color3.fromHSV(h, s, v2)
            preview.BackgroundColor3 = val
            if opts.Flag     then MatchaLib.Flags[opts.Flag] = { Value = val } end
            if opts.Callback then opts.Callback(val) end
        end

        local function hsvRow(lText, initV, trackColor, cb)
            local row = newFrame({ Size = UDim2.new(1, 0, 0, 20), ZIndex = 21, Parent = panel })
            newLabel({ Size=UDim2.new(0,12,1,0), Text=lText, TextColor3=T.TextMuted, TextSize=10, ZIndex=22, Parent=row })
            local bg = Instance.new("Frame")
            bg.Size             = UDim2.new(1, -16, 0, 5)
            bg.Position         = UDim2.new(0, 16, 0.5, -2.5)
            bg.BackgroundColor3 = trackColor
            bg.BorderSizePixel  = 0; bg.ZIndex = 22
            bg.Parent           = row; corner(bg, 2)
            local kn = Instance.new("Frame")
            kn.Size             = UDim2.new(0, 8, 0, 8)
            kn.AnchorPoint      = Vector2.new(0.5, 0.5)
            kn.Position         = UDim2.new(initV, 0, 0.5, 0)
            kn.BackgroundColor3 = Color3.new(1, 1, 1)
            kn.BorderSizePixel  = 0; kn.ZIndex = 23
            kn.Parent           = bg; corner(kn, 4)
            local hb = Instance.new("TextButton")
            hb.Size = UDim2.new(1, 0, 0, 16); hb.Position = UDim2.new(0, 0, 0.5, -8)
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

        hsvRow("H", h, Color3.fromRGB(210, 80, 80),   function(r) h  = r end)
        hsvRow("S", s, Color3.fromRGB(160, 160, 160), function(r) s  = r end)
        hsvRow("V", v2, Color3.fromRGB(255, 255, 255), function(r) v2 = r end)

        local PANEL_H = 90
        hbtn.MouseButton1Click:Connect(function()
            open = not open
            if open then
                tween(panel,     { Size = UDim2.new(1, 0, 0, PANEL_H) }, 0.18)
                tween(container, { Size = UDim2.new(1, 0, 0, 24 + PANEL_H + 4) }, 0.18)
            else
                tween(panel,     { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                tween(container, { Size = UDim2.new(1, 0, 0, 24) }, 0.15)
            end
        end)

        if opts.Flag then MatchaLib.Flags[opts.Flag] = { Value = val } end
        return {
            Set      = function(_, c) val=c; preview.BackgroundColor3=c; h,s,v2=Color3.toHSV(c) end,
            GetValue = function() return val end,
        }
    end

    -- ── KEYBIND ─────────────────────────────────────────────
    function el:AddBind(opts)
        opts = opts or {}
        local key     = opts.Default or Enum.KeyCode.Unknown
        local waiting = false

        local row = newFrame({ Size = UDim2.new(1, 0, 0, 24), Parent = col })

        newLabel({
            Size       = UDim2.new(1, -60, 1, 0),
            Text       = opts.Name or "Bind",
            TextColor3 = T.TextSec,
            TextSize   = 12,
            Parent     = row,
        })

        local keyBox = Instance.new("TextButton")
        keyBox.Size             = UDim2.new(0, 56, 0, 18)
        keyBox.Position         = UDim2.new(1, -56, 0.5, -9)
        keyBox.BackgroundColor3 = T.Surface
        keyBox.BorderSizePixel  = 0
        keyBox.Text             = key == Enum.KeyCode.Unknown and "NONE" or key.Name
        keyBox.Font             = Enum.Font.Code
        keyBox.TextSize         = 10
        keyBox.TextColor3       = T.Accent
        keyBox.ZIndex           = 3
        keyBox.Parent           = row
        corner(keyBox, 3)
        uiStroke(keyBox, T.Border)

        keyBox.MouseButton1Click:Connect(function()
            waiting = true
            keyBox.Text      = "..."
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
        local btn = Instance.new("TextButton")
        btn.Size             = UDim2.new(1, 0, 0, 22)
        btn.BackgroundColor3 = T.Surface
        btn.BorderSizePixel  = 0
        btn.Text             = opts.Name or "Button"
        btn.Font             = Enum.Font.Code
        btn.TextSize         = 12
        btn.TextColor3       = T.TextPri
        btn.AutoButtonColor  = false
        btn.Parent           = col
        corner(btn, 3)
        uiStroke(btn, T.Border)

        btn.MouseEnter:Connect(function()    tween(btn, { BackgroundColor3 = T.SurfaceHov }, 0.1) end)
        btn.MouseLeave:Connect(function()    tween(btn, { BackgroundColor3 = T.Surface },    0.1) end)
        btn.MouseButton1Click:Connect(function()
            tween(btn, { BackgroundColor3 = T.AccentDim }, 0.07)
            task.wait(0.1)
            tween(btn, { BackgroundColor3 = T.Surface }, 0.15)
            if opts.Callback then opts.Callback() end
        end)
    end

    -- ── TEXTBOX ─────────────────────────────────────────────
    function el:AddTextbox(opts)
        opts = opts or {}
        local wrap = newFrame({ Size = UDim2.new(1, 0, 0, 38), Parent = col })

        newLabel({
            Size       = UDim2.new(1, 0, 0, 16),
            Text       = opts.Name or "Input",
            TextColor3 = T.TextSec,
            TextSize   = 12,
            Parent     = wrap,
        })

        local box = Instance.new("TextBox")
        box.Size               = UDim2.new(1, 0, 0, 18)
        box.Position           = UDim2.new(0, 0, 0, 18)
        box.BackgroundColor3   = T.SliderBg
        box.BorderSizePixel    = 0
        box.Text               = opts.Default or ""
        box.Font               = Enum.Font.Code
        box.TextSize           = 11
        box.TextColor3         = T.TextPri
        box.PlaceholderText    = opts.Placeholder or "..."
        box.PlaceholderColor3  = T.TextMuted
        box.ClearTextOnFocus   = false
        box.ZIndex             = 3
        box.Parent             = wrap
        corner(box, 3)
        uiStroke(box, T.Border)
        local bp = Instance.new("UIPadding"); bp.PaddingLeft = UDim.new(0, 6); bp.Parent = box

        box.FocusLost:Connect(function()
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

    -- Ventana
    local main = Instance.new("Frame")
    main.Size             = UDim2.new(0, W, 0, 0)
    main.Position         = UDim2.new(0.5, -W/2, 0.5, -H/2)
    main.BackgroundColor3 = T.Bg
    main.BorderSizePixel  = 0
    main.Parent           = gui
    corner(main, 6)
    uiStroke(main, T.Border)

    -- Animación apertura
    tween(main, { Size = UDim2.new(0, W, 0, H) }, 0.28, Enum.EasingStyle.Back)

    -- ── TITLEBAR ────────────────────────────────────────────
    local titleBar = Instance.new("Frame")
    titleBar.Size             = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = T.BgAlt
    titleBar.BorderSizePixel  = 0
    titleBar.ZIndex           = 2
    titleBar.Parent           = main
    corner(titleBar, 6)
    -- fix bottom corners planos
    newFrame({
        Size            = UDim2.new(1, 0, 0, 8),
        Position        = UDim2.new(0, 0, 1, -8),
        BackgroundColor3 = T.BgAlt,
        ZIndex          = 2,
        Parent          = titleBar,
    })

    -- pip rosa izquierda
    local pip = Instance.new("Frame")
    pip.Size             = UDim2.new(0, 3, 0, 14)
    pip.Position         = UDim2.new(0, 8, 0.5, -7)
    pip.BackgroundColor3 = T.Accent
    pip.BorderSizePixel  = 0
    pip.ZIndex           = 3
    pip.Parent           = titleBar
    corner(pip, 2)

    -- Icono 🌿 + titulo
    newLabel({
        Size       = UDim2.new(0.55, 0, 1, 0),
        Position   = UDim2.new(0, 18, 0, 0),
        Text       = (opts.Icon and opts.Icon .. "  " or "") .. (opts.Title or "MatchaLib"),
        TextColor3 = T.TextPri,
        Font       = Enum.Font.GothamBold,
        TextSize   = 12,
        ZIndex     = 3,
        Parent     = titleBar,
    })

    if opts.Subtitle and opts.Subtitle ~= "" then
        newLabel({
            Size       = UDim2.new(0.3, 0, 1, 0),
            Position   = UDim2.new(0.55, 0, 0, 0),
            Text       = opts.Subtitle,
            TextColor3 = T.TextMuted,
            TextSize   = 10,
            ZIndex     = 3,
            Parent     = titleBar,
        })
    end

    -- Botones control
    local function ctrlBtn(txt, xOff, hoverColor)
        local b = Instance.new("TextButton")
        b.Size             = UDim2.new(0, 22, 0, 22)
        b.Position         = UDim2.new(1, xOff, 0.5, -11)
        b.BackgroundColor3 = T.Surface
        b.BorderSizePixel  = 0
        b.Text             = txt
        b.Font             = Enum.Font.GothamBold
        b.TextSize         = 13
        b.TextColor3       = T.TextSec
        b.ZIndex           = 4
        b.Parent           = titleBar
        corner(b, 4)
        b.MouseEnter:Connect(function() tween(b, { BackgroundColor3 = hoverColor or T.SurfaceHov }, 0.1) end)
        b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = T.Surface }, 0.1) end)
        return b
    end

    local closeBtn = ctrlBtn("×", -6,  Color3.fromRGB(180, 50, 50))
    local minBtn   = ctrlBtn("−", -32, T.SurfaceHov)

    closeBtn.MouseButton1Click:Connect(function()
        tween(main, { Size = UDim2.new(0, W, 0, 0) }, 0.18)
        task.wait(0.2); gui:Destroy()
    end)

    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        tween(main, { Size = UDim2.new(0, W, 0, minimized and 30 or H) }, 0.18)
    end)

    makeDraggable(main, titleBar)

    -- ── TAB BAR ─────────────────────────────────────────────
    local tabBar = Instance.new("Frame")
    tabBar.Size             = UDim2.new(1, 0, 0, 24)
    tabBar.Position         = UDim2.new(0, 0, 0, 30)
    tabBar.BackgroundColor3 = T.BgAlt
    tabBar.BorderSizePixel  = 0
    tabBar.ZIndex           = 2
    tabBar.Parent           = main

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection      = Enum.FillDirection.Horizontal
    tabLayout.SortOrder          = Enum.SortOrder.LayoutOrder
    tabLayout.Padding            = UDim.new(0, 0)
    tabLayout.VerticalAlignment  = Enum.VerticalAlignment.Center
    tabLayout.Parent             = tabBar

    local tabPad = Instance.new("UIPadding")
    tabPad.PaddingLeft = UDim.new(0, 6)
    tabPad.Parent      = tabBar

    -- Línea separadora entre tabbar y contenido
    local sep = Instance.new("Frame")
    sep.Size             = UDim2.new(1, 0, 0, 1)
    sep.Position         = UDim2.new(0, 0, 0, 54)
    sep.BackgroundColor3 = T.Border
    sep.BorderSizePixel  = 0
    sep.ZIndex           = 2
    sep.Parent           = main

    -- ── ÁREA DE CONTENIDO ───────────────────────────────────
    local contentArea = Instance.new("Frame")
    contentArea.Size              = UDim2.new(1, 0, 1, -56)
    contentArea.Position          = UDim2.new(0, 0, 0, 56)
    contentArea.BackgroundTransparency = 1
    contentArea.ClipsDescendants  = true
    contentArea.Parent            = main

    -- ── CREAR TAB ───────────────────────────────────────────
    function win:CreateTab(name)
        local tab = {}

        -- Botón del tab
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size              = UDim2.new(0, 0, 1, 0)
        tabBtn.AutomaticSize     = Enum.AutomaticSize.X
        tabBtn.BackgroundTransparency = 1
        tabBtn.Text              = name
        tabBtn.Font              = Enum.Font.Code
        tabBtn.TextSize          = 11
        tabBtn.TextColor3        = T.TextMuted
        tabBtn.AutoButtonColor   = false
        tabBtn.ZIndex            = 3
        tabBtn.Parent            = tabBar

        local tbPad = Instance.new("UIPadding"); tbPad.Parent = tabBtn
        tbPad.PaddingLeft  = UDim.new(0, 10)
        tbPad.PaddingRight = UDim.new(0, 10)

        -- Subrayado activo
        local underline = Instance.new("Frame")
        underline.Size                   = UDim2.new(1, -20, 0, 1)
        underline.Position               = UDim2.new(0, 10, 1, -1)
        underline.BackgroundColor3       = T.Accent
        underline.BorderSizePixel        = 0
        underline.BackgroundTransparency = 1
        underline.ZIndex                 = 4
        underline.Parent                 = tabBtn

        -- Scroll del tab
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size                    = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency  = 1
        scroll.BorderSizePixel         = 0
        scroll.ScrollBarThickness      = 2
        scroll.ScrollBarImageColor3    = T.Accent
        scroll.CanvasSize              = UDim2.new(0, 0, 0, 0)
        scroll.Visible                 = false
        scroll.ZIndex                  = 1
        scroll.Parent                  = contentArea

        -- Holder de dos columnas
        local colHolder = newFrame({
            Size     = UDim2.new(1, -16, 1, 0),
            Position = UDim2.new(0, 8, 0, 6),
            Parent   = scroll,
        })
        colHolder.AutomaticSize = Enum.AutomaticSize.Y

        local colList = Instance.new("UIListLayout")
        colList.FillDirection        = Enum.FillDirection.Horizontal
        colList.HorizontalAlignment  = Enum.HorizontalAlignment.Left
        colList.Padding              = UDim.new(0, 0)
        colList.Parent               = colHolder

        -- Columna izquierda
        local leftCol = Instance.new("Frame")
        leftCol.Size             = UDim2.new(0.5, -1, 0, 0)
        leftCol.AutomaticSize    = Enum.AutomaticSize.Y
        leftCol.BackgroundTransparency = 1
        leftCol.Parent           = colHolder

        local leftList = Instance.new("UIListLayout")
        leftList.SortOrder = Enum.SortOrder.LayoutOrder
        leftList.Padding   = UDim.new(0, 4)
        leftList.Parent    = leftCol
        local lPad = Instance.new("UIPadding"); lPad.PaddingRight = UDim.new(0, 6); lPad.Parent = leftCol

        -- Línea divisora central
        local divLine = Instance.new("Frame")
        divLine.Size             = UDim2.new(0, 1, 1, 0)
        divLine.BackgroundColor3 = T.ColDivider
        divLine.BorderSizePixel  = 0
        divLine.Parent           = colHolder

        -- Columna derecha
        local rightCol = Instance.new("Frame")
        rightCol.Size             = UDim2.new(0.5, -1, 0, 0)
        rightCol.AutomaticSize    = Enum.AutomaticSize.Y
        rightCol.BackgroundTransparency = 1
        rightCol.Parent           = colHolder

        local rightList = Instance.new("UIListLayout")
        rightList.SortOrder = Enum.SortOrder.LayoutOrder
        rightList.Padding   = UDim.new(0, 4)
        rightList.Parent    = rightCol
        local rPad = Instance.new("UIPadding"); rPad.PaddingLeft = UDim.new(0, 6); rPad.Parent = rightCol

        -- Auto-resize scroll canvas
        local function updateCanvas()
            local lH = leftList.AbsoluteContentSize.Y
            local rH = rightList.AbsoluteContentSize.Y
            scroll.CanvasSize = UDim2.new(0, 0, 0, math.max(lH, rH) + 24)
        end
        leftList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
        rightList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

        -- Construir APIs de elementos
        local leftEl  = buildElements(leftCol)
        local rightEl = buildElements(rightCol)

        tab.Left  = leftEl
        tab.Right = rightEl

        -- Shortcut: métodos en tab -> columna izquierda
        function tab:AddSection(n)        return leftEl:AddSection(n) end
        function tab:AddLabel(t)          return leftEl:AddLabel(t) end
        function tab:AddToggle(o)         return leftEl:AddToggle(o) end
        function tab:AddSlider(o)         return leftEl:AddSlider(o) end
        function tab:AddDropdown(o)       return leftEl:AddDropdown(o) end
        function tab:AddColorpicker(o)    return leftEl:AddColorpicker(o) end
        function tab:AddBind(o)           return leftEl:AddBind(o) end
        function tab:AddButton(o)         return leftEl:AddButton(o) end
        function tab:AddTextbox(o)        return leftEl:AddTextbox(o) end

        -- Activar / desactivar
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

        -- Primer tab activo por defecto
        if #tabContents == 1 then
            scroll.Visible              = true
            tabBtn.TextColor3           = T.TextPri
            underline.BackgroundTransparency = 0
            currentTab                  = name
        end

        return tab
    end

    -- Ocultar / mostrar ventana programáticamente
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

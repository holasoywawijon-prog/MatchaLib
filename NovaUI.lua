--[[
    NovaUI v3 - Réplica exacta del layout de referencia
    (tabs simples arriba, columnas divididas por línea vertical,
    checkboxes cuadrados, slider tipo barra, dropdown plano)

    USO:
        local NovaUI = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/holasoywawijon-prog/MatchaLib/refs/heads/main/NovaUI.lua"
        ))()

        local Window = NovaUI:CreateWindow({Title = "AimLib"}) -- pon aquí el título que quieras

        local Tab = Window:AddTab("Aiming")
        Window:AddTab("Visuals")

        local Col1 = Tab:AddColumn("Aim Assist", 215)
        Col1:AddCheckbox({Text = "Enabled", Callback = function(v) end})
        Col1:AddSlider({Text = "Slider", Min = 0, Max = 30, Default = 0, Callback = function(v) end})
        Col1:AddDropdown({Text = "Aim", Options = {"NONE", "Head", "Chest"}, Callback = function(v) end})

        local Col2 = Tab:AddColumn("Silent Aimbot")
        Col2:AddCheckbox({Text = "Enabled", Callback = function(v) end})

    Solo interfaz. Los callbacks quedan vacíos para que conectes tu propia lógica.
]]

local NovaUI = {}
NovaUI.__index = NovaUI

----------------------------------------------------------------
-- SERVICIOS
----------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer

----------------------------------------------------------------
-- PALETA (monocromática, fiel a la referencia)
----------------------------------------------------------------
local Theme = {
    Background      = Color3.fromRGB(24, 24, 24),
    HeaderBar       = Color3.fromRGB(30, 30, 30),
    ColumnHeader    = Color3.fromRGB(34, 34, 34),
    FieldBg         = Color3.fromRGB(32, 32, 32),
    Stroke          = Color3.fromRGB(48, 48, 48),
    TextPrimary     = Color3.fromRGB(230, 230, 230),
    TextSecondary   = Color3.fromRGB(140, 140, 140),
    Accent          = Color3.fromRGB(235, 235, 235),
    Success         = Color3.fromRGB(87, 201, 132),
    Warning         = Color3.fromRGB(230, 175, 70),
    Error           = Color3.fromRGB(230, 90, 90),
    Info            = Color3.fromRGB(90, 160, 230),
}

local FONT = Enum.Font.Gotham
local FONT_BOLD = Enum.Font.GothamBold

----------------------------------------------------------------
-- UTILIDADES
----------------------------------------------------------------
local function create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    for _, child in ipairs(children or {}) do child.Parent = inst end
    return inst
end

local function corner(radius) return create("UICorner", {CornerRadius = UDim.new(0, radius or 3)}) end
local function stroke(color, thickness)
    return create("UIStroke", {Color = color or Theme.Stroke, Thickness = thickness or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
end
local function tween(inst, props, duration, style, dir)
    local info = TweenInfo.new(duration or 0.15, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

local function makeDraggable(topBar, target)
    local dragging, dragStart, startPos
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    topBar.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- chevron dibujado (no depende de fuentes)
local function buildChevron(parent, size, color)
    size = size or 8
    local holder = create("Frame", {BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size), Parent = parent})
    create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, -size * 0.22, 0.5, 0),
        Size = UDim2.fromOffset(size * 0.55, 2), Rotation = 45, BackgroundColor3 = color or Theme.TextSecondary,
        BorderSizePixel = 0, Parent = holder,
    }, {corner(1)})
    create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, size * 0.22, 0.5, 0),
        Size = UDim2.fromOffset(size * 0.55, 2), Rotation = -45, BackgroundColor3 = color or Theme.TextSecondary,
        BorderSizePixel = 0, Parent = holder,
    }, {corner(1)})
    return holder
end

-- check mark dibujado (para checkboxes)
local function buildCheck(parent, color)
    local holder = create("Frame", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = parent, Visible = false, Name = "Check"})
    create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.35, 0, 0.55, 0),
        Size = UDim2.fromOffset(6, 2), Rotation = 45, BackgroundColor3 = color or Theme.Background, BorderSizePixel = 0, Parent = holder,
    }, {corner(1)})
    create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.6, 0, 0.4, 0),
        Size = UDim2.fromOffset(10, 2), Rotation = -45, BackgroundColor3 = color or Theme.Background, BorderSizePixel = 0, Parent = holder,
    }, {corner(1)})
    return holder
end

----------------------------------------------------------------
-- ROOT
----------------------------------------------------------------
local ScreenGui = create("ScreenGui", {Name = "NovaUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999})
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

----------------------------------------------------------------
-- STATS BAR
----------------------------------------------------------------
local function buildStatsBar()
    local bar = create("Frame", {Name = "StatsBar", Size = UDim2.new(0, 560, 0, 26), Position = UDim2.new(0, 8, 0, 8), BackgroundColor3 = Theme.HeaderBar, BorderSizePixel = 0, Parent = ScreenGui}, {corner(4), stroke()})
    create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 10), Parent = bar})
    create("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = bar})

    local function statLabel(text)
        return create("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Font = FONT, Text = text, TextColor3 = Theme.TextSecondary, TextSize = 13, Parent = bar})
    end
    local gameLabel = statLabel(game.Name); gameLabel.TextColor3 = Theme.TextPrimary; gameLabel.Font = FONT_BOLD
    statLabel("|"); statLabel("Private"); statLabel("|")
    local fpsLabel = statLabel("-- fps"); statLabel("|")
    local pingLabel = statLabel("-- ms"); statLabel("|")
    local timeLabel = statLabel(os.date("%H:%M:%S")); statLabel("|")
    local dateLabel = statLabel(os.date("%b, %d, %Y"))

    local frames, lastCheck = 0, os.clock()
    RunService.RenderStepped:Connect(function()
        frames += 1
        local now = os.clock()
        if now - lastCheck >= 1 then fpsLabel.Text = string.format("%d fps", frames); frames = 0; lastCheck = now end
    end)
    task.spawn(function()
        while bar.Parent do
            local ok, ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
            pingLabel.Text = ok and string.format("%dms", ping) or "--ms"
            timeLabel.Text = os.date("%H:%M:%S")
            dateLabel.Text = os.date("%b, %d, %Y")
            task.wait(1)
        end
    end)
    return bar
end
local StatsBar = buildStatsBar()

----------------------------------------------------------------
-- NOTIFICACIONES
----------------------------------------------------------------
local NotifyHolder = create("Frame", {Name = "Notifications", BackgroundTransparency = 1, Size = UDim2.new(0, 300, 1, -20), Position = UDim2.new(1, -310, 0, 10), Parent = ScreenGui})
create("UIListLayout", {HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Top, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = NotifyHolder})
local TYPE_COLORS = {Info = Theme.Info, Success = Theme.Success, Warning = Theme.Warning, Error = Theme.Error}

function NovaUI:Notify(opts)
    opts = opts or {}
    local color = TYPE_COLORS[opts.Type or "Info"] or Theme.Accent
    local duration = opts.Duration or 4
    local card = create("Frame", {BackgroundColor3 = Theme.HeaderBar, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(1, 40, 0, 0), BorderSizePixel = 0, Parent = NotifyHolder}, {corner(6), stroke()})
    create("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = card})
    create("Frame", {BackgroundColor3 = color, Size = UDim2.new(0, 4, 1, 0), BorderSizePixel = 0, Parent = card}, {corner(2)})
    create("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -12, 0, 18), Font = FONT_BOLD, Text = opts.Title or "Notificación", TextColor3 = Theme.TextPrimary, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = card})
    create("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 20), Size = UDim2.new(1, -12, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = FONT, Text = opts.Content or "", TextColor3 = Theme.TextSecondary, TextSize = 13, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = card})
    tween(card, {Position = UDim2.new(0, 0, 0, 0)}, 0.25)
    task.spawn(function()
        task.wait(duration)
        local t = tween(card, {Position = UDim2.new(1, 40, 0, 0)}, 0.25)
        t.Completed:Wait()
        card:Destroy()
    end)
    return card
end

----------------------------------------------------------------
-- LOGGER
----------------------------------------------------------------
local LogFrame = create("Frame", {Name = "Logger", Size = UDim2.new(0, 320, 0, 140), Position = UDim2.new(0, 8, 1, -150), BackgroundColor3 = Theme.HeaderBar, BorderSizePixel = 0, Parent = ScreenGui}, {corner(6), stroke()})
local LogTop = create("Frame", {Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = Theme.ColumnHeader, BorderSizePixel = 0, Parent = LogFrame}, {corner(6)})
create("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -40, 1, 0), Font = FONT_BOLD, Text = "Logger", TextColor3 = Theme.TextPrimary, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = LogTop})
local LogToggleBtn = create("TextButton", {BackgroundTransparency = 1, Position = UDim2.new(1, -26, 0, 0), Size = UDim2.new(0, 26, 1, 0), Font = FONT_BOLD, Text = "-", TextColor3 = Theme.TextSecondary, TextSize = 16, Parent = LogTop})
local LogScroll = create("ScrollingFrame", {Position = UDim2.new(0, 0, 0, 26), Size = UDim2.new(1, 0, 1, -26), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.TextSecondary, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = LogFrame})
create("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), Parent = LogScroll})
local LogLayout = create("UIListLayout", {Padding = UDim.new(0, 2), Parent = LogScroll})

local logCollapsed = false
LogToggleBtn.MouseButton1Click:Connect(function()
    logCollapsed = not logCollapsed
    LogScroll.Visible = not logCollapsed
    LogToggleBtn.Text = logCollapsed and "+" or "-"
    tween(LogFrame, {Size = logCollapsed and UDim2.new(0, 320, 0, 26) or UDim2.new(0, 320, 0, 140)}, 0.2)
end)
makeDraggable(LogTop, LogFrame)

local LOG_COLORS = {Info = Theme.TextSecondary, Success = Theme.Success, Warning = Theme.Warning, Error = Theme.Error}
function NovaUI:Log(message, logType)
    logType = logType or "Info"
    local color = LOG_COLORS[logType] or Theme.TextSecondary
    local timestamp = os.date("%H:%M:%S")
    local entry = create("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = FONT, TextSize = 12,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, RichText = true,
        Text = string.format('<font color="rgb(120,122,135)">[%s]</font> <font color="rgb(%d,%d,%d)">%s</font>', timestamp, color.R * 255, color.G * 255, color.B * 255, message),
        Parent = LogScroll,
    })
    task.wait()
    LogScroll.CanvasPosition = Vector2.new(0, LogLayout.AbsoluteContentSize.Y)
    return entry
end

----------------------------------------------------------------
-- FÁBRICA DE ELEMENTOS (estilo plano, fiel a la referencia)
----------------------------------------------------------------
local function attachElementBuilders(target, container)

    -- Checkbox cuadrado + texto (como "☐ Enabled" de la referencia)
    function target:AddCheckbox(o)
        o = o or {}
        local state = o.Default or false

        local row = create("Frame", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Parent = container})

        local box = create("Frame", {
            Position = UDim2.new(0, 0, 0.5, -7), Size = UDim2.fromOffset(14, 14),
            BackgroundColor3 = state and Theme.Accent or Theme.FieldBg, Parent = row,
        }, {corner(2), stroke()})
        local check = buildCheck(box, Theme.Background)
        check.Visible = state

        create("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.new(0, 22, 0, 0), Size = UDim2.new(1, -22, 1, 0),
            Font = FONT, Text = o.Text or "Enabled", TextColor3 = Theme.TextPrimary, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
        })

        local click = create("TextButton", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", Parent = row})
        click.MouseButton1Click:Connect(function()
            state = not state
            box.BackgroundColor3 = state and Theme.Accent or Theme.FieldBg
            check.Visible = state
            if o.Callback then o.Callback(state) end
        end)
        return row
    end

    -- alias por compatibilidad con la versión anterior (switch clásico)
    function target:AddToggle(o) return target:AddCheckbox(o) end

    -- Slider como barra plana con texto centrado ("Slider: 0/30")
    function target:AddSlider(o)
        o = o or {}
        local min, max = o.Min or 0, o.Max or 100
        local value = o.Default or min

        local track = create("Frame", {Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = Theme.FieldBg, Parent = container}, {corner(3), stroke()})
        local fill = create("Frame", {Size = UDim2.new((value - min) / (max - min), 0, 1, 0), BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.3, Parent = track}, {corner(3)})
        local label = create("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = FONT,
            Text = string.format("%s: %d/%d", o.Text or "Slider", value, max), TextColor3 = Theme.TextPrimary,
            TextSize = 13, ZIndex = 2, Parent = track,
        })

        local dragging = false
        local function update(inputPos)
            local rel = math.clamp((inputPos - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            value = math.floor(min + (max - min) * rel)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            label.Text = string.format("%s: %d/%d", o.Text or "Slider", value, max)
            if o.Callback then o.Callback(value) end
        end

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                update(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input.Position.X) end
        end)
        return track
    end

    -- Label pequeño encima de un campo (como "Aim" antes del dropdown)
    function target:AddLabel(text)
        return create("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Font = FONT, Text = text or "",
            TextColor3 = Theme.TextSecondary, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = container,
        })
    end

    -- Dropdown plano con flecha (como "NONE ▾")
    function target:AddDropdown(o)
        o = o or {}
        local options = o.Options or {}
        local open = false
        local selected = o.Default or options[1] or "NONE"

        if o.Text then target:AddLabel(o.Text) end

        local holder = create("Frame", {Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = Theme.FieldBg, ClipsDescendants = true, Parent = container}, {corner(3), stroke()})
        local btn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Font = FONT, Text = "  " .. tostring(selected),
            TextColor3 = Theme.TextPrimary, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = holder,
        })
        local chevron = buildChevron(holder, 8)
        chevron.Position = UDim2.new(1, -20, 0.5, -4)

        local list = create("Frame", {Position = UDim2.new(0, 0, 0, 24), Size = UDim2.new(1, 0, 0, #options * 22), BackgroundTransparency = 1, Parent = holder})
        create("UIListLayout", {Parent = list})

        for _, opt in ipairs(options) do
            local optBtn = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = Theme.ColumnHeader, AutoButtonColor = false, Font = FONT,
                Text = "  " .. tostring(opt), TextColor3 = Theme.TextSecondary, TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = list,
            })
            optBtn.MouseEnter:Connect(function() tween(optBtn, {TextColor3 = Theme.TextPrimary}, 0.1) end)
            optBtn.MouseLeave:Connect(function() tween(optBtn, {TextColor3 = Theme.TextSecondary}, 0.1) end)
            optBtn.MouseButton1Click:Connect(function()
                selected = opt
                btn.Text = "  " .. tostring(opt)
                open = false
                tween(holder, {Size = UDim2.new(1, 0, 0, 24)}, 0.15)
                if o.Callback then o.Callback(opt) end
            end)
        end

        btn.MouseButton1Click:Connect(function()
            open = not open
            tween(holder, {Size = open and UDim2.new(1, 0, 0, 24 + #options * 22) or UDim2.new(1, 0, 0, 24)}, 0.15)
            tween(chevron, {Rotation = open and 180 or 0}, 0.15)
        end)
        return holder
    end

    function target:AddInput(o)
        o = o or {}
        if o.Text then target:AddLabel(o.Text) end
        local box = create("TextBox", {
            Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = Theme.FieldBg, Font = FONT,
            PlaceholderText = o.Placeholder or "Escribe...", Text = "", TextColor3 = Theme.TextPrimary,
            PlaceholderColor3 = Theme.TextSecondary, TextSize = 13, ClearTextOnFocus = false, Parent = container,
        }, {corner(3), stroke()})
        create("UIPadding", {PaddingLeft = UDim.new(0, 8), Parent = box})
        box.FocusLost:Connect(function(enterPressed) if o.Callback then o.Callback(box.Text, enterPressed) end end)
        return box
    end

    function target:AddKeybind(o)
        o = o or {}
        local currentKey = o.Default or Enum.KeyCode.Unknown
        local listening = false

        local row = create("Frame", {Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Parent = container})
        create("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, -80, 1, 0), Font = FONT, Text = o.Text or "Keybind", TextColor3 = Theme.TextPrimary, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = row})
        local keyBtn = create("TextButton", {
            Position = UDim2.new(1, -70, 0, 0), Size = UDim2.new(0, 70, 1, 0), BackgroundColor3 = Theme.FieldBg,
            Font = FONT_BOLD, Text = currentKey.Name, TextColor3 = Theme.TextPrimary, TextSize = 12, Parent = row,
        }, {corner(3), stroke()})

        keyBtn.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            keyBtn.Text = "..."
        end)
        local conn
        conn = UserInputService.InputBegan:Connect(function(input)
            if not listening then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                currentKey = input.KeyCode
                keyBtn.Text = currentKey.Name
                listening = false
                if o.Callback then o.Callback(currentKey) end
            end
        end)
        row.AncestryChanged:Connect(function(_, parent) if not parent and conn then conn:Disconnect() end end)
        return row
    end

    function target:AddButton(o)
        o = o or {}
        local btn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = Theme.FieldBg, AutoButtonColor = false,
            Font = FONT, Text = o.Text or "Botón", TextColor3 = Theme.TextPrimary, TextSize = 13, Parent = container,
        }, {corner(3), stroke()})
        btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = Theme.ColumnHeader}, 0.1) end)
        btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = Theme.FieldBg}, 0.1) end)
        btn.MouseButton1Click:Connect(function() if o.Callback then o.Callback() end end)
        return btn
    end
end

----------------------------------------------------------------
-- VENTANA PRINCIPAL
----------------------------------------------------------------
function NovaUI:CreateWindow(opts)
    opts = opts or {}
    local size = opts.Size or UDim2.fromOffset(432, 510)

    local Window = {}
    Window.Tabs = {}

    local Main = create("Frame", {
        Name = "Window", Size = size, Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        BackgroundColor3 = Theme.Background, BorderSizePixel = 0, ClipsDescendants = true, Parent = ScreenGui,
    }, {corner(4), stroke()})

    -- Barra de título (igual que la referencia: texto en mayúsculas, negrita, arriba a la izquierda)
    local TitleBar = create("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.HeaderBar, BorderSizePixel = 0, Parent = Main}, {corner(4)})
    create("Frame", {Position = UDim2.new(0, 0, 1, -6), Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = Theme.HeaderBar, BorderSizePixel = 0, Parent = TitleBar})

    create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -50, 1, 0),
        Font = FONT_BOLD, Text = string.upper(opts.Title or "NOVAUI"), TextColor3 = Theme.TextPrimary, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = TitleBar,
    })
    local CloseBtn = create("TextButton", {
        Position = UDim2.new(1, -26, 0, 4), Size = UDim2.new(0, 20, 0, 20), BackgroundTransparency = 1,
        Text = "X", Font = FONT_BOLD, TextColor3 = Theme.TextSecondary, TextSize = 13, Parent = TitleBar,
    })
    CloseBtn.MouseEnter:Connect(function() tween(CloseBtn, {TextColor3 = Theme.Error}, 0.1) end)
    CloseBtn.MouseLeave:Connect(function() tween(CloseBtn, {TextColor3 = Theme.TextSecondary}, 0.1) end)
    CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)
    makeDraggable(TitleBar, Main)

    -- Fila de pestañas simples (texto plano, sin fondo, subrayado si está activa)
    local TabRow = create("Frame", {Position = UDim2.new(0, 0, 0, 30), Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Parent = Main})
    create("Frame", {Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = TabRow})
    local TabLayout = create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 18), Parent = TabRow})
    create("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingTop = UDim.new(0, 6), Parent = TabRow})

    local ContentArea = create("Frame", {
        Position = UDim2.new(0, 0, 0, 58), Size = UDim2.new(1, 0, 1, -58), BackgroundTransparency = 1, Parent = Main,
    })

    ----------------------------------------------------------------
    -- TAB (contenido dividido en columnas, como la referencia)
    ----------------------------------------------------------------
    function Window:AddTab(name)
        local Tab = {}

        local TabBtn = create("TextButton", {
            Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1,
            Font = FONT_BOLD, Text = name, TextColor3 = Theme.TextSecondary, TextSize = 13, Parent = TabRow,
        })
        local underline = create("Frame", {
            Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 1, Parent = TabBtn,
        })

        local Page = create("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, Parent = ContentArea})
        local PageLayout = create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Parent = Page})

        local function selectTab()
            for _, t in ipairs(Window.Tabs) do
                t.Page.Visible = false
                tween(t.Btn, {TextColor3 = Theme.TextSecondary}, 0.1)
                tween(t.Underline, {BackgroundTransparency = 1}, 0.1)
            end
            Page.Visible = true
            tween(TabBtn, {TextColor3 = Theme.TextPrimary}, 0.1)
            tween(underline, {BackgroundTransparency = 0}, 0.1)
        end

        TabBtn.MouseButton1Click:Connect(selectTab)
        table.insert(Window.Tabs, {Btn = TabBtn, Page = Page, Underline = underline})
        if #Window.Tabs == 1 then selectTab() end

        -- Columna: cabecera con título + línea divisoria vertical entre columnas
        function Tab:AddColumn(title, width)
            local isFirst = #Page:GetChildren() <= 1 -- solo UIListLayout presente aún

            local col = create("Frame", {
                Size = width and UDim2.new(0, width, 1, 0) or UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1, Parent = Page,
            })
            if not width then
                col.Size = UDim2.new(1, 0, 1, 0)
            end

            if not isFirst then
                create("Frame", {Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = col})
            end

            local header = create("Frame", {Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = Theme.ColumnHeader, BorderSizePixel = 0, Parent = col})
            create("TextLabel", {
                BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -12, 1, 0),
                Font = FONT_BOLD, Text = title or "Sección", TextColor3 = Theme.TextPrimary, TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
            })

            local body = create("Frame", {
                Position = UDim2.new(0, 0, 0, 26), Size = UDim2.new(1, 0, 1, -26), BackgroundTransparency = 1, Parent = col,
            })
            create("UIListLayout", {Padding = UDim.new(0, 8), Parent = body})
            create("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = body})

            local Column = {}
            attachElementBuilders(Column, body)
            Column.Instance = col
            return Column
        end

        Tab.Instance = Page
        return Tab
    end

    Window.Instance = Main
    return Window
end

----------------------------------------------------------------
-- ACCESOS GLOBALES
----------------------------------------------------------------
NovaUI.ScreenGui = ScreenGui
NovaUI.StatsBar = StatsBar
NovaUI.LogFrame = LogFrame
NovaUI.Theme = Theme

NovaUI:Log("NovaUI cargada correctamente", "Success")

return NovaUI

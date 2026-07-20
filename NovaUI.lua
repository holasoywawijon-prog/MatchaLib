--[[
    NovaUI v2 - Librería de interfaz para Roblox
    Estilo propio, inspirado en menús tipo "executor" clásicos.

    USO (loadstring):
        local NovaUI = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/holasoywawijon-prog/MatchaLib/refs/heads/main/NovaUI.lua"
        ))()

        local Window = NovaUI:CreateWindow({Title = "Tokyo", SubTitle = "Da Hood"})

        local Tab = Window:AddTab("Combat", "rbxassetid://0") -- icono opcional

        local Section = Tab:AddSection("Players")
        Section:AddToggle({Text = "Auto Kill", Default = false, Callback = function(state) end})
        Section:AddSlider({Text = "Reach", Min = 0, Max = 50, Default = 10, Callback = function(v) end})
        Section:AddKeybind({Text = "Toggle Menu", Default = Enum.KeyCode.RightShift, Callback = function(key) end})

        NovaUI:Notify({Title = "Info", Content = "Bienvenido", Type = "Info", Duration = 4})
        NovaUI:Log("Script cargado correctamente", "Success")

    Solo construye interfaz. Los callbacks quedan vacíos: conecta ahí tu propia lógica.
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
-- PALETA
----------------------------------------------------------------
local Theme = {
    Background      = Color3.fromRGB(17, 18, 23),
    Panel           = Color3.fromRGB(23, 25, 32),
    PanelLight      = Color3.fromRGB(29, 31, 39),
    Section         = Color3.fromRGB(21, 23, 29),
    Stroke          = Color3.fromRGB(42, 44, 54),
    TextPrimary     = Color3.fromRGB(238, 238, 242),
    TextSecondary   = Color3.fromRGB(145, 147, 160),
    Accent          = Color3.fromRGB(130, 96, 255),
    AccentDark      = Color3.fromRGB(96, 68, 214),
    Success         = Color3.fromRGB(87, 201, 132),
    Warning         = Color3.fromRGB(230, 175, 70),
    Error           = Color3.fromRGB(230, 90, 90),
    Info            = Color3.fromRGB(90, 160, 230),
}

local FONT = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

----------------------------------------------------------------
-- UTILIDADES
----------------------------------------------------------------
local function create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function corner(radius) return create("UICorner", {CornerRadius = UDim.new(0, radius or 6)}) end
local function stroke(color, thickness)
    return create("UIStroke", {Color = color or Theme.Stroke, Thickness = thickness or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
end
local function padding(all)
    return create("UIPadding", {PaddingTop = UDim.new(0, all), PaddingBottom = UDim.new(0, all), PaddingLeft = UDim.new(0, all), PaddingRight = UDim.new(0, all)})
end
local function tween(inst, props, duration, style, dir)
    local info = TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
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

-- Flecha dibujada con 2 frames (evita glifos "tofu" que dependen de la fuente)
local function buildChevron(parent, size, color)
    size = size or 8
    local holder = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(size, size),
        Parent = parent,
    })
    local left = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, -size * 0.22, 0.5, 0),
        Size = UDim2.fromOffset(size * 0.55, 2),
        Rotation = 45,
        BackgroundColor3 = color or Theme.TextSecondary,
        BorderSizePixel = 0,
        Parent = holder,
    }, {corner(1)})
    local right = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, size * 0.22, 0.5, 0),
        Size = UDim2.fromOffset(size * 0.55, 2),
        Rotation = -45,
        BackgroundColor3 = color or Theme.TextSecondary,
        BorderSizePixel = 0,
        Parent = holder,
    }, {corner(1)})
    return holder, {left, right}
end

----------------------------------------------------------------
-- ROOT
----------------------------------------------------------------
local ScreenGui = create("ScreenGui", {
    Name = "NovaUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
})
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

----------------------------------------------------------------
-- STATS BAR (se mantiene, funcionaba bien)
----------------------------------------------------------------
local function buildStatsBar()
    local bar = create("Frame", {
        Name = "StatsBar", Size = UDim2.new(0, 560, 0, 26), Position = UDim2.new(0, 8, 0, 8),
        BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Parent = ScreenGui,
    }, {corner(6), stroke()})
    create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 10), Parent = bar})
    create("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = bar})

    local function statLabel(text)
        return create("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Font = FONT, Text = text, TextColor3 = Theme.TextSecondary, TextSize = 13, Parent = bar})
    end

    local gameLabel = statLabel(game.Name); gameLabel.TextColor3 = Theme.TextPrimary; gameLabel.Font = FONT_BOLD
    statLabel("|")
    statLabel("Private")
    statLabel("|")
    local fpsLabel = statLabel("-- fps")
    statLabel("|")
    local pingLabel = statLabel("-- ms")
    statLabel("|")
    local timeLabel = statLabel(os.date("%H:%M:%S"))
    statLabel("|")
    local dateLabel = statLabel(os.date("%b, %d, %Y"))

    local frames, lastCheck = 0, os.clock()
    RunService.RenderStepped:Connect(function()
        frames += 1
        local now = os.clock()
        if now - lastCheck >= 1 then
            fpsLabel.Text = string.format("%d fps", frames)
            frames = 0
            lastCheck = now
        end
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
-- NOTIFICACIONES (se mantiene)
----------------------------------------------------------------
local NotifyHolder = create("Frame", {
    Name = "Notifications", BackgroundTransparency = 1, Size = UDim2.new(0, 300, 1, -20), Position = UDim2.new(1, -310, 0, 10), Parent = ScreenGui,
})
create("UIListLayout", {HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Top, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = NotifyHolder})

local TYPE_COLORS = {Info = Theme.Info, Success = Theme.Success, Warning = Theme.Warning, Error = Theme.Error}

function NovaUI:Notify(opts)
    opts = opts or {}
    local color = TYPE_COLORS[opts.Type or "Info"] or Theme.Accent
    local duration = opts.Duration or 4

    local card = create("Frame", {
        BackgroundColor3 = Theme.Panel, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(1, 40, 0, 0), BorderSizePixel = 0, Parent = NotifyHolder,
    }, {corner(8), stroke(), padding(10)})

    create("Frame", {BackgroundColor3 = color, Size = UDim2.new(0, 4, 1, 0), BorderSizePixel = 0, Parent = card}, {corner(2)})

    create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -12, 0, 18),
        Font = FONT_BOLD, Text = opts.Title or "Notificación", TextColor3 = Theme.TextPrimary, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = card,
    })
    create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 20), Size = UDim2.new(1, -12, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, Font = FONT, Text = opts.Content or "", TextColor3 = Theme.TextSecondary,
        TextSize = 13, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = card,
    })

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
-- LOGGER (se mantiene)
----------------------------------------------------------------
local LogFrame = create("Frame", {
    Name = "Logger", Size = UDim2.new(0, 320, 0, 140), Position = UDim2.new(0, 8, 1, -150),
    BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Parent = ScreenGui,
}, {corner(8), stroke()})

local LogTop = create("Frame", {Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = Theme.PanelLight, BorderSizePixel = 0, Parent = LogFrame}, {corner(8)})
create("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -40, 1, 0), Font = FONT_BOLD, Text = "Logger", TextColor3 = Theme.TextPrimary, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = LogTop})

local LogToggleBtn = create("TextButton", {BackgroundTransparency = 1, Position = UDim2.new(1, -26, 0, 0), Size = UDim2.new(0, 26, 1, 0), Font = FONT_BOLD, Text = "-", TextColor3 = Theme.TextSecondary, TextSize = 16, Parent = LogTop})

local LogScroll = create("ScrollingFrame", {
    Position = UDim2.new(0, 0, 0, 26), Size = UDim2.new(1, 0, 1, -26), BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent, CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = LogFrame,
})
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
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Font = FONT, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, RichText = true,
        Text = string.format('<font color="rgb(120,122,135)">[%s]</font> <font color="rgb(%d,%d,%d)">%s</font>',
            timestamp, color.R * 255, color.G * 255, color.B * 255, message),
        Parent = LogScroll,
    })
    task.wait()
    LogScroll.CanvasPosition = Vector2.new(0, LogLayout.AbsoluteContentSize.Y)
    return entry
end

----------------------------------------------------------------
-- FÁBRICA DE ELEMENTOS (usada tanto por Tab directamente como por Section)
----------------------------------------------------------------
local function attachElementBuilders(target, container)
    -- target: tabla donde se agregan los métodos (Tab o Section)
    -- container: Instance (Frame) donde se insertan los elementos visualmente

    function target:AddButton(o)
        o = o or {}
        local row = create("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.PanelLight, Parent = container}, {corner(6), stroke()})

        if o.Icon then
            create("ImageLabel", {
                BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0.5, -9), Size = UDim2.fromOffset(18, 18),
                Image = o.Icon, ImageColor3 = Theme.TextPrimary, Parent = row,
            })
        end

        local btn = create("TextButton", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), AutoButtonColor = false, Font = FONT,
            Text = (o.Icon and "        " or "  ") .. (o.Text or "Botón"), TextColor3 = Theme.TextPrimary, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
        })

        btn.MouseEnter:Connect(function() tween(row, {BackgroundColor3 = Theme.Accent}, 0.15) end)
        btn.MouseLeave:Connect(function() tween(row, {BackgroundColor3 = Theme.PanelLight}, 0.15) end)
        btn.MouseButton1Click:Connect(function() if o.Callback then o.Callback() end end)
        return row
    end

    function target:AddToggle(o)
        o = o or {}
        local state = o.Default or false

        local holder = create("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.PanelLight, Parent = container}, {corner(6), stroke()})
        create("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -60, 1, 0),
            Font = FONT, Text = o.Text or "Toggle", TextColor3 = Theme.TextPrimary, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = holder,
        })

        local switch = create("Frame", {Position = UDim2.new(1, -44, 0.5, -9), Size = UDim2.new(0, 32, 0, 18), BackgroundColor3 = state and Theme.Accent or Theme.Stroke, Parent = holder}, {corner(9)})
        local dot = create("Frame", {Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7), Size = UDim2.new(0, 14, 0, 14), BackgroundColor3 = Theme.TextPrimary, Parent = switch}, {corner(7)})
        local clickArea = create("TextButton", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", Parent = holder})

        clickArea.MouseButton1Click:Connect(function()
            state = not state
            tween(switch, {BackgroundColor3 = state and Theme.Accent or Theme.Stroke}, 0.15)
            tween(dot, {Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}, 0.15)
            if o.Callback then o.Callback(state) end
        end)
        return holder
    end

    function target:AddSlider(o)
        o = o or {}
        local min, max = o.Min or 0, o.Max or 100
        local value = o.Default or min

        local holder = create("Frame", {Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = Theme.PanelLight, Parent = container}, {corner(6), stroke()})
        local label = create("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 6), Size = UDim2.new(1, -24, 0, 16),
            Font = FONT, Text = string.format("%s: %s", o.Text or "Slider", tostring(value)), TextColor3 = Theme.TextPrimary,
            TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = holder,
        })
        local track = create("Frame", {Position = UDim2.new(0, 12, 0, 30), Size = UDim2.new(1, -24, 0, 6), BackgroundColor3 = Theme.Stroke, Parent = holder}, {corner(3)})
        local fill = create("Frame", {Size = UDim2.new((value - min) / (max - min), 0, 1, 0), BackgroundColor3 = Theme.Accent, Parent = track}, {corner(3)})

        local dragging = false
        local function update(inputPos)
            local rel = math.clamp((inputPos - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            value = math.floor(min + (max - min) * rel)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            label.Text = string.format("%s: %s", o.Text or "Slider", tostring(value))
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
        return holder
    end

    function target:AddDropdown(o)
        o = o or {}
        local options = o.Options or {}
        local open = false

        local holder = create("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.PanelLight, ClipsDescendants = true, Parent = container}, {corner(6), stroke()})

        local btn = create("TextButton", {
            Size = UDim2.new(1, -30, 0, 34), BackgroundTransparency = 1, Font = FONT, Text = "  " .. (o.Text or "Selecciona"),
            TextColor3 = Theme.TextPrimary, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = holder,
        })
        local chevron = buildChevron(holder, 8)
        chevron.Position = UDim2.new(1, -22, 0.5, -4)

        local list = create("Frame", {Position = UDim2.new(0, 0, 0, 34), Size = UDim2.new(1, 0, 0, #options * 26), BackgroundTransparency = 1, Parent = holder})
        create("UIListLayout", {Parent = list})

        for _, opt in ipairs(options) do
            local optBtn = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = Theme.Panel, AutoButtonColor = false, Font = FONT,
                Text = "  " .. tostring(opt), TextColor3 = Theme.TextSecondary, TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = list,
            })
            optBtn.MouseEnter:Connect(function() tween(optBtn, {TextColor3 = Theme.TextPrimary}, 0.1) end)
            optBtn.MouseLeave:Connect(function() tween(optBtn, {TextColor3 = Theme.TextSecondary}, 0.1) end)
            optBtn.MouseButton1Click:Connect(function()
                btn.Text = "  " .. tostring(opt)
                open = false
                tween(holder, {Size = UDim2.new(1, 0, 0, 34)}, 0.15)
                if o.Callback then o.Callback(opt) end
            end)
        end

        btn.MouseButton1Click:Connect(function()
            open = not open
            tween(holder, {Size = open and UDim2.new(1, 0, 0, 34 + #options * 26) or UDim2.new(1, 0, 0, 34)}, 0.15)
            tween(chevron, {Rotation = open and 180 or 0}, 0.15)
        end)
        return holder
    end

    function target:AddInput(o)
        o = o or {}
        local holder = create("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.PanelLight, Parent = container}, {corner(6), stroke()})
        local box = create("TextBox", {
            BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -24, 1, 0), Font = FONT,
            PlaceholderText = o.Placeholder or (o.Text or "Escribe..."), Text = "", TextColor3 = Theme.TextPrimary,
            PlaceholderColor3 = Theme.TextSecondary, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false, Parent = holder,
        })
        box.FocusLost:Connect(function(enterPressed) if o.Callback then o.Callback(box.Text, enterPressed) end end)
        return holder
    end

    function target:AddKeybind(o)
        o = o or {}
        local currentKey = o.Default or Enum.KeyCode.Unknown
        local listening = false

        local holder = create("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.PanelLight, Parent = container}, {corner(6), stroke()})
        create("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -100, 1, 0),
            Font = FONT, Text = o.Text or "Keybind", TextColor3 = Theme.TextPrimary, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = holder,
        })

        local keyBtn = create("TextButton", {
            Position = UDim2.new(1, -84, 0.5, -12), Size = UDim2.new(0, 74, 0, 24), BackgroundColor3 = Theme.Panel,
            Font = FONT_BOLD, Text = currentKey.Name, TextColor3 = Theme.Accent, TextSize = 12, Parent = holder,
        }, {corner(6), stroke()})

        keyBtn.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            keyBtn.Text = "..."
            keyBtn.TextColor3 = Theme.Warning
        end)

        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not listening then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                currentKey = input.KeyCode
                keyBtn.Text = currentKey.Name
                keyBtn.TextColor3 = Theme.Accent
                listening = false
                if o.Callback then o.Callback(currentKey) end
            end
        end)

        holder.AncestryChanged:Connect(function(_, parent)
            if not parent and conn then conn:Disconnect() end
        end)

        return holder
    end

    function target:AddColorPicker(o)
        o = o or {}
        local color = o.Default or Theme.Accent

        local holder = create("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.PanelLight, Parent = container}, {corner(6), stroke()})
        create("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -60, 1, 0),
            Font = FONT, Text = o.Text or "Color", TextColor3 = Theme.TextPrimary, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = holder,
        })

        local swatch = create("TextButton", {
            Position = UDim2.new(1, -46, 0.5, -10), Size = UDim2.new(0, 34, 0, 20), BackgroundColor3 = color,
            AutoButtonColor = false, Text = "", Parent = holder,
        }, {corner(5), stroke()})

        -- Panel simple de R/G/B mediante sliders emergentes
        local panel = create("Frame", {
            Visible = false, Position = UDim2.new(0, 0, 1, 4), Size = UDim2.new(1, 0, 0, 110),
            BackgroundColor3 = Theme.Panel, ZIndex = 5, Parent = holder,
        }, {corner(6), stroke(), padding(8)})
        create("UIListLayout", {Padding = UDim.new(0, 6), Parent = panel})

        local channels = {}
        local function updateColor()
            color = Color3.fromRGB(channels.R or 0, channels.G or 0, channels.B or 0)
            swatch.BackgroundColor3 = color
            if o.Callback then o.Callback(color) end
        end

        for _, ch in ipairs({"R", "G", "B"}) do
            local row = create("Frame", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Parent = panel})
            create("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(0, 16, 1, 0), Font = FONT_BOLD, Text = ch, TextColor3 = Theme.TextSecondary, TextSize = 12, Parent = row})
            local track = create("Frame", {Position = UDim2.new(0, 20, 0.5, -3), Size = UDim2.new(1, -24, 0, 6), BackgroundColor3 = Theme.Stroke, Parent = row}, {corner(3)})
            local startVal = math.floor(color[ch == "R" and "R" or (ch == "G" and "G" or "B")] * 255)
            channels[ch] = startVal
            local fill = create("Frame", {Size = UDim2.new(startVal / 255, 0, 1, 0), BackgroundColor3 = Theme.Accent, Parent = track}, {corner(3)})

            local dragging = false
            local function update(inputPos)
                local rel = math.clamp((inputPos - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                channels[ch] = math.floor(rel * 255)
                fill.Size = UDim2.new(rel, 0, 1, 0)
                updateColor()
            end
            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; update(input.Position.X) end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then update(input.Position.X) end
            end)
        end

        swatch.MouseButton1Click:Connect(function()
            panel.Visible = not panel.Visible
        end)

        return holder
    end

    function target:AddLabel(text)
        return create("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Font = FONT, Text = text or "",
            TextColor3 = Theme.TextSecondary, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = container,
        })
    end
end

----------------------------------------------------------------
-- VENTANA PRINCIPAL
----------------------------------------------------------------
function NovaUI:CreateWindow(opts)
    opts = opts or {}
    local size = opts.Size or UDim2.fromOffset(700, 460)

    local Window = {}
    Window.Tabs = {}

    local Main = create("Frame", {
        Name = "Window", Size = size, Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        BackgroundColor3 = Theme.Background, BorderSizePixel = 0, ClipsDescendants = true, Parent = ScreenGui,
    }, {corner(10), stroke()})

    local TopBar = create("Frame", {Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Parent = Main}, {corner(10)})
    create("Frame", {Position = UDim2.new(0, 0, 1, -10), Size = UDim2.new(1, 0, 0, 10), BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Parent = TopBar})

    if opts.Icon then
        create("ImageLabel", {
            BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0.5, -12), Size = UDim2.fromOffset(24, 24),
            Image = opts.Icon, Parent = TopBar,
        })
    end
    local titleOffset = opts.Icon and 46 or 16

    create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, titleOffset, 0, 4), Size = UDim2.new(0.6, 0, 0, 18),
        Font = FONT_BOLD, Text = opts.Title or "NovaUI", TextColor3 = Theme.TextPrimary, TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar,
    })
    create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, titleOffset, 0, 22), Size = UDim2.new(0.6, 0, 0, 16),
        Font = FONT, Text = opts.SubTitle or "", TextColor3 = Theme.TextSecondary, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar,
    })

    local CloseBtn = create("TextButton", {
        Position = UDim2.new(1, -38, 0, 10), Size = UDim2.new(0, 24, 0, 24), BackgroundColor3 = Theme.PanelLight,
        Text = "X", Font = FONT_BOLD, TextColor3 = Theme.TextSecondary, TextSize = 13, Parent = TopBar,
    }, {corner(6)})
    CloseBtn.MouseEnter:Connect(function() tween(CloseBtn, {BackgroundColor3 = Theme.Error}, 0.15) end)
    CloseBtn.MouseLeave:Connect(function() tween(CloseBtn, {BackgroundColor3 = Theme.PanelLight}, 0.15) end)
    CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

    local MinBtn = create("TextButton", {
        Position = UDim2.new(1, -68, 0, 10), Size = UDim2.new(0, 24, 0, 24), BackgroundColor3 = Theme.PanelLight,
        Text = "-", Font = FONT_BOLD, TextColor3 = Theme.TextSecondary, TextSize = 16, Parent = TopBar,
    }, {corner(6)})
    MinBtn.MouseEnter:Connect(function() tween(MinBtn, {BackgroundColor3 = Theme.Accent}, 0.15) end)
    MinBtn.MouseLeave:Connect(function() tween(MinBtn, {BackgroundColor3 = Theme.PanelLight}, 0.15) end)

    makeDraggable(TopBar, Main)

    -- Sidebar de pestañas
    local TabBar = create("Frame", {
        Position = UDim2.new(0, 0, 0, 44), Size = UDim2.new(0, 150, 1, -44), BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0, Parent = Main,
    })
    create("Frame", {Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = TabBar})
    create("UIListLayout", {Padding = UDim.new(0, 4), Parent = TabBar})
    create("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = TabBar})

    local ContentArea = create("Frame", {
        Position = UDim2.new(0, 150, 0, 44), Size = UDim2.new(1, -150, 1, -44), BackgroundTransparency = 1, Parent = Main,
    })

    local collapsed = false
    MinBtn.MouseButton1Click:Connect(function()
        collapsed = not collapsed
        TabBar.Visible = not collapsed
        ContentArea.Visible = not collapsed
        tween(Main, {Size = collapsed and UDim2.new(0, size.X.Offset, 0, 44) or size}, 0.2)
    end)

    ----------------------------------------------------------------
    -- TAB
    ----------------------------------------------------------------
    function Window:AddTab(name, icon)
        local Tab = {}

        local TabBtn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.PanelLight, AutoButtonColor = false,
            Text = "", Parent = TabBar,
        }, {corner(7)})

        local accentBar = create("Frame", {
            Size = UDim2.new(0, 3, 0, 18), Position = UDim2.new(0, 0, 0.5, -9),
            BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1, Parent = TabBtn,
        }, {corner(2)})

        local textStart = 14
        if icon then
            create("ImageLabel", {
                BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0.5, -8), Size = UDim2.fromOffset(16, 16),
                Image = icon, ImageColor3 = Theme.TextSecondary, Name = "Icon", Parent = TabBtn,
            })
            textStart = 34
        end

        local TabLabel = create("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.new(0, textStart, 0, 0), Size = UDim2.new(1, -textStart - 8, 1, 0),
            Font = FONT, Text = name, TextColor3 = Theme.TextSecondary, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = TabBtn,
        })

        local Page = create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent, CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, Parent = ContentArea,
        })
        create("UIListLayout", {Padding = UDim.new(0, 10), Parent = Page})
        create("UIPadding", {PaddingTop = UDim.new(0, 14), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14), Parent = Page})

        local function selectTab()
            for _, t in ipairs(Window.Tabs) do
                t.Page.Visible = false
                tween(t.Btn, {BackgroundColor3 = Theme.PanelLight}, 0.15)
                tween(t.Label, {TextColor3 = Theme.TextSecondary}, 0.15)
                tween(t.Accent, {BackgroundTransparency = 1}, 0.15)
                if t.Icon then tween(t.Icon, {ImageColor3 = Theme.TextSecondary}, 0.15) end
            end
            Page.Visible = true
            tween(TabBtn, {BackgroundColor3 = Theme.PanelLight}, 0.15)
            tween(TabLabel, {TextColor3 = Theme.TextPrimary}, 0.15)
            tween(accentBar, {BackgroundTransparency = 0}, 0.15)
            local iconInst = TabBtn:FindFirstChild("Icon")
            if iconInst then tween(iconInst, {ImageColor3 = Theme.Accent}, 0.15) end
        end

        TabBtn.MouseEnter:Connect(function() if not Page.Visible then tween(TabBtn, {BackgroundColor3 = Theme.Section}, 0.15) end end)
        TabBtn.MouseLeave:Connect(function() if not Page.Visible then tween(TabBtn, {BackgroundColor3 = Theme.PanelLight}, 0.15) end end)
        TabBtn.MouseButton1Click:Connect(selectTab)

        table.insert(Window.Tabs, {Btn = TabBtn, Page = Page, Label = TabLabel, Accent = accentBar, Icon = TabBtn:FindFirstChild("Icon")})
        if #Window.Tabs == 1 then selectTab() end

        -- Elementos directos sobre la página (sin sección)
        attachElementBuilders(Tab, Page)

        -- Sección agrupada (estilo "caja con título" inspirado en la referencia)
        function Tab:AddSection(title)
            local Section = {}

            local box = create("Frame", {
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Theme.Section, Parent = Page,
            }, {corner(8), stroke()})

            create("TextLabel", {
                BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -24, 0, 16),
                Font = FONT_BOLD, Text = title or "Sección", TextColor3 = Theme.TextPrimary, TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = box,
            })
            create("Frame", {
                Position = UDim2.new(0, 12, 0, 28), Size = UDim2.new(1, -24, 0, 1), BackgroundColor3 = Theme.Stroke,
                BorderSizePixel = 0, Parent = box,
            })

            local body = create("Frame", {
                Position = UDim2.new(0, 0, 0, 34), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1, Parent = box,
            })
            create("UIListLayout", {Padding = UDim.new(0, 6), Parent = body})
            create("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), Parent = body})

            attachElementBuilders(Section, body)
            Section.Instance = box
            return Section
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

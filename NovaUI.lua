--[[
    NovaUI - Librería de interfaz para Roblox
    Estilo inspirado en menús tipo "executor" (barra de stats superior,
    ventana con pestañas, panel de notificaciones y logger flotante).

    USO (loadstring):
        local NovaUI = loadstring(game:HttpGet("https://tu-host.com/NovaUI.lua"))()

        local Window = NovaUI:CreateWindow({
            Title = "Tokyo",
            SubTitle = "Da Hood",
            Size = UDim2.fromOffset(720, 480),
        })

        local Tab = Window:AddTab("Combat")
        Tab:AddButton({Text = "Kill Aura", Callback = function() end})
        Tab:AddToggle({Text = "Auto Kill", Default = false, Callback = function(state) end})
        Tab:AddSlider({Text = "Reach", Min = 0, Max = 50, Default = 10, Callback = function(v) end})
        Tab:AddDropdown({Text = "Target", Options = {"Closest","Random"}, Callback = function(v) end})
        Tab:AddInput({Text = "Nombre", Placeholder = "escribe...", Callback = function(v) end})

        NovaUI:Notify({Title = "Info", Content = "Bienvenido", Type = "Info", Duration = 4})
        NovaUI:Log("Script cargado correctamente", "Success")

    Esta librería SOLO construye interfaz (ventanas, controles, notificaciones,
    logger y barra de stats). No incluye lógica de juego (auto-kill, teleport,
    ESP, etc.) — los callbacks quedan vacíos para que el usuario conecte su
    propio código.
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
-- PALETA DE COLORES (estilo propio, oscuro con acento morado/azul)
----------------------------------------------------------------
local Theme = {
    Background      = Color3.fromRGB(18, 19, 24),
    Panel           = Color3.fromRGB(24, 26, 33),
    PanelLight      = Color3.fromRGB(30, 32, 40),
    Stroke          = Color3.fromRGB(45, 47, 58),
    TextPrimary     = Color3.fromRGB(235, 235, 240),
    TextSecondary   = Color3.fromRGB(150, 152, 165),
    Accent          = Color3.fromRGB(124, 92, 255),
    AccentDark      = Color3.fromRGB(94, 66, 214),
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

local function corner(radius)
    return create("UICorner", {CornerRadius = UDim.new(0, radius or 6)})
end

local function stroke(color, thickness)
    return create("UIStroke", {
        Color = color or Theme.Stroke,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function padding(all)
    return create("UIPadding", {
        PaddingTop = UDim.new(0, all),
        PaddingBottom = UDim.new(0, all),
        PaddingLeft = UDim.new(0, all),
        PaddingRight = UDim.new(0, all),
    })
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
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    topBar.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

----------------------------------------------------------------
-- CONTENEDOR RAÍZ (ScreenGui)
----------------------------------------------------------------
local ScreenGui = create("ScreenGui", {
    Name = "NovaUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
})

pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

----------------------------------------------------------------
-- BARRA SUPERIOR DE STATS (Juego | Privacidad | Modo | fps | ms | ping | fecha)
----------------------------------------------------------------
local function buildStatsBar()
    local bar = create("Frame", {
        Name = "StatsBar",
        Size = UDim2.new(0, 560, 0, 26),
        Position = UDim2.new(0, 8, 0, 8),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Parent = ScreenGui,
    }, {corner(6), stroke()})

    local layout = create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 10),
        Parent = bar,
    })
    create("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = bar})

    local function statLabel(text)
        return create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Font = FONT,
            Text = text,
            TextColor3 = Theme.TextSecondary,
            TextSize = 13,
            Parent = bar,
        })
    end

    local gameLabel = statLabel(game.Name)
    gameLabel.TextColor3 = Theme.TextPrimary
    gameLabel.Font = FONT_BOLD
    statLabel("|")
    local privacyLabel = statLabel("Private")
    statLabel("|")
    local fpsLabel = statLabel("-- fps")
    statLabel("|")
    local pingLabel = statLabel("-- ms")
    statLabel("|")
    local timeLabel = statLabel(os.date("%H:%M:%S"))
    statLabel("|")
    local dateLabel = statLabel(os.date("%b, %d, %Y"))

    -- FPS
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

    -- Ping / clock
    task.spawn(function()
        while bar.Parent do
            local ok, ping = pcall(function()
                return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            end)
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
-- SISTEMA DE NOTIFICACIONES
----------------------------------------------------------------
local NotifyHolder = create("Frame", {
    Name = "Notifications",
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 300, 1, -20),
    Position = UDim2.new(1, -310, 0, 10),
    Parent = ScreenGui,
})
create("UIListLayout", {
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Top,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = NotifyHolder,
})

local TYPE_COLORS = {
    Info = Theme.Info,
    Success = Theme.Success,
    Warning = Theme.Warning,
    Error = Theme.Error,
}

function NovaUI:Notify(opts)
    opts = opts or {}
    local nType = opts.Type or "Info"
    local color = TYPE_COLORS[nType] or Theme.Accent
    local duration = opts.Duration or 4

    local card = create("Frame", {
        BackgroundColor3 = Theme.Panel,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(1, 40, 0, 0),
        BorderSizePixel = 0,
        Parent = NotifyHolder,
    }, {corner(8), stroke(), padding(10)})

    create("Frame", {
        BackgroundColor3 = color,
        Size = UDim2.new(0, 4, 1, 0),
        BorderSizePixel = 0,
        Parent = card,
    }, {corner(2)})

    local titleLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -12, 0, 18),
        Font = FONT_BOLD,
        Text = opts.Title or "Notificación",
        TextColor3 = Theme.TextPrimary,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    local contentLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 20),
        Size = UDim2.new(1, -12, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = FONT,
        Text = opts.Content or "",
        TextColor3 = Theme.TextSecondary,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    card.Size = UDim2.new(1, 0, 0, 44 + (contentLabel.TextBounds and 0 or 0))

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
-- LOGGER FLOTANTE
----------------------------------------------------------------
local LogFrame = create("Frame", {
    Name = "Logger",
    Size = UDim2.new(0, 320, 0, 140),
    Position = UDim2.new(0, 8, 1, -150),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel = 0,
    Visible = true,
    Parent = ScreenGui,
}, {corner(8), stroke()})

local LogTop = create("Frame", {
    Size = UDim2.new(1, 0, 0, 26),
    BackgroundColor3 = Theme.PanelLight,
    BorderSizePixel = 0,
    Parent = LogFrame,
}, {corner(8)})

create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 10, 0, 0),
    Size = UDim2.new(1, -40, 1, 0),
    Font = FONT_BOLD,
    Text = "Logger",
    TextColor3 = Theme.TextPrimary,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = LogTop,
})

local LogToggleBtn = create("TextButton", {
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -26, 0, 0),
    Size = UDim2.new(0, 26, 1, 0),
    Font = FONT_BOLD,
    Text = "-",
    TextColor3 = Theme.TextSecondary,
    TextSize = 16,
    Parent = LogTop,
})

local LogScroll = create("ScrollingFrame", {
    Position = UDim2.new(0, 0, 0, 26),
    Size = UDim2.new(1, 0, 1, -26),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Theme.Accent,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Parent = LogFrame,
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

local LOG_COLORS = {
    Info = Theme.TextSecondary,
    Success = Theme.Success,
    Warning = Theme.Warning,
    Error = Theme.Error,
}

function NovaUI:Log(message, logType)
    logType = logType or "Info"
    local color = LOG_COLORS[logType] or Theme.TextSecondary
    local timestamp = os.date("%H:%M:%S")

    local entry = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = FONT,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        RichText = true,
        Text = string.format(
            '<font color="rgb(120,122,135)">[%s]</font> <font color="rgb(%d,%d,%d)">%s</font>',
            timestamp, color.R * 255, color.G * 255, color.B * 255, message
        ),
        Parent = LogScroll,
    })

    task.wait()
    LogScroll.CanvasPosition = Vector2.new(0, LogLayout.AbsoluteContentSize.Y)

    return entry
end

----------------------------------------------------------------
-- VENTANA PRINCIPAL
----------------------------------------------------------------
function NovaUI:CreateWindow(opts)
    opts = opts or {}
    local size = opts.Size or UDim2.fromOffset(680, 460)

    local Window = {}
    Window.Tabs = {}

    local Main = create("Frame", {
        Name = "Window",
        Size = size,
        Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = ScreenGui,
    }, {corner(10), stroke()})

    local TopBar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Parent = Main,
    }, {corner(10)})
    -- cuadra la esquina inferior del topbar (evita redondeo doble)
    create("Frame", {
        Position = UDim2.new(0, 0, 1, -10),
        Size = UDim2.new(1, 0, 0, 10),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Parent = TopBar,
    })

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 0),
        Size = UDim2.new(0.6, 0, 1, 0),
        Font = FONT_BOLD,
        Text = opts.Title or "NovaUI",
        TextColor3 = Theme.TextPrimary,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar,
    })

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 20),
        Size = UDim2.new(0.6, 0, 0, 16),
        Font = FONT,
        Text = opts.SubTitle or "",
        TextColor3 = Theme.TextSecondary,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar,
    })

    local CloseBtn = create("TextButton", {
        Position = UDim2.new(1, -36, 0, 8),
        Size = UDim2.new(0, 24, 0, 24),
        BackgroundColor3 = Theme.PanelLight,
        Text = "X",
        Font = FONT_BOLD,
        TextColor3 = Theme.TextSecondary,
        TextSize = 13,
        Parent = TopBar,
    }, {corner(6)})
    CloseBtn.MouseButton1Click:Connect(function()
        Main.Visible = false
    end)

    local MinBtn = create("TextButton", {
        Position = UDim2.new(1, -66, 0, 8),
        Size = UDim2.new(0, 24, 0, 24),
        BackgroundColor3 = Theme.PanelLight,
        Text = "-",
        Font = FONT_BOLD,
        TextColor3 = Theme.TextSecondary,
        TextSize = 16,
        Parent = TopBar,
    }, {corner(6)})

    makeDraggable(TopBar, Main)

    -- Barra lateral de pestañas
    local TabBar = create("Frame", {
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(0, 140, 1, -40),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Parent = Main,
    })
    local TabList = create("UIListLayout", {
        Padding = UDim.new(0, 4),
        Parent = TabBar,
    })
    create("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = TabBar})

    -- Área de contenido
    local ContentArea = create("Frame", {
        Position = UDim2.new(0, 140, 0, 40),
        Size = UDim2.new(1, -140, 1, -40),
        BackgroundTransparency = 1,
        Parent = Main,
    })

    local collapsed = false
    MinBtn.MouseButton1Click:Connect(function()
        collapsed = not collapsed
        TabBar.Visible = not collapsed
        ContentArea.Visible = not collapsed
        tween(Main, {Size = collapsed and UDim2.new(0, size.X.Offset, 0, 40) or size}, 0.2)
    end)

    ----------------------------------------------------------------
    -- TAB
    ----------------------------------------------------------------
    function Window:AddTab(name)
        local Tab = {}

        local TabBtn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Theme.PanelLight,
            AutoButtonColor = false,
            Font = FONT,
            Text = name,
            TextColor3 = Theme.TextSecondary,
            TextSize = 13,
            Parent = TabBar,
        }, {corner(6)})

        local Page = create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            Parent = ContentArea,
        })
        create("UIListLayout", {Padding = UDim.new(0, 8), Parent = Page})
        create("UIPadding", {
            PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12),
            Parent = Page,
        })

        local function selectTab()
            for _, t in ipairs(Window.Tabs) do
                t.Page.Visible = false
                t.Btn.BackgroundColor3 = Theme.PanelLight
                t.Btn.TextColor3 = Theme.TextSecondary
            end
            Page.Visible = true
            TabBtn.BackgroundColor3 = Theme.Accent
            TabBtn.TextColor3 = Theme.TextPrimary
        end

        TabBtn.MouseButton1Click:Connect(selectTab)
        table.insert(Window.Tabs, {Btn = TabBtn, Page = Page})
        if #Window.Tabs == 1 then
            selectTab()
        end

        ----------------------------------------------------------------
        -- ELEMENTOS
        ----------------------------------------------------------------
        function Tab:AddButton(o)
            o = o or {}
            local btn = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = Theme.PanelLight,
                AutoButtonColor = false,
                Font = FONT,
                Text = o.Text or "Botón",
                TextColor3 = Theme.TextPrimary,
                TextSize = 13,
                Parent = Page,
            }, {corner(6), stroke()})

            btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = Theme.Accent}, 0.15) end)
            btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = Theme.PanelLight}, 0.15) end)
            btn.MouseButton1Click:Connect(function()
                if o.Callback then o.Callback() end
            end)
            return btn
        end

        function Tab:AddToggle(o)
            o = o or {}
            local state = o.Default or false

            local holder = create("Frame", {
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = Theme.PanelLight,
                Parent = Page,
            }, {corner(6), stroke()})

            create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -60, 1, 0),
                Font = FONT,
                Text = o.Text or "Toggle",
                TextColor3 = Theme.TextPrimary,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = holder,
            })

            local switch = create("Frame", {
                Position = UDim2.new(1, -44, 0.5, -9),
                Size = UDim2.new(0, 32, 0, 18),
                BackgroundColor3 = state and Theme.Accent or Theme.Stroke,
                Parent = holder,
            }, {corner(9)})

            local dot = create("Frame", {
                Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
                Size = UDim2.new(0, 14, 0, 14),
                BackgroundColor3 = Theme.TextPrimary,
                Parent = switch,
            }, {corner(7)})

            local clickArea = create("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Text = "",
                Parent = holder,
            })

            clickArea.MouseButton1Click:Connect(function()
                state = not state
                tween(switch, {BackgroundColor3 = state and Theme.Accent or Theme.Stroke}, 0.15)
                tween(dot, {Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}, 0.15)
                if o.Callback then o.Callback(state) end
            end)

            return holder
        end

        function Tab:AddSlider(o)
            o = o or {}
            local min, max = o.Min or 0, o.Max or 100
            local value = o.Default or min

            local holder = create("Frame", {
                Size = UDim2.new(1, 0, 0, 46),
                BackgroundColor3 = Theme.PanelLight,
                Parent = Page,
            }, {corner(6), stroke()})

            local label = create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 6),
                Size = UDim2.new(1, -24, 0, 16),
                Font = FONT,
                Text = string.format("%s: %s", o.Text or "Slider", tostring(value)),
                TextColor3 = Theme.TextPrimary,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = holder,
            })

            local track = create("Frame", {
                Position = UDim2.new(0, 12, 0, 30),
                Size = UDim2.new(1, -24, 0, 6),
                BackgroundColor3 = Theme.Stroke,
                Parent = holder,
            }, {corner(3)})

            local fill = create("Frame", {
                Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = Theme.Accent,
                Parent = track,
            }, {corner(3)})

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
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    update(input.Position.X)
                end
            end)

            return holder
        end

        function Tab:AddDropdown(o)
            o = o or {}
            local options = o.Options or {}
            local open = false

            local holder = create("Frame", {
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = Theme.PanelLight,
                ClipsDescendants = true,
                Parent = Page,
            }, {corner(6), stroke()})

            local btn = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundTransparency = 1,
                Font = FONT,
                Text = "  " .. (o.Text or "Selecciona") .. " ▾",
                TextColor3 = Theme.TextPrimary,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = holder,
            })

            local list = create("Frame", {
                Position = UDim2.new(0, 0, 0, 34),
                Size = UDim2.new(1, 0, 0, #options * 26),
                BackgroundTransparency = 1,
                Parent = holder,
            })
            create("UIListLayout", {Parent = list})

            for _, opt in ipairs(options) do
                local optBtn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 26),
                    BackgroundColor3 = Theme.Panel,
                    AutoButtonColor = false,
                    Font = FONT,
                    Text = "  " .. tostring(opt),
                    TextColor3 = Theme.TextSecondary,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = list,
                })
                optBtn.MouseButton1Click:Connect(function()
                    btn.Text = "  " .. tostring(opt) .. " ▾"
                    open = false
                    tween(holder, {Size = UDim2.new(1, 0, 0, 34)}, 0.15)
                    if o.Callback then o.Callback(opt) end
                end)
            end

            btn.MouseButton1Click:Connect(function()
                open = not open
                tween(holder, {Size = open and UDim2.new(1, 0, 0, 34 + #options * 26) or UDim2.new(1, 0, 0, 34)}, 0.15)
            end)

            return holder
        end

        function Tab:AddInput(o)
            o = o or {}
            local holder = create("Frame", {
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = Theme.PanelLight,
                Parent = Page,
            }, {corner(6), stroke()})

            local box = create("TextBox", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -24, 1, 0),
                Font = FONT,
                PlaceholderText = o.Placeholder or (o.Text or "Escribe..."),
                Text = "",
                TextColor3 = Theme.TextPrimary,
                PlaceholderColor3 = Theme.TextSecondary,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                Parent = holder,
            })

            box.FocusLost:Connect(function(enterPressed)
                if o.Callback then o.Callback(box.Text, enterPressed) end
            end)

            return holder
        end

        function Tab:AddLabel(text)
            return create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 20),
                Font = FONT,
                Text = text or "",
                TextColor3 = Theme.TextSecondary,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Page,
            })
        end

        Tab.Instance = Page
        return Tab
    end

    Window.Instance = Main
    return Window
end

----------------------------------------------------------------
-- ACCESO RÁPIDO A ELEMENTOS GLOBALES
----------------------------------------------------------------
NovaUI.ScreenGui = ScreenGui
NovaUI.StatsBar = StatsBar
NovaUI.LogFrame = LogFrame
NovaUI.Theme = Theme

NovaUI:Log("NovaUI cargada correctamente", "Success")

return NovaUI

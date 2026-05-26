--[[
    MatchaLib - A Roblox UI Library
    Style: Dark + Pink/Magenta
    GitHub: your-repo-here

    Usage:
        local MatchaLib = loadstring(game:HttpGet("YOUR_RAW_URL"))()
        local Window = MatchaLib:CreateWindow({ Title = "My Script" })
        local Tab = Window:CreateTab("Aiming")
        Tab:AddToggle({ Name = "Enabled", Default = false, Callback = function(v) end })
        MatchaLib:Init()
]]

local MatchaLib = {}
MatchaLib.__index = MatchaLib
MatchaLib.Flags = {}

-- Services
local Players         = game:GetService("Players")
local TweenService    = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService      = game:GetService("RunService")
local CoreGui         = game:GetService("CoreGui")

local LP = Players.LocalPlayer

-- ============================================================
-- THEME
-- ============================================================
local Theme = {
    Background     = Color3.fromRGB(18, 18, 22),
    BackgroundAlt  = Color3.fromRGB(24, 24, 30),
    Surface        = Color3.fromRGB(30, 30, 38),
    SurfaceAlt     = Color3.fromRGB(38, 38, 48),
    Border         = Color3.fromRGB(50, 50, 65),
    Accent         = Color3.fromRGB(255, 105, 180),   -- Hot pink
    AccentDark     = Color3.fromRGB(180, 60, 130),
    AccentGlow     = Color3.fromRGB(255, 150, 210),
    TextPrimary    = Color3.fromRGB(240, 240, 245),
    TextSecondary  = Color3.fromRGB(160, 160, 175),
    TextMuted      = Color3.fromRGB(100, 100, 115),
    Success        = Color3.fromRGB(100, 220, 140),
    Danger         = Color3.fromRGB(220, 80, 80),
    SliderFill     = Color3.fromRGB(255, 105, 180),
    ToggleOn       = Color3.fromRGB(255, 105, 180),
    ToggleOff      = Color3.fromRGB(55, 55, 70),
    TabActive      = Color3.fromRGB(255, 105, 180),
    TabInactive    = Color3.fromRGB(38, 38, 48),
    ScrollBar      = Color3.fromRGB(255, 105, 180),
}

-- ============================================================
-- UTILITIES
-- ============================================================
local function tween(obj, props, duration, style, direction)
    style = style or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    return TweenService:Create(obj, TweenInfo.new(duration or 0.2, style, direction), props):Play()
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Border
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

local function newFrame(props)
    local f = Instance.new("Frame")
    for k, v in pairs(props or {}) do f[k] = v end
    return f
end

local function newLabel(props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 13
    l.TextColor3 = Theme.TextPrimary
    l.TextXAlignment = Enum.TextXAlignment.Left
    for k, v in pairs(props or {}) do l[k] = v end
    return l
end

local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = i.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================
local NotifGui = Instance.new("ScreenGui")
NotifGui.Name = "MatchaNotifs"
NotifGui.ResetOnSpawn = false
NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() NotifGui.Parent = CoreGui end)
if not NotifGui.Parent then NotifGui.Parent = LP.PlayerGui end

local NotifHolder = Instance.new("Frame")
NotifHolder.Size = UDim2.new(0, 280, 1, 0)
NotifHolder.Position = UDim2.new(1, -290, 0, 0)
NotifHolder.BackgroundTransparency = 1
NotifHolder.Parent = NotifGui

local NotifLayout = Instance.new("UIListLayout")
NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifLayout.Padding = UDim.new(0, 8)
NotifLayout.Parent = NotifHolder

Instance.new("UIPadding", NotifHolder).PaddingBottom = UDim.new(0, 16)

function MatchaLib:Notify(opts)
    opts = opts or {}
    local title   = opts.Title or "MatchaLib"
    local content = opts.Content or ""
    local duration = opts.Duration or 4
    local ntype   = opts.Type or "info" -- "info", "success", "error"

    local accentColor = Theme.Accent
    if ntype == "success" then accentColor = Theme.Success
    elseif ntype == "error" then accentColor = Theme.Danger end

    local card = newFrame({
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = Theme.Surface,
        ClipsDescendants = true,
        Parent = NotifHolder,
    })
    corner(card, 8)
    stroke(card, Theme.Border)

    -- Accent bar
    local bar = newFrame({
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = accentColor,
        Parent = card,
    })
    corner(bar, 2)

    local titleLbl = newLabel({
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 14, 0, 10),
        Text = title,
        TextColor3 = Theme.TextPrimary,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        Parent = card,
    })

    local contentLbl = newLabel({
        Size = UDim2.new(1, -20, 0, 18),
        Position = UDim2.new(0, 14, 0, 32),
        Text = content,
        TextColor3 = Theme.TextSecondary,
        TextSize = 12,
        Parent = card,
    })

    -- Progress bar
    local progress = newFrame({
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = accentColor,
        Parent = card,
    })

    -- Slide in
    card.Position = UDim2.new(1, 10, 0, 0)
    tween(card, {Position = UDim2.new(0, 0, 0, 0)}, 0.3)
    tween(progress, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        tween(card, {Position = UDim2.new(1, 10, 0, 0)}, 0.3)
        task.wait(0.35)
        card:Destroy()
    end)
end

-- ============================================================
-- WINDOW
-- ============================================================
function MatchaLib:CreateWindow(opts)
    opts = opts or {}
    local title    = opts.Title or "MatchaLib"
    local subtitle = opts.Subtitle or ""
    local width    = opts.Width or 560
    local height   = opts.Height or 420

    local win = {}
    local tabs = {}
    local activeTab = nil

    -- Root GUI
    local gui = Instance.new("ScreenGui")
    gui.Name = "MatchaLib_" .. title
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then gui.Parent = LP.PlayerGui end

    -- Main frame
    local main = newFrame({
        Size = UDim2.new(0, width, 0, height),
        Position = UDim2.new(0.5, -width/2, 0.5, -height/2),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Parent = gui,
    })
    corner(main, 10)
    stroke(main, Theme.Border, 1)

    -- Drop shadow effect (via ImageLabel)
    local shadow = Instance.new("ImageLabel")
    shadow.Size = UDim2.new(1, 40, 1, 40)
    shadow.Position = UDim2.new(0, -20, 0, -20)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6014261993"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.ZIndex = 0
    shadow.Parent = main

    -- TITLEBAR
    local titleBar = newFrame({
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = Theme.BackgroundAlt,
        Parent = main,
        ZIndex = 2,
    })
    corner(titleBar, 10)

    -- Fix bottom corners of titlebar
    local tbFix = newFrame({
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = Theme.BackgroundAlt,
        ZIndex = 2,
        Parent = titleBar,
    })

    -- Accent dot
    local dot = newFrame({
        Size = UDim2.new(0, 8, 0, 8),
        Position = UDim2.new(0, 14, 0.5, -4),
        BackgroundColor3 = Theme.Accent,
        ZIndex = 3,
        Parent = titleBar,
    })
    corner(dot, 4)

    local titleLbl = newLabel({
        Size = UDim2.new(0.6, 0, 1, 0),
        Position = UDim2.new(0, 30, 0, 0),
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Theme.TextPrimary,
        ZIndex = 3,
        Parent = titleBar,
    })

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -36, 0.5, -14)
    closeBtn.BackgroundColor3 = Theme.SurfaceAlt
    closeBtn.Text = "×"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.TextColor3 = Theme.TextSecondary
    closeBtn.ZIndex = 3
    closeBtn.Parent = titleBar
    corner(closeBtn, 6)

    closeBtn.MouseButton1Click:Connect(function()
        tween(main, {Size = UDim2.new(0, width, 0, 0), Position = UDim2.new(0.5, -width/2, 0.5, 0)}, 0.25)
        task.wait(0.26)
        gui:Destroy()
    end)

    -- Minimize button
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 28, 0, 28)
    minBtn.Position = UDim2.new(1, -70, 0.5, -14)
    minBtn.BackgroundColor3 = Theme.SurfaceAlt
    minBtn.Text = "−"
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 16
    minBtn.TextColor3 = Theme.TextSecondary
    minBtn.ZIndex = 3
    minBtn.Parent = titleBar
    corner(minBtn, 6)

    local minimized = false
    local contentFrame -- defined below

    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            tween(main, {Size = UDim2.new(0, width, 0, 42)}, 0.25)
        else
            tween(main, {Size = UDim2.new(0, width, 0, height)}, 0.25)
        end
    end)

    makeDraggable(main, titleBar)

    -- Animate in
    main.Size = UDim2.new(0, width, 0, 0)
    main.Position = UDim2.new(0.5, -width/2, 0.5, 0)
    tween(main, {
        Size = UDim2.new(0, width, 0, height),
        Position = UDim2.new(0.5, -width/2, 0.5, -height/2)
    }, 0.35, Enum.EasingStyle.Back)

    -- TAB BAR (left sidebar)
    local sidebar = newFrame({
        Size = UDim2.new(0, 130, 1, -42),
        Position = UDim2.new(0, 0, 0, 42),
        BackgroundColor3 = Theme.BackgroundAlt,
        Parent = main,
    })

    -- Fix top corner of sidebar
    newFrame({
        Size = UDim2.new(1, 0, 0, 8),
        BackgroundColor3 = Theme.BackgroundAlt,
        Parent = sidebar,
    })

    corner(sidebar, 10)

    -- Fix right corners of sidebar
    newFrame({
        Size = UDim2.new(0, 10, 1, 0),
        Position = UDim2.new(1, -10, 0, 0),
        BackgroundColor3 = Theme.BackgroundAlt,
        Parent = sidebar,
    })

    local tabList = Instance.new("UIListLayout")
    tabList.SortOrder = Enum.SortOrder.LayoutOrder
    tabList.Padding = UDim.new(0, 4)
    tabList.Parent = sidebar

    Instance.new("UIPadding", sidebar).PaddingTop = UDim.new(0, 10)
    local sidepadL = Instance.new("UIPadding", sidebar)
    sidepadL.PaddingLeft = UDim.new(0, 8)
    sidepadL.PaddingRight = UDim.new(0, 8)
    sidepadL.PaddingTop = UDim.new(0, 10)

    -- CONTENT AREA
    contentFrame = newFrame({
        Size = UDim2.new(1, -130, 1, -42),
        Position = UDim2.new(0, 130, 0, 42),
        BackgroundColor3 = Theme.Background,
        ClipsDescendants = true,
        Parent = main,
    })

    -- Tab separator line
    local sep = newFrame({
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = Theme.Border,
        Parent = main,
    })
    sep.Position = UDim2.new(0, 130, 0, 42)

    -- ============================================================
    -- CREATE TAB
    -- ============================================================
    function win:CreateTab(name, icon)
        local tab = {}
        local elements = {}
        local yOffset = 0

        -- Tab button in sidebar
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, 0, 0, 32)
        tabBtn.BackgroundColor3 = Theme.TabInactive
        tabBtn.Text = name
        tabBtn.Font = Enum.Font.GothamMedium
        tabBtn.TextSize = 12
        tabBtn.TextColor3 = Theme.TextSecondary
        tabBtn.AutoButtonColor = false
        tabBtn.ZIndex = 3
        tabBtn.Parent = sidebar
        corner(tabBtn, 6)

        -- Scroll frame for content
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Size = UDim2.new(1, 0, 1, 0)
        scrollFrame.BackgroundTransparency = 1
        scrollFrame.BorderSizePixel = 0
        scrollFrame.ScrollBarThickness = 3
        scrollFrame.ScrollBarImageColor3 = Theme.ScrollBar
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        scrollFrame.Visible = false
        scrollFrame.Parent = contentFrame

        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 6)
        listLayout.Parent = scrollFrame

        local scrollPad = Instance.new("UIPadding")
        scrollPad.PaddingTop = UDim.new(0, 10)
        scrollPad.PaddingLeft = UDim.new(0, 10)
        scrollPad.PaddingRight = UDim.new(0, 14)
        scrollPad.PaddingBottom = UDim.new(0, 10)
        scrollPad.Parent = scrollFrame

        listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
        end)

        local function setActive(active)
            tween(tabBtn, {
                BackgroundColor3 = active and Theme.TabActive or Theme.TabInactive,
                TextColor3 = active and Theme.Background or Theme.TextSecondary,
            }, 0.15)
            scrollFrame.Visible = active
        end

        tabBtn.MouseButton1Click:Connect(function()
            if activeTab then activeTab.setActive(false) end
            activeTab = { setActive = setActive }
            setActive(true)
        end)

        if #tabs == 0 then
            activeTab = { setActive = setActive }
            setActive(true)
        end
        table.insert(tabs, { btn = tabBtn, scroll = scrollFrame, setActive = setActive })

        -- ============================================================
        -- SECTION
        -- ============================================================
        function tab:AddSection(name)
            local sectionLabel = newLabel({
                Size = UDim2.new(1, 0, 0, 22),
                Text = name:upper(),
                TextColor3 = Theme.Accent,
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = scrollFrame,
            })
            Instance.new("UIPadding", sectionLabel).PaddingTop = UDim.new(0, 6)
        end

        -- ============================================================
        -- LABEL
        -- ============================================================
        function tab:AddLabel(text)
            local lbl = newLabel({
                Size = UDim2.new(1, 0, 0, 20),
                Text = text,
                TextColor3 = Theme.TextMuted,
                TextSize = 11,
                Parent = scrollFrame,
            })
            return {
                Set = function(_, t) lbl.Text = t end
            }
        end

        -- ============================================================
        -- BUTTON
        -- ============================================================
        function tab:AddButton(opts)
            opts = opts or {}
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 34)
            btn.BackgroundColor3 = Theme.Surface
            btn.Text = ""
            btn.AutoButtonColor = false
            btn.Parent = scrollFrame
            corner(btn, 6)
            stroke(btn, Theme.Border)

            local lbl = newLabel({
                Size = UDim2.new(1, -16, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                Text = opts.Name or "Button",
                TextColor3 = Theme.TextPrimary,
                TextSize = 13,
                Parent = btn,
            })

            -- Arrow indicator
            newLabel({
                Size = UDim2.new(0, 20, 1, 0),
                Position = UDim2.new(1, -24, 0, 0),
                Text = "›",
                TextColor3 = Theme.Accent,
                TextSize = 18,
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = btn,
            })

            btn.MouseEnter:Connect(function()
                tween(btn, {BackgroundColor3 = Theme.SurfaceAlt}, 0.1)
            end)
            btn.MouseLeave:Connect(function()
                tween(btn, {BackgroundColor3 = Theme.Surface}, 0.1)
            end)
            btn.MouseButton1Click:Connect(function()
                tween(btn, {BackgroundColor3 = Theme.Accent}, 0.07)
                task.wait(0.07)
                tween(btn, {BackgroundColor3 = Theme.Surface}, 0.15)
                if opts.Callback then opts.Callback() end
            end)
        end

        -- ============================================================
        -- TOGGLE
        -- ============================================================
        function tab:AddToggle(opts)
            opts = opts or {}
            local value = opts.Default or false
            local flag = opts.Flag

            local row = newFrame({
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = Theme.Surface,
                Parent = scrollFrame,
            })
            corner(row, 6)
            stroke(row, Theme.Border)

            newLabel({
                Size = UDim2.new(1, -60, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                Text = opts.Name or "Toggle",
                TextColor3 = Theme.TextPrimary,
                Parent = row,
            })

            -- Track
            local track = newFrame({
                Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(1, -52, 0.5, -10),
                BackgroundColor3 = value and Theme.ToggleOn or Theme.ToggleOff,
                Parent = row,
            })
            corner(track, 10)

            -- Knob
            local knob = newFrame({
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(0, value and 22 or 3, 0.5, -7),
                BackgroundColor3 = Color3.new(1,1,1),
                ZIndex = 2,
                Parent = track,
            })
            corner(knob, 7)

            local togBtn = Instance.new("TextButton")
            togBtn.Size = UDim2.new(1, 0, 1, 0)
            togBtn.BackgroundTransparency = 1
            togBtn.Text = ""
            togBtn.ZIndex = 3
            togBtn.Parent = row

            local function update()
                tween(track, {BackgroundColor3 = value and Theme.ToggleOn or Theme.ToggleOff}, 0.15)
                tween(knob, {Position = UDim2.new(0, value and 22 or 3, 0.5, -7)}, 0.15)
                if flag then MatchaLib.Flags[flag] = { Value = value } end
                if opts.Callback then opts.Callback(value) end
            end

            togBtn.MouseButton1Click:Connect(function()
                value = not value
                update()
            end)

            if flag then MatchaLib.Flags[flag] = { Value = value } end

            return {
                Set = function(_, v)
                    value = v
                    update()
                end,
                GetValue = function() return value end,
            }
        end

        -- ============================================================
        -- SLIDER
        -- ============================================================
        function tab:AddSlider(opts)
            opts = opts or {}
            local minVal  = opts.Min or 0
            local maxVal  = opts.Max or 100
            local value   = opts.Default or minVal
            local inc     = opts.Increment or 1
            local suffix  = opts.ValueName or ""
            local flag    = opts.Flag

            local container = newFrame({
                Size = UDim2.new(1, 0, 0, 50),
                BackgroundColor3 = Theme.Surface,
                Parent = scrollFrame,
            })
            corner(container, 6)
            stroke(container, Theme.Border)

            local topRow = newFrame({
                Size = UDim2.new(1, -24, 0, 24),
                Position = UDim2.new(0, 12, 0, 6),
                BackgroundTransparency = 1,
                Parent = container,
            })

            newLabel({
                Size = UDim2.new(0.7, 0, 1, 0),
                Text = opts.Name or "Slider",
                TextColor3 = Theme.TextPrimary,
                Parent = topRow,
            })

            local valLabel = newLabel({
                Size = UDim2.new(0.3, 0, 1, 0),
                Position = UDim2.new(0.7, 0, 0, 0),
                Text = tostring(value) .. " " .. suffix,
                TextColor3 = Theme.Accent,
                TextXAlignment = Enum.TextXAlignment.Right,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                Parent = topRow,
            })

            -- Track bg
            local trackBg = newFrame({
                Size = UDim2.new(1, -24, 0, 6),
                Position = UDim2.new(0, 12, 0, 36),
                BackgroundColor3 = Theme.SurfaceAlt,
                Parent = container,
            })
            corner(trackBg, 3)

            -- Fill
            local fill = newFrame({
                Size = UDim2.new((value - minVal) / (maxVal - minVal), 0, 1, 0),
                BackgroundColor3 = Theme.SliderFill,
                Parent = trackBg,
            })
            corner(fill, 3)

            -- Knob
            local knob = newFrame({
                Size = UDim2.new(0, 12, 0, 12),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new((value - minVal) / (maxVal - minVal), 0, 0.5, 0),
                BackgroundColor3 = Color3.new(1,1,1),
                ZIndex = 3,
                Parent = trackBg,
            })
            corner(knob, 6)

            local dragging = false
            local hitbox = Instance.new("TextButton")
            hitbox.Size = UDim2.new(1, 0, 0, 18)
            hitbox.Position = UDim2.new(0, 0, 0.5, -9)
            hitbox.BackgroundTransparency = 1
            hitbox.Text = ""
            hitbox.ZIndex = 5
            hitbox.Parent = trackBg

            local function updateSlider(inputX)
                local abs = trackBg.AbsolutePosition.X
                local width = trackBg.AbsoluteSize.X
                local rel = math.clamp((inputX - abs) / width, 0, 1)
                local raw = minVal + (maxVal - minVal) * rel
                -- Snap to increment
                local snapped = math.floor(raw / inc + 0.5) * inc
                snapped = math.clamp(snapped, minVal, maxVal)
                -- Round to avoid float issues
                snapped = math.floor(snapped * 1000 + 0.5) / 1000
                value = snapped

                local fillRel = (value - minVal) / (maxVal - minVal)
                tween(fill, {Size = UDim2.new(fillRel, 0, 1, 0)}, 0.05)
                tween(knob, {Position = UDim2.new(fillRel, 0, 0.5, 0)}, 0.05)
                valLabel.Text = tostring(value) .. " " .. suffix

                if flag then MatchaLib.Flags[flag] = { Value = value } end
                if opts.Callback then opts.Callback(value) end
            end

            hitbox.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    updateSlider(i.Position.X)
                end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                    updateSlider(i.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)

            if flag then MatchaLib.Flags[flag] = { Value = value } end

            return {
                Set = function(_, v)
                    value = math.clamp(v, minVal, maxVal)
                    local rel = (value - minVal) / (maxVal - minVal)
                    fill.Size = UDim2.new(rel, 0, 1, 0)
                    knob.Position = UDim2.new(rel, 0, 0.5, 0)
                    valLabel.Text = tostring(value) .. " " .. suffix
                    if flag then MatchaLib.Flags[flag] = { Value = value } end
                end,
                GetValue = function() return value end,
            }
        end

        -- ============================================================
        -- DROPDOWN
        -- ============================================================
        function tab:AddDropdown(opts)
            opts = opts or {}
            local options = opts.Options or {}
            local value   = opts.Default or (options[1] or "")
            local flag    = opts.Flag
            local open    = false

            local container = newFrame({
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = Theme.Surface,
                ClipsDescendants = false,
                Parent = scrollFrame,
            })
            corner(container, 6)
            stroke(container, Theme.Border)

            local header = Instance.new("TextButton")
            header.Size = UDim2.new(1, 0, 0, 34)
            header.BackgroundTransparency = 1
            header.Text = ""
            header.ZIndex = 4
            header.Parent = container

            newLabel({
                Size = UDim2.new(0.55, 0, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                Text = opts.Name or "Dropdown",
                TextColor3 = Theme.TextPrimary,
                ZIndex = 5,
                Parent = container,
            })

            local selectedLbl = newLabel({
                Size = UDim2.new(0.4, -30, 1, 0),
                Position = UDim2.new(0.55, 0, 0, 0),
                Text = value,
                TextColor3 = Theme.Accent,
                TextXAlignment = Enum.TextXAlignment.Right,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                ZIndex = 5,
                Parent = container,
            })

            local arrow = newLabel({
                Size = UDim2.new(0, 20, 1, 0),
                Position = UDim2.new(1, -24, 0, 0),
                Text = "▾",
                TextColor3 = Theme.TextSecondary,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextSize = 14,
                ZIndex = 5,
                Parent = container,
            })

            -- Dropdown panel
            local panel = newFrame({
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 38),
                BackgroundColor3 = Theme.SurfaceAlt,
                ClipsDescendants = true,
                ZIndex = 10,
                Parent = container,
            })
            corner(panel, 6)
            stroke(panel, Theme.Border)

            local panelList = Instance.new("UIListLayout")
            panelList.SortOrder = Enum.SortOrder.LayoutOrder
            panelList.Parent = panel
            Instance.new("UIPadding", panel).PaddingTop = UDim.new(0, 4)

            local optionHeight = 28
            local maxVisible   = 5

            local function buildOptions(optList)
                for _, c in ipairs(panel:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end
                for _, opt in ipairs(optList) do
                    local optBtn = Instance.new("TextButton")
                    optBtn.Size = UDim2.new(1, -8, 0, optionHeight)
                    optBtn.BackgroundColor3 = Theme.SurfaceAlt
                    optBtn.Text = opt
                    optBtn.Font = Enum.Font.Gotham
                    optBtn.TextSize = 12
                    optBtn.TextColor3 = opt == value and Theme.Accent or Theme.TextPrimary
                    optBtn.TextXAlignment = Enum.TextXAlignment.Left
                    optBtn.AutoButtonColor = false
                    optBtn.ZIndex = 11
                    optBtn.Parent = panel
                    Instance.new("UIPadding", optBtn).PaddingLeft = UDim.new(0, 10)
                    corner(optBtn, 4)

                    optBtn.MouseEnter:Connect(function()
                        tween(optBtn, {BackgroundColor3 = Theme.Surface}, 0.1)
                    end)
                    optBtn.MouseLeave:Connect(function()
                        tween(optBtn, {BackgroundColor3 = Theme.SurfaceAlt}, 0.1)
                    end)
                    optBtn.MouseButton1Click:Connect(function()
                        value = opt
                        selectedLbl.Text = value
                        if flag then MatchaLib.Flags[flag] = { Value = value } end
                        if opts.Callback then opts.Callback(value) end
                        -- Close
                        open = false
                        tween(panel, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                        tween(container, {Size = UDim2.new(1, 0, 0, 34)}, 0.2)
                        tween(arrow, {TextColor3 = Theme.TextSecondary}, 0.1)
                        -- Update colors
                        for _, c in ipairs(panel:GetChildren()) do
                            if c:IsA("TextButton") then
                                c.TextColor3 = c.Text == value and Theme.Accent or Theme.TextPrimary
                            end
                        end
                    end)
                end
            end

            buildOptions(options)

            header.MouseButton1Click:Connect(function()
                open = not open
                local panelH = math.min(#options, maxVisible) * optionHeight + 8
                if open then
                    tween(panel, {Size = UDim2.new(1, 0, 0, panelH)}, 0.2)
                    tween(container, {Size = UDim2.new(1, 0, 0, 34 + panelH + 4)}, 0.2)
                    tween(arrow, {TextColor3 = Theme.Accent}, 0.1)
                else
                    tween(panel, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                    tween(container, {Size = UDim2.new(1, 0, 0, 34)}, 0.2)
                    tween(arrow, {TextColor3 = Theme.TextSecondary}, 0.1)
                end
            end)

            if flag then MatchaLib.Flags[flag] = { Value = value } end

            return {
                Set = function(_, v)
                    value = v
                    selectedLbl.Text = v
                    if flag then MatchaLib.Flags[flag] = { Value = value } end
                end,
                Refresh = function(_, newOpts, clear)
                    if clear then options = {} end
                    for _, o in ipairs(newOpts) do table.insert(options, o) end
                    buildOptions(options)
                end,
                GetValue = function() return value end,
            }
        end

        -- ============================================================
        -- COLORPICKER
        -- ============================================================
        function tab:AddColorpicker(opts)
            opts = opts or {}
            local value = opts.Default or Color3.new(1,1,1)
            local flag  = opts.Flag
            local open  = false

            local container = newFrame({
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = Theme.Surface,
                ClipsDescendants = false,
                Parent = scrollFrame,
            })
            corner(container, 6)
            stroke(container, Theme.Border)

            newLabel({
                Size = UDim2.new(0.7, 0, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                Text = opts.Name or "Color",
                TextColor3 = Theme.TextPrimary,
                ZIndex = 3,
                Parent = container,
            })

            local preview = newFrame({
                Size = UDim2.new(0, 22, 0, 22),
                Position = UDim2.new(1, -32, 0.5, -11),
                BackgroundColor3 = value,
                ZIndex = 3,
                Parent = container,
            })
            corner(preview, 4)
            stroke(preview, Theme.Border)

            local header = Instance.new("TextButton")
            header.Size = UDim2.new(1, 0, 0, 34)
            header.BackgroundTransparency = 1
            header.Text = ""
            header.ZIndex = 4
            header.Parent = container

            -- Color panel
            local panel = newFrame({
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 38),
                BackgroundColor3 = Theme.SurfaceAlt,
                ClipsDescendants = true,
                ZIndex = 10,
                Parent = container,
            })
            corner(panel, 6)
            stroke(panel, Theme.Border)

            -- Hue, Sat, Val sliders
            local panelPad = Instance.new("UIPadding", panel)
            panelPad.PaddingLeft = UDim.new(0, 10)
            panelPad.PaddingRight = UDim.new(0, 10)
            panelPad.PaddingTop = UDim.new(0, 8)
            panelPad.PaddingBottom = UDim.new(0, 8)

            local panelList = Instance.new("UIListLayout")
            panelList.Padding = UDim.new(0, 6)
            panelList.Parent = panel

            local h, s, v2 = Color3.toHSV(value)

            local function buildHsvSlider(labelText, initVal, color, cb)
                local row = newFrame({ Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, ZIndex = 11, Parent = panel })
                newLabel({ Size = UDim2.new(0, 24, 1, 0), Text = labelText, TextColor3 = Theme.TextMuted, TextSize = 11, ZIndex = 12, Parent = row })
                local trackBg = newFrame({ Size = UDim2.new(1, -30, 0, 6), Position = UDim2.new(0, 28, 0.5, -3), BackgroundColor3 = color, ZIndex = 12, Parent = row })
                corner(trackBg, 3)
                local knob2 = newFrame({ Size = UDim2.new(0, 10, 0, 10), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(initVal, 0, 0.5, 0), BackgroundColor3 = Color3.new(1,1,1), ZIndex = 13, Parent = trackBg })
                corner(knob2, 5)
                local drag = false
                local hitbox2 = Instance.new("TextButton")
                hitbox2.Size = UDim2.new(1, 0, 0, 16)
                hitbox2.Position = UDim2.new(0, 0, 0.5, -8)
                hitbox2.BackgroundTransparency = 1
                hitbox2.Text = ""
                hitbox2.ZIndex = 14
                hitbox2.Parent = trackBg
                hitbox2.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true end end)
                UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)
                UserInputService.InputChanged:Connect(function(i)
                    if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
                        local rel = math.clamp((i.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X, 0, 1)
                        knob2.Position = UDim2.new(rel, 0, 0.5, 0)
                        cb(rel)
                    end
                end)
                return knob2
            end

            local function updateColor()
                value = Color3.fromHSV(h, s, v2)
                preview.BackgroundColor3 = value
                if flag then MatchaLib.Flags[flag] = { Value = value } end
                if opts.Callback then opts.Callback(value) end
            end

            buildHsvSlider("H", h, Color3.fromRGB(255,100,100), function(rel) h = rel; updateColor() end)
            buildHsvSlider("S", s, Color3.fromRGB(200,200,200), function(rel) s = rel; updateColor() end)
            buildHsvSlider("V", v2, Color3.fromRGB(255,255,255), function(rel) v2 = rel; updateColor() end)

            header.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    tween(panel, {Size = UDim2.new(1, 0, 0, 110)}, 0.2)
                    tween(container, {Size = UDim2.new(1, 0, 0, 152)}, 0.2)
                else
                    tween(panel, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                    tween(container, {Size = UDim2.new(1, 0, 0, 34)}, 0.2)
                end
            end)

            if flag then MatchaLib.Flags[flag] = { Value = value } end

            return {
                Set = function(_, c)
                    value = c
                    preview.BackgroundColor3 = c
                    if flag then MatchaLib.Flags[flag] = { Value = value } end
                end,
                GetValue = function() return value end,
            }
        end

        -- ============================================================
        -- KEYBIND
        -- ============================================================
        function tab:AddBind(opts)
            opts = opts or {}
            local key     = opts.Default or Enum.KeyCode.Unknown
            local flag    = opts.Flag
            local waiting = false

            local row = newFrame({
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = Theme.Surface,
                Parent = scrollFrame,
            })
            corner(row, 6)
            stroke(row, Theme.Border)

            newLabel({
                Size = UDim2.new(0.6, 0, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                Text = opts.Name or "Keybind",
                TextColor3 = Theme.TextPrimary,
                Parent = row,
            })

            local keyBtn = Instance.new("TextButton")
            keyBtn.Size = UDim2.new(0, 80, 0, 22)
            keyBtn.Position = UDim2.new(1, -90, 0.5, -11)
            keyBtn.BackgroundColor3 = Theme.SurfaceAlt
            keyBtn.Text = key == Enum.KeyCode.Unknown and "NONE" or key.Name
            keyBtn.Font = Enum.Font.GothamBold
            keyBtn.TextSize = 11
            keyBtn.TextColor3 = Theme.Accent
            keyBtn.ZIndex = 3
            keyBtn.Parent = row
            corner(keyBtn, 4)

            keyBtn.MouseButton1Click:Connect(function()
                waiting = true
                keyBtn.Text = "..."
                keyBtn.TextColor3 = Theme.TextMuted
            end)

            UserInputService.InputBegan:Connect(function(i, processed)
                if waiting and i.UserInputType == Enum.UserInputType.Keyboard then
                    waiting = false
                    key = i.KeyCode
                    keyBtn.Text = key.Name
                    keyBtn.TextColor3 = Theme.Accent
                    if flag then MatchaLib.Flags[flag] = { Value = key } end
                elseif not waiting and not processed and i.UserInputType == Enum.UserInputType.Keyboard then
                    if i.KeyCode == key and opts.Callback then
                        opts.Callback()
                    end
                end
            end)

            if flag then MatchaLib.Flags[flag] = { Value = key } end

            return {
                Set = function(_, k)
                    key = k
                    keyBtn.Text = k == Enum.KeyCode.Unknown and "NONE" or k.Name
                    if flag then MatchaLib.Flags[flag] = { Value = key } end
                end,
                GetValue = function() return key end,
            }
        end

        -- ============================================================
        -- TEXTBOX
        -- ============================================================
        function tab:AddTextbox(opts)
            opts = opts or {}

            local row = newFrame({
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = Theme.Surface,
                Parent = scrollFrame,
            })
            corner(row, 6)
            stroke(row, Theme.Border)

            newLabel({
                Size = UDim2.new(0.45, 0, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                Text = opts.Name or "Textbox",
                TextColor3 = Theme.TextPrimary,
                Parent = row,
            })

            local box = Instance.new("TextBox")
            box.Size = UDim2.new(0, 120, 0, 22)
            box.Position = UDim2.new(1, -130, 0.5, -11)
            box.BackgroundColor3 = Theme.SurfaceAlt
            box.Text = opts.Default or ""
            box.Font = Enum.Font.Gotham
            box.TextSize = 12
            box.TextColor3 = Theme.TextPrimary
            box.PlaceholderText = opts.Placeholder or "..."
            box.PlaceholderColor3 = Theme.TextMuted
            box.ClearTextOnFocus = false
            box.ZIndex = 3
            box.Parent = row
            corner(box, 4)
            stroke(box, Theme.Border)
            Instance.new("UIPadding", box).PaddingLeft = UDim.new(0, 6)

            box.FocusLost:Connect(function(enter)
                if opts.Callback then opts.Callback(box.Text) end
                if opts.TextDisappear then box.Text = "" end
            end)

            return {
                Set = function(_, t) box.Text = t end,
                GetValue = function() return box.Text end,
            }
        end

        return tab
    end

    -- ============================================================
    -- INIT (called at end of script)
    -- ============================================================
    function win:Init()
        -- nothing needed, kept for API compatibility
    end

    return win
end

function MatchaLib:Init()
    -- compatibility stub
end

return MatchaLib

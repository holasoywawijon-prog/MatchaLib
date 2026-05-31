--[[
╔══════════════════════════════════════════════════════════════╗
║                  MatchaUI Library  v2.0                     ║
║          Fiel ao design do Matcha (Roblox)                  ║
╠══════════════════════════════════════════════════════════════╣
║  QUICK START:                                               ║
║                                                             ║
║  local UI = loadstring(game:HttpGet("RAW_URL"))()           ║
║                                                             ║
║  local Win = UI.CreateWindow({                              ║
║      Title    = "Matcha",                                   ║
║      Profiles = {"Matcha","Comfort","stable"},              ║
║      ToggleKey = Enum.KeyCode.Insert,                       ║
║  })                                                         ║
║                                                             ║
║  local CombatTab = Win:AddTab("Combat")                     ║
║                                                             ║
║  local AimbotSec = CombatTab:AddSubTab("Aimbot")            ║
║  AimbotSec:AddToggle("Enabled", false, function(v) end)     ║
║  AimbotSec:AddSlider("FOV Size", 1, 200, 54, function(v) end)║
║  AimbotSec:AddDropdown("Style",{"Smooth","Snap"}, function(v) end)║
║                                                             ║
║  local FOVSec = CombatTab:AddSubTab("FOV")                  ║
║  FOVSec:AddToggle("Enabled", false, function(v) end)        ║
╚══════════════════════════════════════════════════════════════╝
--]]

-- ════════════════════════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════════════════════════
local Players         = game:GetService("Players")
local TweenService    = game:GetService("TweenService")
local UIS             = game:GetService("UserInputService")
local CoreGui         = game:GetService("CoreGui")
local HttpService     = game:GetService("HttpService")
local LocalPlayer     = Players.LocalPlayer

-- ════════════════════════════════════════════════════════════
--  THEME
-- ════════════════════════════════════════════════════════════
local T = {
    -- backgrounds
    BgMain      = Color3.fromRGB(13,  13,  15),   -- janela principal
    BgSidebar   = Color3.fromRGB(18,  18,  20),   -- sidebar
    BgPanel     = Color3.fromRGB(18,  18,  20),   -- painel direito
    BgBar       = Color3.fromRGB(18,  18,  20),   -- topbar / bottombar
    BgItem      = Color3.fromRGB(24,  24,  27),   -- itens (toggle bg, slider track)
    BgHover     = Color3.fromRGB(28,  28,  32),   -- hover em rows

    -- borders
    Border      = Color3.fromRGB(38,  38,  43),
    BorderHi    = Color3.fromRGB(60,  60,  68),

    -- accent
    Accent      = Color3.fromRGB(232, 71,  139),
    AccentDim   = Color3.fromRGB(180, 50,  100),
    AccentGlow  = Color3.fromRGB(232, 71,  139),
    AccentAlpha = 0.88,                            -- transparência do fundo ativo nav

    -- texto
    TextPrimary = Color3.fromRGB(228, 228, 232),
    TextMuted   = Color3.fromRGB(100, 100, 110),
    TextDim     = Color3.fromRGB(70,  70,  78),

    -- misc
    White       = Color3.new(1, 1, 1),
    Success     = Color3.fromRGB(100, 200, 110),
    Danger      = Color3.fromRGB(220, 70,  70),
}

local FONT      = Enum.Font.Gotham
local FONT_SEMI = Enum.Font.GothamSemibold
local FONT_BOLD = Enum.Font.GothamBold

-- ════════════════════════════════════════════════════════════
--  UTILS
-- ════════════════════════════════════════════════════════════
local function Tween(obj, props, t, style)
    TweenService:Create(obj,
        TweenInfo.new(t or 0.14, style or Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out), props):Play()
end

local function N(class, props, children)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    for _, c in pairs(children or {}) do c.Parent = o end
    return o
end

local function Corner(r)
    return N("UICorner", { CornerRadius = UDim.new(0, r or 6) })
end

local function Stroke(col, thick)
    return N("UIStroke", { Color = col or T.Border, Thickness = thick or 1 })
end

local function Padding(l, r, t, b)
    return N("UIPadding", {
        PaddingLeft   = UDim.new(0, l or 0),
        PaddingRight  = UDim.new(0, r or 0),
        PaddingTop    = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or 0),
    })
end

local function ListLayout(dir, padding, xalign, yalign)
    return N("UIListLayout", {
        FillDirection      = dir or Enum.FillDirection.Vertical,
        SortOrder          = Enum.SortOrder.LayoutOrder,
        Padding            = UDim.new(0, padding or 0),
        HorizontalAlignment = xalign or Enum.HorizontalAlignment.Left,
        VerticalAlignment  = yalign or Enum.VerticalAlignment.Top,
    })
end

-- Draggable
local function MakeDraggable(frame, handle)
    handle = handle or frame
    local drag, input, startV, startP
    handle.InputBegan:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        drag = true; startV = i.Position; startP = frame.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then drag = false end
        end)
    end)
    handle.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement then input = i end
    end)
    UIS.InputChanged:Connect(function(i)
        if i == input and drag then
            local d = i.Position - startV
            frame.Position = UDim2.new(
                startP.X.Scale, startP.X.Offset + d.X,
                startP.Y.Scale, startP.Y.Offset + d.Y)
        end
    end)
end

-- Config save/load (pcall para não dar erro se não tiver writefile)
local CFG_FOLDER = "MatchaUI"
local function SaveCfg(name, data)
    pcall(function()
        if not isfolder(CFG_FOLDER) then makefolder(CFG_FOLDER) end
        writefile(CFG_FOLDER.."/"..name..".json", HttpService:JSONEncode(data))
    end)
end
local function LoadCfg(name)
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(CFG_FOLDER.."/"..name..".json"))
    end)
    return ok and data or {}
end

-- ════════════════════════════════════════════════════════════
--  COMPONENT BUILDERS  (reutilizados por SubTabs)
-- ════════════════════════════════════════════════════════════

-- Linha base (container horizontal 22px)
local function MakeRow(parent, order, h)
    return N("Frame", {
        Parent = parent,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, h or 22),
        LayoutOrder = order,
    })
end

-- ─── Toggle (Checkbox) ────────────────────────────────────
local function BuildToggle(parent, order, label, val, cfg, cfgKey, cb)
    local Row = N("Frame", {
        Parent = parent, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24), LayoutOrder = order,
    })

    -- Box
    local Box = N("Frame", {
        Parent = Row,
        BackgroundColor3 = val and T.Accent or T.BgItem,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, -9),
        Size = UDim2.new(0, 18, 0, 18),
    }, { Corner(4), Stroke(val and T.Accent or T.Border, 1.5) })

    -- Ícone check (usando frame em vez de imagem para não depender de asset)
    local ChkA = N("Frame", {  -- barra diagonal curta
        Parent = Box, BackgroundColor3 = T.White, BorderSizePixel = 0,
        Position = UDim2.new(0, 3, 0, 10), Size = UDim2.new(0, 5, 0, 1.5),
        Rotation = -45,
        BackgroundTransparency = val and 0 or 1,
    }, { Corner(1) })
    local ChkB = N("Frame", {  -- barra diagonal longa
        Parent = Box, BackgroundColor3 = T.White, BorderSizePixel = 0,
        Position = UDim2.new(0, 5, 0, 6), Size = UDim2.new(0, 9, 0, 1.5),
        Rotation = 45,
        BackgroundTransparency = val and 0 or 1,
    }, { Corner(1) })

    -- Label
    N("TextLabel", {
        Parent = Row, BackgroundTransparency = 1,
        Position = UDim2.new(0, 26, 0, 0), Size = UDim2.new(1, -26, 1, 0),
        Font = FONT, Text = label, TextColor3 = T.TextPrimary,
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
    })

    -- Hover bg
    local Hover = N("Frame", {
        Parent = Row, BackgroundColor3 = T.BgHover,
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
    }, { Corner(4) })

    local Btn = N("TextButton", {
        Parent = Row, BackgroundTransparency = 1,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), Text = "",
        ZIndex = 2,
    })

    Btn.MouseEnter:Connect(function() Tween(Hover, {BackgroundTransparency=0.82}, 0.1) end)
    Btn.MouseLeave:Connect(function() Tween(Hover, {BackgroundTransparency=1}, 0.1) end)

    Btn.MouseButton1Click:Connect(function()
        val = not val
        local stroke = Box:FindFirstChildOfClass("UIStroke")
        if val then
            Tween(Box, {BackgroundColor3=T.Accent}, 0.12)
            if stroke then stroke.Color = T.Accent end
            Tween(ChkA, {BackgroundTransparency=0}, 0.08)
            Tween(ChkB, {BackgroundTransparency=0}, 0.08)
        else
            Tween(Box, {BackgroundColor3=T.BgItem}, 0.12)
            if stroke then stroke.Color = T.Border end
            Tween(ChkA, {BackgroundTransparency=1}, 0.08)
            Tween(ChkB, {BackgroundTransparency=1}, 0.08)
        end
        if cfg and cfgKey then cfg[cfgKey] = val; SaveCfg("config", cfg) end
        if cb then cb(val) end
    end)

    return { Get=function() return val end, Set=function(v) if v~=val then Btn.MouseButton1Click:Fire() end end }
end

-- ─── Slider ───────────────────────────────────────────────
local function BuildSlider(parent, order, label, min, max, val, cfg, cfgKey, cb)
    val = math.clamp(val, min, max)

    local Container = N("Frame", {
        Parent = parent, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 44), LayoutOrder = order,
    })

    -- Label row
    N("TextLabel", {
        Parent = Container, BackgroundTransparency = 1,
        Size = UDim2.new(0.65, 0, 0, 18),
        Font = FONT, Text = label, TextColor3 = T.TextMuted,
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
    })

    local ValLbl = N("TextLabel", {
        Parent = Container, BackgroundTransparency = 1,
        Position = UDim2.new(0.65, 0, 0, 0), Size = UDim2.new(0.35, 0, 0, 18),
        Font = FONT_SEMI, Text = tostring(val), TextColor3 = T.TextPrimary,
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right,
    })

    -- Track
    local Track = N("Frame", {
        Parent = Container, BackgroundColor3 = T.Border,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 26), Size = UDim2.new(1, 0, 0, 3),
    }, { Corner(2) })

    local pct = (val - min) / (max - min)

    local Fill = N("Frame", {
        Parent = Track, BackgroundColor3 = T.Accent,
        BorderSizePixel = 0, Size = UDim2.new(pct, 0, 1, 0),
    }, { Corner(2) })

    local Thumb = N("Frame", {
        Parent = Track, BackgroundColor3 = T.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(pct, -7, 0.5, -7), Size = UDim2.new(0, 14, 0, 14),
        ZIndex = 3,
    }, {
        Corner(7),
        N("UIStroke", { Color = Color3.fromRGB(255,255,255), Thickness = 1.5,
            Transparency = 0.6 }),
    })

    -- Hit zone
    local Hit = N("TextButton", {
        Parent = Track, BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0, -8, 0, -12), Size = UDim2.new(1, 16, 0, 27),
        Text = "", ZIndex = 4,
    })

    local sliding = false

    local function SetVal(v)
        v = math.clamp(v, min, max)
        -- arredondar
        local decimals = (max - min < 10) and 2 or 0
        v = math.floor(v * 10^decimals + 0.5) / 10^decimals
        val = v
        local p = (v - min) / (max - min)
        Fill.Size     = UDim2.new(p, 0, 1, 0)
        Thumb.Position = UDim2.new(p, -7, 0.5, -7)
        ValLbl.Text   = tostring(v)
        if cfg and cfgKey then cfg[cfgKey] = v; SaveCfg("config", cfg) end
        if cb then cb(v) end
    end

    local function Calc(input)
        local p = math.clamp(
            (input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        SetVal(min + p * (max - min))
    end

    Hit.MouseButton1Down:Connect(function() sliding = true end)
    UIS.InputChanged:Connect(function(i)
        if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then Calc(i) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)

    return { Get=function() return val end, Set=SetVal }
end

-- ─── Dropdown ─────────────────────────────────────────────
local function BuildDropdown(parent, order, label, opts, val, cfg, cfgKey, cb)
    val = val or opts[1]

    local totalH = 28 + #opts * 26 + 6

    local Container = N("Frame", {
        Parent = parent, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28), LayoutOrder = order,
        ClipsDescendants = true,
    })

    local Header = N("TextButton", {
        Parent = Container, BackgroundColor3 = T.BgItem,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 28),
        Font = FONT, Text = "", AutoButtonColor = false,
    }, { Corner(5), Stroke(T.Border, 1) })

    N("TextLabel", {
        Parent = Header, BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -30, 1, 0),
        Font = FONT, Text = label .. ":  " .. val, TextColor3 = T.TextPrimary,
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
        Name = "Lbl",
    })

    local Arrow = N("TextLabel", {
        Parent = Header, BackgroundTransparency = 1,
        Position = UDim2.new(1, -22, 0, 0), Size = UDim2.new(0, 16, 1, 0),
        Font = FONT_BOLD, Text = "▾", TextColor3 = T.TextMuted, TextSize = 12,
    })

    local List = N("Frame", {
        Parent = Container, BackgroundColor3 = T.BgItem,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 30), Size = UDim2.new(1, 0, 0, #opts * 26 + 4),
    }, {
        Corner(5), Stroke(T.Border, 1),
        ListLayout(nil, 0),
        Padding(0, 0, 2, 2),
    })

    local optBtns = {}
    for i, opt in ipairs(opts) do
        local ob = N("TextButton", {
            Parent = List, BackgroundTransparency = 1, BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 26), LayoutOrder = i,
            Font = FONT, Text = opt, AutoButtonColor = false,
            TextColor3 = opt == val and T.Accent or T.TextPrimary, TextSize = 12,
        }, { Padding(10) })
        optBtns[i] = ob

        ob.MouseEnter:Connect(function()
            if opt ~= val then Tween(ob, {TextColor3=T.Accent}, 0.1) end
            Tween(ob, {BackgroundTransparency=0.88}, 0.1)
            ob.BackgroundColor3 = T.BgHover
        end)
        ob.MouseLeave:Connect(function()
            if opt ~= val then Tween(ob, {TextColor3=T.TextPrimary}, 0.1) end
            Tween(ob, {BackgroundTransparency=1}, 0.1)
        end)
        ob.MouseButton1Click:Connect(function()
            val = opt
            Header:FindFirstChild("Lbl").Text = label .. ":  " .. val
            for _, b in ipairs(optBtns) do
                b.TextColor3 = b.Text == val and T.Accent or T.TextPrimary
            end
            -- fechar
            Tween(Container, {Size=UDim2.new(1,0,0,28)}, 0.15)
            Arrow.Text = "▾"
            if cfg and cfgKey then cfg[cfgKey]=val; SaveCfg("config",cfg) end
            if cb then cb(val) end
        end)
    end

    local open = false
    Header.MouseButton1Click:Connect(function()
        open = not open
        Tween(Container, {Size=UDim2.new(1,0,0, open and totalH or 28)}, 0.15)
        Arrow.Text = open and "▴" or "▾"
    end)

    return { Get=function() return val end,
             Set=function(v) val=v; Header:FindFirstChild("Lbl").Text=label..":  "..v end }
end

-- ─── Button ───────────────────────────────────────────────
local function BuildButton(parent, order, label, cb)
    local Btn = N("TextButton", {
        Parent = parent, BackgroundColor3 = T.BgItem,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = order,
        Font = FONT_SEMI, Text = label, TextColor3 = T.TextPrimary,
        TextSize = 12, AutoButtonColor = false,
    }, { Corner(5), Stroke(T.Border, 1) })

    Btn.MouseEnter:Connect(function()
        Tween(Btn, {BackgroundColor3=T.BgHover, TextColor3=T.Accent}, 0.1)
        Btn:FindFirstChildOfClass("UIStroke").Color = T.Accent
    end)
    Btn.MouseLeave:Connect(function()
        Tween(Btn, {BackgroundColor3=T.BgItem, TextColor3=T.TextPrimary}, 0.1)
        Btn:FindFirstChildOfClass("UIStroke").Color = T.Border
    end)
    Btn.MouseButton1Down:Connect(function()
        Tween(Btn, {BackgroundColor3=T.AccentDim}, 0.08)
    end)
    Btn.MouseButton1Up:Connect(function()
        Tween(Btn, {BackgroundColor3=T.BgHover}, 0.1)
        if cb then cb() end
    end)
end

-- ─── Keybind ──────────────────────────────────────────────
local function BuildKeybind(parent, order, label, default, cfg, cfgKey, cb)
    local cur = default or Enum.KeyCode.Unknown
    local listening = false
    local Row = MakeRow(parent, order, 22)

    N("TextLabel", {
        Parent = Row, BackgroundTransparency = 1,
        Size = UDim2.new(0.65, 0, 1, 0), Font = FONT, Text = label,
        TextColor3 = T.TextMuted, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
    })

    local KeyBtn = N("TextButton", {
        Parent = Row, BackgroundColor3 = T.BgItem, BorderSizePixel = 0,
        Position = UDim2.new(0.65, 0, 0.1, 0), Size = UDim2.new(0.35, 0, 0.8, 0),
        Font = FONT, Text = cur.Name, TextColor3 = T.TextPrimary,
        TextSize = 10, AutoButtonColor = false,
    }, { Corner(3), Stroke(T.Border, 1) })

    KeyBtn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        KeyBtn.Text = "..."
        KeyBtn.TextColor3 = T.Accent
        local conn
        conn = UIS.InputBegan:Connect(function(i, gpe)
            if gpe or i.UserInputType ~= Enum.UserInputType.Keyboard then return end
            cur = i.KeyCode
            KeyBtn.Text = i.KeyCode.Name
            KeyBtn.TextColor3 = T.TextPrimary
            listening = false
            conn:Disconnect()
            if cfg and cfgKey then cfg[cfgKey]=i.KeyCode.Name; SaveCfg("config",cfg) end
            if cb then cb(i.KeyCode) end
        end)
    end)
    return { Get=function() return cur end }
end

-- ─── Label ────────────────────────────────────────────────
local function BuildLabel(parent, order, text, color)
    N("TextLabel", {
        Parent = parent, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18), LayoutOrder = order,
        Font = FONT, Text = text, TextColor3 = color or T.TextMuted,
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
    })
end

-- ─── Section header ───────────────────────────────────────
local function BuildSection(parent, order, text)
    local F = N("Frame", {
        Parent = parent, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24), LayoutOrder = order,
    })
    N("TextLabel", {
        Parent = F, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0,0,1,-16),
        Font = FONT_BOLD, Text = text:upper(), TextColor3 = T.TextMuted,
        TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
    })
    N("Frame", {
        Parent = F, BackgroundColor3 = T.Border, BorderSizePixel = 0,
        Position = UDim2.new(0,0,1,-1), Size = UDim2.new(1,0,0,1),
    })
end

-- ─── Divider ──────────────────────────────────────────────
local function BuildDivider(parent, order)
    N("Frame", {
        Parent = parent, BackgroundColor3 = T.Border,
        BorderSizePixel = 0, Size = UDim2.new(1,0,0,1), LayoutOrder = order,
    })
end

-- ─── ColorPicker (swatches) ───────────────────────────────
local function BuildColorPicker(parent, order, label, colors, def, cb)
    colors = colors or {
        Color3.new(1,1,1),
        Color3.fromRGB(232,71,139),
        Color3.fromRGB(90,200,255),
        Color3.fromRGB(100,220,100),
        Color3.fromRGB(255,180,50),
        Color3.fromRGB(180,100,255),
    }
    def = def or colors[1]
    local selected = def

    local Row = MakeRow(parent, order, 24)

    N("TextLabel", {
        Parent = Row, BackgroundTransparency = 1,
        Size = UDim2.new(0.4, 0, 1, 0), Font = FONT, Text = label,
        TextColor3 = T.TextMuted, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
    })

    local SwatchRow = N("Frame", {
        Parent = Row, BackgroundTransparency = 1,
        Position = UDim2.new(0.4, 0, 0.1, 0), Size = UDim2.new(0.6, 0, 0.8, 0),
    }, { ListLayout(Enum.FillDirection.Horizontal, 4, nil, Enum.VerticalAlignment.Center) })

    local swatches = {}
    for _, c in ipairs(colors) do
        local sw = N("TextButton", {
            Parent = SwatchRow, BackgroundColor3 = c, BorderSizePixel = 0,
            Size = UDim2.new(0, 18, 0, 18), Text = "", AutoButtonColor = false,
        }, {
            Corner(3),
            N("UIStroke", { Color = c==selected and T.White or T.BgMain, Thickness = 1.5 }),
        })
        table.insert(swatches, {btn=sw, color=c})
        sw.MouseButton1Click:Connect(function()
            selected = c
            for _, s in ipairs(swatches) do
                s.btn:FindFirstChildOfClass("UIStroke").Color =
                    s.color==selected and T.White or T.BgMain
            end
            if cb then cb(c) end
        end)
    end
    return { Get=function() return selected end }
end

-- ─── TextBox ──────────────────────────────────────────────
local function BuildTextbox(parent, order, label, placeholder, cb)
    local Container = N("Frame", {
        Parent = parent, BackgroundTransparency = 1,
        Size = UDim2.new(1,0,0,46), LayoutOrder = order,
    }, { ListLayout(nil, 4) })

    N("TextLabel", {
        Parent = Container, BackgroundTransparency = 1,
        Size = UDim2.new(1,0,0,16), LayoutOrder = 1,
        Font = FONT, Text = label, TextColor3 = T.TextMuted,
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
    })

    local Box = N("TextBox", {
        Parent = Container, BackgroundColor3 = T.BgItem,
        BorderSizePixel = 0, Size = UDim2.new(1,0,0,26), LayoutOrder = 2,
        Font = FONT, PlaceholderText = placeholder or "",
        Text = "", TextColor3 = T.TextPrimary,
        PlaceholderColor3 = T.TextDim, TextSize = 12, ClearTextOnFocus = false,
    }, { Corner(5), Stroke(T.Border, 1, "Stk"), Padding(8) })

    Box.Focused:Connect(function()
        Box:FindFirstChild("Stk").Color = T.Accent
    end)
    Box.FocusLost:Connect(function(enter)
        Box:FindFirstChild("Stk").Color = T.Border
        if cb then cb(Box.Text, enter) end
    end)
end

-- ════════════════════════════════════════════════════════════
--  SUB-TAB OBJECT  (painel dentro de um Tab, como "Aimbot","FOV")
-- ════════════════════════════════════════════════════════════
local function MakeSubTab(scrollFrame, cfg)
    local ST = { _scroll = scrollFrame, _order = 0, _cfg = cfg }

    local function O() ST._order = ST._order + 1; return ST._order end

    function ST:AddToggle(label, default, cb)
        local key = label:lower():gsub("%s+","_")
        local v = ST._cfg[key]
        if v == nil then v = default end
        return BuildToggle(ST._scroll, O(), label, v, ST._cfg, key, cb)
    end
    function ST:AddSlider(label, min, max, default, cb)
        local key = label:lower():gsub("%s+","_")
        local v = tonumber(ST._cfg[key]) or default
        return BuildSlider(ST._scroll, O(), label, min, max, v, ST._cfg, key, cb)
    end
    function ST:AddDropdown(label, opts, cb)
        local key = label:lower():gsub("%s+","_")
        local v = ST._cfg[key] or opts[1]
        return BuildDropdown(ST._scroll, O(), label, opts, v, ST._cfg, key, cb)
    end
    function ST:AddButton(label, cb)      BuildButton(ST._scroll, O(), label, cb) end
    function ST:AddKeybind(label, def, cb)
        local key = label:lower():gsub("%s+","_")
        return BuildKeybind(ST._scroll, O(), label, def, ST._cfg, key, cb)
    end
    function ST:AddLabel(text, color)     BuildLabel(ST._scroll, O(), text, color) end
    function ST:AddSection(text)          BuildSection(ST._scroll, O(), text) end
    function ST:AddDivider()              BuildDivider(ST._scroll, O()) end
    function ST:AddColorPicker(label, colors, def, cb)
        return BuildColorPicker(ST._scroll, O(), label, colors, def, cb)
    end
    function ST:AddTextbox(label, ph, cb) BuildTextbox(ST._scroll, O(), label, ph, cb) end

    return ST
end

-- ════════════════════════════════════════════════════════════
--  TAB OBJECT  (sidebar item: "Combat", "Visuals", ...)
--  Cada tab tem subtabs horizontais no topo do painel
-- ════════════════════════════════════════════════════════════
local function MakeTab(panelArea, cfg)
    -- Painel principal do tab (oculto por padrão)
    local Panel = N("Frame", {
        Parent = panelArea,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
    })

    -- Sub-tab bar (linha de subtabs no topo)
    local SubBar = N("Frame", {
        Parent = Panel, BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 30),
    }, {
        ListLayout(Enum.FillDirection.Horizontal, 2),
        Padding(12, 12, 0, 0),
    })

    -- Linha inferior da subbar
    N("Frame", {
        Parent = Panel, BackgroundColor3 = T.Border, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 30), Size = UDim2.new(1, 0, 0, 1),
    })

    -- Área de conteúdo dos subtabs
    local ContentArea = N("Frame", {
        Parent = Panel, BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 31), Size = UDim2.new(1, 0, 1, -31),
    })

    local Tab = {
        _panel       = Panel,
        _subBar      = SubBar,
        _contentArea = ContentArea,
        _subTabs     = {},
        _activeSubTab = nil,
        _cfg         = cfg,
    }

    function Tab:_SelectSubTab(idx)
        self._activeSubTab = idx
        for i, s in ipairs(self._subTabs) do
            local active = i == idx
            s.scroll.Visible = active
            Tween(s.btn, {
                TextColor3 = active and T.Accent or T.TextMuted
            }, 0.12)
            -- underline
            s.line.BackgroundTransparency = active and 0 or 1
        end
    end

    function Tab:AddSubTab(name)
        local idx = #self._subTabs + 1

        -- Botão da subtab
        local Btn = N("TextButton", {
            Parent = self._subBar, BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
            Font = FONT, Text = name, TextColor3 = T.TextMuted,
            TextSize = 12, AutoButtonColor = false, LayoutOrder = idx,
        }, { Padding(8, 8, 0, 0) })

        -- Underline accent
        local Line = N("Frame", {
            Parent = Btn, BackgroundColor3 = T.Accent, BorderSizePixel = 0,
            Position = UDim2.new(0, 8, 1, -2), Size = UDim2.new(1, -16, 0, 2),
            BackgroundTransparency = 1,
        }, { Corner(1) })

        -- ScrollingFrame de conteúdo
        local Scroll = N("ScrollingFrame", {
            Parent = self._contentArea,
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = T.Border,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
        }, {
            ListLayout(nil, 6),
            Padding(14, 14, 10, 10),
        })

        table.insert(self._subTabs, { btn=Btn, line=Line, scroll=Scroll })

        Btn.MouseButton1Click:Connect(function() self:_SelectSubTab(idx) end)
        Btn.MouseEnter:Connect(function()
            if self._activeSubTab ~= idx then Tween(Btn, {TextColor3=T.TextPrimary}, 0.1) end
        end)
        Btn.MouseLeave:Connect(function()
            if self._activeSubTab ~= idx then Tween(Btn, {TextColor3=T.TextMuted}, 0.1) end
        end)

        -- Selecionar primeiro
        if idx == 1 then self:_SelectSubTab(1) end

        return MakeSubTab(Scroll, self._cfg)
    end

    -- Atalho: se o tab só precisar de uma "página" sem subtabs
    function Tab:AddSection(text)
        if #self._subTabs == 0 then self:AddSubTab("General") end
        -- não expõe diretamente, mas facilita uso simples
    end

    return Tab
end

-- ════════════════════════════════════════════════════════════
--  CREATE WINDOW  — função principal
-- ════════════════════════════════════════════════════════════
local UI = {}

function UI.CreateWindow(opts)
    opts = opts or {}
    local title     = opts.Title      or "Matcha"
    local profiles  = opts.Profiles   or {title}
    local toggleKey = opts.ToggleKey  or Enum.KeyCode.Insert
    local size      = opts.Size       or Vector2.new(520, 400)
    local cfgName   = title:lower():gsub("%s+","_")

    -- ── ScreenGui ──────────────────────────────────────────
    local Gui = N("ScreenGui", {
        Name = "MatchaUI_"..title,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
    })
    pcall(function() Gui.Parent = CoreGui end)
    if not Gui.Parent then Gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    -- ── Main Frame ─────────────────────────────────────────
    local W, H = size.X, size.Y

    local Main = N("Frame", {
        Parent = Gui, Name = "Main",
        BackgroundColor3 = T.BgMain,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, -W/2, 0.5, -H/2),
        Size = UDim2.new(0, W, 0, H),
        ClipsDescendants = true,
    }, {
        Corner(10),
        Stroke(T.Border, 1),
    })

    -- ── Top Bar (38px) ─────────────────────────────────────
    local TopBar = N("Frame", {
        Parent = Main, Name = "TopBar",
        BackgroundColor3 = T.BgBar, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
    })
    -- fix bottom sharp edge
    N("Frame", {
        Parent = TopBar, BackgroundColor3 = T.BgBar, BorderSizePixel = 0,
        Position = UDim2.new(0,0,0.5,0), Size = UDim2.new(1,0,0.5,0),
    })

    -- Profile tabs (esquerda)
    local ProfileRow = N("Frame", {
        Parent = TopBar, BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -120, 1, 0),
    }, { ListLayout(Enum.FillDirection.Horizontal, 16, nil, Enum.VerticalAlignment.Center) })

    local profileColors = { T.Accent, T.TextMuted, T.Success }
    for i, name in ipairs(profiles) do
        local col = profileColors[i] or T.TextMuted
        local lbl = N("TextLabel", {
            Parent = ProfileRow, BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
            Font = i == 1 and FONT_SEMI or FONT,
            Text = name, TextColor3 = col, TextSize = 13,
            LayoutOrder = i,
        })
        -- underline no primeiro (ativo)
        if i == 1 then
            N("Frame", {
                Parent = lbl, BackgroundColor3 = col, BorderSizePixel = 0,
                Position = UDim2.new(0,0,1,-2), Size = UDim2.new(1,0,0,2),
            }, { Corner(1) })
        end
    end

    -- Username (direita da topbar)
    N("TextLabel", {
        Parent = TopBar, BackgroundTransparency = 1,
        Position = UDim2.new(1,-110,0,0), Size = UDim2.new(0,104,1,0),
        Font = FONT, Text = LocalPlayer.Name,
        TextColor3 = T.TextMuted, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, { Padding(0,8) })

    -- Linha separadora abaixo da topbar
    N("Frame", {
        Parent = Main, BackgroundColor3 = T.Border, BorderSizePixel = 0,
        Position = UDim2.new(0,0,0,38), Size = UDim2.new(1,0,0,1),
    })

    -- ── Bottom Bar (28px) ──────────────────────────────────
    local BotBar = N("Frame", {
        Parent = Main, Name = "BotBar",
        BackgroundColor3 = T.BgBar, BorderSizePixel = 0,
        Position = UDim2.new(0,0,1,-28), Size = UDim2.new(1,0,0,28),
    })
    N("Frame", {
        Parent = BotBar, BackgroundColor3 = T.BgBar, BorderSizePixel = 0,
        Size = UDim2.new(1,0,0.5,0),
    })
    N("Frame", {
        Parent = Main, BackgroundColor3 = T.Border, BorderSizePixel = 0,
        Position = UDim2.new(0,0,1,-28), Size = UDim2.new(1,0,0,1),
    })

    -- Dot online
    N("Frame", {
        Parent = BotBar, BackgroundColor3 = T.Accent, BorderSizePixel = 0,
        Position = UDim2.new(0,10,0.5,-4), Size = UDim2.new(0,8,0,8),
        ZIndex = 2,
    }, { Corner(4) })

    -- Texto online count
    N("TextLabel", {
        Parent = BotBar, BackgroundTransparency = 1,
        Position = UDim2.new(0,24,0,0), Size = UDim2.new(0.5,0,1,0),
        Font = FONT, Text = "matcha.pink/discord",
        TextColor3 = T.TextMuted, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2,
    })

    -- Versão
    N("TextLabel", {
        Parent = BotBar, BackgroundTransparency = 1,
        Position = UDim2.new(1,-60,0,0), Size = UDim2.new(0,54,1,0),
        Font = FONT, Text = "v2.0",
        TextColor3 = T.TextDim, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 2,
    })

    -- ── Body (entre topbar e botbar) ───────────────────────
    local Body = N("Frame", {
        Parent = Main, BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0,0,0,39), Size = UDim2.new(1,0,1,-68),
    })

    -- ── Sidebar (100px) ────────────────────────────────────
    local Sidebar = N("Frame", {
        Parent = Body, BackgroundColor3 = T.BgSidebar,
        BorderSizePixel = 0, Size = UDim2.new(0,100,1,0),
    }, {
        ListLayout(nil, 0),
        Padding(0,0,6,6),
    })

    -- Divisor vertical
    N("Frame", {
        Parent = Body, BackgroundColor3 = T.Border, BorderSizePixel = 0,
        Position = UDim2.new(0,100,0,0), Size = UDim2.new(0,1,1,0),
    })

    -- ── Panel area (direita da sidebar) ────────────────────
    local PanelArea = N("Frame", {
        Parent = Body, BackgroundColor3 = T.BgPanel,
        BorderSizePixel = 0,
        Position = UDim2.new(0,101,0,0), Size = UDim2.new(1,-101,1,0),
        ClipsDescendants = true,
    })

    MakeDraggable(Main, TopBar)

    -- ── Toggle visibility ──────────────────────────────────
    UIS.InputBegan:Connect(function(i, gpe)
        if gpe then return end
        if i.KeyCode == toggleKey then
            Main.Visible = not Main.Visible
        end
    end)

    -- ── Window object ──────────────────────────────────────
    local Win = {
        _sidebar  = Sidebar,
        _panel    = PanelArea,
        _navItems = {},
        _activeNav = nil,
        _cfg      = LoadCfg(cfgName),
        _cfgName  = cfgName,
    }

    function Win:_SelectNav(idx)
        self._activeNav = idx
        for i, item in ipairs(self._navItems) do
            local active = i == idx
            item.tab._panel.Visible = active
            -- accent bar
            item.bar.BackgroundTransparency = active and 0 or 1
            Tween(item.btn, {
                TextColor3 = active and T.Accent or T.TextMuted
            }, 0.12)
            -- bg highlight
            item.bg.BackgroundTransparency = active and T.AccentAlpha or 1
        end
    end

    function Win:AddTab(name)
        local idx = #self._navItems + 1

        -- Nav button
        local NavBtn = N("TextButton", {
            Parent = self._sidebar, BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1,0,0,30), LayoutOrder = idx,
            Font = FONT, Text = name, TextColor3 = T.TextMuted,
            TextSize = 12, AutoButtonColor = false,
        }, { Padding(14,4) })

        local NavBg = N("Frame", {
            Parent = NavBtn, BackgroundColor3 = T.Accent,
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Size = UDim2.new(1,0,1,0), ZIndex = 0,
        })

        local AccentBar = N("Frame", {
            Parent = NavBtn, BackgroundColor3 = T.Accent,
            BorderSizePixel = 0,
            Position = UDim2.new(0,0,0.15,0), Size = UDim2.new(0,2,0.7,0),
            BackgroundTransparency = 1, ZIndex = 2,
        }, { Corner(1) })

        table.insert(self._navItems, { btn=NavBtn, bar=AccentBar, bg=NavBg })

        -- Create tab
        local tab = MakeTab(self._panel, self._cfg)
        self._navItems[idx].tab = tab

        NavBtn.MouseButton1Click:Connect(function() self:_SelectNav(idx) end)
        NavBtn.MouseEnter:Connect(function()
            if self._activeNav ~= idx then
                Tween(NavBtn, {TextColor3=T.TextPrimary}, 0.1)
                Tween(NavBg, {BackgroundTransparency=0.94}, 0.1)
            end
        end)
        NavBtn.MouseLeave:Connect(function()
            if self._activeNav ~= idx then
                Tween(NavBtn, {TextColor3=T.TextMuted}, 0.1)
                Tween(NavBg, {BackgroundTransparency=1}, 0.1)
            end
        end)

        if idx == 1 then self:_SelectNav(1) end

        return tab
    end

    -- Helper: esconder/mostrar
    function Win:SetVisible(v)
        Main.Visible = v
    end

    return Win
end

-- ════════════════════════════════════════════════════════════
return UI
--[[
═══════════════════════════════════════════════════════════════
EXEMPLO DE USO COMPLETO:

local UI = loadstring(game:HttpGet("RAW_URL"))()

local Win = UI.CreateWindow({
    Title    = "Matcha",
    Profiles = {"Matcha", "Comfort", "stable"},
    ToggleKey = Enum.KeyCode.Insert,
    Size = Vector2.new(520, 400),
})

-- ── Combat Tab ──────────────────────────────────────────
local CombatTab = Win:AddTab("Combat")

local AimbotSub = CombatTab:AddSubTab("Aimbot")
AimbotSub:AddSection("General")
AimbotSub:AddToggle("Enabled",   false, function(v) end)
AimbotSub:AddToggle("Team Check",false, function(v) end)
AimbotSub:AddSlider("FOV Size",  1, 200, 54, function(v) end)
AimbotSub:AddSlider("Smoothness",1, 100, 20, function(v) end)

local PredSub = CombatTab:AddSubTab("Prediction")
PredSub:AddToggle("Enabled", false, function(v) end)
PredSub:AddSlider("Strength", 0, 100, 50, function(v) end)

local FOVSub = CombatTab:AddSubTab("FOV")
FOVSub:AddToggle("Enabled", false, function(v) end)
FOVSub:AddToggle("Glow",    false, function(v) end)
FOVSub:AddToggle("Filled",  false, function(v) end)
FOVSub:AddSlider("Size", 1, 200, 42, function(v) end)
FOVSub:AddDropdown("Style", {"Smooth","Circle","Square"}, function(v) end)

local TriggerSub = CombatTab:AddSubTab("Trigger")
TriggerSub:AddToggle("Enabled",       false, function(v) end)
TriggerSub:AddToggle("Visible Check", false, function(v) end)
TriggerSub:AddToggle("Team Check",    false, function(v) end)
TriggerSub:AddSlider("Hitbox Mul",    0.5, 5, 1,  function(v) end)
TriggerSub:AddSlider("Delay (ms)",    0, 500, 1,  function(v) end)
TriggerSub:AddSlider("Release (ms)",  0, 500, 10, function(v) end)
TriggerSub:AddKeybind("Trigger Key", Enum.KeyCode.Q, function(k) end)

-- ── Visuals Tab ──────────────────────────────────────────
local VisualsTab = Win:AddTab("Visuals")

local ESPSub = VisualsTab:AddSubTab("ESP")
ESPSub:AddSection("Players")
ESPSub:AddToggle("Box ESP",    false, function(v) end)
ESPSub:AddToggle("Name ESP",   false, function(v) end)
ESPSub:AddToggle("Health Bar", false, function(v) end)
ESPSub:AddSection("Chams")
ESPSub:AddToggle("Chams",      false, function(v) end)
ESPSub:AddSlider("Opacity", 0, 100, 75, function(v) end)
ESPSub:AddColorPicker("Color", nil, nil, function(c) end)

-- ── Options Tab ──────────────────────────────────────────
local OptsTab = Win:AddTab("Options")

local GenSub = OptsTab:AddSubTab("General")
GenSub:AddSection("Interface")
GenSub:AddSlider("UI Scale", 70, 150, 100, function(v) end)
GenSub:AddDropdown("Language", {"English","Português","Español"}, function(v) end)
GenSub:AddSection("Config")
GenSub:AddButton("Save Config",  function() print("saved") end)
GenSub:AddButton("Load Config",  function() print("loaded") end)
GenSub:AddButton("Reset Config", function() print("reset") end)

═══════════════════════════════════════════════════════════════
--]]

-- ╔══════════════════════════════════════════════════╗
-- ║           MatchaUI Library  v1.0                ║
-- ║     Inspired by Matcha • github style loader    ║
-- ╚══════════════════════════════════════════════════╝
--
-- USAGE EXAMPLE (LocalScript):
--   local MatcaUI = loadstring(game:HttpGet("YOUR_RAW_URL"))()
--   local Window = MatcaUI:CreateWindow("Matcha", "dogback45")
--   local Tab = Window:AddTab("Combat")
--   Tab:AddToggle("Aimbot", false, function(v) print(v) end)
--   Tab:AddSlider("FOV Size", 1, 150, 54, function(v) print(v) end)
--   Tab:AddDropdown("Style", {"Smooth","Snap","Raw"}, function(v) print(v) end)

local MatcaUI = {}
MatcaUI.__index = MatcaUI

-- ─── Services ─────────────────────────────────────────────
local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local CoreGui        = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ─── Theme ────────────────────────────────────────────────
local Theme = {
    Bg          = Color3.fromRGB(14,  14,  16),
    Surface     = Color3.fromRGB(22,  22,  24),
    Surface2    = Color3.fromRGB(28,  28,  31),
    Border      = Color3.fromRGB(42,  42,  46),
    Accent      = Color3.fromRGB(232, 71,  139),
    AccentDark  = Color3.fromRGB(160, 40,  90),
    Text        = Color3.fromRGB(232, 232, 234),
    Muted       = Color3.fromRGB(107, 107, 114),
    White       = Color3.fromRGB(255, 255, 255),
    Success     = Color3.fromRGB(111, 186, 111),
}

local FONT       = Enum.Font.Gotham
local FONT_BOLD  = Enum.Font.GothamBold
local FONT_SEMI  = Enum.Font.GothamSemibold

-- ─── Tween helper ─────────────────────────────────────────
local function Tween(obj, props, duration, style, dir)
    local info = TweenInfo.new(
        duration or 0.15,
        style or Enum.EasingStyle.Quad,
        dir   or Enum.EasingDirection.Out
    )
    TweenService:Create(obj, info, props):Play()
end

-- ─── Create instance helper ───────────────────────────────
local function New(class, props, children)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    for _, child in pairs(children or {}) do
        child.Parent = obj
    end
    return obj
end

-- ─── Drag helper ──────────────────────────────────────────
local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ─── SaveConfig / LoadConfig ──────────────────────────────
local CONFIG_FOLDER = "MatchaUI_Configs"

local function SaveConfig(name, data)
    if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
    local encoded = game:GetService("HttpService"):JSONEncode(data)
    writefile(CONFIG_FOLDER .. "/" .. name .. ".json", encoded)
end

local function LoadConfig(name)
    local path = CONFIG_FOLDER .. "/" .. name .. ".json"
    if isfile(path) then
        local ok, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(readfile(path))
        end)
        if ok then return data end
    end
    return {}
end

-- ══════════════════════════════════════════════════════════
--  MatcaUI:CreateWindow(title, subtitle, toggleKey)
-- ══════════════════════════════════════════════════════════
function MatcaUI:CreateWindow(title, subtitle, toggleKey)
    toggleKey = toggleKey or Enum.KeyCode.Insert

    -- ── ScreenGui ──────────────────────────────────────────
    local ScreenGui = New("ScreenGui", {
        Name            = "MatchaUI_" .. title,
        ResetOnSpawn    = false,
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    })

    -- protect from detection via syn/krnl
    pcall(function()
        ScreenGui.Parent = CoreGui
    end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- ── Main Frame ─────────────────────────────────────────
    local Main = New("Frame", {
        Name            = "Main",
        Parent          = ScreenGui,
        BackgroundColor3 = Theme.Bg,
        BorderSizePixel = 0,
        Position        = UDim2.new(0.5, -230, 0.5, -200),
        Size            = UDim2.new(0, 460, 0, 400),
        ClipsDescendants = true,
    }, {
        New("UICorner", { CornerRadius = UDim.new(0, 8) }),
        New("UIStroke", { Color = Theme.Border, Thickness = 1 }),
    })

    -- ── Title Bar ──────────────────────────────────────────
    local TitleBar = New("Frame", {
        Name            = "TitleBar",
        Parent          = Main,
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Size            = UDim2.new(1, 0, 0, 36),
    }, {
        New("UICorner", { CornerRadius = UDim.new(0, 8) }),
    })

    -- fix bottom corners of titlebar
    New("Frame", {
        Parent          = TitleBar,
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Position        = UDim2.new(0, 0, 0.5, 0),
        Size            = UDim2.new(1, 0, 0.5, 0),
    })

    -- Tab row (top)
    local TopTabContainer = New("Frame", {
        Name            = "TopTabs",
        Parent          = TitleBar,
        BackgroundTransparency = 1,
        Position        = UDim2.new(0, 10, 0, 0),
        Size            = UDim2.new(1, -80, 1, 0),
    }, {
        New("UIListLayout", {
            FillDirection   = Enum.FillDirection.Horizontal,
            SortOrder       = Enum.SortOrder.LayoutOrder,
            Padding         = UDim.new(0, 14),
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }),
    })

    -- User label (right side of titlebar)
    New("TextLabel", {
        Parent          = TitleBar,
        BackgroundTransparency = 1,
        Position        = UDim2.new(1, -80, 0, 0),
        Size            = UDim2.new(0, 74, 1, 0),
        Font            = FONT,
        Text            = subtitle or "",
        TextColor3      = Theme.Muted,
        TextSize        = 11,
        TextXAlignment  = Enum.TextXAlignment.Right,
    })

    -- ── Bottom bar (status) ────────────────────────────────
    local BottomBar = New("Frame", {
        Name            = "BottomBar",
        Parent          = Main,
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Position        = UDim2.new(0, 0, 1, -26),
        Size            = UDim2.new(1, 0, 0, 26),
    }, {
        New("UICorner", { CornerRadius = UDim.new(0, 8) }),
    })
    -- fix top corners
    New("Frame", {
        Parent          = BottomBar,
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Size            = UDim2.new(1, 0, 0.5, 0),
    })

    -- Online dot
    local OnlineDot = New("Frame", {
        Parent          = BottomBar,
        BackgroundColor3 = Theme.Accent,
        Position        = UDim2.new(0, 10, 0.5, -4),
        Size            = UDim2.new(0, 8, 0, 8),
        ZIndex          = 2,
    }, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })

    New("TextLabel", {
        Parent          = BottomBar,
        BackgroundTransparency = 1,
        Position        = UDim2.new(0, 24, 0, 0),
        Size            = UDim2.new(0.4, 0, 1, 0),
        Font            = FONT,
        Text            = "matcha.pink/discord",
        TextColor3      = Theme.Muted,
        TextSize        = 11,
        TextXAlignment  = Enum.TextXAlignment.Left,
        ZIndex          = 2,
    })

    -- ── Content area (between titlebar and bottombar) ──────
    local Content = New("Frame", {
        Name            = "Content",
        Parent          = Main,
        BackgroundTransparency = 1,
        Position        = UDim2.new(0, 0, 0, 36),
        Size            = UDim2.new(1, 0, 1, -62),
    })

    -- Sidebar nav
    local Sidebar = New("Frame", {
        Name            = "Sidebar",
        Parent          = Content,
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Size            = UDim2.new(0, 100, 1, 0),
    }, {
        New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 0),
        }),
        New("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }),
    })

    -- Vertical divider
    New("Frame", {
        Parent          = Content,
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Position        = UDim2.new(0, 100, 0, 0),
        Size            = UDim2.new(0, 1, 1, 0),
    })

    -- Panel area
    local PanelArea = New("Frame", {
        Name            = "PanelArea",
        Parent          = Content,
        BackgroundTransparency = 1,
        Position        = UDim2.new(0, 101, 0, 0),
        Size            = UDim2.new(1, -101, 1, 0),
        ClipsDescendants = true,
    })

    MakeDraggable(Main, TitleBar)

    -- ── Toggle visibility ──────────────────────────────────
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == toggleKey then
            Main.Visible = not Main.Visible
        end
    end)

    -- ── Window object ──────────────────────────────────────
    local Window = {
        _gui        = ScreenGui,
        _main       = Main,
        _topTabs    = TopTabContainer,
        _sidebar    = Sidebar,
        _panelArea  = PanelArea,
        _navItems   = {},
        _panels     = {},
        _activeNav  = nil,
        _configName = title:lower():gsub("%s+","_"),
        _config     = LoadConfig(title:lower():gsub("%s+","_")),
    }

    -- ── Add top profile tabs (Matcha / Comfort / stable) ───
    function Window:AddProfileTab(name, color)
        color = color or Theme.Accent
        local lbl = New("TextLabel", {
            Parent          = self._topTabs,
            BackgroundTransparency = 1,
            Size            = UDim2.new(0, 0, 1, 0),
            AutomaticSize   = Enum.AutomaticSize.X,
            Font            = FONT_SEMI,
            Text            = name,
            TextColor3      = color,
            TextSize        = 13,
        })
        return lbl
    end

    -- Auto-add the title as first profile tab
    Window:AddProfileTab(title, Theme.Accent)

    -- ── AddTab (sidebar nav) ───────────────────────────────
    function Window:AddTab(name)
        local idx = #self._navItems + 1

        -- Nav button
        local NavBtn = New("TextButton", {
            Parent          = self._sidebar,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size            = UDim2.new(1, 0, 0, 28),
            Font            = FONT,
            Text            = name,
            TextColor3      = Theme.Muted,
            TextSize        = 12,
            AutoButtonColor = false,
            LayoutOrder     = idx,
        }, {
            New("UIPadding", { PaddingLeft = UDim.new(0, 12) }),
        })

        local AccentBar = New("Frame", {
            Parent          = NavBtn,
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Position        = UDim2.new(0, 0, 0.1, 0),
            Size            = UDim2.new(0, 2, 0.8, 0),
            Visible         = false,
        }, { New("UICorner", { CornerRadius = UDim.new(0, 2) }) })

        -- Panel scroll frame
        local Panel = New("ScrollingFrame", {
            Parent              = self._panelArea,
            BackgroundTransparency = 1,
            BorderSizePixel     = 0,
            Size                = UDim2.new(1, 0, 1, 0),
            ScrollBarThickness  = 3,
            ScrollBarImageColor3 = Theme.Border,
            CanvasSize          = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible             = false,
        }, {
            New("UIPadding", {
                PaddingLeft   = UDim.new(0, 14),
                PaddingRight  = UDim.new(0, 14),
                PaddingTop    = UDim.new(0, 12),
                PaddingBottom = UDim.new(0, 12),
            }),
            New("UIListLayout", {
                SortOrder   = Enum.SortOrder.LayoutOrder,
                Padding     = UDim.new(0, 6),
            }),
        })

        table.insert(self._navItems, { btn = NavBtn, bar = AccentBar, panel = Panel })
        table.insert(self._panels, Panel)

        -- Click nav
        NavBtn.MouseButton1Click:Connect(function()
            self:_SelectTab(idx)
        end)

        NavBtn.MouseEnter:Connect(function()
            if self._activeNav ~= idx then
                Tween(NavBtn, { TextColor3 = Theme.Text }, 0.1)
            end
        end)
        NavBtn.MouseLeave:Connect(function()
            if self._activeNav ~= idx then
                Tween(NavBtn, { TextColor3 = Theme.Muted }, 0.1)
            end
        end)

        -- Auto select first tab
        if idx == 1 then
            self:_SelectTab(1)
        end

        -- ── Tab object ──────────────────────────────────────
        local Tab = {
            _panel  = Panel,
            _order  = 0,
            _win    = self,
        }

        -- ── Helpers ─────────────────────────────────────────
        local function NextOrder(t)
            t._order = t._order + 1
            return t._order
        end

        local function MakeRow(parent, order)
            return New("Frame", {
                Parent          = parent,
                BackgroundTransparency = 1,
                Size            = UDim2.new(1, 0, 0, 22),
                LayoutOrder     = order,
            })
        end

        -- ── Section label ────────────────────────────────────
        function Tab:AddSection(text)
            New("TextLabel", {
                Parent          = self._panel,
                BackgroundTransparency = 1,
                Size            = UDim2.new(1, 0, 0, 18),
                LayoutOrder     = NextOrder(self),
                Font            = FONT_BOLD,
                Text            = text:upper(),
                TextColor3      = Theme.Muted,
                TextSize        = 10,
                TextXAlignment  = Enum.TextXAlignment.Left,
            })
        end

        -- ── Divider ──────────────────────────────────────────
        function Tab:AddDivider()
            New("Frame", {
                Parent          = self._panel,
                BackgroundColor3 = Theme.Border,
                BorderSizePixel = 0,
                Size            = UDim2.new(1, 0, 0, 1),
                LayoutOrder     = NextOrder(self),
            })
        end

        -- ── Toggle (checkbox) ────────────────────────────────
        function Tab:AddToggle(label, default, callback)
            local key = name .. "_" .. label
            local val = (self._win._config[key] ~= nil) and self._win._config[key] or (default or false)

            local Row = New("Frame", {
                Parent          = self._panel,
                BackgroundTransparency = 1,
                Size            = UDim2.new(1, 0, 0, 22),
                LayoutOrder     = NextOrder(self),
            })

            -- Checkbox box
            local Box = New("Frame", {
                Parent          = Row,
                BackgroundColor3 = val and Theme.Accent or Theme.Surface2,
                BorderSizePixel = 0,
                Position        = UDim2.new(0, 0, 0.5, -7),
                Size            = UDim2.new(0, 14, 0, 14),
            }, {
                New("UICorner", { CornerRadius = UDim.new(0, 3) }),
                New("UIStroke", { Color = val and Theme.Accent or Theme.Border, Thickness = 1.5 }),
            })

            -- Checkmark
            local Check = New("ImageLabel", {
                Parent          = Box,
                BackgroundTransparency = 1,
                Image           = "rbxassetid://10709790644",
                ImageColor3     = Theme.White,
                Size            = UDim2.new(1, -2, 1, -2),
                Position        = UDim2.new(0, 1, 0, 1),
                ImageTransparency = val and 0 or 1,
            })

            New("TextLabel", {
                Parent          = Row,
                BackgroundTransparency = 1,
                Position        = UDim2.new(0, 22, 0, 0),
                Size            = UDim2.new(1, -22, 1, 0),
                Font            = FONT,
                Text            = label,
                TextColor3      = Theme.Text,
                TextSize        = 12,
                TextXAlignment  = Enum.TextXAlignment.Left,
            })

            -- Hover bg
            local HoverBg = New("Frame", {
                Parent          = Row,
                BackgroundColor3 = Theme.Surface2,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size            = UDim2.new(1, 0, 1, 0),
                ZIndex          = 0,
            }, { New("UICorner", { CornerRadius = UDim.new(0, 4) }) })

            local Btn = New("TextButton", {
                Parent          = Row,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size            = UDim2.new(1, 0, 1, 0),
                Text            = "",
                ZIndex          = 2,
            })

            Btn.MouseEnter:Connect(function()
                Tween(HoverBg, { BackgroundTransparency = 0.85 }, 0.1)
            end)
            Btn.MouseLeave:Connect(function()
                Tween(HoverBg, { BackgroundTransparency = 1 }, 0.1)
            end)

            Btn.MouseButton1Click:Connect(function()
                val = not val
                local stroke = Box:FindFirstChildOfClass("UIStroke")
                if val then
                    Tween(Box,   { BackgroundColor3 = Theme.Accent }, 0.12)
                    Tween(Check, { ImageTransparency = 0 }, 0.1)
                    if stroke then stroke.Color = Theme.Accent end
                else
                    Tween(Box,   { BackgroundColor3 = Theme.Surface2 }, 0.12)
                    Tween(Check, { ImageTransparency = 1 }, 0.1)
                    if stroke then stroke.Color = Theme.Border end
                end
                self._win._config[key] = val
                SaveConfig(self._win._configName, self._win._config)
                if callback then callback(val) end
            end)

            -- Returns setter
            return {
                Set = function(v)
                    val = v
                    Btn.MouseButton1Click:Fire()
                end,
                Get = function() return val end,
            }
        end

        -- ── Slider ───────────────────────────────────────────
        function Tab:AddSlider(label, min, max, default, callback)
            local key = name .. "_" .. label
            local val = tonumber(self._win._config[key]) or default or min
            val = math.clamp(val, min, max)

            -- Container (label row + slider row = 40px)
            local Container = New("Frame", {
                Parent          = self._panel,
                BackgroundTransparency = 1,
                Size            = UDim2.new(1, 0, 0, 40),
                LayoutOrder     = NextOrder(self),
            })

            -- Label + value
            New("TextLabel", {
                Parent          = Container,
                BackgroundTransparency = 1,
                Size            = UDim2.new(0.6, 0, 0, 18),
                Font            = FONT,
                Text            = label,
                TextColor3      = Theme.Muted,
                TextSize        = 12,
                TextXAlignment  = Enum.TextXAlignment.Left,
            })

            local ValLabel = New("TextLabel", {
                Parent          = Container,
                BackgroundTransparency = 1,
                Position        = UDim2.new(0.6, 0, 0, 0),
                Size            = UDim2.new(0.4, 0, 0, 18),
                Font            = FONT_SEMI,
                Text            = tostring(math.round(val * 100) / 100),
                TextColor3      = Theme.Text,
                TextSize        = 12,
                TextXAlignment  = Enum.TextXAlignment.Right,
            })

            -- Track
            local Track = New("Frame", {
                Parent          = Container,
                BackgroundColor3 = Theme.Border,
                BorderSizePixel = 0,
                Position        = UDim2.new(0, 0, 0, 24),
                Size            = UDim2.new(1, 0, 0, 3),
            }, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })

            -- Fill
            local pct = (val - min) / (max - min)
            local Fill = New("Frame", {
                Parent          = Track,
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                Size            = UDim2.new(pct, 0, 1, 0),
            }, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })

            -- Thumb
            local Thumb = New("Frame", {
                Parent          = Track,
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                Position        = UDim2.new(pct, -6, 0.5, -6),
                Size            = UDim2.new(0, 12, 0, 12),
                ZIndex          = 2,
            }, {
                New("UICorner", { CornerRadius = UDim.new(1, 0) }),
                New("UIStroke", { Color = Color3.fromRGB(255,255,255), Thickness = 0,
                    Transparency = 0.7 }),
            })

            -- Hit area
            local Hit = New("TextButton", {
                Parent          = Track,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position        = UDim2.new(0, -6, 0, -10),
                Size            = UDim2.new(1, 12, 0, 23),
                Text            = "",
                ZIndex          = 3,
            })

            local sliding = false

            local function SetValue(v)
                v = math.clamp(v, min, max)
                -- round to 2 decimals
                v = math.round(v * 100) / 100
                val = v
                local p = (v - min) / (max - min)
                Fill.Size     = UDim2.new(p, 0, 1, 0)
                Thumb.Position = UDim2.new(p, -6, 0.5, -6)
                ValLabel.Text  = tostring(v)
                self._win._config[key] = v
                SaveConfig(self._win._configName, self._win._config)
                if callback then callback(v) end
            end

            local function HandleInput(input)
                local trackPos  = Track.AbsolutePosition.X
                local trackSize = Track.AbsoluteSize.X
                local rel = math.clamp((input.Position.X - trackPos) / trackSize, 0, 1)
                SetValue(min + rel * (max - min))
            end

            Hit.MouseButton1Down:Connect(function()
                sliding = true
            end)

            UserInputService.InputChanged:Connect(function(input)
                if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                    HandleInput(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    sliding = false
                end
            end)

            return { Set = SetValue, Get = function() return val end }
        end

        -- ── Dropdown ─────────────────────────────────────────
        function Tab:AddDropdown(label, options, callback)
            local key = name .. "_" .. label
            local selected = self._win._config[key] or options[1]
            local open = false

            New("TextLabel", {
                Parent          = self._panel,
                BackgroundTransparency = 1,
                Size            = UDim2.new(1, 0, 0, 16),
                LayoutOrder     = NextOrder(self),
                Font            = FONT,
                Text            = label,
                TextColor3      = Theme.Muted,
                TextSize        = 12,
                TextXAlignment  = Enum.TextXAlignment.Left,
            })

            -- Container (expands when open)
            local DDContainer = New("Frame", {
                Parent          = self._panel,
                BackgroundTransparency = 1,
                Size            = UDim2.new(1, 0, 0, 28),
                LayoutOrder     = NextOrder(self),
                ClipsDescendants = true,
            })

            -- Header button
            local Header = New("TextButton", {
                Parent          = DDContainer,
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel = 0,
                Size            = UDim2.new(1, 0, 0, 28),
                Font            = FONT,
                Text            = "",
                AutoButtonColor = false,
            }, { New("UICorner", { CornerRadius = UDim.new(0, 5) }),
                New("UIStroke", { Color = Theme.Border, Thickness = 1 }) })

            New("TextLabel", {
                Parent          = Header,
                BackgroundTransparency = 1,
                Position        = UDim2.new(0, 10, 0, 0),
                Size            = UDim2.new(1, -30, 1, 0),
                Font            = FONT,
                Text            = selected,
                TextColor3      = Theme.Text,
                TextSize        = 12,
                TextXAlignment  = Enum.TextXAlignment.Left,
                Name            = "SelectedLabel",
            })

            -- Arrow
            local Arrow = New("TextLabel", {
                Parent          = Header,
                BackgroundTransparency = 1,
                Position        = UDim2.new(1, -24, 0, 0),
                Size            = UDim2.new(0, 18, 1, 0),
                Font            = FONT_BOLD,
                Text            = "▾",
                TextColor3      = Theme.Muted,
                TextSize        = 12,
            })

            -- Options list
            local OptionList = New("Frame", {
                Parent          = DDContainer,
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel = 0,
                Position        = UDim2.new(0, 0, 0, 30),
                Size            = UDim2.new(1, 0, 0, #options * 26),
            }, {
                New("UICorner", { CornerRadius = UDim.new(0, 5) }),
                New("UIStroke", { Color = Theme.Border, Thickness = 1 }),
                New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
            })

            for i, opt in ipairs(options) do
                local OptBtn = New("TextButton", {
                    Parent          = OptionList,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size            = UDim2.new(1, 0, 0, 26),
                    Font            = FONT,
                    Text            = opt,
                    TextColor3      = opt == selected and Theme.Accent or Theme.Text,
                    TextSize        = 12,
                    LayoutOrder     = i,
                    AutoButtonColor = false,
                }, { New("UIPadding", { PaddingLeft = UDim.new(0, 10) }) })

                OptBtn.MouseEnter:Connect(function()
                    if opt ~= selected then
                        Tween(OptBtn, { TextColor3 = Theme.Accent }, 0.1)
                    end
                end)
                OptBtn.MouseLeave:Connect(function()
                    if opt ~= selected then
                        Tween(OptBtn, { TextColor3 = Theme.Text }, 0.1)
                    end
                end)

                OptBtn.MouseButton1Click:Connect(function()
                    selected = opt
                    Header:FindFirstChild("SelectedLabel").Text = opt
                    -- reset all option colors
                    for _, child in ipairs(OptionList:GetChildren()) do
                        if child:IsA("TextButton") then
                            child.TextColor3 = child.Text == selected and Theme.Accent or Theme.Text
                        end
                    end
                    -- close
                    open = false
                    Tween(DDContainer, { Size = UDim2.new(1, 0, 0, 28) }, 0.15)
                    Arrow.Text = "▾"
                    self._win._config[key] = selected
                    SaveConfig(self._win._configName, self._win._config)
                    if callback then callback(selected) end
                end)
            end

            Header.MouseButton1Click:Connect(function()
                open = not open
                local targetH = open and (28 + #options * 26 + 4) or 28
                Tween(DDContainer, { Size = UDim2.new(1, 0, 0, targetH) }, 0.15)
                Arrow.Text = open and "▴" or "▾"
            end)

            return {
                Set = function(v)
                    selected = v
                    Header:FindFirstChild("SelectedLabel").Text = v
                end,
                Get = function() return selected end,
            }
        end

        -- ── Button ───────────────────────────────────────────
        function Tab:AddButton(label, callback)
            local Btn = New("TextButton", {
                Parent          = self._panel,
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel = 0,
                Size            = UDim2.new(1, 0, 0, 28),
                LayoutOrder     = NextOrder(self),
                Font            = FONT_SEMI,
                Text            = label,
                TextColor3      = Theme.Text,
                TextSize        = 12,
                AutoButtonColor = false,
            }, {
                New("UICorner", { CornerRadius = UDim.new(0, 5) }),
                New("UIStroke", { Color = Theme.Border, Thickness = 1 }),
            })

            Btn.MouseEnter:Connect(function()
                Tween(Btn, { BackgroundColor3 = Theme.Surface, TextColor3 = Theme.Accent }, 0.1)
                Btn:FindFirstChildOfClass("UIStroke").Color = Theme.Accent
            end)
            Btn.MouseLeave:Connect(function()
                Tween(Btn, { BackgroundColor3 = Theme.Surface2, TextColor3 = Theme.Text }, 0.1)
                Btn:FindFirstChildOfClass("UIStroke").Color = Theme.Border
            end)
            Btn.MouseButton1Down:Connect(function()
                Tween(Btn, { BackgroundColor3 = Theme.AccentDark }, 0.08)
            end)
            Btn.MouseButton1Up:Connect(function()
                Tween(Btn, { BackgroundColor3 = Theme.Surface2 }, 0.1)
            end)
            Btn.MouseButton1Click:Connect(function()
                if callback then callback() end
            end)
        end

        -- ── Keybind ──────────────────────────────────────────
        function Tab:AddKeybind(label, default, callback)
            local key = name .. "_kb_" .. label
            local currentKey = self._win._config[key] or default or Enum.KeyCode.Unknown
            local listening = false

            local Row = New("Frame", {
                Parent          = self._panel,
                BackgroundTransparency = 1,
                Size            = UDim2.new(1, 0, 0, 22),
                LayoutOrder     = NextOrder(self),
            })

            New("TextLabel", {
                Parent          = Row,
                BackgroundTransparency = 1,
                Size            = UDim2.new(0.7, 0, 1, 0),
                Font            = FONT,
                Text            = label,
                TextColor3      = Theme.Muted,
                TextSize        = 12,
                TextXAlignment  = Enum.TextXAlignment.Left,
            })

            local KeyBtn = New("TextButton", {
                Parent          = Row,
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel = 0,
                Position        = UDim2.new(0.7, 0, 0.1, 0),
                Size            = UDim2.new(0.3, 0, 0.8, 0),
                Font            = FONT,
                Text            = tostring(currentKey.Name),
                TextColor3      = Theme.Text,
                TextSize        = 10,
                AutoButtonColor = false,
            }, {
                New("UICorner", { CornerRadius = UDim.new(0, 3) }),
                New("UIStroke", { Color = Theme.Border, Thickness = 1 }),
            })

            KeyBtn.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                KeyBtn.Text = "..."
                KeyBtn.TextColor3 = Theme.Accent
                local conn
                conn = UserInputService.InputBegan:Connect(function(input, gpe)
                    if gpe then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = input.KeyCode
                        KeyBtn.Text = input.KeyCode.Name
                        KeyBtn.TextColor3 = Theme.Text
                        listening = false
                        conn:Disconnect()
                        self._win._config[key] = input.KeyCode.Name
                        SaveConfig(self._win._configName, self._win._config)
                        if callback then callback(input.KeyCode) end
                    end
                end)
            end)

            return {
                Get = function() return currentKey end,
            }
        end

        -- ── ColorPicker (simple inline swatches) ─────────────
        function Tab:AddColorPicker(label, colors, default, callback)
            colors = colors or {
                Color3.new(1,1,1),
                Color3.fromRGB(232,71,139),
                Color3.fromRGB(100,200,255),
                Color3.fromRGB(100,220,100),
                Color3.fromRGB(255,180,50),
            }
            local selected = default or colors[1]

            New("TextLabel", {
                Parent          = self._panel,
                BackgroundTransparency = 1,
                Size            = UDim2.new(1, 0, 0, 16),
                LayoutOrder     = NextOrder(self),
                Font            = FONT,
                Text            = label,
                TextColor3      = Theme.Muted,
                TextSize        = 12,
                TextXAlignment  = Enum.TextXAlignment.Left,
            })

            local Row = New("Frame", {
                Parent          = self._panel,
                BackgroundTransparency = 1,
                Size            = UDim2.new(1, 0, 0, 22),
                LayoutOrder     = NextOrder(self),
            }, {
                New("UIListLayout", {
                    FillDirection   = Enum.FillDirection.Horizontal,
                    Padding         = UDim.new(0, 5),
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                }),
            })

            local swatches = {}
            for _, c in ipairs(colors) do
                local swatch = New("TextButton", {
                    Parent          = Row,
                    BackgroundColor3 = c,
                    BorderSizePixel = 0,
                    Size            = UDim2.new(0, 20, 0, 20),
                    Text            = "",
                    AutoButtonColor = false,
                }, {
                    New("UICorner", { CornerRadius = UDim.new(0, 3) }),
                    New("UIStroke", {
                        Color     = c == selected and Theme.White or Theme.Bg,
                        Thickness = 1.5,
                    }),
                })
                table.insert(swatches, { btn = swatch, color = c })

                swatch.MouseButton1Click:Connect(function()
                    selected = c
                    for _, s in ipairs(swatches) do
                        s.btn:FindFirstChildOfClass("UIStroke").Color =
                            s.color == selected and Theme.White or Theme.Bg
                    end
                    if callback then callback(c) end
                end)
            end
        end

        -- ── Label (read-only text row) ────────────────────────
        function Tab:AddLabel(text)
            New("TextLabel", {
                Parent          = self._panel,
                BackgroundTransparency = 1,
                Size            = UDim2.new(1, 0, 0, 18),
                LayoutOrder     = NextOrder(self),
                Font            = FONT,
                Text            = text,
                TextColor3      = Theme.Muted,
                TextSize        = 12,
                TextXAlignment  = Enum.TextXAlignment.Left,
                TextWrapped     = true,
            })
        end

        -- ── TextBox input ─────────────────────────────────────
        function Tab:AddTextbox(label, placeholder, callback)
            New("TextLabel", {
                Parent          = self._panel,
                BackgroundTransparency = 1,
                Size            = UDim2.new(1, 0, 0, 16),
                LayoutOrder     = NextOrder(self),
                Font            = FONT,
                Text            = label,
                TextColor3      = Theme.Muted,
                TextSize        = 12,
                TextXAlignment  = Enum.TextXAlignment.Left,
            })

            local Box = New("TextBox", {
                Parent          = self._panel,
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel = 0,
                Size            = UDim2.new(1, 0, 0, 28),
                LayoutOrder     = NextOrder(self),
                Font            = FONT,
                PlaceholderText = placeholder or "",
                Text            = "",
                TextColor3      = Theme.Text,
                PlaceholderColor3 = Theme.Muted,
                TextSize        = 12,
                ClearTextOnFocus = false,
            }, {
                New("UICorner", { CornerRadius = UDim.new(0, 5) }),
                New("UIStroke", { Color = Theme.Border, Thickness = 1, Name = "Stroke" }),
                New("UIPadding", { PaddingLeft = UDim.new(0, 8) }),
            })

            Box.Focused:Connect(function()
                Box:FindFirstChild("Stroke").Color = Theme.Accent
            end)
            Box.FocusLost:Connect(function(enter)
                Box:FindFirstChild("Stroke").Color = Theme.Border
                if callback then callback(Box.Text, enter) end
            end)
        end

        return Tab
    end

    -- ── Internal tab select ────────────────────────────────
    function Window:_SelectTab(idx)
        self._activeNav = idx
        for i, item in ipairs(self._navItems) do
            local active = i == idx
            item.bar.Visible = active
            Tween(item.btn, {
                TextColor3 = active and Theme.Accent or Theme.Muted
            }, 0.12)
            if active then
                item.btn.BackgroundTransparency = 0
                item.btn.BackgroundColor3 = Color3.fromRGB(232,71,139)
                Tween(item.btn, { BackgroundTransparency = 0.92 }, 0.1)
            else
                Tween(item.btn, { BackgroundTransparency = 1 }, 0.1)
            end
            item.panel.Visible = active
        end
    end

    return Window
end

-- ══════════════════════════════════════════════════════════
return MatcaUI
--
-- ─── QUICK START ───────────────────────────────────────────
--
-- local MatcaUI = loadstring(game:HttpGet("RAW_URL"))()
--
-- local Win = MatcaUI:CreateWindow("Matcha", "username", Enum.KeyCode.Insert)
-- Win:AddProfileTab("Comfort")
-- Win:AddProfileTab("stable", Color3.fromRGB(111,186,111))
--
-- local Combat = Win:AddTab("Combat")
-- Combat:AddSection("FOV")
-- Combat:AddToggle("Enabled", true, function(v) print("enabled:", v) end)
-- Combat:AddToggle("Glow", false, function(v) end)
-- Combat:AddSlider("Size", 1, 150, 54, function(v) print("fov:", v) end)
-- Combat:AddDropdown("Style", {"Smooth","Snap","Raw","Linear"}, function(v) print(v) end)
--
-- local Combat2 = Win:AddTab("Visuals")
-- Combat2:AddSection("Trigger Bot")
-- Combat2:AddToggle("Enabled", false, function(v) end)
-- Combat2:AddSlider("Hitbox Mul", 0.5, 3, 1, function(v) end)
-- Combat2:AddSlider("Delay (ms)", 0, 200, 1, function(v) end)
-- Combat2:AddKeybind("Trigger Key", Enum.KeyCode.Q, function(k) print(k) end)
--
-- local Opts = Win:AddTab("Options")
-- Opts:AddButton("Save Config", function() print("saved") end)
-- Opts:AddButton("Reset Config", function() print("reset") end)

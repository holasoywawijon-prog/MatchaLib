--[[
	NovaUI - Roblox UI Library
	Estilo: fondo oscuro, barra de acento lateral, tabs superiores,
	secciones con cuadro de fondo, barra de stats (juego | fps | ms | data)
	y sistema de notificaciones.

	Uso básico:
		local NovaUI = loadstring(game:HttpGet("URL_RAW"))()
		local Window = NovaUI:CreateWindow("Title")
		local Tab1 = Window:CreateTab("Tab 1")
		local Section1 = Tab1:CreateSection("Section 1")
		Section1:AddCheckbox("Enabled", false, function(value) end)
		Section1:AddSlider("Slider", 0, 30, 0, function(value) end)
		Section1:AddDropdown("Dropdown", {"Option 1","Option 2"}, "Option 1", function(value) end)

		NovaUI:Notify({Title = "Saved", Content = "Settings saved.", Duration = 4})
]]

local NovaUI = {}
NovaUI.__index = NovaUI

-- ============ CONFIG DE ESTILO ============
local Theme = {
	Background      = Color3.fromRGB(27, 27, 27),   -- fondo principal
	HeaderBg        = Color3.fromRGB(22, 22, 22),   -- barra de título
	StatsBarBg      = Color3.fromRGB(18, 18, 18),   -- barra superior de stats
	TabBarBg        = Color3.fromRGB(30, 30, 30),
	SectionBg       = Color3.fromRGB(33, 33, 33),   -- cuadro de fondo de la sección
	SectionHeaderBg = Color3.fromRGB(42, 42, 42),
	ElementBg       = Color3.fromRGB(46, 46, 46),
	CheckboxBg      = Color3.fromRGB(22, 22, 22),
	AccentDark      = Color3.fromRGB(58, 13, 13),   -- rojo oscuro (arriba de la barra)
	AccentBar       = Color3.fromRGB(199, 58, 58),  -- rojo medio
	AccentBright    = Color3.fromRGB(224, 75, 75),  -- rojo brillante (abajo de la barra)
	TextPrimary     = Color3.fromRGB(234, 234, 234),
	TextSecondary   = Color3.fromRGB(154, 154, 154),
	TextDisabled    = Color3.fromRGB(110, 110, 110),
	Stroke          = Color3.fromRGB(16, 16, 16),
	Success         = Color3.fromRGB(90, 200, 120),
	Error           = Color3.fromRGB(220, 90, 90),
	Font            = Enum.Font.GothamBold,
	FontRegular     = Enum.Font.Gotham,
}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local TextService = game:GetService("TextService")

local function measureText(text, size, font)
	local ok, bounds = pcall(function()
		return TextService:GetTextSize(text, size, font, Vector2.new(1000, 100))
	end)
	if ok then
		return bounds.X
	end
	return #text * (size * 0.6) -- fallback estimado si GetTextSize falla
end

-- ============ HELPERS ============
local function create(class, props)
	local inst = Instance.new(class)
	for prop, value in pairs(props) do
		inst[prop] = value
	end
	return inst
end

local function gradient(frame, colorSequence, rotation)
	create("UIGradient", {
		Color = colorSequence,
		Rotation = rotation or 90,
		Parent = frame,
	})
end

local function makeDraggable(topBar, frame)
	local dragging, dragInput, dragStart, startPos

	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	topBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
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

-- ============ ROOT SCREENGUI (compartido por ventana y notificaciones) ============
local RootGui = nil
local function getRootGui()
	if RootGui and RootGui.Parent then
		return RootGui
	end
	RootGui = create("ScreenGui", {
		Name = "NovaUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = (gethui and gethui()) or game:GetService("CoreGui"),
	})
	return RootGui
end

-- ============ SISTEMA DE NOTIFICACIONES ============
local NotifHolder = nil
local function getNotifHolder()
	if NotifHolder and NotifHolder.Parent then
		return NotifHolder
	end
	NotifHolder = create("Frame", {
		Name = "Notifications",
		Size = UDim2.new(0, 260, 1, -20),
		Position = UDim2.new(1, -270, 0, 10),
		BackgroundTransparency = 1,
		Parent = getRootGui(),
	})
	create("UIListLayout", {
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = NotifHolder,
	})
	return NotifHolder
end

-- opts: { Title, Content, Duration, Type = "Info"|"Success"|"Error" }
function NovaUI:Notify(opts)
	opts = opts or {}
	local holder = getNotifHolder()

	local accent = Theme.AccentBar
	if opts.Type == "Success" then accent = Theme.Success end
	if opts.Type == "Error" then accent = Theme.Error end

	local Toast = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.SectionBg,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = os.clock() * 1000,
		Parent = holder,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = Toast })
	create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Parent = Toast })

	local Bar = create("Frame", {
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Parent = Toast,
	})

	local TextHolder = create("Frame", {
		Size = UDim2.new(1, -16, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		Parent = Toast,
	})
	create("UIListLayout", {
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = TextHolder,
	})
	create("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		Parent = TextHolder,
	})

	create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Text = opts.Title or "Notification",
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = Theme.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
		Parent = TextHolder,
	})

	if opts.Content then
		create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = opts.Content,
			Font = Theme.FontRegular,
			TextSize = 12,
			TextColor3 = Theme.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			LayoutOrder = 2,
			Parent = TextHolder,
		})
	end

	Toast.BackgroundTransparency = 1
	Bar.BackgroundTransparency = 1
	for _, child in ipairs(TextHolder:GetChildren()) do
		if child:IsA("TextLabel") then child.TextTransparency = 1 end
	end

	TweenService:Create(Toast, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
	TweenService:Create(Bar, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
	for _, child in ipairs(TextHolder:GetChildren()) do
		if child:IsA("TextLabel") then
			TweenService:Create(child, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
		end
	end

	task.delay(opts.Duration or 4, function()
		if not Toast.Parent then return end
		TweenService:Create(Toast, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(Bar, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
		for _, child in ipairs(TextHolder:GetChildren()) do
			if child:IsA("TextLabel") then
				TweenService:Create(child, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
			end
		end
		task.wait(0.25)
		Toast:Destroy()
	end)
end

-- ============ WINDOW ============
function NovaUI:CreateWindow(title)
	local ScreenGui = getRootGui()

	local Main = create("Frame", {
		Name = "Main",
		Size = UDim2.new(0, 430, 0, 510),
		Position = UDim2.new(0.5, -215, 0.5, -255),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		Parent = ScreenGui,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Main })
	create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Parent = Main })
	create("UIPadding", {}) -- no-op placeholder kept out; Main clips children via ClipsDescendants below
	Main.ClipsDescendants = true

	-- ============ BARRA DE STATS (juego | fps | ms | data) ============
	local StatsBar = create("Frame", {
		Name = "StatsBar",
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundColor3 = Theme.StatsBarBg,
		BorderSizePixel = 0,
		Parent = Main,
	})
	local StatsLabel = create("TextLabel", {
		Name = "StatsLabel",
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		Font = Theme.FontRegular,
		TextSize = 11,
		TextColor3 = Theme.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = StatsBar,
	})

	do
		local frameCount, lastClock, fps = 0, os.clock(), 0
		local heartbeatConn
		heartbeatConn = RunService.Heartbeat:Connect(function()
			frameCount = frameCount + 1
			local now = os.clock()
			if now - lastClock >= 1 then
				fps = frameCount
				frameCount = 0
				lastClock = now

				local ok, ping = pcall(function()
					return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
				end)
				ping = ok and ping or 0

				local dataOk, dataKbps = pcall(function()
					return Stats.DataReceiveKbps + Stats.DataSendKbps
				end)
				local dataStr = dataOk and (string.format("%.1f KB/s", dataKbps)) or "0 KB/s"

				local gameName = "Game"
				pcall(function() gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end)

				StatsLabel.Text = string.format("%s | %d FPS | %d ms | %s", gameName, fps, ping, dataStr)
			end
			if not StatsBar.Parent then
				heartbeatConn:Disconnect()
			end
		end)
	end

	-- Barra de acento lateral (roja, degradado) - debajo de header + tabs
	local AccentBar = create("Frame", {
		Name = "AccentBar",
		Size = UDim2.new(0, 4, 1, -92),
		Position = UDim2.new(0, 0, 0, 92),
		BackgroundColor3 = Theme.AccentBar,
		BorderSizePixel = 0,
		Parent = Main,
	})
	gradient(AccentBar, ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.AccentDark),
		ColorSequenceKeypoint.new(0.6, Theme.AccentBar),
		ColorSequenceKeypoint.new(1, Theme.AccentBright),
	}), 90)

	-- Header / Título
	local Header = create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 36),
		Position = UDim2.new(0, 0, 0, 22),
		BackgroundColor3 = Theme.HeaderBg,
		BorderSizePixel = 0,
		Parent = Main,
	})

	local TitleLabel = create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = title or "Title",
		TextColor3 = Theme.TextPrimary,
		Font = Theme.Font,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Header,
	})

	makeDraggable(StatsBar, Main)
	makeDraggable(Header, Main)

	-- Barra de Tabs
	local TabBar = create("Frame", {
		Name = "TabBar",
		Size = UDim2.new(1, 0, 0, 34),
		Position = UDim2.new(0, 0, 0, 58),
		BackgroundColor3 = Theme.TabBarBg,
		BorderSizePixel = 0,
		Parent = Main,
	})
	create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = Theme.Stroke,
		BorderSizePixel = 0,
		Parent = TabBar,
	})

	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 4),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = TabBar,
	})
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 14),
		Parent = TabBar,
	})

	-- Contenedor de contenido de tabs
	local ContentArea = create("Frame", {
		Name = "ContentArea",
		Size = UDim2.new(1, -4, 1, -92),
		Position = UDim2.new(0, 4, 0, 92),
		BackgroundTransparency = 1,
		Parent = Main,
	})

	local Window = setmetatable({}, { __index = self })
	Window.ScreenGui = ScreenGui
	Window.Main = Main
	Window.TabBar = TabBar
	Window.ContentArea = ContentArea
	Window.Tabs = {}
	Window._firstTab = nil
	Window.Overlays = {} -- listas de dropdown u otros elementos parentados fuera de Main

	-- ============ TAB ============
	function Window:CreateTab(tabName)
		local textWidth = measureText(tabName, 13, Theme.Font)
		local buttonWidth = math.ceil(textWidth) + 16 -- padding horizontal total

		local TabButton = create("TextButton", {
			Name = tabName,
			Size = UDim2.new(0, buttonWidth, 1, 0),
			BackgroundTransparency = 1,
			Text = "",
			Parent = TabBar,
		})
		local TabLabel = create("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = tabName,
			Font = Theme.Font,
			TextSize = 13,
			TextColor3 = Theme.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = TabButton,
		})

		local TabPage = create("ScrollingFrame", {
			Name = tabName .. "_Page",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.AccentBar,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
			Parent = ContentArea,
		})
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = TabPage,
		})
		create("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 10),
			Parent = TabPage,
		})

		local Tab = {}
		Tab.Button = TabButton
		Tab.Label = TabLabel
		Tab.Page = TabPage
		Tab.Columns = {}

		local function selectTab()
			for _, t in pairs(Window.Tabs) do
				t.Page.Visible = false
				t.Label.TextColor3 = Theme.TextSecondary
			end
			TabPage.Visible = true
			TabLabel.TextColor3 = Theme.TextPrimary
		end

		TabButton.MouseButton1Click:Connect(selectTab)

		-- ============ SECTION (columna dentro del tab, con cuadro de fondo) ============
		function Tab:CreateSection(sectionName)
			local Column = create("Frame", {
				Name = sectionName,
				Size = UDim2.new(0, 200, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Theme.SectionBg,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				LayoutOrder = #Tab.Columns + 1,
				Parent = TabPage,
			})
			create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Column })
			create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Parent = Column })

			local ColLayout = create("UIListLayout", {
				Padding = UDim.new(0, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = Column,
			})

			local SectionHeader = create("Frame", {
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundColor3 = Theme.SectionHeaderBg,
				BorderSizePixel = 0,
				LayoutOrder = 1,
				Parent = Column,
			})
			create("TextLabel", {
				Size = UDim2.new(1, -16, 1, 0),
				Position = UDim2.new(0, 8, 0, 0),
				BackgroundTransparency = 1,
				Text = sectionName,
				Font = Theme.Font,
				TextSize = 13,
				TextColor3 = Theme.TextPrimary,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = SectionHeader,
			})

			local Body = create("Frame", {
				Name = "Body",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 2,
				Parent = Column,
			})
			create("UIListLayout", {
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = Body,
			})
			create("UIPadding", {
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
				Parent = Body,
			})

			local Section = {}
			local elementOrder = 0
			local function nextOrder()
				elementOrder = elementOrder + 1
				return elementOrder
			end

			-- ---- Checkbox ----
			function Section:AddCheckbox(text, default, callback)
				local Holder = create("TextButton", {
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					Text = "",
					LayoutOrder = nextOrder(),
					Parent = Body,
				})

				local Box = create("Frame", {
					Size = UDim2.new(0, 16, 0, 16),
					Position = UDim2.new(0, 0, 0.5, -8),
					BackgroundColor3 = Theme.CheckboxBg,
					BorderSizePixel = 0,
					Parent = Holder,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = Box })
				create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Parent = Box })

				local Check = create("Frame", {
					Size = UDim2.new(1, -6, 1, -6),
					Position = UDim2.new(0, 3, 0, 3),
					BackgroundColor3 = Theme.AccentBar,
					BorderSizePixel = 0,
					Visible = default or false,
					Parent = Box,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = Check })

				create("TextLabel", {
					Size = UDim2.new(1, -24, 1, 0),
					Position = UDim2.new(0, 24, 0, 0),
					BackgroundTransparency = 1,
					Text = text,
					Font = Theme.FontRegular,
					TextSize = 13,
					TextColor3 = Theme.TextPrimary,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = Holder,
				})

				local value = default or false
				Holder.MouseButton1Click:Connect(function()
					value = not value
					Check.Visible = value
					if callback then callback(value) end
				end)

				return {
					Set = function(_, v)
						value = v
						Check.Visible = v
					end,
					Get = function() return value end,
				}
			end

			-- ---- Slider ----
			function Section:AddSlider(text, min, max, default, callback)
				min, max = min or 0, max or 100
				default = math.clamp(default or min, min, max)

				local SliderFrame = create("Frame", {
					Size = UDim2.new(1, 0, 0, 22),
					BackgroundColor3 = Theme.ElementBg,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					LayoutOrder = nextOrder(),
					Parent = Body,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = SliderFrame })

				local Fill = create("Frame", {
					Name = "Fill",
					Size = UDim2.new((default - min) / math.max(max - min, 1), 0, 1, 0),
					BackgroundColor3 = Theme.AccentBar,
					BackgroundTransparency = 0.55,
					BorderSizePixel = 0,
					ZIndex = 1,
					Parent = SliderFrame,
				})

				local Label = create("TextLabel", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = text .. ": " .. tostring(default) .. "/" .. tostring(max),
					Font = Theme.FontRegular,
					TextSize = 12,
					TextColor3 = Theme.TextPrimary,
					ZIndex = 2,
					Parent = SliderFrame,
				})

				local dragging = false
				local value = default

				local function updateFromX(xPos)
					local rel = math.clamp((xPos - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X, 0, 1)
					value = math.floor(min + rel * (max - min) + 0.5)
					Fill.Size = UDim2.new((value - min) / math.max(max - min, 1), 0, 1, 0)
					Label.Text = text .. ": " .. tostring(value) .. "/" .. tostring(max)
					if callback then callback(value) end
				end

				SliderFrame.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = true
						updateFromX(input.Position.X)
					end
				end)
				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = false
					end
				end)
				UserInputService.InputChanged:Connect(function(input)
					if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						updateFromX(input.Position.X)
					end
				end)

				return {
					Set = function(_, v)
						value = math.clamp(v, min, max)
						Fill.Size = UDim2.new((value - min) / math.max(max - min, 1), 0, 1, 0)
						Label.Text = text .. ": " .. tostring(value) .. "/" .. tostring(max)
					end,
					Get = function() return value end,
				}
			end

			-- ---- Dropdown ----
			function Section:AddDropdown(text, options, default, callback)
				options = options or {}

				local Container = create("Frame", {
					Size = UDim2.new(1, 0, 0, 42),
					BackgroundTransparency = 1,
					LayoutOrder = nextOrder(),
					Parent = Body,
				})

				create("TextLabel", {
					Size = UDim2.new(1, 0, 0, 16),
					BackgroundTransparency = 1,
					Text = text,
					Font = Theme.FontRegular,
					TextSize = 13,
					TextColor3 = Theme.TextPrimary,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = Container,
				})

				local Box = create("TextButton", {
					Size = UDim2.new(1, 0, 0, 22),
					Position = UDim2.new(0, 0, 0, 18),
					BackgroundColor3 = Theme.ElementBg,
					BorderSizePixel = 0,
					Text = "",
					AutoButtonColor = false,
					ZIndex = 4,
					Parent = Container,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = Box })

				local SelectedLabel = create("TextLabel", {
					Size = UDim2.new(1, -26, 1, 0),
					Position = UDim2.new(0, 8, 0, 0),
					BackgroundTransparency = 1,
					Text = default or "NONE",
					Font = Theme.FontRegular,
					TextSize = 12,
					TextColor3 = Theme.TextSecondary,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 4,
					Parent = Box,
				})

				create("TextLabel", {
					Size = UDim2.new(0, 20, 1, 0),
					Position = UDim2.new(1, -22, 0, 0),
					BackgroundTransparency = 1,
					Text = "▼",
					Font = Theme.FontRegular,
					TextSize = 10,
					TextColor3 = Theme.TextSecondary,
					ZIndex = 4,
					Parent = Box,
				})

				-- La lista se parentea directamente al ScreenGui (no a Box/Main) para que no quede
				-- recortada por el ClipsDescendants de la sección, ni por el ScrollingFrame del tab,
				-- ni por el ClipsDescendants de la ventana principal.
				local ListFrame = create("Frame", {
					Name = "DropdownList",
					Size = UDim2.new(0, 0, 0, #options * 20),
					BackgroundColor3 = Theme.ElementBg,
					BorderSizePixel = 0,
					Visible = false,
					ZIndex = 50,
					Parent = ScreenGui,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = ListFrame })
				create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Parent = ListFrame })
				create("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Parent = ListFrame,
				})

				local value = default
				for i, opt in ipairs(options) do
					local OptButton = create("TextButton", {
						Size = UDim2.new(1, 0, 0, 20),
						BackgroundTransparency = 1,
						Text = opt,
						Font = Theme.FontRegular,
						TextSize = 12,
						TextColor3 = Theme.TextPrimary,
						ZIndex = 51,
						AutoButtonColor = false,
						LayoutOrder = i,
						Parent = ListFrame,
					})
					OptButton.MouseButton1Click:Connect(function()
						value = opt
						SelectedLabel.Text = opt
						ListFrame.Visible = false
						if callback then callback(value) end
					end)
				end

				table.insert(Window.Overlays, ListFrame)

				local function openList()
					-- Posiciona la lista justo debajo de la caja, en coordenadas absolutas de pantalla
					local boxPos = Box.AbsolutePosition
					ListFrame.Position = UDim2.new(0, boxPos.X, 0, boxPos.Y + Box.AbsoluteSize.Y + 2)
					ListFrame.Size = UDim2.new(0, Box.AbsoluteSize.X, 0, #options * 20)
					ListFrame.Visible = not ListFrame.Visible
				end

				Box.MouseButton1Click:Connect(openList)

				-- Cierra la lista si se hace click fuera de ella y de la caja
				UserInputService.InputBegan:Connect(function(input, processed)
					if not ListFrame.Visible then return end
					if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
					local pos = input.Position
					local inBox = pos.X >= Box.AbsolutePosition.X and pos.X <= Box.AbsolutePosition.X + Box.AbsoluteSize.X
						and pos.Y >= Box.AbsolutePosition.Y and pos.Y <= Box.AbsolutePosition.Y + Box.AbsoluteSize.Y
					local inList = pos.X >= ListFrame.AbsolutePosition.X and pos.X <= ListFrame.AbsolutePosition.X + ListFrame.AbsoluteSize.X
						and pos.Y >= ListFrame.AbsolutePosition.Y and pos.Y <= ListFrame.AbsolutePosition.Y + ListFrame.AbsoluteSize.Y
					if not inBox and not inList then
						ListFrame.Visible = false
					end
				end)

				return {
					Set = function(_, v)
						value = v
						SelectedLabel.Text = v
					end,
					Get = function() return value end,
				}
			end

			-- ---- Button ----
			function Section:AddButton(text, callback)
				local Btn = create("TextButton", {
					Size = UDim2.new(1, 0, 0, 22),
					BackgroundColor3 = Theme.ElementBg,
					BorderSizePixel = 0,
					Text = text,
					Font = Theme.FontRegular,
					TextSize = 12,
					TextColor3 = Theme.TextPrimary,
					AutoButtonColor = false,
					LayoutOrder = nextOrder(),
					Parent = Body,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = Btn })
				Btn.MouseButton1Click:Connect(function()
					if callback then callback() end
				end)
				return Btn
			end

			table.insert(Tab.Columns, Column)
			return Section
		end

		table.insert(Window.Tabs, Tab)
		if not Window._firstTab then
			Window._firstTab = Tab
			selectTab()
		end

		return Tab
	end

	function Window:Toggle()
		Main.Visible = not Main.Visible
	end

	function Window:Destroy()
		for _, overlay in ipairs(Window.Overlays) do
			if overlay and overlay.Parent then
				overlay:Destroy()
			end
		end
		Main:Destroy()
	end

	return Window
end

return NovaUI

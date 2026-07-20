--[[
	NovaUI - Roblox UI Library
	Estilo: fondo oscuro, barra de acento lateral, tabs superiores,
	secciones con checkbox / slider / dropdown.

	Uso básico:
		local NovaUI = loadstring(game:HttpGet("URL_RAW"))()
		local Window = NovaUI:CreateWindow("Title")
		local Tab1 = Window:CreateTab("Tab 1")
		local Section1 = Tab1:CreateSection("Section 1")
		Section1:AddCheckbox("Enabled", false, function(value) end)
		Section1:AddSlider("Slider", 0, 30, 0, function(value) end)
		Section1:AddDropdown("Dropdown", {"Option 1","Option 2"}, "Option 1", function(value) end)
]]

local NovaUI = {}
NovaUI.__index = NovaUI

-- ============ CONFIG DE ESTILO ============
local Theme = {
	Background      = Color3.fromRGB(30, 30, 30),   -- fondo principal
	HeaderBg        = Color3.fromRGB(24, 24, 24),   -- barra de título
	TabBarBg        = Color3.fromRGB(27, 27, 27),
	SectionHeaderBg = Color3.fromRGB(38, 38, 38),
	ElementBg       = Color3.fromRGB(45, 45, 45),
	AccentBar       = Color3.fromRGB(200, 40, 40),  -- barra roja lateral
	TextPrimary     = Color3.fromRGB(235, 235, 235),
	TextSecondary   = Color3.fromRGB(160, 160, 160),
	TextDisabled    = Color3.fromRGB(110, 110, 110),
	Stroke          = Color3.fromRGB(15, 15, 15),
	CheckboxBg      = Color3.fromRGB(20, 20, 20),
	Font            = Enum.Font.GothamBold,
	FontRegular     = Enum.Font.Gotham,
}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- ============ HELPERS ============
local function create(class, props)
	local inst = Instance.new(class)
	for prop, value in pairs(props) do
		inst[prop] = value
	end
	return inst
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

-- ============ WINDOW ============
function NovaUI:CreateWindow(title)
	local ScreenGui = create("ScreenGui", {
		Name = "NovaUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = (gethui and gethui()) or game:GetService("CoreGui"),
	})

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

	-- Barra de acento lateral (roja) - ocupa el lado izquierdo, debajo del header
	local AccentBar = create("Frame", {
		Name = "AccentBar",
		Size = UDim2.new(0, 4, 1, -70),
		Position = UDim2.new(0, 0, 0, 70),
		BackgroundColor3 = Theme.AccentBar,
		BorderSizePixel = 0,
		Parent = Main,
	})

	-- Header / Título
	local Header = create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = Theme.HeaderBg,
		BorderSizePixel = 0,
		Parent = Main,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Header })
	-- Cubrir esquinas inferiores del header para que no se redondeen
	create("Frame", {
		Size = UDim2.new(1, 0, 0, 10),
		Position = UDim2.new(0, 0, 1, -10),
		BackgroundColor3 = Theme.HeaderBg,
		BorderSizePixel = 0,
		ZIndex = 0,
		Parent = Header,
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

	makeDraggable(Header, Main)

	-- Barra de Tabs
	local TabBar = create("Frame", {
		Name = "TabBar",
		Size = UDim2.new(1, 0, 0, 34),
		Position = UDim2.new(0, 0, 0, 36),
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

	local TabButtonsLayout = create("UIListLayout", {
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
		Size = UDim2.new(1, -4, 1, -70),
		Position = UDim2.new(0, 4, 0, 70),
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

	-- ============ TAB ============
	function Window:CreateTab(tabName)
		local TabButton = create("TextButton", {
			Name = tabName,
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Text = "",
			Parent = TabBar,
		})
		create("UIPadding", {
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 12),
			Parent = TabButton,
		})
		local TabLabel = create("TextLabel", {
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Text = tabName,
			Font = Theme.Font,
			TextSize = 13,
			TextColor3 = Theme.TextSecondary,
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
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = TabPage,
		})
		create("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 8),
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

		-- ============ SECTION (columna dentro del tab) ============
		function Tab:CreateSection(sectionName)
			local Column = create("Frame", {
				Name = sectionName,
				Size = UDim2.new(0, 195, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = #Tab.Columns + 1,
				Parent = TabPage,
			})
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
			create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = SectionHeader })
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
			local BodyLayout = create("UIListLayout", {
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = Body,
			})
			create("UIPadding", {
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 4),
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
					LayoutOrder = nextOrder(),
					Parent = Body,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = SliderFrame })

				local Fill = create("Frame", {
					Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
					BackgroundColor3 = Theme.AccentBar,
					BackgroundTransparency = 0.75,
					BorderSizePixel = 0,
					Parent = SliderFrame,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Fill })

				local Label = create("TextLabel", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = text .. ": " .. tostring(default) .. "/" .. tostring(max),
					Font = Theme.FontRegular,
					TextSize = 12,
					TextColor3 = Theme.TextPrimary,
					Parent = SliderFrame,
				})

				local dragging = false
				local value = default

				local function updateFromX(xPos)
					local rel = math.clamp((xPos - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X, 0, 1)
					value = math.floor(min + rel * (max - min) + 0.5)
					Fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
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
						Fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
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
					Parent = Container,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Box })

				local SelectedLabel = create("TextLabel", {
					Size = UDim2.new(1, -26, 1, 0),
					Position = UDim2.new(0, 8, 0, 0),
					BackgroundTransparency = 1,
					Text = default or "NONE",
					Font = Theme.FontRegular,
					TextSize = 12,
					TextColor3 = Theme.TextSecondary,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = Box,
				})

				local Arrow = create("TextLabel", {
					Size = UDim2.new(0, 20, 1, 0),
					Position = UDim2.new(1, -22, 0, 0),
					BackgroundTransparency = 1,
					Text = "▼",
					Font = Theme.FontRegular,
					TextSize = 10,
					TextColor3 = Theme.TextSecondary,
					Parent = Box,
				})

				local ListFrame = create("Frame", {
					Size = UDim2.new(1, 0, 0, #options * 20),
					Position = UDim2.new(0, 0, 1, 2),
					BackgroundColor3 = Theme.ElementBg,
					BorderSizePixel = 0,
					Visible = false,
					ZIndex = 5,
					Parent = Box,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = ListFrame })
				local ListLayout = create("UIListLayout", {
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
						ZIndex = 5,
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

				Box.MouseButton1Click:Connect(function()
					ListFrame.Visible = not ListFrame.Visible
				end)

				return {
					Set = function(_, v)
						value = v
						SelectedLabel.Text = v
					end,
					Get = function() return value end,
				}
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
		ScreenGui:Destroy()
	end

	return Window
end

return NovaUI

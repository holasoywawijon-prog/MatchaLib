
--[[
    MatchaLib - Roblox UI Library
    Layout: Horizontal tabs (top) + two-column content
    Style: Dark + Pink/Magenta (Matcha-inspired)
    GitHub: https://raw.githubusercontent.com/holasoywawijon-prog/MatchaLib/refs/heads/main/matchalib.lua
]]

local MatchaLib = {}
MatchaLib.__index = MatchaLib
MatchaLib.Flags = {}

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local LP               = Players.LocalPlayer

-- ============================================================
-- THEME
-- ============================================================
local T = {
    Bg          = Color3.fromRGB(15, 15, 18),
    BgAlt       = Color3.fromRGB(20, 20, 25),
    Surface     = Color3.fromRGB(26, 26, 32),
    SurfaceAlt  = Color3.fromRGB(32, 32, 40),
    Border      = Color3.fromRGB(45, 45, 58),
    Accent      = Color3.fromRGB(255, 105, 180),
    AccentDim   = Color3.fromRGB(180, 60, 130),
    TextPri     = Color3.fromRGB(235, 235, 240),
    TextSec     = Color3.fromRGB(155, 155, 170),
    TextMuted   = Color3.fromRGB(90, 90, 105),
    On          = Color3.fromRGB(255, 105, 180),
    Off         = Color3.fromRGB(48, 48, 60),
    SliderFill  = Color3.fromRGB(255, 105, 180),
    TabActive   = Color3.fromRGB(255, 105, 180),
    TabInactive = Color3.fromRGB(26, 26, 32),
    Success     = Color3.fromRGB(100, 220, 140),
    Danger      = Color3.fromRGB(220, 80, 80),
}

-- ============================================================
-- UTILS
-- ============================================================
local function tw(obj, props, t, s, d)
    TweenService:Create(obj, TweenInfo.new(t or 0.18, s or Enum.EasingStyle.Quart, d or Enum.EasingDirection.Out), props):Play()
end
local function corner(p, r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 6); c.Parent=p; return c end
local function stroke(p, col, th) local s=Instance.new("UIStroke"); s.Color=col or T.Border; s.Thickness=th or 1; s.Parent=p; return s end

local function frame(props)
    local f = Instance.new("Frame")
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    for k,v in pairs(props or {}) do f[k]=v end
    return f
end

local function label(props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.BorderSizePixel = 0
    l.Font = Enum.Font.Gotham
    l.TextSize = 12
    l.TextColor3 = T.TextSec
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    for k,v in pairs(props or {}) do l[k]=v end
    return l
end

local function makeDraggable(win, handle)
    local drag, dstart, dpos = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag=true; dstart=i.Position; dpos=win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dstart
            win.Position = UDim2.new(dpos.X.Scale, dpos.X.Offset+d.X, dpos.Y.Scale, dpos.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
local notifGui = Instance.new("ScreenGui")
notifGui.Name = "MatchaNotifs"
notifGui.ResetOnSpawn = false
notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() notifGui.Parent = CoreGui end)
if not notifGui.Parent then notifGui.Parent = LP.PlayerGui end

local notifHolder = frame({ Size=UDim2.new(0,270,1,0), Position=UDim2.new(1,-282,0,0), Parent=notifGui })
local notifLayout = Instance.new("UIListLayout")
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifLayout.Padding = UDim.new(0,6)
notifLayout.Parent = notifHolder
local notifPad = Instance.new("UIPadding")
notifPad.PaddingBottom = UDim.new(0,14)
notifPad.Parent = notifHolder

function MatchaLib:Notify(opts)
    opts = opts or {}
    local accent = opts.Type == "success" and T.Success or opts.Type == "error" and T.Danger or T.Accent
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1,0,0,60)
    card.BackgroundColor3 = T.Surface
    card.BorderSizePixel = 0
    card.Parent = notifHolder
    corner(card, 7)
    stroke(card, T.Border)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0,2,1,0); bar.BackgroundColor3 = accent; bar.BorderSizePixel=0; bar.Parent=card
    corner(bar,2)

    label({ Size=UDim2.new(1,-18,0,22), Position=UDim2.new(0,12,0,8),
        Text=opts.Title or "MatchaLib", TextColor3=T.TextPri,
        Font=Enum.Font.GothamBold, TextSize=12, Parent=card })
    label({ Size=UDim2.new(1,-18,0,18), Position=UDim2.new(0,12,0,30),
        Text=opts.Content or "", TextSize=11, Parent=card })

    local prog = Instance.new("Frame")
    prog.Size=UDim2.new(1,0,0,2); prog.Position=UDim2.new(0,0,1,-2)
    prog.BackgroundColor3=accent; prog.BorderSizePixel=0; prog.Parent=card

    card.Position = UDim2.new(1,10,0,0)
    tw(card,{Position=UDim2.new(0,0,0,0)},0.3)
    tw(prog,{Size=UDim2.new(0,0,0,2)},opts.Duration or 4,Enum.EasingStyle.Linear)
    task.delay(opts.Duration or 4, function()
        tw(card,{Position=UDim2.new(1,10,0,0)},0.25)
        task.wait(0.3); card:Destroy()
    end)
end

-- ============================================================
-- ELEMENT BUILDER (shared between columns)
-- ============================================================
local function buildElements(col)
    local el = {}

    -- SECTION
    function el:AddSection(name)
        local lbl = label({
            Size = UDim2.new(1,0,0,18),
            Text = name,
            TextColor3 = T.Accent,
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            Parent = col,
        })
        -- underline
        local line = Instance.new("Frame")
        line.Size = UDim2.new(1,0,0,1)
        line.Position = UDim2.new(0,0,1,-1)
        line.BackgroundColor3 = T.Border
        line.BorderSizePixel = 0
        line.Parent = lbl
    end

    -- LABEL
    function el:AddLabel(text)
        local lbl = label({
            Size = UDim2.new(1,0,0,18),
            Text = text,
            TextSize = 11,
            TextColor3 = T.TextMuted,
            Parent = col,
        })
        return { Set = function(_,t) lbl.Text=t end }
    end

    -- TOGGLE
    function el:AddToggle(opts)
        opts = opts or {}
        local val = opts.Default or false

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1,0,0,26)
        row.BackgroundTransparency = 1
        row.Parent = col

        -- Circle toggle (Matcha style)
        local circle = Instance.new("Frame")
        circle.Size = UDim2.new(0,16,0,16)
        circle.Position = UDim2.new(0,0,0.5,-8)
        circle.BackgroundColor3 = val and T.On or T.Off
        circle.BorderSizePixel = 0
        circle.Parent = row
        corner(circle,8)
        stroke(circle, val and T.On or T.Border)

        -- Inner dot
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0,8,0,8)
        dot.Position = UDim2.new(0.5,-4,0.5,-4)
        dot.BackgroundColor3 = Color3.new(1,1,1)
        dot.BackgroundTransparency = val and 0 or 1
        dot.BorderSizePixel = 0
        dot.Parent = circle
        corner(dot,4)

        label({
            Size=UDim2.new(1,-26,1,0),
            Position=UDim2.new(0,24,0,0),
            Text=opts.Name or "Toggle",
            TextColor3=T.TextPri,
            TextSize=12,
            Parent=row,
        })

        -- Bind display (optional, like Matcha's "rbutton")
        local bindLbl
        if opts.Bind then
            bindLbl = label({
                Size=UDim2.new(0,60,0,20),
                Position=UDim2.new(1,-62,0.5,-10),
                Text=opts.Bind,
                TextColor3=T.TextMuted,
                TextXAlignment=Enum.TextXAlignment.Right,
                TextSize=11,
                Parent=row,
            })
        end

        local btn = Instance.new("TextButton")
        btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""; btn.Parent=row

        local function update()
            tw(circle,{BackgroundColor3=val and T.On or T.Off},0.12)
            circle.UIStroke.Color = val and T.On or T.Border
            dot.BackgroundTransparency = val and 0 or 1
            if opts.Flag then MatchaLib.Flags[opts.Flag]={Value=val} end
            if opts.Callback then opts.Callback(val) end
        end

        btn.MouseButton1Click:Connect(function() val=not val; update() end)
        if opts.Flag then MatchaLib.Flags[opts.Flag]={Value=val} end

        return {
            Set=function(_,v) val=v; update() end,
            GetValue=function() return val end,
        }
    end

    -- SLIDER
    function el:AddSlider(opts)
        opts = opts or {}
        local minV=opts.Min or 0; local maxV=opts.Max or 100
        local val=opts.Default or minV; local inc=opts.Increment or 1
        local suf=opts.ValueName or ""

        local wrap = Instance.new("Frame")
        wrap.Size = UDim2.new(1,0,0,38)
        wrap.BackgroundTransparency = 1
        wrap.Parent = col

        local topRow = frame({Size=UDim2.new(1,0,0,18), Parent=wrap})

        label({
            Size=UDim2.new(0.6,0,1,0),
            Text=opts.Name or "Slider",
            TextColor3=T.TextPri, TextSize=12,
            Parent=topRow,
        })

        local valLbl = label({
            Size=UDim2.new(0.4,0,1,0),
            Position=UDim2.new(0.6,0,0,0),
            Text=tostring(val).." "..suf,
            TextColor3=T.Accent,
            TextXAlignment=Enum.TextXAlignment.Right,
            Font=Enum.Font.GothamBold,
            TextSize=11,
            Parent=topRow,
        })

        local trackBg = Instance.new("Frame")
        trackBg.Size=UDim2.new(1,0,0,4)
        trackBg.Position=UDim2.new(0,0,0,24)
        trackBg.BackgroundColor3=T.SurfaceAlt
        trackBg.BorderSizePixel=0
        trackBg.Parent=wrap
        corner(trackBg,2)

        local fillF = Instance.new("Frame")
        fillF.Size=UDim2.new((val-minV)/(maxV-minV),0,1,0)
        fillF.BackgroundColor3=T.SliderFill
        fillF.BorderSizePixel=0
        fillF.Parent=trackBg
        corner(fillF,2)

        local knob = Instance.new("Frame")
        knob.Size=UDim2.new(0,10,0,10)
        knob.AnchorPoint=Vector2.new(0.5,0.5)
        knob.Position=UDim2.new((val-minV)/(maxV-minV),0,0.5,0)
        knob.BackgroundColor3=Color3.new(1,1,1)
        knob.BorderSizePixel=0
        knob.ZIndex=3
        knob.Parent=trackBg
        corner(knob,5)

        local hit = Instance.new("TextButton")
        hit.Size=UDim2.new(1,0,0,16); hit.Position=UDim2.new(0,0,0.5,-8)
        hit.BackgroundTransparency=1; hit.Text=""; hit.ZIndex=4; hit.Parent=trackBg

        local drag=false
        local function upd(x)
            local rel=math.clamp((x-trackBg.AbsolutePosition.X)/trackBg.AbsoluteSize.X,0,1)
            local raw=minV+(maxV-minV)*rel
            val=math.floor(raw/inc+0.5)*inc
            val=math.clamp(math.floor(val*1000+0.5)/1000,minV,maxV)
            local fr=(val-minV)/(maxV-minV)
            fillF.Size=UDim2.new(fr,0,1,0)
            knob.Position=UDim2.new(fr,0,0.5,0)
            valLbl.Text=tostring(val).." "..suf
            if opts.Flag then MatchaLib.Flags[opts.Flag]={Value=val} end
            if opts.Callback then opts.Callback(val) end
        end

        hit.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; upd(i.Position.X) end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if drag and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i.Position.X) end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
        end)

        if opts.Flag then MatchaLib.Flags[opts.Flag]={Value=val} end
        return {
            Set=function(_,v)
                val=math.clamp(v,minV,maxV)
                local fr=(val-minV)/(maxV-minV)
                fillF.Size=UDim2.new(fr,0,1,0); knob.Position=UDim2.new(fr,0,0.5,0)
                valLbl.Text=tostring(val).." "..suf
            end,
            GetValue=function() return val end,
        }
    end

    -- DROPDOWN
    function el:AddDropdown(opts)
        opts = opts or {}
        local options=opts.Options or {}
        local val=opts.Default or (options[1] or "")
        local open=false

        local container = Instance.new("Frame")
        container.Size=UDim2.new(1,0,0,26)
        container.BackgroundTransparency=1
        container.ClipsDescendants=false
        container.Parent=col

        local topRow = frame({Size=UDim2.new(1,0,0,26), Parent=container})

        label({
            Size=UDim2.new(0.5,0,1,0),
            Text=opts.Name or "Dropdown",
            TextColor3=T.TextPri, TextSize=12,
            Parent=topRow,
        })

        -- Value box (Matcha style: dark pill with value)
        local box = Instance.new("Frame")
        box.Size=UDim2.new(0.48,0,0,20)
        box.Position=UDim2.new(0.5,0,0.5,-10)
        box.BackgroundColor3=T.SurfaceAlt
        box.BorderSizePixel=0
        box.Parent=topRow
        corner(box,4)
        stroke(box,T.Border)

        local valLbl = label({
            Size=UDim2.new(1,-20,1,0),
            Position=UDim2.new(0,8,0,0),
            Text=val, TextColor3=T.TextPri,
            TextSize=11,
            Parent=box,
        })

        local arrow = label({
            Size=UDim2.new(0,18,1,0),
            Position=UDim2.new(1,-18,0,0),
            Text="▾",
            TextColor3=T.TextMuted,
            TextXAlignment=Enum.TextXAlignment.Center,
            TextSize=12,
            Parent=box,
        })

        -- Panel
        local panel = Instance.new("Frame")
        panel.Size=UDim2.new(0.48,0,0,0)
        panel.Position=UDim2.new(0.5,0,0,28)
        panel.BackgroundColor3=T.SurfaceAlt
        panel.BorderSizePixel=0
        panel.ClipsDescendants=true
        panel.ZIndex=20
        panel.Parent=container
        corner(panel,4)
        stroke(panel,T.Border)

        local pList=Instance.new("UIListLayout"); pList.Parent=panel
        local pPad=Instance.new("UIPadding"); pPad.PaddingTop=UDim.new(0,3); pPad.PaddingBottom=UDim.new(0,3); pPad.Parent=panel

        local OH=22
        local function buildOpts(list)
            for _,c in ipairs(panel:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
            for _,opt in ipairs(list) do
                local ob=Instance.new("TextButton")
                ob.Size=UDim2.new(1,0,0,OH); ob.BackgroundTransparency=1
                ob.Text=opt; ob.Font=Enum.Font.Gotham; ob.TextSize=11
                ob.TextColor3=opt==val and T.Accent or T.TextPri
                ob.TextXAlignment=Enum.TextXAlignment.Left
                ob.ZIndex=21; ob.Parent=panel
                Instance.new("UIPadding",ob).PaddingLeft=UDim.new(0,8)
                ob.MouseEnter:Connect(function() ob.BackgroundTransparency=0; ob.BackgroundColor3=T.Surface end)
                ob.MouseLeave:Connect(function() ob.BackgroundTransparency=1 end)
                ob.MouseButton1Click:Connect(function()
                    val=opt; valLbl.Text=val
                    for _,c in ipairs(panel:GetChildren()) do
                        if c:IsA("TextButton") then c.TextColor3=c.Text==val and T.Accent or T.TextPri end
                    end
                    open=false
                    tw(panel,{Size=UDim2.new(0.48,0,0,0)},0.15)
                    tw(container,{Size=UDim2.new(1,0,0,26)},0.15)
                    if opts.Flag then MatchaLib.Flags[opts.Flag]={Value=val} end
                    if opts.Callback then opts.Callback(val) end
                end)
            end
        end
        buildOpts(options)

        local hbtn=Instance.new("TextButton")
        hbtn.Size=UDim2.new(1,0,1,0); hbtn.BackgroundTransparency=1; hbtn.Text=""; hbtn.ZIndex=5; hbtn.Parent=topRow
        hbtn.MouseButton1Click:Connect(function()
            open=not open
            local ph=math.min(#options,6)*OH+6
            if open then
                tw(panel,{Size=UDim2.new(0.48,0,0,ph)},0.18)
                tw(container,{Size=UDim2.new(1,0,0,26+ph+4)},0.18)
            else
                tw(panel,{Size=UDim2.new(0.48,0,0,0)},0.15)
                tw(container,{Size=UDim2.new(1,0,0,26)},0.15)
            end
        end)

        if opts.Flag then MatchaLib.Flags[opts.Flag]={Value=val} end
        return {
            Set=function(_,v) val=v; valLbl.Text=v end,
            Refresh=function(_,list,clear)
                if clear then options={} end
                for _,o in ipairs(list) do table.insert(options,o) end
                buildOpts(options)
            end,
            GetValue=function() return val end,
        }
    end

    -- COLORPICKER
    function el:AddColorpicker(opts)
        opts = opts or {}
        local val=opts.Default or Color3.new(1,1,1)
        local open=false
        local h,s,v2=Color3.toHSV(val)

        local container=Instance.new("Frame")
        container.Size=UDim2.new(1,0,0,26)
        container.BackgroundTransparency=1
        container.ClipsDescendants=false
        container.Parent=col

        local topRow=frame({Size=UDim2.new(1,0,0,26),Parent=container})

        label({
            Size=UDim2.new(0.6,0,1,0),
            Text=opts.Name or "Color",
            TextColor3=T.TextPri, TextSize=12,
            Parent=topRow,
        })

        local preview=Instance.new("Frame")
        preview.Size=UDim2.new(0,18,0,18); preview.Position=UDim2.new(1,-20,0.5,-9)
        preview.BackgroundColor3=val; preview.BorderSizePixel=0; preview.ZIndex=3; preview.Parent=topRow
        corner(preview,3); stroke(preview,T.Border)

        local hbtn=Instance.new("TextButton")
        hbtn.Size=UDim2.new(1,0,1,0); hbtn.BackgroundTransparency=1; hbtn.Text=""; hbtn.ZIndex=4; hbtn.Parent=topRow

        local panel=Instance.new("Frame")
        panel.Size=UDim2.new(1,0,0,0); panel.Position=UDim2.new(0,0,0,28)
        panel.BackgroundColor3=T.SurfaceAlt; panel.BorderSizePixel=0
        panel.ClipsDescendants=true; panel.ZIndex=20; panel.Parent=container
        corner(panel,4); stroke(panel,T.Border)

        local pList=Instance.new("UIListLayout"); pList.Padding=UDim.new(0,4); pList.Parent=panel
        local pp=Instance.new("UIPadding"); pp.PaddingLeft=UDim.new(0,8); pp.PaddingRight=UDim.new(0,8)
        pp.PaddingTop=UDim.new(0,6); pp.PaddingBottom=UDim.new(0,6); pp.Parent=panel

        local function upd()
            val=Color3.fromHSV(h,s,v2)
            preview.BackgroundColor3=val
            if opts.Flag then MatchaLib.Flags[opts.Flag]={Value=val} end
            if opts.Callback then opts.Callback(val) end
        end

        local function hsvRow(lText, initV, trackCol, cb)
            local row=frame({Size=UDim2.new(1,0,0,22), ZIndex=21, Parent=panel})
            label({Size=UDim2.new(0,14,1,0),Text=lText,TextColor3=T.TextMuted,TextSize=10,ZIndex=22,Parent=row})
            local bg=Instance.new("Frame"); bg.Size=UDim2.new(1,-18,0,5); bg.Position=UDim2.new(0,18,0.5,-2.5)
            bg.BackgroundColor3=trackCol; bg.BorderSizePixel=0; bg.ZIndex=22; bg.Parent=row; corner(bg,2)
            local kn=Instance.new("Frame"); kn.Size=UDim2.new(0,9,0,9); kn.AnchorPoint=Vector2.new(0.5,0.5)
            kn.Position=UDim2.new(initV,0,0.5,0); kn.BackgroundColor3=Color3.new(1,1,1); kn.BorderSizePixel=0; kn.ZIndex=23; kn.Parent=bg; corner(kn,5)
            local hb=Instance.new("TextButton"); hb.Size=UDim2.new(1,0,0,16); hb.Position=UDim2.new(0,0,0.5,-8)
            hb.BackgroundTransparency=1; hb.Text=""; hb.ZIndex=24; hb.Parent=bg
            local drag=false
            hb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true end end)
            UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
            UserInputService.InputChanged:Connect(function(i)
                if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
                    local r=math.clamp((i.Position.X-bg.AbsolutePosition.X)/bg.AbsoluteSize.X,0,1)
                    kn.Position=UDim2.new(r,0,0.5,0); cb(r); upd()
                end
            end)
        end

        hsvRow("H",h,Color3.fromRGB(200,80,80),function(r) h=r end)
        hsvRow("S",s,Color3.fromRGB(180,180,180),function(r) s=r end)
        hsvRow("V",v2,Color3.fromRGB(255,255,255),function(r) v2=r end)

        hbtn.MouseButton1Click:Connect(function()
            open=not open
            if open then
                tw(panel,{Size=UDim2.new(1,0,0,100)},0.18)
                tw(container,{Size=UDim2.new(1,0,0,130)},0.18)
            else
                tw(panel,{Size=UDim2.new(1,0,0,0)},0.15)
                tw(container,{Size=UDim2.new(1,0,0,26)},0.15)
            end
        end)

        if opts.Flag then MatchaLib.Flags[opts.Flag]={Value=val} end
        return {
            Set=function(_,c) val=c; preview.BackgroundColor3=c; h,s,v2=Color3.toHSV(c) end,
            GetValue=function() return val end,
        }
    end

    -- KEYBIND
    function el:AddBind(opts)
        opts=opts or {}
        local key=opts.Default or Enum.KeyCode.Unknown
        local waiting=false

        local row=frame({Size=UDim2.new(1,0,0,26), Parent=col})

        label({
            Size=UDim2.new(0.5,0,1,0),
            Text=opts.Name or "Bind",
            TextColor3=T.TextPri, TextSize=12,
            Parent=row,
        })

        local keyBox=Instance.new("TextButton")
        keyBox.Size=UDim2.new(0.48,0,0,20); keyBox.Position=UDim2.new(0.5,0,0.5,-10)
        keyBox.BackgroundColor3=T.SurfaceAlt; keyBox.BorderSizePixel=0
        keyBox.Text=key==Enum.KeyCode.Unknown and "NONE" or key.Name
        keyBox.Font=Enum.Font.GothamBold; keyBox.TextSize=10
        keyBox.TextColor3=T.Accent; keyBox.ZIndex=3; keyBox.Parent=row
        corner(keyBox,4); stroke(keyBox,T.Border)

        keyBox.MouseButton1Click:Connect(function()
            waiting=true; keyBox.Text="..."; keyBox.TextColor3=T.TextMuted
        end)

        UserInputService.InputBegan:Connect(function(i,gp)
            if waiting and i.UserInputType==Enum.UserInputType.Keyboard then
                waiting=false; key=i.KeyCode
                keyBox.Text=key.Name; keyBox.TextColor3=T.Accent
                if opts.Flag then MatchaLib.Flags[opts.Flag]={Value=key} end
            elseif not waiting and not gp and i.UserInputType==Enum.UserInputType.Keyboard then
                if i.KeyCode==key and opts.Callback then opts.Callback() end
            end
        end)

        if opts.Flag then MatchaLib.Flags[opts.Flag]={Value=key} end
        return {
            Set=function(_,k) key=k; keyBox.Text=k==Enum.KeyCode.Unknown and "NONE" or k.Name end,
            GetValue=function() return key end,
        }
    end

    -- BUTTON
    function el:AddButton(opts)
        opts=opts or {}
        local btn=Instance.new("TextButton")
        btn.Size=UDim2.new(1,0,0,26); btn.BackgroundColor3=T.SurfaceAlt; btn.BorderSizePixel=0
        btn.Text=opts.Name or "Button"; btn.Font=Enum.Font.GothamMedium; btn.TextSize=12
        btn.TextColor3=T.TextPri; btn.AutoButtonColor=false; btn.Parent=col
        corner(btn,4); stroke(btn,T.Border)
        btn.MouseEnter:Connect(function() tw(btn,{BackgroundColor3=T.Surface},0.1) end)
        btn.MouseLeave:Connect(function() tw(btn,{BackgroundColor3=T.SurfaceAlt},0.1) end)
        btn.MouseButton1Click:Connect(function()
            tw(btn,{BackgroundColor3=T.Accent},0.07)
            task.wait(0.1); tw(btn,{BackgroundColor3=T.SurfaceAlt},0.15)
            if opts.Callback then opts.Callback() end
        end)
    end

    -- TEXTBOX
    function el:AddTextbox(opts)
        opts=opts or {}
        local row=frame({Size=UDim2.new(1,0,0,26), Parent=col})
        label({Size=UDim2.new(0.45,0,1,0), Text=opts.Name or "Input",
            TextColor3=T.TextPri, TextSize=12, Parent=row})
        local box=Instance.new("TextBox")
        box.Size=UDim2.new(0.48,0,0,20); box.Position=UDim2.new(0.5,0,0.5,-10)
        box.BackgroundColor3=T.SurfaceAlt; box.BorderSizePixel=0
        box.Text=opts.Default or ""; box.Font=Enum.Font.Gotham; box.TextSize=11
        box.TextColor3=T.TextPri; box.PlaceholderText=opts.Placeholder or "..."
        box.PlaceholderColor3=T.TextMuted; box.ClearTextOnFocus=false; box.ZIndex=3; box.Parent=row
        corner(box,4); stroke(box,T.Border)
        Instance.new("UIPadding",box).PaddingLeft=UDim.new(0,6)
        box.FocusLost:Connect(function()
            if opts.Callback then opts.Callback(box.Text) end
            if opts.TextDisappear then box.Text="" end
        end)
        return { Set=function(_,t) box.Text=t end, GetValue=function() return box.Text end }
    end

    return el
end

-- ============================================================
-- WINDOW
-- ============================================================
function MatchaLib:CreateWindow(opts)
    opts = opts or {}
    local W = opts.Width or 600
    local H = opts.Height or 420

    local win = {}
    local tabButtons = {}
    local tabContents = {}
    local currentTab = nil

    local gui = Instance.new("ScreenGui")
    gui.Name = "MatchaLib"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then gui.Parent = LP.PlayerGui end

    -- Main frame
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0,W,0,0)
    main.Position = UDim2.new(0.5,-W/2,0.5,-H/2)
    main.BackgroundColor3 = T.Bg
    main.BorderSizePixel = 0
    main.Parent = gui
    corner(main,8)
    stroke(main,T.Border)

    -- Animate open
    tw(main,{Size=UDim2.new(0,W,0,H)},0.3,Enum.EasingStyle.Back)

    -- TITLEBAR
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1,0,0,36)
    titleBar.BackgroundColor3 = T.BgAlt
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = 2
    titleBar.Parent = main
    corner(titleBar,8)
    -- fix bottom corners
    local tbFix=frame({Size=UDim2.new(1,0,0,8),Position=UDim2.new(0,0,1,-8),BackgroundColor3=T.BgAlt,ZIndex=2,Parent=titleBar})

    -- Accent pip
    local pip=Instance.new("Frame")
    pip.Size=UDim2.new(0,3,0,16); pip.Position=UDim2.new(0,10,0.5,-8)
    pip.BackgroundColor3=T.Accent; pip.BorderSizePixel=0; pip.ZIndex=3; pip.Parent=titleBar
    corner(pip,2)

    label({
        Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0,20,0,0),
        Text=opts.Title or "MatchaLib",
        TextColor3=T.TextPri, Font=Enum.Font.GothamBold, TextSize=13,
        ZIndex=3, Parent=titleBar,
    })

    -- Subtitle
    if opts.Subtitle and opts.Subtitle ~= "" then
        label({
            Size=UDim2.new(0.3,0,1,0), Position=UDim2.new(0.5,-30,0,0),
            Text=opts.Subtitle, TextColor3=T.TextMuted, TextSize=11,
            ZIndex=3, Parent=titleBar,
        })
    end

    -- Close / minimize
    local function mkCtrlBtn(txt, xOff)
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(0,24,0,24); b.Position=UDim2.new(1,xOff,0.5,-12)
        b.BackgroundColor3=T.SurfaceAlt; b.BorderSizePixel=0
        b.Text=txt; b.Font=Enum.Font.GothamBold; b.TextSize=14
        b.TextColor3=T.TextSec; b.ZIndex=4; b.Parent=titleBar
        corner(b,5)
        b.MouseEnter:Connect(function() tw(b,{BackgroundColor3=T.Surface},0.1) end)
        b.MouseLeave:Connect(function() tw(b,{BackgroundColor3=T.SurfaceAlt},0.1) end)
        return b
    end

    local closeBtn = mkCtrlBtn("×", -8)
    local minBtn   = mkCtrlBtn("−", -36)

    closeBtn.MouseButton1Click:Connect(function()
        tw(main,{Size=UDim2.new(0,W,0,0)},0.2)
        task.wait(0.22); gui:Destroy()
    end)

    local minimized=false
    minBtn.MouseButton1Click:Connect(function()
        minimized=not minimized
        tw(main,{Size=UDim2.new(0,W,0,minimized and 36 or H)},0.2)
    end)

    makeDraggable(main, titleBar)

    -- TAB BAR (horizontal, below titlebar)
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1,0,0,30)
    tabBar.Position = UDim2.new(0,0,0,36)
    tabBar.BackgroundColor3 = T.BgAlt
    tabBar.BorderSizePixel = 0
    tabBar.ZIndex = 2
    tabBar.Parent = main

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0,2)
    tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tabLayout.Parent = tabBar
    Instance.new("UIPadding",tabBar).PaddingLeft = UDim.new(0,8)

    -- Separator line
    local sep=Instance.new("Frame")
    sep.Size=UDim2.new(1,0,0,1); sep.Position=UDim2.new(0,0,0,66)
    sep.BackgroundColor3=T.Border; sep.BorderSizePixel=0; sep.ZIndex=2; sep.Parent=main

    -- CONTENT AREA
    local contentArea = Instance.new("Frame")
    contentArea.Size = UDim2.new(1,0,1,-68)
    contentArea.Position = UDim2.new(0,0,0,68)
    contentArea.BackgroundTransparency = 1
    contentArea.ClipsDescendants = true
    contentArea.Parent = main

    -- ============================================================
    -- CREATE TAB
    -- ============================================================
    function win:CreateTab(name)
        local tab = {}

        -- Tab button
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(0,0,1,0)
        tabBtn.AutomaticSize = Enum.AutomaticSize.X
        tabBtn.BackgroundTransparency = 1
        tabBtn.Text = name
        tabBtn.Font = Enum.Font.GothamMedium
        tabBtn.TextSize = 12
        tabBtn.TextColor3 = T.TextMuted
        tabBtn.AutoButtonColor = false
        tabBtn.ZIndex = 3
        tabBtn.Parent = tabBar
        Instance.new("UIPadding",tabBtn).PaddingLeft = UDim.new(0,10)
        local tabBtnPad = Instance.new("UIPadding",tabBtn)
        tabBtnPad.PaddingLeft = UDim.new(0,10)
        tabBtnPad.PaddingRight = UDim.new(0,10)

        -- Active underline
        local underline = Instance.new("Frame")
        underline.Size = UDim2.new(1,-20,0,2)
        underline.Position = UDim2.new(0,10,1,-2)
        underline.BackgroundColor3 = T.Accent
        underline.BorderSizePixel = 0
        underline.BackgroundTransparency = 1
        underline.ZIndex = 4
        underline.Parent = tabBtn

        -- TWO-COLUMN SCROLL layout (like Matcha)
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1,0,1,0)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 3
        scroll.ScrollBarImageColor3 = T.Accent
        scroll.CanvasSize = UDim2.new(0,0,0,0)
        scroll.Visible = false
        scroll.ZIndex = 1
        scroll.Parent = contentArea

        local colHolder = frame({Size=UDim2.new(1,-20,1,0), Position=UDim2.new(0,10,0,8), Parent=scroll})

        local colList = Instance.new("UIListLayout")
        colList.FillDirection = Enum.FillDirection.Horizontal
        colList.HorizontalAlignment = Enum.HorizontalAlignment.Left
        colList.Padding = UDim.new(0,10)
        colList.Parent = colHolder

        -- Left column
        local leftCol = Instance.new("Frame")
        leftCol.Size = UDim2.new(0.5,-5,0,0)
        leftCol.AutomaticSize = Enum.AutomaticSize.Y
        leftCol.BackgroundTransparency = 1
        leftCol.Parent = colHolder

        local leftList = Instance.new("UIListLayout")
        leftList.SortOrder = Enum.SortOrder.LayoutOrder
        leftList.Padding = UDim.new(0,6)
        leftList.Parent = leftCol

        -- Right column
        local rightCol = Instance.new("Frame")
        rightCol.Size = UDim2.new(0.5,-5,0,0)
        rightCol.AutomaticSize = Enum.AutomaticSize.Y
        rightCol.BackgroundTransparency = 1
        rightCol.Parent = colHolder

        local rightList = Instance.new("UIListLayout")
        rightList.SortOrder = Enum.SortOrder.LayoutOrder
        rightList.Padding = UDim.new(0,6)
        rightList.Parent = rightCol

        -- Auto-resize canvas
        local function updateCanvas()
            local lH = leftList.AbsoluteContentSize.Y
            local rH = rightList.AbsoluteContentSize.Y
            scroll.CanvasSize = UDim2.new(0,0,0,math.max(lH,rH)+20)
        end
        leftList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
        rightList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

        -- Build element APIs for each column
        local leftEl  = buildElements(leftCol)
        local rightEl = buildElements(rightCol)

        -- Expose both columns
        tab.Left  = leftEl
        tab.Right = rightEl

        -- Shortcut: default adds go to left col
        -- Users can do tab:AddToggle(...) -> left, tab.Right:AddToggle(...) -> right
        for k,v in pairs(leftEl) do tab[k]=v end

        -- Activate/deactivate
        local function setActive(active)
            scroll.Visible = active
            tw(tabBtn,{TextColor3 = active and T.TextPri or T.TextMuted},0.12)
            tw(underline,{BackgroundTransparency = active and 0 or 1},0.12)
        end

        tabBtn.MouseButton1Click:Connect(function()
            -- hide all others
            for _, entry in ipairs(tabContents) do
                entry.scroll.Visible = false
                tw(entry.btn, {TextColor3=T.TextMuted}, 0.12)
                tw(entry.underline, {BackgroundTransparency=1}, 0.12)
            end
            -- show this one
            scroll.Visible = true
            tw(tabBtn, {TextColor3=T.TextPri}, 0.12)
            tw(underline, {BackgroundTransparency=0}, 0.12)
            currentTab = name
        end)

        table.insert(tabContents, { scroll=scroll, btn=tabBtn, underline=underline })

        -- First tab is active by default
        if #tabContents == 1 then
            scroll.Visible = true
            tabBtn.TextColor3 = T.TextPri
            underline.BackgroundTransparency = 0
            currentTab = name
        end

        return tab
    end

    return win
end

function MatchaLib:Init() end

return MatchaLib


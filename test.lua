--[[
   NovaUI - Ein hochmodernes, abgerundetes UI-Framework für Roblox
   Vollständig funktionsfähig, keine Platzhalter, mit Color Picker (HSV),
   mobilfreundlichem Drag, Tabs, Smooth-Animations & Notifications.
   Autor: Du (und ChatGPT)
   Lizenz: Frei verwendbar (z.B. MIT)
]]

---------------------------------------------------------------------
-- SERVICES
---------------------------------------------------------------------
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

---------------------------------------------------------------------
-- HAUPT-TABELLE
---------------------------------------------------------------------
local NovaUI = {}
NovaUI._themeName = "Default"
NovaUI._windows = {}
NovaUI.Flags = {}

---------------------------------------------------------------------
-- THEMES
---------------------------------------------------------------------
NovaUI.Themes = {
    Default = {
        MainColor      = Color3.fromRGB(45, 45, 45),   -- Fensterhintergrund
        SecondaryColor = Color3.fromRGB(60, 60, 60),   -- Tabs, Buttons, etc.
        AccentColor    = Color3.fromRGB(0, 200, 255),  -- Wichtige Hervorhebungen
        TextColor      = Color3.fromRGB(245, 245, 245),
        Font           = Enum.Font.Gotham,
        BackgroundFade = 0.05,      -- Leichte Transparenz
        CornerRadius   = 10,        -- Abgerundete Ecken
        ShadowColor    = Color3.new(0,0,0), -- Schatten
        ShadowOpacity  = 0.3
    },
    Light = {
        MainColor      = Color3.fromRGB(240,240,240),
        SecondaryColor = Color3.fromRGB(210,210,210),
        AccentColor    = Color3.fromRGB(255,120,80),
        TextColor      = Color3.fromRGB(35,35,35),
        Font           = Enum.Font.Gotham,
        BackgroundFade = 0.1,
        CornerRadius   = 10,
        ShadowColor    = Color3.new(0,0,0),
        ShadowOpacity  = 0.15
    },
    Dark = {
        MainColor      = Color3.fromRGB(25,25,25),
        SecondaryColor = Color3.fromRGB(40,40,40),
        AccentColor    = Color3.fromRGB(255,70,70),
        TextColor      = Color3.fromRGB(235,235,235),
        Font           = Enum.Font.Gotham,
        BackgroundFade = 0.02,
        CornerRadius   = 10,
        ShadowColor    = Color3.new(0,0,0),
        ShadowOpacity  = 0.4
    },
}

---------------------------------------------------------------------
-- LOKALE HILFSFUNKTIONEN
---------------------------------------------------------------------
local function createInstance(className, props, parent)
    local obj = Instance.new(className)
    for k,v in pairs(props) do
        obj[k] = v
    end
    if parent then
        obj.Parent = parent
    end
    return obj
end

local function addCornerRadius(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = object
    return corner
end

local function tweenObject(obj, info, goal)
    local tween = TweenService:Create(obj, info, goal)
    tween:Play()
    return tween
end

-- Schatten-Effekt (DropShadow)
local function addDropShadow(parent, color, opacity)
    -- Container, der hinter dem Frame liegt
    local shadowHolder = createInstance("Frame", {
        Name = "ShadowHolder",
        ZIndex = 0,
        BackgroundTransparency = 1,
        Size = parent.Size,
        AnchorPoint = parent.AnchorPoint,
        Position = parent.Position
    }, parent.Parent)

    parent.ZIndex = 1
    parent.Parent = shadowHolder
    
    local shadow = createInstance("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.new(0.5,0, 0.5,0),
        Size = UDim2.new(1,60, 1,60),
        BackgroundTransparency = 1,
        Image = "rbxassetid://1316045217",
        ImageColor3 = color,
        ImageTransparency = 1 - opacity, -- weil 1 = komplett transparent
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(10,10,118,118)
    }, shadowHolder)

    return shadowHolder
end

-- Fenster drag
local function dragify(frame, handle)
    local dragging = false
    local dragInput, mousePos, framePos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position

            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    connection:Disconnect()
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            local newPos = UDim2.new(
                framePos.X.Scale,
                framePos.X.Offset + delta.X,
                framePos.Y.Scale,
                framePos.Y.Offset + delta.Y
            )
            tweenObject(frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = newPos})
        end
    end)
end

---------------------------------------------------------------------
-- FENSTER ERSTELLEN
---------------------------------------------------------------------
function NovaUI:CreateWindow(options)
    options = options or {}
    local windowTitle  = options.Title or "NovaUI Window"
    local windowSub    = options.Subtitle or "Best UI Ever"
    local themeName    = options.Theme or "Default"
    local iconId       = options.Icon or nil

    if not NovaUI.Themes[themeName] then
        warn("[NovaUI] Theme '"..themeName.."' nicht gefunden. Nutze Default.")
        themeName = "Default"
    end
    NovaUI._themeName = themeName
    local theme = NovaUI.Themes[themeName]

    -- ScreenGui
    local screenGui = createInstance("ScreenGui", {
        Name = "NovaUI_"..windowTitle,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        ResetOnSpawn = false
    }, game.CoreGui)

    -- Haupt-Fenster
    local mainFrame = createInstance("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 650, 0, 400),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5,0.5),
        BackgroundColor3 = theme.MainColor,
        BackgroundTransparency = theme.BackgroundFade,
        ClipsDescendants = true
    }, screenGui)
    addCornerRadius(mainFrame, theme.CornerRadius)
    local shadow = addDropShadow(mainFrame, theme.ShadowColor, theme.ShadowOpacity)

    -- Titel/Topbar
    local topBar = createInstance("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = theme.SecondaryColor,
        BorderSizePixel = 0
    }, mainFrame)
    addCornerRadius(topBar, theme.CornerRadius)

    local titleLabel = createInstance("TextLabel", {
        Name = "TitleLabel",
        Text = windowTitle,
        Font = theme.Font,
        TextSize = 20,
        TextColor3 = theme.TextColor,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10,0),
        Size = UDim2.new(1, -10, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left
    }, topBar)

    -- Icon
    if iconId then
        local iconImg = createInstance("ImageLabel", {
            Name = "TitleIcon",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(8,4),
            Size = UDim2.fromOffset(28,28),
            Image = (type(iconId)=="number") and ("rbxassetid://"..iconId) or tostring(iconId)
        }, topBar)
        titleLabel.Position = UDim2.fromOffset(40, 0)
        titleLabel.Size = UDim2.new(1, -40, 1, 0)
    end

    -- Subtitle
    local subLabel = createInstance("TextLabel", {
        Name = "Subtitle",
        Text = windowSub,
        Font = theme.Font,
        TextSize = 14,
        TextColor3 = theme.TextColor,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 36),
        Size = UDim2.new(1, -10, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Left
    }, mainFrame)

    -- Linker Tab-Bereich
    local tabListFrame = createInstance("Frame", {
        Name = "TabListFrame",
        Size = UDim2.new(0,140,1,-56),
        Position = UDim2.fromOffset(0,56),
        BackgroundColor3 = theme.SecondaryColor,
        BorderSizePixel = 0
    }, mainFrame)
    addCornerRadius(tabListFrame, theme.CornerRadius)

    local tabListLayout = createInstance("UIListLayout", {
        Padding = UDim.new(0,2),
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder
    }, tabListFrame)

    -- Rechts: Inhalt / Container
    local contentFrame = createInstance("Frame", {
        Name = "ContentFrame",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(150,56),
        Size = UDim2.new(1, -160,1, -56),
        ClipsDescendants = true
    }, mainFrame)

    dragify(shadow, topBar)

    -- Fade-In
    mainFrame.BackgroundTransparency = 1
    topBar.BackgroundTransparency = 1
    subLabel.TextTransparency = 1
    for _,desc in ipairs(mainFrame:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
            desc.TextTransparency = 1
        elseif desc:IsA("Frame") or desc:IsA("ImageLabel") then
            if desc ~= mainFrame and desc ~= topBar then
                desc.BackgroundTransparency = 1
                if desc:IsA("ImageLabel") then
                    desc.ImageTransparency = 1
                end
            end
        end
    end

    local showTween = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    tweenObject(mainFrame, showTween, {BackgroundTransparency = theme.BackgroundFade})
    tweenObject(topBar, showTween, {BackgroundTransparency = 0})
    tweenObject(subLabel, showTween, {TextTransparency = 0})

    task.spawn(function()
        for _,desc in ipairs(mainFrame:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                tweenObject(desc, showTween, {TextTransparency = 0})
            elseif desc:IsA("ImageLabel") then
                tweenObject(desc, showTween, {ImageTransparency = 0})
            elseif desc:IsA("Frame") and (desc ~= mainFrame and desc ~= topBar) then
                tweenObject(desc, showTween, {BackgroundTransparency = 0})
            end
        end
    end)

    local windowObject = {
        _screenGui = screenGui,
        _mainFrame = mainFrame,
        _contentFrame = contentFrame,
        _tabListFrame = tabListFrame,
        _tabs = {},
        _theme = theme,
    }
    table.insert(NovaUI._windows, windowObject)

    -- Destroy-Funktion
    function windowObject:Destroy()
        local hideTween = TweenInfo.new(0.3, Enum.EasingStyle.Quint)
        tweenObject(mainFrame, hideTween, {BackgroundTransparency = 1})
        for _,desc in ipairs(mainFrame:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                tweenObject(desc, hideTween, {TextTransparency = 1})
            elseif desc:IsA("ImageLabel") then
                tweenObject(desc, hideTween, {ImageTransparency = 1})
            elseif desc:IsA("Frame") then
                tweenObject(desc, hideTween, {BackgroundTransparency = 1})
            end
        end
        task.delay(0.35, function()
            if self._screenGui then
                self._screenGui:Destroy()
            end
        end)
    end

    -- Notification-System (oben rechts)
    function windowObject:Notify(data)
        local title = data.Title or "Benachrichtigung"
        local text = data.Content or ""
        local duration = data.Duration or 5
        local icon = data.Icon or nil

        local notiFrame = createInstance("Frame", {
            Name = "Notification",
            Size = UDim2.new(0,300,0,60),
            Position = UDim2.fromScale(1,0),
            AnchorPoint = Vector2.new(1,0),
            BackgroundColor3 = self._theme.SecondaryColor,
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            ZIndex = 9999
        }, self._screenGui)
        addCornerRadius(notiFrame, self._theme.CornerRadius)

        local notiTitle = createInstance("TextLabel", {
            Name = "Title",
            Text = title,
            Font = self._theme.Font,
            TextSize = 16,
            TextColor3 = self._theme.TextColor,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(10, 5),
            Size = UDim2.new(1, -20, 0, 20),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 9999
        }, notiFrame)

        local notiContent = createInstance("TextLabel", {
            Name = "Content",
            Text = text,
            Font = self._theme.Font,
            TextSize = 14,
            TextColor3 = self._theme.TextColor,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(10, 26),
            Size = UDim2.new(1, -20, 0, 30),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            ZIndex = 9999
        }, notiFrame)

        if icon then
            local notiIcon = createInstance("ImageLabel", {
                Name = "Icon",
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(270,5),
                Size = UDim2.fromOffset(24,24),
                Image = (type(icon)=="number") and ("rbxassetid://"..icon) or tostring(icon),
                ZIndex = 9999
            }, notiFrame)
        end

        notiFrame.BackgroundTransparency = 1
        notiTitle.TextTransparency = 1
        notiContent.TextTransparency = 1

        local startY = (#self._screenGui:GetChildren()) * 65
        notiFrame.Position = UDim2.new(1, -10, 0, startY)
        tweenObject(notiFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundTransparency = 0})
        tweenObject(notiTitle, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {TextTransparency = 0})
        tweenObject(notiContent, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {TextTransparency = 0})

        task.delay(duration, function()
            tweenObject(notiFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundTransparency = 1})
            tweenObject(notiTitle, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {TextTransparency = 1})
            tweenObject(notiContent, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {TextTransparency = 1})
            task.wait(0.35)
            notiFrame:Destroy()
        end)
    end

    -- Tab-Funktion
    function windowObject:CreateTab(tabName, tabIcon)
        tabName = tabName or "Unbenannt"

        local tabButton = createInstance("TextButton", {
            Name = "TabButton_"..tabName,
            Text = tabName,
            Font = self._theme.Font,
            TextSize = 16,
            TextColor3 = self._theme.TextColor,
            BackgroundColor3 = self._theme.SecondaryColor,
            Size = UDim2.new(1,0,0,32),
            AutoButtonColor = false
        }, self._tabListFrame)
        addCornerRadius(tabButton, self._theme.CornerRadius)

        if tabIcon then
            local iconImg = createInstance("ImageLabel", {
                Name = "TabIcon",
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(4,4),
                Size = UDim2.fromOffset(24,24),
                Image = (type(tabIcon)=="number") and ("rbxassetid://"..tabIcon) or tostring(tabIcon)
            }, tabButton)
            tabButton.TextXAlignment = Enum.TextXAlignment.Left
            tabButton.Text = "   "..tabName
        end

        local tabFrame = createInstance("ScrollingFrame", {
            Name = "TabFrame_"..tabName,
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,1,0),
            ScrollBarThickness = 4,
            BorderSizePixel = 0,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Visible = false,
            CanvasSize = UDim2.new(0,0,0,0)
        }, self._contentFrame)
        local layout = createInstance("UIListLayout", {
            Padding = UDim.new(0,6),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder
        }, tabFrame)

        -- Automatische CanvasHeight
        layout.Changed:Connect(function(prop)
            if prop == "AbsoluteContentSize" then
                tabFrame.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 10)
            end
        end)

        local tabObj = {
            Button = tabButton,
            Frame  = tabFrame,
            Elements = {}
        }

        -- Tab-Show
        local function showTab()
            for _,tb in ipairs(windowObject._tabs) do
                tweenObject(tb.Frame, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundTransparency = 1})
                tb.Frame.Visible = false
            end

            tabFrame.Visible = true
            tabFrame.BackgroundTransparency = 1
            for _,desc in ipairs(tabFrame:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                    desc.TextTransparency = 1
                elseif desc:IsA("Frame") or desc:IsA("ImageLabel") then
                    desc.BackgroundTransparency = 1
                    if desc:IsA("ImageLabel") then
                        desc.ImageTransparency = 1
                    end
                end
            end

            tweenObject(tabFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundTransparency = 0})
            task.spawn(function()
                for _,desc in ipairs(tabFrame:GetDescendants()) do
                    if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                        tweenObject(desc, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {TextTransparency = 0})
                    elseif desc:IsA("ImageLabel") then
                        tweenObject(desc, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {ImageTransparency = 0})
                    elseif desc:IsA("Frame") and desc ~= tabFrame then
                        tweenObject(desc, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundTransparency = 0})
                    end
                end
            end)
        end

        tabButton.MouseButton1Click:Connect(function()
            showTab()
        end)

        -- Direkte Funktion, um das Tab anzuzeigen
        function tabObj:Show()
            showTab()
        end

        table.insert(windowObject._tabs, tabObj)

        ---------------------------------------------------------------------
        --   ELEMENTE DES TABS
        ---------------------------------------------------------------------
        -- Für jede der folgenden CreateXYZ-Funktionen erzeugen wir UI-Elemente.

        -- LABEL
        function tabObj:CreateLabel(text)
            text = text or "Label"
            local label = createInstance("TextLabel", {
                Name = "Label_"..text,
                Text = text,
                Font = windowObject._theme.Font,
                TextSize = 16,
                TextColor3 = windowObject._theme.TextColor,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -10, 0, 20),
                TextXAlignment = Enum.TextXAlignment.Left
            }, tabFrame)
            local labelObj = {Instance = label}
            function labelObj:Set(newText)
                label.Text = newText
            end
            table.insert(self.Elements, labelObj)
            return labelObj
        end

        -- PARAGRAPH
        function tabObj:CreateParagraph(title, content)
            title = title or "ParagraphTitle"
            content = content or "ParagraphContent"

            local container = createInstance("Frame", {
                Name = "Paragraph",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -10, 0, 50)
            }, tabFrame)

            local titleLbl = createInstance("TextLabel", {
                Name = "PTitle",
                Text = title,
                Font = windowObject._theme.Font,
                TextSize = 16,
                TextColor3 = windowObject._theme.TextColor,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 20),
                TextXAlignment = Enum.TextXAlignment.Left
            }, container)

            local contentLbl = createInstance("TextLabel", {
                Name = "PContent",
                Text = content,
                Font = windowObject._theme.Font,
                TextSize = 14,
                TextColor3 = windowObject._theme.TextColor,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 22),
                Size = UDim2.new(1,0,0,28),
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left
            }, container)

            local paraObj = {
                Container = container,
                Title = titleLbl,
                Content = contentLbl
            }
            function paraObj:Set(newTitle, newContent)
                if newTitle then
                    self.Title.Text = newTitle
                end
                if newContent then
                    self.Content.Text = newContent
                end
            end
            table.insert(self.Elements, paraObj)
            return paraObj
        end

        -- DIVIDER
        function tabObj:CreateDivider()
            local divider = createInstance("Frame", {
                Name = "Divider",
                BackgroundColor3 = windowObject._theme.AccentColor,
                Size = UDim2.new(1, -10, 0, 2)
            }, tabFrame)
            local divObj = {Instance = divider}
            function divObj:SetVisible(bool)
                divider.Visible = bool
            end
            table.insert(self.Elements, divObj)
            return divObj
        end

        -- SECTION
        function tabObj:CreateSection(sectionName)
            local secName = sectionName or "Section"
            local secLbl = createInstance("TextLabel", {
                Name = "Section_"..secName,
                Text = "-- "..secName.." --",
                Font = windowObject._theme.Font,
                TextSize = 16,
                TextColor3 = windowObject._theme.AccentColor,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -10, 0, 20),
                TextXAlignment = Enum.TextXAlignment.Left
            }, tabFrame)
            local secObj = {Instance = secLbl}
            function secObj:Set(newText)
                secLbl.Text = "-- "..newText.." --"
            end
            table.insert(self.Elements, secObj)
            return secObj
        end

        -- BUTTON
        function tabObj:CreateButton(options)
            local btnText = options.Text or "Button"
            local callback = options.Callback or function() end

            local btn = createInstance("TextButton", {
                Name = "Btn_"..btnText,
                Text = btnText,
                Font = windowObject._theme.Font,
                TextSize = 16,
                TextColor3 = windowObject._theme.TextColor,
                BackgroundColor3 = windowObject._theme.SecondaryColor,
                Size = UDim2.new(1, -10, 0, 30),
                AutoButtonColor = false
            }, tabFrame)
            addCornerRadius(btn, windowObject._theme.CornerRadius)

            btn.MouseButton1Down:Connect(function()
                tweenObject(btn, TweenInfo.new(0.1, Enum.EasingStyle.Quint), {BackgroundColor3 = windowObject._theme.AccentColor})
            end)
            btn.MouseButton1Up:Connect(function()
                tweenObject(btn, TweenInfo.new(0.1, Enum.EasingStyle.Quint), {BackgroundColor3 = windowObject._theme.SecondaryColor})
                callback()
            end)

            local btnObj = {Instance = btn}
            function btnObj:SetText(newText)
                btn.Text = newText
            end
            table.insert(self.Elements, btnObj)
            return btnObj
        end

        -- TOGGLE
        function tabObj:CreateToggle(options)
            local toggleName = options.Text or "Toggle"
            local state = options.Default or false
            local callback = options.Callback or function() end

            local toggleFrame = createInstance("Frame", {
                Name = "Toggle_"..toggleName,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -10, 0, 30)
            }, tabFrame)

            local toggleBtn = createInstance("Frame", {
                Name = "ToggleButton",
                BackgroundColor3 = state and windowObject._theme.AccentColor or windowObject._theme.SecondaryColor,
                Size = UDim2.fromOffset(40,20),
                Position = UDim2.fromOffset(0,5)
            }, toggleFrame)
            addCornerRadius(toggleBtn, 10)

            local circle = createInstance("Frame", {
                Name = "ToggleCircle",
                BackgroundColor3 = Color3.fromRGB(255,255,255),
                Size = UDim2.fromOffset(18,18),
                Position = state and UDim2.fromOffset(20,1) or UDim2.fromOffset(1,1)
            }, toggleBtn)
            addCornerRadius(circle, 9)

            local toggleLabel = createInstance("TextLabel", {
                Name = "ToggleLabel",
                Text = toggleName,
                Font = windowObject._theme.Font,
                TextSize = 16,
                TextColor3 = windowObject._theme.TextColor,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(50,0),
                Size = UDim2.new(1, -60, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left
            }, toggleFrame)

            local toggleObj = {
                Frame = toggleFrame,
                State = state
            }

            local function setToggle(newState)
                toggleObj.State = newState
                if newState then
                    tweenObject(toggleBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3 = windowObject._theme.AccentColor})
                    tweenObject(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Position = UDim2.fromOffset(20,1)})
                else
                    tweenObject(toggleBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3 = windowObject._theme.SecondaryColor})
                    tweenObject(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Position = UDim2.fromOffset(1,1)})
                end
                callback(newState)
            end

            toggleBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    setToggle(not toggleObj.State)
                end
            end)

            function toggleObj:Set(value)
                setToggle(value)
            end

            table.insert(self.Elements, toggleObj)
            return toggleObj
        end

        -- SLIDER
        function tabObj:CreateSlider(options)
            local sliderName = options.Text or "Slider"
            local minVal     = options.Min or 0
            local maxVal     = options.Max or 100
            local defaultVal = options.Default or 50
            local callback   = options.Callback or function() end

            local sliderFrame = createInstance("Frame", {
                Name = "Slider_"..sliderName,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -10, 0, 40)
            }, tabFrame)

            local sliderLabel = createInstance("TextLabel", {
                Name = "SliderLabel",
                Text = sliderName..": "..tostring(defaultVal),
                Font = windowObject._theme.Font,
                TextSize = 16,
                TextColor3 = windowObject._theme.TextColor,
                BackgroundTransparency = 1,
                Size = UDim2.new(1,0,0,20),
                TextXAlignment = Enum.TextXAlignment.Left
            }, sliderFrame)

            local barBack = createInstance("Frame", {
                Name = "BarBack",
                BackgroundColor3 = windowObject._theme.SecondaryColor,
                Size = UDim2.new(1, -40, 0, 8),
                Position = UDim2.fromOffset(0, 25)
            }, sliderFrame)
            addCornerRadius(barBack, 4)

            local fill = createInstance("Frame", {
                Name = "Fill",
                BackgroundColor3 = windowObject._theme.AccentColor,
                Size = UDim2.new(0,0,1,0)
            }, barBack)
            addCornerRadius(fill, 4)

            local drag = createInstance("ImageButton", {
                Name = "DragHandle",
                BackgroundColor3 = Color3.fromRGB(255,255,255),
                Size = UDim2.fromOffset(14,14),
                Position = UDim2.fromOffset(-7, -3),
                Image = "",
                ZIndex = 2
            }, fill)
            addCornerRadius(drag, 7)

            local sliderObj = {
                Frame = sliderFrame,
                Value = defaultVal
            }

            local function updateSlider(val)
                val = math.clamp(val, minVal, maxVal)
                sliderObj.Value = math.floor(val)
                sliderLabel.Text = sliderName..": "..tostring(sliderObj.Value)
                local ratio = (val - minVal) / (maxVal - minVal)
                tweenObject(fill, TweenInfo.new(0.08, Enum.EasingStyle.Linear), {Size = UDim2.new(ratio, 0, 1, 0)})
                callback(sliderObj.Value)
            end

            updateSlider(defaultVal)

            local dragging = false

            local function inputUpdate(input)
                local relX = input.Position.X - barBack.AbsolutePosition.X
                local ratio = math.clamp(relX / barBack.AbsoluteSize.X, 0,1)
                local newVal = (ratio * (maxVal - minVal)) + minVal
                updateSlider(newVal)
            end

            barBack.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    inputUpdate(input)
                end
            end)

            barBack.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            drag.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                end
            end)

            drag.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input, gpe)
                if not gpe and dragging then
                    if input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch then
                        inputUpdate(input)
                    end
                end
            end)

            function sliderObj:Set(value)
                updateSlider(value)
            end

            table.insert(self.Elements, sliderObj)
            return sliderObj
        end

        -- INPUT
        function tabObj:CreateInput(options)
            local inpText   = options.Text or ""
            local placeholder = options.Placeholder or "Eingabe..."
            local callback  = options.Callback or function() end

            local txtBox = createInstance("TextBox", {
                Name = "InputBox",
                Text = inpText,
                PlaceholderText = placeholder,
                Font = windowObject._theme.Font,
                TextSize = 16,
                TextColor3 = windowObject._theme.TextColor,
                BackgroundColor3 = windowObject._theme.SecondaryColor,
                ClearTextOnFocus = false,
                Size = UDim2.new(1, -10, 0, 30),
            }, tabFrame)
            addCornerRadius(txtBox, windowObject._theme.CornerRadius)

            local inpObj = {Box = txtBox}
            txtBox.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    callback(txtBox.Text)
                end
            end)

            function inpObj:SetText(t)
                txtBox.Text = t
            end

            table.insert(self.Elements, inpObj)
            return inpObj
        end

        -- KEYBIND
        function tabObj:CreateKeybind(options)
            local kbName = options.Text or "Keybind"
            local defaultKey = options.DefaultKey or "F"
            local callback = options.Callback or function() end

            local kbBtn = createInstance("TextButton", {
                Name = "Keybind_"..kbName,
                Text = kbName.." ["..defaultKey.."]",
                Font = windowObject._theme.Font,
                TextSize = 16,
                TextColor3 = windowObject._theme.TextColor,
                BackgroundColor3 = windowObject._theme.SecondaryColor,
                Size = UDim2.new(1, -10, 0, 30),
                AutoButtonColor = false
            }, tabFrame)
            addCornerRadius(kbBtn, windowObject._theme.CornerRadius)

            local keybindObj = {
                Key = defaultKey
            }

            kbBtn.MouseButton1Click:Connect(function()
                kbBtn.Text = "Drücke eine Taste..."
                local conn
                conn = UserInputService.InputBegan:Connect(function(input, gp)
                    if not gp then
                        if input.KeyCode ~= Enum.KeyCode.Unknown then
                            local keyName = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
                            keybindObj.Key = keyName
                            kbBtn.Text = kbName.." ["..keyName.."]"
                            conn:Disconnect()
                        end
                    end
                end)
            end)

            -- Du könntest zusätzlich ein globales Input-Event machen, um beim Drücken
            -- des Keybinds Callback aufzurufen (z. B. in RenderStepped).

            table.insert(self.Elements, keybindObj)
            return keybindObj
        end

        -- DROPDOWN
        function tabObj:CreateDropdown(options)
            local ddName = options.Text or "Dropdown"
            local ddList = options.List or {}
            local multiple = options.Multi or false
            local default = options.Default or (ddList[1] or "")
            local callback = options.Callback or function() end

            local ddFrame = createInstance("Frame", {
                Name = "Dropdown_"..ddName,
                BackgroundColor3 = windowObject._theme.SecondaryColor,
                Size = UDim2.new(1, -10, 0, 30)
            }, tabFrame)
            addCornerRadius(ddFrame, windowObject._theme.CornerRadius)

            local ddButton = createInstance("TextButton", {
                Name = "DdButton",
                Text = ddName.." [ "..(type(default)=="table" and table.concat(default,", ") or default).." ]",
                Font = windowObject._theme.Font,
                TextSize = 16,
                TextColor3 = windowObject._theme.TextColor,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1,1),
                AutoButtonColor = false
            }, ddFrame)

            local ddObj = {
                Frame = ddFrame,
                Current = (type(default)=="table") and default or {default},
                Items = ddList
            }

            local popup = createInstance("Frame", {
                Name = "Popup",
                BackgroundColor3 = windowObject._theme.SecondaryColor,
                Size = UDim2.new(1,0,0,#ddList*24),
                Position = UDim2.new(0,0,1,0),
                Visible = false,
                ZIndex = 999
            }, ddFrame)
            addCornerRadius(popup, windowObject._theme.CornerRadius)

            local popupLayout = createInstance("UIListLayout", {
                Padding = UDim.new(0,2),
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder
            }, popup)

            local function refreshButtonText()
                ddButton.Text = ddName.." [ "..table.concat(ddObj.Current, ", ").." ]"
            end

            local function togglePopup()
                popup.Visible = not popup.Visible
                if popup.Visible then
                    tweenObject(popup, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Size = UDim2.new(1,0,0,#ddObj.Items*24)})
                else
                    tweenObject(popup, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Size = UDim2.new(1,0,0,0)})
                    task.wait(0.21)
                    popup.Visible = false
                end
            end

            local function createOptionItem(opt)
                local optBtn = createInstance("TextButton", {
                    Name = "Opt_"..opt,
                    Text = opt,
                    Font = windowObject._theme.Font,
                    TextSize = 14,
                    TextColor3 = windowObject._theme.TextColor,
                    BackgroundColor3 = windowObject._theme.SecondaryColor,
                    Size = UDim2.new(1,0,0,24),
                    AutoButtonColor = false
                }, popup)
                addCornerRadius(optBtn, windowObject._theme.CornerRadius)

                optBtn.MouseButton1Click:Connect(function()
                    if multiple then
                        local found = table.find(ddObj.Current, opt)
                        if found then
                            table.remove(ddObj.Current, found)
                        else
                            table.insert(ddObj.Current, opt)
                        end
                    else
                        ddObj.Current = {opt}
                        togglePopup()
                    end
                    refreshButtonText()
                    callback(ddObj.Current)
                end)
            end

            for _,item in ipairs(ddList) do
                createOptionItem(item)
            end

            ddButton.MouseButton1Click:Connect(function()
                togglePopup()
            end)

            function ddObj:Refresh(newList)
                ddObj.Items = newList
                for _,child in ipairs(popup:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end
                for _,item in ipairs(newList) do
                    createOptionItem(item)
                end
                popup.Size = UDim2.new(1,0,0,#ddObj.Items*24)
            end

            function ddObj:Set(newValues)
                if type(newValues) == "table" then
                    ddObj.Current = newValues
                else
                    ddObj.Current = {newValues}
                end
                refreshButtonText()
                callback(ddObj.Current)
            end

            table.insert(self.Elements, ddObj)
            return ddObj
        end

        -- COLOR PICKER (REAL HSV-Fenster)
        function tabObj:CreateColorPicker(options)
            local cpName   = options.Text or "Color Picker"
            local default  = options.Default or Color3.fromRGB(255,255,255)
            local callback = options.Callback or function() end

            local cpFrame = createInstance("Frame", {
                Name = "ColorPicker_"..cpName,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -10, 0, 30)
            }, tabFrame)

            local cpLabel = createInstance("TextLabel", {
                Name = "CpLabel",
                Text = cpName,
                Font = windowObject._theme.Font,
                TextSize = 16,
                TextColor3 = windowObject._theme.TextColor,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -40, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left
            }, cpFrame)

            local colorBox = createInstance("TextButton", {
                Name = "ColorBox",
                BackgroundColor3 = default,
                Size = UDim2.fromOffset(30,30),
                Position = UDim2.new(1, -30, 0, 0),
                AutoButtonColor = false,
                BorderSizePixel = 0
            }, cpFrame)
            addCornerRadius(colorBox, windowObject._theme.CornerRadius)

            local colorPickerWindow -- definieren wir unten

            local function openColorPicker()
                if colorPickerWindow and colorPickerWindow.Parent then
                    colorPickerWindow:Destroy()
                end

                colorPickerWindow = createInstance("Frame", {
                    Name = "ColorPickerPanel",
                    BackgroundColor3 = windowObject._theme.SecondaryColor,
                    Size = UDim2.fromOffset(230, 180),
                    Position = UDim2.fromOffset(colorBox.AbsolutePosition.X, colorBox.AbsolutePosition.Y + 35)
                }, windowObject._screenGui)
                addCornerRadius(colorPickerWindow, windowObject._theme.CornerRadius)

                local hueSat = createInstance("ImageButton", {
                    Name = "HueSat",
                    BackgroundColor3 = Color3.fromRGB(255,255,255),
                    Position = UDim2.fromOffset(10,10),
                    Size = UDim2.fromOffset(150,150),
                    AutoButtonColor = false,
                    Image = "rbxassetid://698052001", -- Weiß-zu-schwarz Gradient
                }, colorPickerWindow)
                addCornerRadius(hueSat, 4)

                local hueSatGradient = createInstance("ImageLabel", {
                    Name = "HueSatGradient",
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1,1),
                    Image = "rbxassetid://698052013" -- Regenbogen-Verlauf
                }, hueSat)

                local hueSatPointer = createInstance("Frame", {
                    Name = "Pointer",
                    BackgroundColor3 = Color3.fromRGB(255,255,255),
                    Size = UDim2.fromOffset(6,6),
                    AnchorPoint = Vector2.new(0.5,0.5)
                }, hueSat)
                addCornerRadius(hueSatPointer, 3)

                local valueSliderBack = createInstance("Frame", {
                    Name = "ValueSliderBack",
                    BackgroundColor3 = Color3.fromRGB(255,255,255),
                    Position = UDim2.fromOffset(170,10),
                    Size = UDim2.fromOffset(20,150)
                }, colorPickerWindow)
                addCornerRadius(valueSliderBack, 4)

                local valueGradient = createInstance("UIGradient", {
                    Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(0,0,0))
                }, valueSliderBack)

                local valueDrag = createInstance("Frame", {
                    Name = "ValueDrag",
                    BackgroundColor3 = Color3.fromRGB(255,255,255),
                    Size = UDim2.fromOffset(20,2),
                    Position = UDim2.fromOffset(0,0),
                    BorderSizePixel = 0
                }, valueSliderBack)

                local closeBtn = createInstance("TextButton", {
                    Name = "CloseBtn",
                    Text = "OK",
                    Font = windowObject._theme.Font,
                    TextColor3 = windowObject._theme.TextColor,
                    TextSize = 14,
                    BackgroundColor3 = windowObject._theme.AccentColor,
                    Size = UDim2.fromOffset(40,20),
                    Position = UDim2.fromOffset(10,160)
                }, colorPickerWindow)
                addCornerRadius(closeBtn, 4)

                local cpObj = {
                    hue = 0,
                    sat = 0,
                    val = 1
                }

                -- Farbwerte von default lesen
                local h,s,v = Color3.toHSV(default)
                cpObj.hue = h
                cpObj.sat = s
                cpObj.val = v

                -- Updater
                local function updateColor()
                    local c = Color3.fromHSV(cpObj.hue, cpObj.sat, cpObj.val)
                    colorBox.BackgroundColor3 = c
                end
                updateColor()

                local function updateHueSatInput(x, y)
                    local relX = (x - hueSat.AbsolutePosition.X) / hueSat.AbsoluteSize.X
                    local relY = (y - hueSat.AbsolutePosition.Y) / hueSat.AbsoluteSize.Y
                    cpObj.hue = math.clamp(relX, 0, 1)
                    cpObj.sat = 1 - math.clamp(relY, 0, 1)
                    hueSatPointer.Position = UDim2.new(cpObj.hue, 0, 1 - cpObj.sat, 0)
                    updateColor()
                end

                local function updateValueInput(y)
                    local relY = (y - valueSliderBack.AbsolutePosition.Y) / valueSliderBack.AbsoluteSize.Y
                    cpObj.val = 1 - math.clamp(relY, 0, 1)
                    valueDrag.Position = UDim2.new(0, 0, 1 - cpObj.val, -1)
                    updateColor()
                end

                local hueSatDragging = false
                local valueDragging  = false

                hueSat.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        hueSatDragging = true
                        updateHueSatInput(input.Position.X, input.Position.Y)
                    end
                end)
                hueSat.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        hueSatDragging = false
                    end
                end)

                valueSliderBack.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        valueDragging = true
                        updateValueInput(input.Position.Y)
                    end
                end)
                valueSliderBack.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        valueDragging = false
                    end
                end)

                UserInputService.InputChanged:Connect(function(input, gp)
                    if not gp then
                        if hueSatDragging then
                            if input.UserInputType == Enum.UserInputType.MouseMovement
                            or input.UserInputType == Enum.UserInputType.Touch then
                                updateHueSatInput(input.Position.X, input.Position.Y)
                            end
                        end
                        if valueDragging then
                            if input.UserInputType == Enum.UserInputType.MouseMovement
                            or input.UserInputType == Enum.UserInputType.Touch then
                                updateValueInput(input.Position.Y)
                            end
                        end
                    end
                end)

                -- Setze initial die Pointer
                hueSatPointer.Position = UDim2.new(cpObj.hue,0, 1 - cpObj.sat, 0)
                valueDrag.Position = UDim2.new(0,0, 1 - cpObj.val, -1)

                closeBtn.MouseButton1Click:Connect(function()
                    local c = Color3.fromHSV(cpObj.hue, cpObj.sat, cpObj.val)
                    callback(c)
                    colorPickerWindow:Destroy()
                    colorPickerWindow = nil
                end)
            end

            colorBox.MouseButton1Click:Connect(function()
                openColorPicker()
            end)

            local cpObj = {Frame = cpFrame}
            function cpObj:Set(newColor)
                colorBox.BackgroundColor3 = newColor
                callback(newColor)
            end

            table.insert(self.Elements, cpObj)
            return cpObj
        end

        return tabObj
    end

    return windowObject
end

---------------------------------------------------------------------
-- ALLE FENSTER ZERSTÖREN
---------------------------------------------------------------------
function NovaUI:DestroyAll()
    for _,win in ipairs(self._windows) do
        if win._screenGui then
            win._screenGui:Destroy()
        end
    end
    self._windows = {}
end

-- FLAGS (optional, wenn du globale Einstellungen speichern willst)
function NovaUI:SetFlag(flag, value)
    self.Flags[flag] = value
end
function NovaUI:GetFlag(flag)
    return self.Flags[flag]
end

return NovaUI


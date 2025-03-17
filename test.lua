--[[
   SelfWareUI by cyberseall
   - Endlevel moderne UI-Library für Roblox
   - Mit Glas-Effekt, Blur, hochmodernen Notifications, Sound, Keysystem
   - Dark-Purple Standardtheme + DarkRed und Light Themes
   - Oben rechts: Settings-Icon, Minimieren, Schließen + Keybind Hide/Show
   - Autor: Du (und ChatGPT)
   Lizenz: Frei nutzbar (z.B. MIT)
]]

----------------------------------------------------------
-- 0) SERVICES & LOKALE HILFSFUNKTIONEN
----------------------------------------------------------
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local SelfWareUI = {}
SelfWareUI._windows = {}
SelfWareUI.Flags = {}

-- THEMES
SelfWareUI.Themes = {
    DarkPurple = {
        MainColor      = Color3.fromRGB(30, 0, 45),     -- Leicht transparenter, dunkler Violett-Ton
        SecondaryColor = Color3.fromRGB(50, 0, 80),
        AccentColor    = Color3.fromRGB(190, 60, 255),  -- Leuchtendes Lila
        TextColor      = Color3.fromRGB(245, 245, 245),
        BackgroundFade = 0.2,
        CornerRadius   = 12,
        ShadowColor    = Color3.new(0,0,0),
        ShadowOpacity  = 0.4,
        Font           = Enum.Font.Gotham
    },
    DarkRed = {
        MainColor      = Color3.fromRGB(45, 0, 0),
        SecondaryColor = Color3.fromRGB(60, 0, 0),
        AccentColor    = Color3.fromRGB(255, 70, 70),
        TextColor      = Color3.fromRGB(240, 240, 240),
        BackgroundFade = 0.2,
        CornerRadius   = 12,
        ShadowColor    = Color3.new(0,0,0),
        ShadowOpacity  = 0.4,
        Font           = Enum.Font.Gotham
    },
    Light = {
        MainColor      = Color3.fromRGB(235, 235, 235),
        SecondaryColor = Color3.fromRGB(210, 210, 210),
        AccentColor    = Color3.fromRGB(160, 80, 255),
        TextColor      = Color3.fromRGB(35, 35, 35),
        BackgroundFade = 0.05,
        CornerRadius   = 10,
        ShadowColor    = Color3.new(0,0,0),
        ShadowOpacity  = 0.2,
        Font           = Enum.Font.Gotham
    }
}

-- Default-Theme, falls der Nutzer nichts wählt
SelfWareUI._defaultTheme = "DarkPurple"

local function createInstance(class, props, parent)
    local obj = Instance.new(class)
    for k,v in pairs(props) do
        obj[k] = v
    end
    if parent then
        obj.Parent = parent
    end
    return obj
end

local function addCornerRadius(obj, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = obj
    return corner
end

local function tweenObject(obj, tweenInfo, goal)
    local tw = TweenService:Create(obj, tweenInfo, goal)
    tw:Play()
    return tw
end

-- DropShadow-Helfer (wie ein Container, in den wir unser Frame packen)
local function addDropShadow(frame, color, opacity)
    local shadowHolder = createInstance("Frame", {
        Name = "ShadowHolder",
        BackgroundTransparency = 1,
        Size = frame.Size,
        Position = frame.Position,
        AnchorPoint = frame.AnchorPoint,
        ZIndex = frame.ZIndex - 1
    }, frame.Parent)

    frame.Parent = shadowHolder
    frame.ZIndex = frame.ZIndex + 1

    local shadow = createInstance("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 60, 1, 60),
        Image = "rbxassetid://1316045217",
        BackgroundTransparency = 1,
        ImageColor3 = color,
        ImageTransparency = 1 - opacity, -- da 1= komplett transparent
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(10,10,118,118)
    }, shadowHolder)

    return shadowHolder
end

-- Drag-Funktion
local function dragify(frame, handle)
    local dragging = false
    local dragInput, startPos, startOffset

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startPos = input.Position
            startOffset = frame.Position
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    conn:Disconnect()
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if ( input.UserInputType == Enum.UserInputType.MouseMovement
          or input.UserInputType == Enum.UserInputType.Touch ) then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - startPos
            local newPos = UDim2.new(
                startOffset.X.Scale,
                startOffset.X.Offset + delta.X,
                startOffset.Y.Scale,
                startOffset.Y.Offset + delta.Y
            )
            tweenObject(frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = newPos})
        end
    end)
end

-- Spielsound abspielen (z.B. Button-Klick)
local function playSound(id)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://"..tostring(id)
    sound.Volume = 2
    sound.PlayOnRemove = true
    sound.Parent = game.SoundService
    sound:Destroy()
end

-- Blur + Anzeige "SelfWare UI by cyberseall"
local function showIntro()
    -- Blur-Effekt
    local blur = Instance.new("BlurEffect")
    blur.Size = 0
    blur.Parent = Lighting
    tweenObject(blur, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Size = 10})

    -- ScreenGui für Intro
    local introGui = Instance.new("ScreenGui")
    introGui.Name = "SelfWareIntro"
    introGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    introGui.IgnoreGuiInset = true
    introGui.ResetOnSpawn = false
    introGui.Parent = game.CoreGui

    local frame = createInstance("Frame", {
        BackgroundColor3 = Color3.fromRGB(0,0,0),
        BackgroundTransparency = 0.4,
        Size = UDim2.fromScale(1,1)
    }, introGui)

    local introLabel = createInstance("TextLabel", {
        Text = "SelfWare UI by cyberseall",
        Font = Enum.Font.GothamBold,
        TextColor3 = Color3.fromRGB(255,255,255),
        TextSize = 34,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.fromScale(0.5,0.5),
        Size = UDim2.new(0,600,0,50)
    }, frame)

    -- 2s Pause, dann fade out
    task.delay(2, function()
        tweenObject(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {BackgroundTransparency = 1})
        tweenObject(introLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 1})
        tweenObject(blur, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Size = 0})
        task.wait(0.6)
        introGui:Destroy()
        blur:Destroy()
    end)
end

----------------------------------------------------------
-- 1) MAIN-FUNKTION: CREATEWINDOW
----------------------------------------------------------
function SelfWareUI:CreateWindow(options)
    options = options or {}
    local title      = options.Title or "SelfWare Window"
    local subtitle   = options.Subtitle or "by cyberseall"
    local themeName  = options.Theme or SelfWareUI._defaultTheme
    local iconId     = options.Icon or nil
    local keySystem  = options.KeySystem or false
    local validKeys  = options.Keys or {"SelfWare"}  -- Liste erlaubter Keys
    local settingsKeyBind = Enum.KeyCode.RightControl -- Default Keybind

    if not SelfWareUI.Themes[themeName] then
        warn("[SelfWareUI] Theme '"..themeName.."' wurde nicht gefunden. Nutze Standard (DarkPurple).")
        themeName = SelfWareUI._defaultTheme
    end
    local theme = SelfWareUI.Themes[themeName]

    -- Nur einmal pro Session das Intro anzeigen
    if #SelfWareUI._windows == 0 then
        showIntro()
    end

    -- ScreenGui
    local screenGui = createInstance("ScreenGui", {
        Name = "SelfWareUI_"..title,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        ResetOnSpawn   = false
    }, game.CoreGui)

    -- Haupt-Frame
    local mainFrame = createInstance("Frame", {
        Name = "MainFrame",
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.fromScale(0.5,0.5),
        Size = UDim2.new(0,700, 0,420),
        BackgroundColor3 = theme.MainColor,
        BackgroundTransparency = theme.BackgroundFade,
        ClipsDescendants = true
    }, screenGui)
    addCornerRadius(mainFrame, theme.CornerRadius)
    local shadow = addDropShadow(mainFrame, theme.ShadowColor, theme.ShadowOpacity)

    -- TOP-BAR
    local topBar = createInstance("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1,0, 0,36),
        BackgroundColor3 = theme.SecondaryColor
    }, mainFrame)
    addCornerRadius(topBar, theme.CornerRadius)

    local titleLabel = createInstance("TextLabel", {
        Name = "TitleLabel",
        Text = title,
        Font = theme.Font,
        TextSize = 20,
        TextColor3 = theme.TextColor,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10,0),
        Size = UDim2.new(1, -10, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left
    }, topBar)

    if iconId then
        local iconImg = createInstance("ImageLabel", {
            Name = "TitleIcon",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(5,5),
            Size = UDim2.fromOffset(26,26),
            Image = (type(iconId)=="string") and iconId or ("rbxassetid://"..iconId)
        }, topBar)
        titleLabel.Position = UDim2.fromOffset(40,0)
        titleLabel.Size = UDim2.new(1, -40, 1, 0)
    end

    local subLabel = createInstance("TextLabel", {
        Name = "Subtitle",
        Text = subtitle,
        Font = theme.Font,
        TextSize = 14,
        TextColor3 = theme.TextColor,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 36),
        Size = UDim2.new(1, -10, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Left
    }, mainFrame)

    -- ContentFrame (großer Container für Tabs etc.)
    local contentFrame = createInstance("Frame", {
        Name = "ContentFrame",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 60),
        Size = UDim2.new(1, 0, 1, -60)
    }, mainFrame)

    -- SETTINGS-, MINIMIZE- und CLOSE-Buttons oben rechts
    local closeBtn = createInstance("TextButton", {
        Name = "CloseButton",
        Text = "X",
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextColor3 = Color3.fromRGB(255,70,70),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -35, 0, 0),
        Size = UDim2.fromOffset(35,36)
    }, topBar)

    local minimizeBtn = createInstance("TextButton", {
        Name = "MinimizeButton",
        Text = "-",
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextColor3 = theme.TextColor,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -70, 0, 0),
        Size = UDim2.fromOffset(35,36)
    }, topBar)

    local settingsBtn = createInstance("TextButton", {
        Name = "SettingsButton",
        Text = "⚙",
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = theme.TextColor,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -105, 0, 0),
        Size = UDim2.fromOffset(35,36)
    }, topBar)

    -- SETTINGS-FRAME (Popup)
    local settingsFrame = createInstance("Frame", {
        Name = "SettingsFrame",
        BackgroundColor3 = theme.SecondaryColor,
        Size = UDim2.new(0, 200, 0, 120),
        Position = UDim2.new(1, -210, 0, 38),
        Visible = false,
        ZIndex = 999
    }, mainFrame)
    addCornerRadius(settingsFrame, theme.CornerRadius)

    local settingsLayout = createInstance("UIListLayout", {
        Padding = UDim.new(0,5),
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder
    }, settingsFrame)

    -- "Keybind to Hide/Show" label
    local keybindLabel = createInstance("TextLabel", {
        Name = "KeybindLabel",
        Text = "Hide/Show Keybind:",
        Font = theme.Font,
        TextSize = 14,
        TextColor3 = theme.TextColor,
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,0,20),
        ZIndex = 999
    }, settingsFrame)

    local keybindButton = createInstance("TextButton", {
        Name = "KeybindButton",
        Text = "[RightControl]",
        Font = theme.Font,
        TextSize = 14,
        TextColor3 = theme.TextColor,
        BackgroundColor3 = theme.MainColor,
        Size = UDim2.new(1, -10, 0, 24),
        ZIndex = 999
    }, settingsFrame)
    addCornerRadius(keybindButton, theme.CornerRadius)

    local manualHideBtn = createInstance("TextButton", {
        Name = "ManualHide",
        Text = "Hide UI",
        Font = theme.Font,
        TextSize = 14,
        TextColor3 = theme.TextColor,
        BackgroundColor3 = theme.MainColor,
        Size = UDim2.new(1, -10, 0, 24),
        ZIndex = 999
    }, settingsFrame)
    addCornerRadius(manualHideBtn, theme.CornerRadius)

    local function showSettingsFrame(show)
        settingsFrame.Visible = show
        if show then
            settingsFrame.Size = UDim2.new(0,200,0,0)
            settingsFrame:TweenSize(UDim2.new(0,200,0,120), "Out", "Quad", 0.2, true)
        else
            settingsFrame:TweenSize(UDim2.new(0,200,0,0), "Out", "Quad", 0.2, true)
            task.delay(0.25, function()
                if not settingsFrame then return end
                settingsFrame.Visible = false
            end)
        end
    end

    settingsBtn.MouseButton1Click:Connect(function()
        playSound(5419091377) -- Klick-Sound
        showSettingsFrame(not settingsFrame.Visible)
    end)

    -- Minimieren
    local minimized = false
    minimizeBtn.MouseButton1Click:Connect(function()
        playSound(5419091377)
        minimized = not minimized
        if minimized then
            minimizeBtn.Text = "+"
            contentFrame.Visible = false
            subLabel.Visible = false
            mainFrame:TweenSize(UDim2.new(0,700, 0,36), "Out", "Quint", 0.3, true)
        else
            minimizeBtn.Text = "-"
            mainFrame:TweenSize(UDim2.new(0,700, 0,420), "Out", "Quint", 0.3, true)
            task.delay(0.31, function()
                contentFrame.Visible = true
                subLabel.Visible = true
            end)
        end
    end)

    -- Close
    closeBtn.MouseButton1Click:Connect(function()
        playSound(5419091377)
        windowObject:Destroy()
    end)

    -- Hide UI (toggle)
    local hiddenUI = false
    local function setUIHidden(state)
        hiddenUI = state
        mainFrame.Visible = not state
    end
    manualHideBtn.MouseButton1Click:Connect(function()
        playSound(5419091377)
        setUIHidden(true)
    end)

    -- Keybind zum Hide/Show
    keybindButton.MouseButton1Click:Connect(function()
        playSound(5419091377)
        keybindButton.Text = "Press any key..."
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gp)
            if not gp then
                if input.KeyCode ~= Enum.KeyCode.Unknown then
                    settingsKeyBind = input.KeyCode
                    keybindButton.Text = "["..tostring(settingsKeyBind).."]"
                    conn:Disconnect()
                end
            end
        end)
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == settingsKeyBind then
            setUIHidden(not hiddenUI)
        end
    end)

    -- KeySystem-Fenster (falls KeySystem=true)
    local function openKeySystem(callback)
        local keyGui = createInstance("ScreenGui", {
            Name = "SelfWareKeySystem",
            ZIndexBehavior = Enum.ZIndexBehavior.Global,
            ResetOnSpawn = false
        }, game.CoreGui)

        local keyFrame = createInstance("Frame", {
            BackgroundColor3 = theme.SecondaryColor,
            Size = UDim2.new(0, 300, 0, 150),
            AnchorPoint = Vector2.new(0.5,0.5),
            Position = UDim2.fromScale(0.5,0.5)
        }, keyGui)
        addCornerRadius(keyFrame, theme.CornerRadius)
        addDropShadow(keyFrame, theme.ShadowColor, theme.ShadowOpacity)

        local promptLbl = createInstance("TextLabel", {
            Text = "Please enter the Key to continue",
            Font = theme.Font,
            TextSize = 16,
            TextColor3 = theme.TextColor,
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,0,40),
            Position = UDim2.fromOffset(0,10)
        }, keyFrame)

        local textBox = createInstance("TextBox", {
            Text = "",
            PlaceholderText = "Key hier eingeben...",
            Font = theme.Font,
            TextSize = 14,
            TextColor3 = theme.TextColor,
            BackgroundColor3 = theme.MainColor,
            Size = UDim2.new(0.8,0,0,30),
            Position = UDim2.fromScale(0.5,0.5),
            AnchorPoint = Vector2.new(0.5,0.5),
            ClearTextOnFocus = false
        }, keyFrame)
        addCornerRadius(textBox, theme.CornerRadius)

        local confirmBtn = createInstance("TextButton", {
            Text = "Confirm",
            Font = theme.Font,
            TextSize = 14,
            TextColor3 = theme.TextColor,
            BackgroundColor3 = theme.AccentColor,
            Size = UDim2.new(0.8,0,0,30),
            Position = UDim2.fromScale(0.5,0.8),
            AnchorPoint = Vector2.new(0.5,0.5)
        }, keyFrame)
        addCornerRadius(confirmBtn, theme.CornerRadius)

        confirmBtn.MouseButton1Click:Connect(function()
            playSound(5419091377)
            local entered = textBox.Text
            -- Check ob Key passt
            for _,k in ipairs(validKeys) do
                if entered == k then
                    keyGui:Destroy()
                    callback(true)
                    return
                end
            end
            promptLbl.Text = "Falscher Key! Versuche es erneut."
        end)
    end

    -- Objekt mit Infos, Tabs etc.
    local windowObject = {
        _screenGui = screenGui,
        _mainFrame = mainFrame,
        _contentFrame = contentFrame,
        _theme      = theme,
        _tabs       = {}
    }
    table.insert(SelfWareUI._windows, windowObject)

    -- Draggify
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

    local fadeIn = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    tweenObject(mainFrame, fadeIn, {BackgroundTransparency = theme.BackgroundFade})
    tweenObject(topBar, fadeIn, {BackgroundTransparency = 0})
    tweenObject(subLabel, fadeIn, {TextTransparency = 0})
    task.spawn(function()
        for _,desc in ipairs(mainFrame:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                tweenObject(desc, fadeIn, {TextTransparency = 0})
            elseif desc:IsA("ImageLabel") then
                tweenObject(desc, fadeIn, {ImageTransparency = 0})
            elseif desc:IsA("Frame") and (desc ~= mainFrame and desc ~= topBar) then
                tweenObject(desc, fadeIn, {BackgroundTransparency = 0})
            end
        end
    end)

    -- KeySystem abhandeln (falls gewünscht)
    if keySystem then
        setUIHidden(true)  -- erst unsichtbar, bis Key eingegeben
        openKeySystem(function(success)
            if success then
                setUIHidden(false)
            else
                -- Du könntest hier "Destroy" oder so machen:
                windowObject:Destroy()
            end
        end)
    end

    ---------------------------------------------------------
    -- 2) NOTIFICATION-FUNKTION
    ---------------------------------------------------------
    function windowObject:Notify(data)
        local notifTitle = data.Title or "Notification"
        local notifText  = data.Content or ""
        local duration   = data.Duration or 4
        local iconId     = data.Icon or nil

        local notifFrame = createInstance("Frame", {
            Name = "NotifFrame",
            BackgroundColor3 = self._theme.SecondaryColor,
            Size = UDim2.new(0,300, 0,60),
            Position = UDim2.new(1, 310, 0, 50), -- Start: etwas rechts außerhalb
            AnchorPoint = Vector2.new(1,0),
            ClipsDescendants = true,
            ZIndex = 9999
        }, self._screenGui)
        addCornerRadius(notifFrame, self._theme.CornerRadius)

        local notifTitleLbl = createInstance("TextLabel", {
            Name = "NotifTitle",
            Text = notifTitle,
            Font = self._theme.Font,
            TextSize = 16,
            TextColor3 = self._theme.TextColor,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(10,5),
            Size = UDim2.new(1, -20, 0, 20),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 9999
        }, notifFrame)

        local notifTextLbl = createInstance("TextLabel", {
            Name = "NotifText",
            Text = notifText,
            Font = self._theme.Font,
            TextSize = 14,
            TextColor3 = self._theme.TextColor,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(10,26),
            Size = UDim2.new(1, -20, 0, 30),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            ZIndex = 9999
        }, notifFrame)

        if iconId then
            local nIcon = createInstance("ImageLabel", {
                Name = "Icon",
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -35, 0, 5),
                Size = UDim2.fromOffset(24,24),
                Image = (type(iconId)=="string") and iconId or ("rbxassetid://"..iconId),
                ZIndex = 9999
            }, notifFrame)
        end

        -- Start invisible
        notifFrame.Position = UDim2.new(1, 320, 0, 50)
        notifFrame.BackgroundTransparency = 1
        notifTitleLbl.TextTransparency = 1
        notifTextLbl.TextTransparency = 1

        local showT = TweenInfo.new(0.4, Enum.EasingStyle.Quint)
        tweenObject(notifFrame, showT, {Position = UDim2.new(1, -10, 0, 50), BackgroundTransparency = 0})
        tweenObject(notifTitleLbl, showT, {TextTransparency = 0})
        tweenObject(notifTextLbl, showT, {TextTransparency = 0})

        -- Fade out nach 'duration'
        task.delay(duration, function()
            local hideT = TweenInfo.new(0.4, Enum.EasingStyle.Quint)
            tweenObject(notifFrame, hideT, {Position = UDim2.new(1, 320, 0, 50), BackgroundTransparency = 1})
            tweenObject(notifTitleLbl, hideT, {TextTransparency = 1})
            tweenObject(notifTextLbl, hideT, {TextTransparency = 1})
            task.wait(0.45)
            notifFrame:Destroy()
        end)
    end

    ---------------------------------------------------------
    -- 3) DESTROY-FUNKTION
    ---------------------------------------------------------
    function windowObject:Destroy()
        tweenObject(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundTransparency = 1})
        for _,desc in ipairs(mainFrame:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                tweenObject(desc, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {TextTransparency = 1})
            elseif desc:IsA("Frame") or desc:IsA("ImageLabel") then
                tweenObject(desc, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundTransparency = 1, ImageTransparency = 1})
            end
        end
        task.delay(0.35, function()
            screenGui:Destroy()
        end)
    end

    ---------------------------------------------------------
    -- 4) TAB-ERSTELLUNG
    ---------------------------------------------------------
    function windowObject:CreateTab(tabName, tabIcon)
        local tab = {}
        tabName = tabName or "Unbenannt"

        local tabFrame = createInstance("ScrollingFrame", {
            Name = "Tab_"..tabName,
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,1,0),
            ScrollBarThickness = 6,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Visible = false,
            CanvasSize = UDim2.new(0,0,0,0)
        }, contentFrame)
        local layout = createInstance("UIListLayout", {
            Padding = UDim.new(0,6),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder
        }, tabFrame)
        layout.Changed:Connect(function(prop)
            if prop == "AbsoluteContentSize" then
                tabFrame.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 10)
            end
        end)

        local tabBtn = createInstance("TextButton", {
            Name = "TabButton_"..tabName,
            Text = tabName,
            Font = theme.Font,
            TextSize = 16,
            TextColor3 = theme.TextColor,
            BackgroundColor3 = theme.SecondaryColor,
            Size = UDim2.new(0,120,0,30),
            Parent = mainFrame -- Wir könnten z.B. links eine TabBar bauen – Für Demo fügen wir es oben links an
        })
        addCornerRadius(tabBtn, theme.CornerRadius)
        tabBtn.Position = UDim2.new(0, 10 + (#windowObject._tabs * 130), 0, 64)

        if tabIcon then
            local iconImg = createInstance("ImageLabel", {
                Name = "TabIcon",
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(4,4),
                Size = UDim2.fromOffset(22,22),
                Image = (type(tabIcon)=="string") and tabIcon or ("rbxassetid://"..tabIcon)
            }, tabBtn)
            tabBtn.TextXAlignment = Enum.TextXAlignment.Left
            tabBtn.Text = "   "..tabName
        end

        local function showTab()
            for _,tb in ipairs(windowObject._tabs) do
                tb.Frame.Visible = false
            end
            tabFrame.Visible = true
        end

        tabBtn.MouseButton1Click:Connect(function()
            playSound(5419091377)
            showTab()
        end)

        -- Dem Benutzer ermöglichen, es direkt zu zeigen
        function tab:Show()
            showTab()
        end
        tab.Frame = tabFrame
        tab.Elements = {}

        -- Erstelle nun UI-Element-Funktionen (Button, Toggle etc.)
        function tab:CreateLabel(text)
            local lbl = createInstance("TextLabel", {
                BackgroundTransparency = 1,
                Font = theme.Font,
                TextSize = 16,
                TextColor3 = theme.TextColor,
                Size = UDim2.new(1, -10, 0, 20),
                Text = text or "Label"
            }, tabFrame)
            local obj = {Instance = lbl}
            function obj:Set(newText)
                lbl.Text = newText
            end
            table.insert(tab.Elements, obj)
            return obj
        end

        function tab:CreateParagraph(title, content)
            local container = createInstance("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -10, 0, 50)
            }, tabFrame)

            local titleLbl = createInstance("TextLabel", {
                BackgroundTransparency = 1,
                Font = theme.Font,
                TextSize = 16,
                TextColor3 = theme.TextColor,
                Text = title or "Paragraph Title",
                Size = UDim2.new(1,0,0,20),
                TextXAlignment = Enum.TextXAlignment.Left
            }, container)

            local contentLbl = createInstance("TextLabel", {
                BackgroundTransparency = 1,
                Font = theme.Font,
                TextSize = 14,
                TextColor3 = theme.TextColor,
                Text = content or "Paragraph Content",
                Size = UDim2.new(1,0,0,30),
                Position = UDim2.fromOffset(0,20),
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left
            }, container)

            local obj = {Container=container, Title=titleLbl, Content=contentLbl}
            function obj:Set(newTitle,newContent)
                if newTitle then
                    titleLbl.Text = newTitle
                end
                if newContent then
                    contentLbl.Text = newContent
                end
            end
            table.insert(tab.Elements, obj)
            return obj
        end

        function tab:CreateDivider()
            local div = createInstance("Frame", {
                BackgroundColor3 = theme.AccentColor,
                Size = UDim2.new(1, -10, 0, 2)
            }, tabFrame)
            local obj = {Instance = div}
            function obj:SetVisible(bool)
                div.Visible = bool
            end
            table.insert(tab.Elements, obj)
            return obj
        end

        function tab:CreateSection(secName)
            local secLbl = createInstance("TextLabel", {
                BackgroundTransparency = 1,
                Font = theme.Font,
                TextSize = 16,
                TextColor3 = theme.AccentColor,
                Text = "-- "..(secName or "Section").." --",
                Size = UDim2.new(1, -10, 0, 20),
                TextXAlignment = Enum.TextXAlignment.Left
            }, tabFrame)
            local obj = {Instance=secLbl}
            function obj:Set(newName)
                secLbl.Text = "-- "..newName.." --"
            end
            table.insert(tab.Elements, obj)
            return obj
        end

        function tab:CreateButton(opt)
            local text = opt.Text or "Button"
            local callback = opt.Callback or function() end

            local btn = createInstance("TextButton", {
                BackgroundColor3 = theme.SecondaryColor,
                Font = theme.Font,
                TextSize = 16,
                TextColor3 = theme.TextColor,
                Text = text,
                Size = UDim2.new(1, -10, 0, 30)
            }, tabFrame)
            addCornerRadius(btn, theme.CornerRadius)

            btn.MouseButton1Down:Connect(function()
                playSound(5419091377)
                tweenObject(btn, TweenInfo.new(0.1, Enum.EasingStyle.Quint), {BackgroundColor3 = theme.AccentColor})
            end)
            btn.MouseButton1Up:Connect(function()
                tweenObject(btn, TweenInfo.new(0.1, Enum.EasingStyle.Quint), {BackgroundColor3 = theme.SecondaryColor})
                callback()
            end)

            local obj = {Instance=btn}
            function obj:SetText(newText)
                btn.Text = newText
            end
            table.insert(tab.Elements, obj)
            return obj
        end

        function tab:CreateToggle(opt)
            local text = opt.Text or "Toggle"
            local default = opt.Default or false
            local callback = opt.Callback or function() end

            local frame = createInstance("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -10, 0, 30)
            }, tabFrame)

            local toggleBG = createInstance("Frame", {
                BackgroundColor3 = default and theme.AccentColor or theme.SecondaryColor,
                Size = UDim2.fromOffset(40,20),
                Position = UDim2.fromOffset(0,5)
            }, frame)
            addCornerRadius(toggleBG, 10)

            local circle = createInstance("Frame", {
                BackgroundColor3 = Color3.fromRGB(255,255,255),
                Size = UDim2.fromOffset(18,18),
                Position = default and UDim2.fromOffset(20,1) or UDim2.fromOffset(1,1)
            }, toggleBG)
            addCornerRadius(circle, 9)

            local lbl = createInstance("TextLabel", {
                BackgroundTransparency = 1,
                Font = theme.Font,
                TextSize = 16,
                TextColor3 = theme.TextColor,
                Text = text,
                Position = UDim2.fromOffset(50,0),
                Size = UDim2.new(1, -60, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left
            }, frame)

            local toggleObj = {Value=default}
            local function setToggle(val)
                toggleObj.Value = val
                if val then
                    tweenObject(toggleBG, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3 = theme.AccentColor})
                    tweenObject(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Position = UDim2.fromOffset(20,1)})
                else
                    tweenObject(toggleBG, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3 = theme.SecondaryColor})
                    tweenObject(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Position = UDim2.fromOffset(1,1)})
                end
                callback(val)
            end

            toggleBG.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    playSound(5419091377)
                    setToggle(not toggleObj.Value)
                end
            end)

            function toggleObj:Set(val)
                setToggle(val)
            end

            table.insert(tab.Elements, toggleObj)
            return toggleObj
        end

        function tab:CreateSlider(opt)
            local text = opt.Text or "Slider"
            local minVal = opt.Min or 0
            local maxVal = opt.Max or 100
            local default = opt.Default or 50
            local callback = opt.Callback or function() end

            local sliderFrame = createInstance("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -10, 0, 40)
            }, tabFrame)

            local sliderLabel = createInstance("TextLabel", {
                BackgroundTransparency = 1,
                Font = theme.Font,
                TextSize = 16,
                TextColor3 = theme.TextColor,
                Text = text..": "..tostring(default),
                Size = UDim2.new(1, 0, 0, 20),
                TextXAlignment = Enum.TextXAlignment.Left
            }, sliderFrame)

            local barBack = createInstance("Frame", {
                BackgroundColor3 = theme.SecondaryColor,
                Size = UDim2.new(1, -40, 0, 8),
                Position = UDim2.fromOffset(0, 25)
            }, sliderFrame)
            addCornerRadius(barBack, 4)

            local fill = createInstance("Frame", {
                BackgroundColor3 = theme.AccentColor,
                Size = UDim2.new(0,0, 1, 0)
            }, barBack)
            addCornerRadius(fill, 4)

            local handle = createInstance("Frame", {
                BackgroundColor3 = Color3.fromRGB(255,255,255),
                Size = UDim2.fromOffset(14,14),
                Position = UDim2.fromOffset(-7, -3)
            }, fill)
            addCornerRadius(handle, 7)

            local sliderObj = {Value=default}
            local function updateSlider(val)
                val = math.clamp(val, minVal, maxVal)
                sliderObj.Value = math.floor(val)
                sliderLabel.Text = text..": "..sliderObj.Value
                local ratio = (val - minVal)/(maxVal - minVal)
                fill.Size = UDim2.new(ratio,0, 1,0)
                callback(sliderObj.Value)
            end
            updateSlider(default)

            local dragging = false
            local function inputUpdate(x)
                local relX = x - barBack.AbsolutePosition.X
                local ratio = math.clamp(relX / barBack.AbsoluteSize.X, 0, 1)
                local newVal = (ratio*(maxVal-minVal)) + minVal
                updateSlider(newVal)
            end

            barBack.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    inputUpdate(input.Position.X)
                end
            end)
            barBack.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            handle.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                end
            end)
            handle.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input,gpe)
                if dragging and not gpe then
                    if input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch then
                        inputUpdate(input.Position.X)
                    end
                end
            end)

            function sliderObj:Set(val)
                updateSlider(val)
            end

            table.insert(tab.Elements, sliderObj)
            return sliderObj
        end

        function tab:CreateInput(opt)
            local text = opt.Text or ""
            local placeholder = opt.Placeholder or "Eingabe..."
            local callback = opt.Callback or function() end

            local box = createInstance("TextBox", {
                BackgroundColor3 = theme.SecondaryColor,
                Font = theme.Font,
                TextSize = 16,
                TextColor3 = theme.TextColor,
                Text = text,
                PlaceholderText = placeholder,
                Size = UDim2.new(1, -10, 0, 30),
                ClearTextOnFocus = false
            }, tabFrame)
            addCornerRadius(box, theme.CornerRadius)

            local inpObj = {Box=box}
            box.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    callback(box.Text)
                end
            end)
            function inpObj:SetText(t)
                box.Text = t
            end
            table.insert(tab.Elements, inpObj)
            return inpObj
        end

        function tab:CreateKeybind(opt)
            local text = opt.Text or "Keybind"
            local defaultKey = opt.DefaultKey or "F"
            local callback = opt.Callback or function() end

            local kbBtn = createInstance("TextButton", {
                BackgroundColor3 = theme.SecondaryColor,
                Font = theme.Font,
                TextSize = 16,
                TextColor3 = theme.TextColor,
                Text = text.." ["..defaultKey.."]",
                Size = UDim2.new(1, -10, 0, 30)
            }, tabFrame)
            addCornerRadius(kbBtn, theme.CornerRadius)

            local keybindObj = {Key = defaultKey}
            kbBtn.MouseButton1Click:Connect(function()
                playSound(5419091377)
                kbBtn.Text = "Press any key..."
                local conn
                conn = UserInputService.InputBegan:Connect(function(input, gp)
                    if not gp then
                        if input.KeyCode ~= Enum.KeyCode.Unknown then
                            local kName = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
                            keybindObj.Key = kName
                            kbBtn.Text = text.." ["..kName.."]"
                            conn:Disconnect()
                        end
                    end
                end)
            end)

            -- Du kannst hier optional in `RenderStepped` oder so einen Check machen:
            -- user drückt keybindObj.Key => callback()

            table.insert(tab.Elements, keybindObj)
            return keybindObj
        end

        function tab:CreateDropdown(opt)
            local ddName = opt.Text or "Dropdown"
            local list   = opt.List or {}
            local multi  = opt.Multi or false
            local default= opt.Default or (list[1] or "")
            local callback = opt.Callback or function() end

            local ddFrame = createInstance("Frame", {
                BackgroundColor3 = theme.SecondaryColor,
                Size = UDim2.new(1, -10, 0, 30)
            }, tabFrame)
            addCornerRadius(ddFrame, theme.CornerRadius)

            local ddButton = createInstance("TextButton", {
                BackgroundTransparency = 1,
                Font = theme.Font,
                TextSize = 16,
                TextColor3 = theme.TextColor,
                Text = ddName.." [ "..(type(default)=="table" and table.concat(default, ", ") or tostring(default)).." ]",
                Size = UDim2.new(1,0,1,0),
                Parent = ddFrame
            })

            local ddObj = {
                Frame = ddFrame,
                Current = (type(default)=="table") and default or {default},
                Items = list
            }

            local popup = createInstance("Frame", {
                BackgroundColor3 = theme.SecondaryColor,
                Size = UDim2.new(1,0, 0, #list*24),
                Position = UDim2.new(0,0,1,0),
                Visible = false,
                ZIndex = 999
            }, ddFrame)
            addCornerRadius(popup, theme.CornerRadius)

            local layout2 = createInstance("UIListLayout", {
                Padding = UDim.new(0,2),
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder
            }, popup)

            local function refreshText()
                ddButton.Text = ddName.." [ "..table.concat(ddObj.Current, ", ").." ]"
            end

            local function togglePopup()
                popup.Visible = not popup.Visible
                if popup.Visible then
                    popup.Size = UDim2.new(1,0,0,0)
                    popup:TweenSize(UDim2.new(1,0,0,#ddObj.Items*24), "Out", "Quint", 0.2, true)
                else
                    popup:TweenSize(UDim2.new(1,0,0,0), "Out", "Quint", 0.2, true)
                    task.wait(0.21)
                    if popup then
                        popup.Visible = false
                    end
                end
            end

            ddButton.MouseButton1Click:Connect(function()
                playSound(5419091377)
                togglePopup()
            end)

            local function createOption(optTxt)
                local optBtn = createInstance("TextButton", {
                    BackgroundColor3 = theme.SecondaryColor,
                    Font = theme.Font,
                    TextSize = 14,
                    TextColor3 = theme.TextColor,
                    Text = optTxt,
                    Size = UDim2.new(1,0,0,24),
                    AutoButtonColor = false
                }, popup)
                addCornerRadius(optBtn, theme.CornerRadius)

                optBtn.MouseButton1Click:Connect(function()
                    playSound(5419091377)
                    if multi then
                        local found = table.find(ddObj.Current, optTxt)
                        if found then
                            table.remove(ddObj.Current, found)
                        else
                            table.insert(ddObj.Current, optTxt)
                        end
                    else
                        ddObj.Current = {optTxt}
                        togglePopup()
                    end
                    refreshText()
                    callback(ddObj.Current)
                end)
            end

            for _,item in ipairs(list) do
                createOption(item)
            end

            function ddObj:Set(newVal)
                if type(newVal)=="table" then
                    ddObj.Current = newVal
                else
                    ddObj.Current = {newVal}
                end
                refreshText()
                callback(ddObj.Current)
            end

            function ddObj:Refresh(newList)
                ddObj.Items = newList
                for _,child in pairs(popup:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end
                for _,item in ipairs(newList) do
                    createOption(item)
                end
                popup.Size = UDim2.new(1,0,0,#ddObj.Items*24)
            end

            table.insert(tab.Elements, ddObj)
            return ddObj
        end

        table.insert(windowObject._tabs, tab)
        return tab
    end

    return windowObject
end

----------------------------------------------------------
-- 5) DESTROY ALLE FENSTER
----------------------------------------------------------
function SelfWareUI:DestroyAll()
    for _,win in ipairs(self._windows) do
        if win._screenGui then
            win._screenGui:Destroy()
        end
    end
    self._windows = {}
end

----------------------------------------------------------
-- 6) GET/SET-FLAGS (optional)
----------------------------------------------------------
function SelfWareUI:SetFlag(flag, value)
    self.Flags[flag] = value
end
function SelfWareUI:GetFlag(flag)
    return self.Flags[flag]
end

----------------------------------------------------------
-- FINALE RÜCKGABE
----------------------------------------------------------
return SelfWareUI


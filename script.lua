--!strict
-- [ MODULE: Services ]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [ MODULE: Constants ]
local TOGGLE_KEY = Enum.KeyCode.V
local DEFAULT_ACCENT = Color3.fromRGB(0, 170, 255)
local WINDOW_SIZE = Vector2.new(420, 600)
local BUTTON_HEIGHT = 32
local BUTTON_PADDING = 6

local IGNORE_COLLIDE = { HumanoidRootPart = true }
local NOCLIP_RESTORE_HOLD = 3

local SPEED_MIN, SPEED_MAX, SPEED_STEP = 1, 500, 1
local FLY_MIN, FLY_MAX, FLY_STEP = 1, 500, 1

-- [ MODULE: State ]
local state = {
    esp = false,
    fly = false,
    noclip = false,
    speed = false,
    infJump = false,
    accent = DEFAULT_ACCENT,
    windowOpen = true,
    dragging = false,
    dragStart = Vector2.zero,
    dragOrigin = Vector2.zero,
    restoreUntil = 0,
    speedValue = 50,
    flySpeedValue = 60,
}

-- [ MODULE: Forward ]
local accentSwatches = {}
local espHighlights = {}
local espBillboards = {}
local playerListFrame = nil
local flyBodyVelocity = nil
local flyBodyGyro = nil
local jumpConn = nil

-- [ MODULE: Helpers ]
local function getCharacter()
    return LocalPlayer.Character
end

local function getHumanoid()
    local char = getCharacter()
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local char = getCharacter()
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function clamp(v, min, max)
    if v < min then return min end
    if v > max then return max end
    return v
end

-- [ MODULE: GUI Build ]
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ControlPanel"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.fromOffset(WINDOW_SIZE.X, WINDOW_SIZE.Y)
mainFrame.Position = UDim2.new(0, 40, 0, 40)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = state.accent
stroke.Thickness = 2
stroke.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 10
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -12, 1, 0)
titleLabel.Position = UDim2.fromOffset(10, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "T1MOSHKA SCRIPT"
titleLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.ZIndex = 11
titleLabel.Parent = titleBar

local content = Instance.new("ScrollingFrame")
content.Name = "Content"
content.Size = UDim2.new(1, -12, 1, -48)
content.Position = UDim2.fromOffset(6, 42)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.ScrollBarImageColor3 = state.accent
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.ScrollingDirection = Enum.ScrollingDirection.Y
content.ZIndex = 6
content.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, BUTTON_PADDING)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = content

-- [ MODULE: Toggle Factory ]
local toggles = {}

local function createToggle(name, display, order)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(1, 0, 0, BUTTON_HEIGHT)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.ZIndex = 7
    btn.Parent = content

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.fromOffset(6, BUTTON_HEIGHT - 12)
    indicator.Position = UDim2.fromOffset(6, 6)
    indicator.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    indicator.BorderSizePixel = 0
    indicator.ZIndex = 8
    indicator.Parent = btn

    local indCorner = Instance.new("UICorner")
    indCorner.CornerRadius = UDim.new(0, 3)
    indCorner.Parent = indicator

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -24, 1, 0)
    label.Position = UDim2.fromOffset(20, 0)
    label.BackgroundTransparency = 1
    label.Text = display
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.ZIndex = 8
    label.Parent = btn

    toggles[name] = { button = btn, indicator = indicator, label = label }
    return btn
end

createToggle("esp", "ESP", 1)
createToggle("fly", "Fly", 2)
createToggle("noclip", "Noclip", 3)
createToggle("speed", "Speed", 4)
createToggle("infJump", "Infinity Jump", 5)

-- [ MODULE: Stepper Factory ]
local function createStepper(order, display, initial, min, max, step, onChange)
    local row = Instance.new("Frame")
    row.Name = display .. "Row"
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.ZIndex = 7
    row.Parent = content

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 6)
    rowCorner.Parent = row

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, -8, 1, 0)
    label.Position = UDim2.fromOffset(8, 0)
    label.BackgroundTransparency = 1
    label.Text = display
    label.TextColor3 = Color3.fromRGB(200, 200, 210)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.ZIndex = 8
    label.Parent = row

    local minusBtn = Instance.new("TextButton")
    minusBtn.Size = UDim2.fromOffset(28, 22)
    minusBtn.Position = UDim2.new(1, -132, 0, 4)
    minusBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 72)
    minusBtn.BorderSizePixel = 0
    minusBtn.Text = "-"
    minusBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
    minusBtn.Font = Enum.Font.GothamBold
    minusBtn.TextSize = 14
    minusBtn.AutoButtonColor = false
    minusBtn.ZIndex = 8
    minusBtn.Parent = row

    local mCorner = Instance.new("UICorner")
    mCorner.CornerRadius = UDim.new(0, 4)
    mCorner.Parent = minusBtn

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 64, 0, 22)
    valueLabel.Position = UDim2.new(1, -100, 0, 4)
    valueLabel.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    valueLabel.BorderSizePixel = 0
    valueLabel.Text = tostring(initial)
    valueLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 13
    valueLabel.ZIndex = 8
    valueLabel.Parent = row

    local vCorner = Instance.new("UICorner")
    vCorner.CornerRadius = UDim.new(0, 4)
    vCorner.Parent = valueLabel

    local plusBtn = Instance.new("TextButton")
    plusBtn.Size = UDim2.fromOffset(28, 22)
    plusBtn.Position = UDim2.new(1, -32, 0, 4)
    plusBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 72)
    plusBtn.BorderSizePixel = 0
    plusBtn.Text = "+"
    plusBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
    plusBtn.Font = Enum.Font.GothamBold
    plusBtn.TextSize = 14
    plusBtn.AutoButtonColor = false
    plusBtn.ZIndex = 8
    plusBtn.Parent = row

    local pCorner = Instance.new("UICorner")
    pCorner.CornerRadius = UDim.new(0, 4)
    pCorner.Parent = plusBtn

    local current = initial

    local function apply(newVal)
        current = clamp(newVal, min, max)
        valueLabel.Text = tostring(current)
        onChange(current)
    end

    minusBtn.MouseButton1Click:Connect(function() apply(current - step) end)
    plusBtn.MouseButton1Click:Connect(function() apply(current + step) end)

    local holding = false
    local function startHold(dir)
        holding = true
        task.spawn(function()
            task.wait(0.35)
            while holding do
                apply(current + dir * step)
                task.wait(0.05)
            end
        end)
    end
    minusBtn.MouseButton1Down:Connect(function() startHold(-1) end)
    minusBtn.MouseButton1Up:Connect(function() holding = false end)
    minusBtn.MouseLeave:Connect(function() holding = false end)
    plusBtn.MouseButton1Down:Connect(function() startHold(1) end)
    plusBtn.MouseButton1Up:Connect(function() holding = false end)
    plusBtn.MouseLeave:Connect(function() holding = false end)
end

local function applyPlayerSpeed()
    if state.speed then
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = state.speedValue end
    end
end

createStepper(20, "Скорость игрока", state.speedValue, SPEED_MIN, SPEED_MAX, SPEED_STEP, function(v)
    state.speedValue = v
    applyPlayerSpeed()
end)

createStepper(21, "Скорость полёта", state.flySpeedValue, FLY_MIN, FLY_MAX, FLY_STEP, function(v)
    state.flySpeedValue = v
end)

-- [ MODULE: Toggle Visual ]
local function setToggleVisual(name, enabled)
    local data = toggles[name]
    if not data then return end
    local targetColor = enabled and state.accent or Color3.fromRGB(80, 80, 90)
    TweenService:Create(data.indicator, TweenInfo.new(0.15), { BackgroundColor3 = targetColor }):Play()
    TweenService:Create(data.button, TweenInfo.new(0.15), {
        BackgroundColor3 = enabled and Color3.fromRGB(55, 55, 70) or Color3.fromRGB(45, 45, 55)
    }):Play()
end

-- [ MODULE: Apply Accent ]
local function applyAccentRaw(color, updateSwatches)
    state.accent = color
    stroke.Color = color
    content.ScrollBarImageColor3 = color
    if updateSwatches then
        for _, swatch in ipairs(accentSwatches) do
            if swatch.color == color then
                swatch.button.BackgroundColor3 = color
                swatch.stroke.Transparency = 0
            else
                swatch.button.BackgroundColor3 = swatch.color:Lerp(Color3.new(0, 0, 0), 0.35)
                swatch.stroke.Transparency = 1
            end
        end
    end
    for name, data in pairs(toggles) do
        local enabled = state[name] == true
        if enabled then
            data.indicator.BackgroundColor3 = color
        end
    end
    for _, hl in pairs(espHighlights) do
        hl.FillColor = color
    end
    for _, bb in pairs(espBillboards) do
        local nameLabel = bb:FindFirstChildOfClass("TextLabel")
        if nameLabel then
            nameLabel.TextColor3 = color
        end
    end
end

-- [ MODULE: Big Palette ]
local BIG_PALETTE = {
    Color3.fromRGB(255, 60, 60),   Color3.fromRGB(255, 120, 60),
    Color3.fromRGB(255, 180, 60),  Color3.fromRGB(255, 230, 60),
    Color3.fromRGB(200, 255, 60),  Color3.fromRGB(120, 255, 80),
    Color3.fromRGB(60, 255, 140),  Color3.fromRGB(60, 255, 220),
    Color3.fromRGB(60, 200, 255),  Color3.fromRGB(60, 140, 255),
    Color3.fromRGB(80, 90, 255),   Color3.fromRGB(140, 80, 255),
    Color3.fromRGB(200, 80, 255),  Color3.fromRGB(255, 80, 220),
    Color3.fromRGB(255, 80, 160),  Color3.fromRGB(255, 80, 100),
    Color3.fromRGB(180, 40, 40),   Color3.fromRGB(180, 100, 40),
    Color3.fromRGB(160, 160, 40),  Color3.fromRGB(60, 160, 60),
    Color3.fromRGB(40, 140, 160),  Color3.fromRGB(40, 80, 180),
    Color3.fromRGB(90, 40, 160),   Color3.fromRGB(160, 40, 140),
    Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200),
    Color3.fromRGB(140, 140, 140), Color3.fromRGB(80, 80, 80),
    Color3.fromRGB(40, 40, 40),    Color3.fromRGB(0, 0, 0),
    Color3.fromRGB(255, 200, 150), Color3.fromRGB(150, 200, 255),
}

local function createBigPalette(order, title, palette, onPick)
    local section = Instance.new("Frame")
    section.Name = title .. "Section"
    section.Size = UDim2.new(1, 0, 0, 0)
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.BackgroundTransparency = 1
    section.LayoutOrder = order
    section.ZIndex = 7
    section.Parent = content

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 16)
    label.BackgroundTransparency = 1
    label.Text = title
    label.TextColor3 = Color3.fromRGB(180, 180, 190)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.ZIndex = 8
    label.Parent = section

    local grid = Instance.new("Frame")
    grid.Name = "Grid"
    grid.Size = UDim2.new(1, 0, 0, 0)
    grid.Position = UDim2.fromOffset(0, 20)
    grid.AutomaticSize = Enum.AutomaticSize.Y
    grid.BackgroundTransparency = 1
    grid.ZIndex = 8
    grid.Parent = section

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.fromOffset(26, 26)
    gridLayout.CellPadding = UDim2.fromOffset(4, 4)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = grid

    local buttons = {}
    for i, color in ipairs(palette) do
        local swatch = Instance.new("TextButton")
        swatch.Name = "Swatch" .. i
        swatch.BackgroundColor3 = color
        swatch.BorderSizePixel = 0
        swatch.Text = ""
        swatch.AutoButtonColor = false
        swatch.LayoutOrder = i
        swatch.ZIndex = 9
        swatch.Parent = grid

        local swatchCorner = Instance.new("UICorner")
        swatchCorner.CornerRadius = UDim.new(0, 4)
        swatchCorner.Parent = swatch

        local swatchStroke = Instance.new("UIStroke")
        swatchStroke.Color = Color3.fromRGB(255, 255, 255)
        swatchStroke.Thickness = 2
        swatchStroke.Transparency = 1
        swatchStroke.Parent = swatch

        table.insert(buttons, { button = swatch, color = color, stroke = swatchStroke })

        swatch.MouseButton1Click:Connect(function()
            onPick(color)
        end)
    end
    return buttons
end

accentSwatches = createBigPalette(30, "Цвет акцента", BIG_PALETTE, function(color)
    applyAccentRaw(color, true)
end)

for _, swatch in ipairs(accentSwatches) do
    if swatch.color == state.accent then
        swatch.button.BackgroundColor3 = swatch.color
        swatch.stroke.Transparency = 0
    else
        swatch.button.BackgroundColor3 = swatch.color:Lerp(Color3.new(0, 0, 0), 0.35)
    end
end

-- [ MODULE: Teleport to Player ]
local function teleportTo(player)
    local myRoot = getRoot()
    if not myRoot then return end
    local targetChar = player.Character
    if not targetChar then return end
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
    if targetHum and targetHum.Health <= 0 then return end

    local offset = targetRoot.CFrame.LookVector * -3 + Vector3.new(0, 1, 0)
    myRoot.CFrame = CFrame.new(targetRoot.Position + offset, targetRoot.Position)
end

local function rebuildPlayerList()
    if not playerListFrame then return end
    for _, child in ipairs(playerListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Name = player.Name
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 62)
            btn.BorderSizePixel = 0
            btn.Text = ""
            btn.AutoButtonColor = false
            btn.LayoutOrder = 1
            btn.ZIndex = 9
            btn.Parent = playerListFrame

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 4)
            btnCorner.Parent = btn

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -12, 1, 0)
            nameLbl.Position = UDim2.fromOffset(10, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text = player.Name
            nameLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.Font = Enum.Font.Gotham
            nameLbl.TextSize = 14
            nameLbl.ZIndex = 10
            nameLbl.Parent = btn

            btn.MouseButton1Click:Connect(function()
                teleportTo(player)
            end)
        end
    end
end

local function createPlayerList(order)
    local section = Instance.new("Frame")
    section.Name = "TeleportSection"
    section.Size = UDim2.new(1, 0, 0, 0)
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.BackgroundTransparency = 1
    section.LayoutOrder = order
    section.ZIndex = 7
    section.Parent = content

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 16)
    label.BackgroundTransparency = 1
    label.Text = "Телепорт к игроку"
    label.TextColor3 = Color3.fromRGB(180, 180, 190)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.ZIndex = 8
    label.Parent = section

    local list = Instance.new("Frame")
    list.Name = "List"
    list.Size = UDim2.new(1, 0, 0, 0)
    list.Position = UDim2.fromOffset(0, 20)
    list.AutomaticSize = Enum.AutomaticSize.Y
    list.BackgroundTransparency = 1
    list.ZIndex = 8
    list.Parent = section

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 4)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = list

    return list
end

playerListFrame = createPlayerList(40)
rebuildPlayerList()

Players.PlayerAdded:Connect(function()
    task.defer(rebuildPlayerList)
end)
Players.PlayerRemoving:Connect(function()
    task.defer(rebuildPlayerList)
end)

-- [ MODULE: ESP ]
local function clearEsp(player)
    local hl = espHighlights[player]
    if hl then hl:Destroy() espHighlights[player] = nil end
    local bb = espBillboards[player]
    if bb then bb:Destroy() espBillboards[player] = nil end
end

local function applyEsp(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end

    clearEsp(player)

    local hl = Instance.new("Highlight")
    hl.Name = "EspHighlight"
    hl.FillColor = state.accent
    hl.OutlineColor = Color3.new(1, 1, 1)
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = char
    hl.Parent = char
    espHighlights[player] = hl

    local head = char:FindFirstChild("Head")
    if head then
        local bb = Instance.new("BillboardGui")
        bb.Name = "EspBillboard"
        bb.Size = UDim2.fromOffset(140, 40)
        bb.StudsOffset = Vector3.new(0, 2.5, 0)
        bb.AlwaysOnTop = true
        bb.Adornee = head
        bb.Parent = head

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = state.accent
        nameLabel.TextStrokeTransparency = 0
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 13
        nameLabel.Parent = bb

        local distLabel = Instance.new("TextLabel")
        distLabel.Name = "Dist"
        distLabel.Size = UDim2.new(1, 0, 0.5, 0)
        distLabel.Position = UDim2.new(0, 0, 0.5, 0)
        distLabel.BackgroundTransparency = 1
        distLabel.Text = ""
        distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        distLabel.TextStrokeTransparency = 0
        distLabel.Font = Enum.Font.Gotham
        distLabel.TextSize = 11
        distLabel.Parent = bb

        espBillboards[player] = bb
    end
end

local function refreshEspAll()
    if not state.esp then return end
    for _, player in ipairs(Players:GetPlayers()) do
        applyEsp(player)
    end
end

local function setEsp(enabled)
    state.esp = enabled
    setToggleVisual("esp", enabled)
    if enabled then
        refreshEspAll()
    else
        for player in pairs(espHighlights) do clearEsp(player) end
        for player in pairs(espBillboards) do clearEsp(player) end
        espHighlights = {}
        espBillboards = {}
    end
end

-- [ MODULE: Fly ]
local function stopFly()
    if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
    if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
end

local function startFly()
    local root = getRoot()
    if not root then return end
    stopFly()

    local bv = Instance.new("BodyVelocity")
    bv.Name = "FlyVelocity"
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity = Vector3.zero
    bv.Parent = root

    local bg = Instance.new("BodyGyro")
    bg.Name = "FlyGyro"
    bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bg.P = 2000
    bg.D = 50
    bg.CFrame = root.CFrame
    bg.Parent = root

    flyBodyVelocity = bv
    flyBodyGyro = bg
end

local function setFly(enabled)
    state.fly = enabled
    setToggleVisual("fly", enabled)
    if enabled then
        startFly()
    else
        stopFly()
    end
end

-- [ MODULE: Noclip ]
local function enableNoclip()
    local char = getCharacter()
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and not IGNORE_COLLIDE[part.Name] then
            part.CanCollide = false
        end
    end
end

local function disableNoclip()
    local char = getCharacter()
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and not IGNORE_COLLIDE[part.Name] then
                part.CanCollide = true
            end
        end
    end
    state.restoreUntil = os.clock() + NOCLIP_RESTORE_HOLD
end

local function setNoclip(enabled)
    state.noclip = enabled
    setToggleVisual("noclip", enabled)
    if enabled then
        enableNoclip()
    else
        disableNoclip()
    end
end

-- [ MODULE: Speed ]
local function setSpeed(enabled)
    state.speed = enabled
    setToggleVisual("speed", enabled)
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = enabled and state.speedValue or 16
    end
end

-- [ MODULE: Infinity Jump ]
local function enableInfJump()
    if jumpConn then jumpConn:Disconnect() jumpConn = nil end
    jumpConn = UserInputService.JumpRequest:Connect(function()
        if not state.infJump then return end
        local hum = getHumanoid()
        if not hum then return end
        if hum.Health <= 0 then return end
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end)
end

local function setInfJump(enabled)
    state.infJump = enabled
    setToggleVisual("infJump", enabled)
    if enabled then
        enableInfJump()
    else
        if jumpConn then jumpConn:Disconnect() jumpConn = nil end
    end
end

-- [ MODULE: Toggle Clicks ]
toggles.esp.button.MouseButton1Click:Connect(function() setEsp(not state.esp) end)
toggles.fly.button.MouseButton1Click:Connect(function() setFly(not state.fly) end)
toggles.noclip.button.MouseButton1Click:Connect(function() setNoclip(not state.noclip) end)
toggles.speed.button.MouseButton1Click:Connect(function() setSpeed(not state.speed) end)
toggles.infJump.button.MouseButton1Click:Connect(function() setInfJump(not state.infJump) end)

-- [ MODULE: Drag Window ]
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        state.dragging = true
        state.dragStart = Vector2.new(input.Position.X, input.Position.Y)
        state.dragOrigin = Vector2.new(mainFrame.AbsolutePosition.X, mainFrame.AbsolutePosition.Y)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not state.dragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local delta = Vector2.new(input.Position.X, input.Position.Y) - state.dragStart
    local newPos = state.dragOrigin + delta
    mainFrame.Position = UDim2.fromOffset(newPos.X, newPos.Y)
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        state.dragging = false
    end
end)

-- [ MODULE: Toggle Key (V) ]
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == TOGGLE_KEY then
        state.windowOpen = not state.windowOpen
        mainFrame.Visible = state.windowOpen
    end
end)

-- [ MODULE: Heartbeat Loop ]
RunService.Heartbeat:Connect(function(dt)
    -- Noclip
    if state.noclip then
        local char = getCharacter()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide and not IGNORE_COLLIDE[part.Name] then
                    part.CanCollide = false
                end
            end
        end
    elseif os.clock() < state.restoreUntil then
        local char = getCharacter()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and not part.CanCollide and not IGNORE_COLLIDE[part.Name] then
                    part.CanCollide = true
                end
            end
        end
    end

    -- Fly
    if state.fly and flyBodyVelocity and flyBodyGyro then
        local root = getRoot()
        if not root then
            stopFly()
        else
            local cam = Camera
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end

            if dir.Magnitude > 0 then
                flyBodyVelocity.Velocity = dir.Unit * state.flySpeedValue
            else
                flyBodyVelocity.Velocity = Vector3.zero
            end
            flyBodyGyro.CFrame = CFrame.new(root.Position, root.Position + cam.CFrame.LookVector)
        end
    end

    -- ESP
    if state.esp then
        local myRoot = getRoot()
        if myRoot then
            for player, bb in pairs(espBillboards) do
                local char = player.Character
                if not char then
                    clearEsp(player)
                else
                    local head = char:FindFirstChild("Head")
                    if not head then
                        clearEsp(player)
                    else
                        local distLabel = bb:FindFirstChild("Dist")
                        if distLabel then
                            local dist = (myRoot.Position - head.Position).Magnitude
                            distLabel.Text = string.format("%d studs", dist)
                        end
                        local hl = espHighlights[player]
                        if hl and hl.Adornee ~= char then
                            hl.Adornee = char
                        end
                        bb.Adornee = head
                    end
                end
            end
        end
    end
end)

-- [ MODULE: Player Events ]
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if state.esp then
            task.wait(0.5)
            applyEsp(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    clearEsp(player)
end)

-- [ MODULE: Character Respawn ]
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)

    if state.speed then
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = state.speedValue end
    end
    if state.fly then
        startFly()
    end
    if state.esp then
        refreshEspAll()
    end
    if state.noclip then
        enableNoclip()
    else
        state.restoreUntil = os.clock() + NOCLIP_RESTORE_HOLD
    end
end)

-- [ MODULE: Initial ]
stroke.Color = state.accent
refreshEspAll()

pcall(function()
    StarterGui:SetCore("TopbarEnabled", true)
end)

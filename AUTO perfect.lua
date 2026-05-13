-- === AUTO QTE v10 ===

pcall(function()
    if game:GetService("CoreGui"):FindFirstChild("AutoQTE_GUI") then
        game:GetService("CoreGui"):FindFirstChild("AutoQTE_GUI"):Destroy()
    end
end)
pcall(function() if _G.QTEConnection then _G.QTEConnection:Disconnect() end end)
_G.StopQTE = true
task.wait(0.2)
_G.StopQTE = false

print("[v10] Запуск...")

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VIM = game:GetService("VirtualInputManager")
local player = game.Players.LocalPlayer
local pgui = player.PlayerGui

local enabledQTE = false
local enabledAutoStart = false
local enabledAutoSell = false

-- === КЛИК в безопасную точку через VIM ===
local function safeVIMClick()
    pcall(function()
        local vp = workspace.CurrentCamera.ViewportSize
        local x = vp.X * 0.8
        local y = vp.Y * 0.8
        VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
        task.wait(0.03)
        VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)
end

-- === ПРОВЕРКИ ===
local function isMenuOpen()
    local ok, result = pcall(function()
        return GuiService.MenuIsOpen
    end)
    return ok and result
end

local function normalizeAngle(a) return a % 360 end
local function angleDiff(a, b)
    local d = math.abs(normalizeAngle(a) - normalizeAngle(b))
    return d > 180 and 360 - d or d
end

-- === GUI ===
local gui = Instance.new("ScreenGui")
gui.Name = "AutoQTE_GUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Panel"
mainFrame.Size = UDim2.new(0, 190, 0, 118)
mainFrame.Position = UDim2.new(0, 20, 0.5, -59)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = gui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(50, 50, 70)
mainStroke.Thickness = 1.5
mainStroke.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 24)
titleLabel.Position = UDim2.new(0, 0, 0, 2)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚡ Auto Perfect Boss"
titleLabel.TextColor3 = Color3.fromRGB(200, 200, 230)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

local function createToggle(name, yPos, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -20, 0, 26)
    row.Position = UDim2.new(0, 10, 0, yPos)
    row.BackgroundTransparency = 1
    row.Parent = mainFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 110, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(170, 170, 190)
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 40, 0, 20)
    bg.Position = UDim2.new(1, -40, 0.5, -10)
    bg.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    bg.BorderSizePixel = 0
    bg.Parent = row
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.Position = UDim2.new(0, 2, 0.5, -8)
    circle.BackgroundColor3 = Color3.fromRGB(130, 130, 150)
    circle.BorderSizePixel = 0
    circle.Parent = bg
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = bg

    local state = false
    local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quad)

    local function set(v)
        state = v
        if state then
            TweenService:Create(circle, ti, {
                Position = UDim2.new(1, -18, 0.5, -8),
                BackgroundColor3 = Color3.fromRGB(80, 255, 160)
            }):Play()
            TweenService:Create(bg, ti, {
                BackgroundColor3 = Color3.fromRGB(25, 70, 50)
            }):Play()
            label.TextColor3 = Color3.fromRGB(80, 255, 160)
        else
            TweenService:Create(circle, ti, {
                Position = UDim2.new(0, 2, 0.5, -8),
                BackgroundColor3 = Color3.fromRGB(130, 130, 150)
            }):Play()
            TweenService:Create(bg, ti, {
                BackgroundColor3 = Color3.fromRGB(35, 35, 50)
            }):Play()
            label.TextColor3 = Color3.fromRGB(170, 170, 190)
        end
        callback(state)
    end

    btn.MouseButton1Click:Connect(function() set(not state) end)
    return set
end

local setQTE = createToggle("Auto QTE", 28, function(v) enabledQTE = v end)
local setStart = createToggle("Auto Start", 56, function(v) enabledAutoStart = v end)
local setSell = createToggle("Auto Sell", 84, function(v) enabledAutoSell = v end)

print("[v10] GUI готов")

-- === QTE ЛОГИКА (PERFECT CLICK) ===
local prevDiff = 999
local clicked = false
local prevLineRot = nil
local qteLineMoving = false

_G.QTEConnection = RunService.RenderStepped:Connect(function()
    if not enabledQTE then
        prevDiff = 999
        clicked = false
        return
    end

    pcall(function()
        local qte = pgui:FindFirstChild("QTE")
        if not qte then prevDiff = 999; clicked = false; qteLineMoving = false return end
        local main = qte:FindFirstChild("Main")
        if not main then qteLineMoving = false return end
        local line = main:FindFirstChild("Line")
        local bars = main:FindFirstChild("Bars")
        if not line or not bars then qteLineMoving = false return end

        -- Проверяем вращается ли линия (мини-игра активна)
        local lineRot = line.Rotation
        if prevLineRot ~= nil then
            qteLineMoving = math.abs(lineRot - prevLineRot) > 0.1
        end
        prevLineRot = lineRot

        local targetBar
        for _, bar in pairs(bars:GetChildren()) do
            if bar:IsA("ImageLabel") and bar.Visible then
                targetBar = bar
                break
            end
        end
        if not targetBar then prevDiff = 999; clicked = false return end

        local diff = angleDiff(lineRot, targetBar.Rotation)
        local barSize = tonumber(targetBar.Name:match("%d+")) or 15

        if not clicked and diff <= (barSize * 2) then
            if diff > prevDiff then
                safeVIMClick()
                clicked = true
            end
        end

        if diff > barSize then
            clicked = false
        end

        prevDiff = diff
    end)
end)

-- === AUTO START ===
spawn(function()
    print("[v10] Auto Start запущен")
    while not _G.StopQTE do
        if enabledAutoStart and not qteLineMoving then
            safeVIMClick()
        end
        task.wait(0.5)
    end
end)

-- === AUTO SELL ===
spawn(function()
    print("[v10] Auto Sell запущен")
    while not _G.StopQTE do
        if enabledAutoSell then
            pcall(function()
                local Event = ReplicatedStorage:FindFirstChild("ByteNetReliable")
                if Event then
                    Event:FireServer(buffer.fromstring("4"), nil)
                end
            end)
        end
        task.wait(2)
    end
end)

print("Auto Perfect BOSSSS")

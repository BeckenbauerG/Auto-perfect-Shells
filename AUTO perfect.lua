repeat task.wait() until game:IsLoaded()

--// CLEANUP
pcall(function()
    if getgenv().QTE_V11 then
        getgenv().QTE_V11:Destroy()
    end
end)

local QTE_V11 = {}
getgenv().QTE_V11 = QTE_V11

QTE_V11.Connections = {}
QTE_V11.Tasks = {}
QTE_V11.Running = true

function QTE_V11:Connect(signal, func)
    local c = signal:Connect(func)
    table.insert(self.Connections, c)
    return c
end

function QTE_V11:Task(func)
    local t = task.spawn(func)
    table.insert(self.Tasks, t)
    return t
end

function QTE_V11:Destroy()
    self.Running = false

    for _, c in pairs(self.Connections) do
        pcall(function()
            c:Disconnect()
        end)
    end

    pcall(function()
        if game:GetService("CoreGui"):FindFirstChild("AutoQTE_GUI") then
            game:GetService("CoreGui").AutoQTE_GUI:Destroy()
        end
    end)

    getgenv().QTE_V11 = nil
end

print("[v11] Initializing...")

--// SERVICES
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VIM = game:GetService("VirtualInputManager")

--// PLAYER
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// SETTINGS
local Settings = {
    AutoQTE = false,
    AutoStart = false,
    AutoSell = false,

    Humanize = false,

    QTE_FPS = 240,

    ClickRandomness = 8,

    MinReaction = 0,
    MaxReaction = 0,

    AutoStartDelay = 0.7,
    AutoSellDelay = 2.0,
}

--// UTILS
local function RandomFloat(min, max)
    return min + math.random() * (max - min)
end

local function NormalizeAngle(a)
    return a % 360
end

local function AngleDiff(a, b)
    local d = math.abs(NormalizeAngle(a) - NormalizeAngle(b))
    return d > 180 and 360 - d or d
end

local function IsMenuOpen()
    local ok, result = pcall(function()
        return GuiService.MenuIsOpen
    end)

    return ok and result
end

local function -- HumanWait() disabled for instant response
    if not Settings.Humanize then
        return
    end

    task.wait(RandomFloat(Settings.MinReaction, Settings.MaxReaction))
end

--// SAFE CLICK
local function SafeClick(x, y)
    pcall(function()
        local viewport = workspace.CurrentCamera.ViewportSize

        x = x or viewport.X * 0.75
        y = y or viewport.Y * 0.75

        if Settings.Humanize then
            x += math.random(-Settings.ClickRandomness, Settings.ClickRandomness)
            y += math.random(-Settings.ClickRandomness, Settings.ClickRandomness)
        end

        HumanWait()

        VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)

        task.wait()

        VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)
end

--// GUI
local GUI = Instance.new("ScreenGui")
GUI.Name = "AutoQTE_GUI"
GUI.ResetOnSpawn = false
GUI.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 210, 0, 155)
Main.Position = UDim2.new(0, 20, 0.5, -75)
Main.BackgroundColor3 = Color3.fromRGB(18,18,25)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = GUI

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(60,60,80)
Stroke.Thickness = 1.2
Stroke.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,30)
Title.BackgroundTransparency = 1
Title.Text = "⚡ Auto QTE v11"
Title.TextColor3 = Color3.fromRGB(220,220,255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = Main

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1,0,0,18)
Status.Position = UDim2.new(0,0,0,24)
Status.BackgroundTransparency = 1
Status.Text = "Idle"
Status.TextColor3 = Color3.fromRGB(120,255,160)
Status.Font = Enum.Font.Gotham
Status.TextSize = 11
Status.Parent = Main

local function CreateToggle(text, y, callback)
    local Holder = Instance.new("Frame")
    Holder.Size = UDim2.new(1,-20,0,28)
    Holder.Position = UDim2.new(0,10,0,y)
    Holder.BackgroundTransparency = 1
    Holder.Parent = Main

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0,130,1,0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(190,190,210)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Holder

    local Toggle = Instance.new("Frame")
    Toggle.Size = UDim2.new(0,42,0,22)
    Toggle.Position = UDim2.new(1,-42,0.5,-11)
    Toggle.BackgroundColor3 = Color3.fromRGB(35,35,50)
    Toggle.BorderSizePixel = 0
    Toggle.Parent = Holder

    Instance.new("UICorner", Toggle).CornerRadius = UDim.new(1,0)

    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0,18,0,18)
    Circle.Position = UDim2.new(0,2,0.5,-9)
    Circle.BackgroundColor3 = Color3.fromRGB(130,130,150)
    Circle.BorderSizePixel = 0
    Circle.Parent = Toggle

    Instance.new("UICorner", Circle).CornerRadius = UDim.new(1,0)

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1,0,1,0)
    Button.BackgroundTransparency = 1
    Button.Text = ""
    Button.Parent = Toggle

    local State = false

    local function Set(v)
        State = v

        if State then
            TweenService:Create(Circle, TweenInfo.new(0.2), {
                Position = UDim2.new(1,-20,0.5,-9),
                BackgroundColor3 = Color3.fromRGB(100,255,170)
            }):Play()

            TweenService:Create(Toggle, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(30,70,55)
            }):Play()
        else
            TweenService:Create(Circle, TweenInfo.new(0.2), {
                Position = UDim2.new(0,2,0.5,-9),
                BackgroundColor3 = Color3.fromRGB(130,130,150)
            }):Play()

            TweenService:Create(Toggle, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(35,35,50)
            }):Play()
        end

        callback(State)
    end

    Button.MouseButton1Click:Connect(function()
        Set(not State)
    end)
end

CreateToggle("Auto QTE", 50, function(v)
    Settings.AutoQTE = v
end)

CreateToggle("Auto Start", 82, function(v)
    Settings.AutoStart = v
end)

CreateToggle("Auto Sell", 114, function(v)
    Settings.AutoSell = v
end)

--// QTE
local PreviousDiff = 999
local Clicked = false
local PreviousRotation = nil
local LastUpdate = 0

QTE_V11:Connect(RunService.RenderStepped, function()
    if not QTE_V11.Running then
        return
    end

    if tick() - LastUpdate < (1 / Settings.QTE_FPS) then
        return
    end

    LastUpdate = tick()

    if not Settings.AutoQTE then
        PreviousDiff = 999
        Clicked = false
        return
    end

    if IsMenuOpen() then
        return
    end

    pcall(function()
        local QTE = PlayerGui:FindFirstChild("QTE")

        if not QTE then
            Status.Text = "Waiting QTE"
            PreviousDiff = 999
            Clicked = false
            return
        end

        local MainFrame = QTE:FindFirstChild("Main")

        if not MainFrame then
            return
        end

        local Line = MainFrame:FindFirstChild("Line")
        local Bars = MainFrame:FindFirstChild("Bars")

        if not Line or not Bars then
            return
        end

        local CurrentRotation = Line.Rotation

        local TargetBar

        for _, bar in pairs(Bars:GetChildren()) do
            if bar:IsA("ImageLabel") and bar.Visible then
                TargetBar = bar
                break
            end
        end

        if not TargetBar then
            return
        end

        local Difference = AngleDiff(CurrentRotation, TargetBar.Rotation)

        local BarSize = tonumber(TargetBar.Name:match("%d+")) or 15

        if not Clicked and Difference <= (BarSize / 2) then
            if Difference > PreviousDiff then
                Status.Text = "Perfect Hit"

                SafeClick()

                Clicked = true
            end
        end

        if Difference > BarSize then
            Clicked = false
        end

        PreviousDiff = Difference
        PreviousRotation = CurrentRotation
    end)
end)

--// AUTO START
QTE_V11:Task(function()
    while QTE_V11.Running do
        task.wait(Settings.AutoStartDelay)

        if not Settings.AutoStart then
            continue
        end

        if IsMenuOpen() then
            continue
        end

        local QTE = PlayerGui:FindFirstChild("QTE")

        if not QTE then
            Status.Text = "Auto Starting"
            SafeClick()
        end
    end
end)

--// AUTO SELL
QTE_V11:Task(function()
    while QTE_V11.Running do
        task.wait(Settings.AutoSellDelay)

        if not Settings.AutoSell then
            continue
        end

        pcall(function()
            local Remote = ReplicatedStorage:FindFirstChild("ByteNetReliable")

            if Remote then
                Status.Text = "Auto Selling"

                Remote:FireServer(buffer.fromstring("4"), nil)
            end
        end)
    end
end)

print("[v11] Loaded successfully")
* Less spam clicking
* Improved state handling

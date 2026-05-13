repeat task.wait() until game:IsLoaded()

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

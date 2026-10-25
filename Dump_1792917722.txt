

-- [HTTPGET #1]: https://scriptblox.com/raw/Universal-Script-FE-Touch-Fling-with-Animations-R6-R15-245062
print("sub to openscripts")
--notify: if code obfuscated — it's not original script

--script:
local plrs = game:GetService("Players")
local runS = game:GetService("RunService")
local tweenS = game:GetService("TweenService")

local plr = plrs.LocalPlayer
local gui = plr:WaitForChild("PlayerGui")

local function getRoot(char)
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then return root end
    return char:FindFirstChild("Torso")
end

local function disableCol(char, state)
    if not char then return end
    for _, p in pairs(char:GetChildren()) do
        if p:IsA("BasePart") then
            p.CanCollide = state
        end
    end
end

local function getCharType(char)
    if not char then return "Unknown" end
    if char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("UpperTorso") then
        return "R15"
    elseif char:FindFirstChild("Torso") then
        return "R6"
    end
    return "Unknown"
end

local function setupUI()
    if gui:FindFirstChild("flingGui") then
        gui.flingGui:Destroy()
    end

    local sc = Instance.new("ScreenGui")
    sc.Name = "flingGui"
    sc.ResetOnSpawn = false
    sc.Parent = gui
    
    local frm = Instance.new("Frame")
    frm.Name = "MainFrame"
    frm.BackgroundColor3 = Color3.fromRGB(5, 10, 5)
    frm.BorderSizePixel = 0
    frm.Size = UDim2.new(0, 190, 0, 130)
    frm.Position = UDim2.new(0, 20, 0, 20)
    frm.Active = true
    frm.Draggable = true
    frm.Parent = sc
    
    local frmStrk = Instance.new("UIStroke")
    frmStrk.Color = Color3.fromRGB(0, 255, 70)
    frmStrk.Thickness = 1.5
    frmStrk.Parent = frm

    local btn = Instance.new("TextButton")
    btn.Name = "MainButton"
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.Position = UDim2.new(0, 5, 0, 5)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.Code
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(0, 255, 70)
    btn.AutoButtonColor = false 
    btn.Parent = frm

    local pwrBox = Instance.new("TextBox")
    pwrBox.Name = "FlingPower"
    pwrBox.Size = UDim2.new(1, -10, 0, 30)
    pwrBox.Position = UDim2.new(0, 5, 0, 45)
    pwrBox.BackgroundColor3 = Color3.fromRGB(10, 20, 10)
    pwrBox.BorderSizePixel = 0
    pwrBox.Font = Enum.Font.Code
    pwrBox.TextSize = 13
    pwrBox.TextColor3 = Color3.fromRGB(0, 255, 70)
    pwrBox.Text = "1000000"
    pwrBox.PlaceholderText = "Fling Power"
    pwrBox.ClearTextOnFocus = false
    pwrBox.Parent = frm

    local boxStrk = Instance.new("UIStroke")
    boxStrk.Color = Color3.fromRGB(0, 255, 70)
    boxStrk.Thickness = 1
    boxStrk.Parent = pwrBox

    local pnchBtn = Instance.new("TextButton")
    pnchBtn.Name = "PunchButton"
    pnchBtn.Size = UDim2.new(1, -10, 0, 25)
    pnchBtn.Position = UDim2.new(0, 5, 0, 85)
    pnchBtn.BorderSizePixel = 0
    pnchBtn.Font = Enum.Font.Code
    pnchBtn.TextSize = 12
    pnchBtn.TextColor3 = Color3.fromRGB(0, 255, 70)
    pnchBtn.AutoButtonColor = false
    pnchBtn.BackgroundColor3 = Color3.fromRGB(10, 20, 10)
    pnchBtn.Parent = frm

    local pnchStrk = Instance.new("UIStroke")
    pnchStrk.Color = Color3.fromRGB(0, 255, 70)
    pnchStrk.Thickness = 1
    pnchStrk.Parent = pnchBtn

    local isFlinging = false
    local flingConn = nil
    local hboxVis = nil
    local curTrack = nil
    local isPunch = false

    local anims = {
        R6 = "rbxassetid://204062532",
        R15 = 94235564114426
    }

    local bgOn = Color3.fromRGB(0, 40, 10)
    local bgOff = Color3.fromRGB(15, 5, 5)
    local txtOn = Color3.fromRGB(50, 255, 100)
    local txtOff = Color3.fromRGB(255, 50, 50)

    local function getPwr()
        local p = tonumber(pwrBox.Text)
        if not p or p < 1 then return 1 end
        return p
    end

    local function tween(inst, prop, val, dur)
        tweenS:Create(inst, TweenInfo.new(dur or 0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {[prop] = val}):Play()
    end

    local function updateHbox(st)
        if st then
            local char = plr.Character
            local root = getRoot(char)
            if root and not char:FindFirstChild("MatrixHitboxVisual") then
                hboxVis = Instance.new("SelectionBox")
                hboxVis.Name = "MatrixHitboxVisual"
                hboxVis.Adornee = root
                hboxVis.Color3 = Color3.fromRGB(0, 255, 70)
                hboxVis.LineThickness = 0.05
                hboxVis.SurfaceColor3 = Color3.fromRGB(0, 255, 70)
                hboxVis.SurfaceTransparency = 0.85
                hboxVis.Parent = char
            end
        else
            if hboxVis then
                hboxVis:Destroy()
                hboxVis = nil
            end
            local char = plr.Character
            if char then
                local oldVis = char:FindFirstChild("MatrixHitboxVisual")
                if oldVis then oldVis:Destroy() end
            end
        end
    end

    local function updateBtnVis()
        if isFlinging then
            btn.Text = "[ SYSTEM: ACTIVE ]"
            tween(btn, "BackgroundColor3", bgOn)
            tween(btn, "TextColor3", txtOn)
            frmStrk.Color = Color3.fromRGB(0, 255, 70)
            updateHbox(true)
        else
            btn.Text = "[ SYSTEM: OFFLINE ]"
            tween(btn, "BackgroundColor3", bgOff)
            tween(btn, "TextColor3", txtOff)
            frmStrk.Color = Color3.fromRGB(120, 0, 0)
            updateHbox(false)
        end
    end

    local function updatePnchBtn()
        if isPunch then
            pnchBtn.Text = "[ PUNCH MODE: ON ]"
            pnchBtn.TextColor3 = Color3.fromRGB(50, 255, 100)
            pnchBtn.BackgroundColor3 = Color3.fromRGB(0, 40, 10)
            pnchStrk.Color = Color3.fromRGB(0, 255, 70)
        else
            pnchBtn.Text = "[ PUNCH MODE: OFF ]"
            pnchBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
            pnchBtn.BackgroundColor3 = Color3.fromRGB(15, 5, 5)
            pnchStrk.Color = Color3.fromRGB(120, 0, 0)
        end
    end

    btn.MouseEnter:Connect(function()
        if isFlinging then
            tween(btn, "BackgroundColor3", Color3.fromRGB(0, 70, 15))
            tween(btn, "TextColor3", Color3.fromRGB(150, 255, 180))
        else
            tween(btn, "BackgroundColor3", Color3.fromRGB(30, 10, 10))
            tween(btn, "TextColor3", Color3.fromRGB(255, 120, 120))
        end
    end)

    btn.MouseLeave:Connect(updateBtnVis)

    pnchBtn.MouseEnter:Connect(function()
        if isPunch then
            pnchBtn.BackgroundColor3 = Color3.fromRGB(0, 70, 15)
            pnchBtn.TextColor3 = Color3.fromRGB(150, 255, 180)
        else
            pnchBtn.BackgroundColor3 = Color3.fromRGB(30, 10, 10)
            pnchBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
        end
    end)

    pnchBtn.MouseLeave:Connect(updatePnchBtn)

    local function playAnim()
        local char = plr.Character
        if not char then return end
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        
        local cType = getCharType(char)
        local animId = anims[cType] or anims.R6
        
        local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)

        if curTrack then
            curTrack:Stop()
            curTrack:Destroy()
            curTrack = nil
        end

        if cType == "R15" then
            local ok, res = pcall(function()
                return game:GetObjects("rbxassetid://" .. tostring(animId))
            end)

            if ok and res and #res > 0 then
                local a = res[1]
                if a:IsA("Animation") then
                    curTrack = animator:LoadAnimation(a)
                else
                    local newA = Instance.new("Animation")
                    newA.AnimationId = "rbxassetid://" .. tostring(animId)
                    curTrack = animator:LoadAnimation(newA)
                end
            else
                local newA = Instance.new("Animation")
                newA.AnimationId = "rbxassetid://" .. tostring(animId)
                curTrack = animator:LoadAnimation(newA)
            end
        else
            local newA = Instance.new("Animation")
            newA.AnimationId = animId
            curTrack = animator:LoadAnimation(newA)
        end
        
        if curTrack then
            curTrack.Looped = true
            curTrack:Play()
        end
    end

    local function stopAnim()
        if curTrack then
            curTrack:Stop()
            curTrack:Destroy()
            curTrack = nil
        end
    end

    local function startFling()
        if flingConn then return end
        
        isFlinging = true
        
        if isPunch then
            playAnim()
        end
        
        local char = plr.Character
        if char then
            disableCol(char, false)
        end
        
        local movel = 0.1
        local pwr = getPwr()
        
        flingConn = runS.Heartbeat:Connect(function()
            local char = plr.Character
            local root = getRoot(char)
            
            if not (char and char.Parent and root and root.Parent) then 
                return 
            end
            
            if not char:FindFirstChild("MatrixHitboxVisual") and isFlinging then
                updateHbox(true)
            end
            
            if isFlinging then
                disableCol(char, false)
            end
            
            local lastVel = root.AssemblyLinearVelocity
            root.AssemblyLinearVelocity = Vector3.new(pwr, pwr/2, pwr)
            
            runS.RenderStepped:Wait()
            if char and char.Parent and root and root.Parent then
                root.AssemblyLinearVelocity = lastVel
            end
            
            runS.Stepped:Wait()
            if char and char.Parent and root and root.Parent then
                root.AssemblyLinearVelocity = lastVel + Vector3.new(0, movel, 0)
                movel = movel * -1
            end
        end)
        
        updateBtnVis()
    end

    local function stopFling()
        if flingConn then
            flingConn:Disconnect()
            flingConn = nil
        end
        isFlinging = false
        
        stopAnim()
        
        local char = plr.Character
        if char then
            disableCol(char, true)
        end
        
        updateBtnVis()
    end

    local function toggleFling()
        if isFlinging then
            stopFling()
        else
            startFling()
        end
    end

    local function togglePnch()
        isPunch = not isPunch
        updatePnchBtn()
        
        if isFlinging then
            stopFling()
            startFling()
        end
    end

    pwrBox.FocusLost:Connect(function()
        local v = tonumber(pwrBox.Text)
        if not v or v < 1 then
            pwrBox.Text = "1"
        end
        if isFlinging then
            stopFling()
            startFling()
        end
    end)

    plr.CharacterAdded:Connect(function(char)
        if isFlinging then
            task.wait(0.1)
            disableCol(char, false)
            if isPunch then
                stopAnim()
                playAnim()
            end
        end
    end)

    updateBtnVis()
    updatePnchBtn()
    
    btn.MouseButton1Click:Connect(toggleFling)
    pnchBtn.MouseButton1Click:Connect(togglePnch)
end

setupUI()



-- [LOADSTRING #2] - Chunk: nil
print("sub to openscripts")
--notify: if code obfuscated — it's not original script

--script:
local plrs = game:GetService("Players")
local runS = game:GetService("RunService")
local tweenS = game:GetService("TweenService")

local plr = plrs.LocalPlayer
local gui = plr:WaitForChild("PlayerGui")

local function getRoot(char)
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then return root end
    return char:FindFirstChild("Torso")
end

local function disableCol(char, state)
    if not char then return end
    for _, p in pairs(char:GetChildren()) do
        if p:IsA("BasePart") then
            p.CanCollide = state
        end
    end
end

local function getCharType(char)
    if not char then return "Unknown" end
    if char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("UpperTorso") then
        return "R15"
    elseif char:FindFirstChild("Torso") then
        return "R6"
    end
    return "Unknown"
end

local function setupUI()
    if gui:FindFirstChild("flingGui") then
        gui.flingGui:Destroy()
    end

    local sc = Instance.new("ScreenGui")
    sc.Name = "flingGui"
    sc.ResetOnSpawn = false
    sc.Parent = gui
    
    local frm = Instance.new("Frame")
    frm.Name = "MainFrame"
    frm.BackgroundColor3 = Color3.fromRGB(5, 10, 5)
    frm.BorderSizePixel = 0
    frm.Size = UDim2.new(0, 190, 0, 130)
    frm.Position = UDim2.new(0, 20, 0, 20)
    frm.Active = true
    frm.Draggable = true
    frm.Parent = sc
    
    local frmStrk = Instance.new("UIStroke")
    frmStrk.Color = Color3.fromRGB(0, 255, 70)
    frmStrk.Thickness = 1.5
    frmStrk.Parent = frm

    local btn = Instance.new("TextButton")
    btn.Name = "MainButton"
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.Position = UDim2.new(0, 5, 0, 5)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.Code
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(0, 255, 70)
    btn.AutoButtonColor = false 
    btn.Parent = frm

    local pwrBox = Instance.new("TextBox")
    pwrBox.Name = "FlingPower"
    pwrBox.Size = UDim2.new(1, -10, 0, 30)
    pwrBox.Position = UDim2.new(0, 5, 0, 45)
    pwrBox.BackgroundColor3 = Color3.fromRGB(10, 20, 10)
    pwrBox.BorderSizePixel = 0
    pwrBox.Font = Enum.Font.Code
    pwrBox.TextSize = 13
    pwrBox.TextColor3 = Color3.fromRGB(0, 255, 70)
    pwrBox.Text = "1000000"
    pwrBox.PlaceholderText = "Fling Power"
    pwrBox.ClearTextOnFocus = false
    pwrBox.Parent = frm

    local boxStrk = Instance.new("UIStroke")
    boxStrk.Color = Color3.fromRGB(0, 255, 70)
    boxStrk.Thickness = 1
    boxStrk.Parent = pwrBox

    local pnchBtn = Instance.new("TextButton")
    pnchBtn.Name = "PunchButton"
    pnchBtn.Size = UDim2.new(1, -10, 0, 25)
    pnchBtn.Position = UDim2.new(0, 5, 0, 85)
    pnchBtn.BorderSizePixel = 0
    pnchBtn.Font = Enum.Font.Code
    pnchBtn.TextSize = 12
    pnchBtn.TextColor3 = Color3.fromRGB(0, 255, 70)
    pnchBtn.AutoButtonColor = false
    pnchBtn.BackgroundColor3 = Color3.fromRGB(10, 20, 10)
    pnchBtn.Parent = frm

    local pnchStrk = Instance.new("UIStroke")
    pnchStrk.Color = Color3.fromRGB(0, 255, 70)
    pnchStrk.Thickness = 1
    pnchStrk.Parent = pnchBtn

    local isFlinging = false
    local flingConn = nil
    local hboxVis = nil
    local curTrack = nil
    local isPunch = false

    local anims = {
        R6 = "rbxassetid://204062532",
        R15 = 94235564114426
    }

    local bgOn = Color3.fromRGB(0, 40, 10)
    local bgOff = Color3.fromRGB(15, 5, 5)
    local txtOn = Color3.fromRGB(50, 255, 100)
    local txtOff = Color3.fromRGB(255, 50, 50)

    local function getPwr()
        local p = tonumber(pwrBox.Text)
        if not p or p < 1 then return 1 end
        return p
    end

    local function tween(inst, prop, val, dur)
        tweenS:Create(inst, TweenInfo.new(dur or 0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {[prop] = val}):Play()
    end

    local function updateHbox(st)
        if st then
            local char = plr.Character
            local root = getRoot(char)
            if root and not char:FindFirstChild("MatrixHitboxVisual") then
                hboxVis = Instance.new("SelectionBox")
                hboxVis.Name = "MatrixHitboxVisual"
                hboxVis.Adornee = root
                hboxVis.Color3 = Color3.fromRGB(0, 255, 70)
                hboxVis.LineThickness = 0.05
                hboxVis.SurfaceColor3 = Color3.fromRGB(0, 255, 70)
                hboxVis.SurfaceTransparency = 0.85
                hboxVis.Parent = char
            end
        else
            if hboxVis then
                hboxVis:Destroy()
                hboxVis = nil
            end
            local char = plr.Character
            if char then
                local oldVis = char:FindFirstChild("MatrixHitboxVisual")
                if oldVis then oldVis:Destroy() end
            end
        end
    end

    local function updateBtnVis()
        if isFlinging then
            btn.Text = "[ SYSTEM: ACTIVE ]"
            tween(btn, "BackgroundColor3", bgOn)
            tween(btn, "TextColor3", txtOn)
            frmStrk.Color = Color3.fromRGB(0, 255, 70)
            updateHbox(true)
        else
            btn.Text = "[ SYSTEM: OFFLINE ]"
            tween(btn, "BackgroundColor3", bgOff)
            tween(btn, "TextColor3", txtOff)
            frmStrk.Color = Color3.fromRGB(120, 0, 0)
            updateHbox(false)
        end
    end

    local function updatePnchBtn()
        if isPunch then
            pnchBtn.Text = "[ PUNCH MODE: ON ]"
            pnchBtn.TextColor3 = Color3.fromRGB(50, 255, 100)
            pnchBtn.BackgroundColor3 = Color3.fromRGB(0, 40, 10)
            pnchStrk.Color = Color3.fromRGB(0, 255, 70)
        else
            pnchBtn.Text = "[ PUNCH MODE: OFF ]"
            pnchBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
            pnchBtn.BackgroundColor3 = Color3.fromRGB(15, 5, 5)
            pnchStrk.Color = Color3.fromRGB(120, 0, 0)
        end
    end

    btn.MouseEnter:Connect(function()
        if isFlinging then
            tween(btn, "BackgroundColor3", Color3.fromRGB(0, 70, 15))
            tween(btn, "TextColor3", Color3.fromRGB(150, 255, 180))
        else
            tween(btn, "BackgroundColor3", Color3.fromRGB(30, 10, 10))
            tween(btn, "TextColor3", Color3.fromRGB(255, 120, 120))
        end
    end)

    btn.MouseLeave:Connect(updateBtnVis)

    pnchBtn.MouseEnter:Connect(function()
        if isPunch then
            pnchBtn.BackgroundColor3 = Color3.fromRGB(0, 70, 15)
            pnchBtn.TextColor3 = Color3.fromRGB(150, 255, 180)
        else
            pnchBtn.BackgroundColor3 = Color3.fromRGB(30, 10, 10)
            pnchBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
        end
    end)

    pnchBtn.MouseLeave:Connect(updatePnchBtn)

    local function playAnim()
        local char = plr.Character
        if not char then return end
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        
        local cType = getCharType(char)
        local animId = anims[cType] or anims.R6
        
        local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)

        if curTrack then
            curTrack:Stop()
            curTrack:Destroy()
            curTrack = nil
        end

        if cType == "R15" then
            local ok, res = pcall(function()
                return game:GetObjects("rbxassetid://" .. tostring(animId))
            end)

            if ok and res and #res > 0 then
                local a = res[1]
                if a:IsA("Animation") then
                    curTrack = animator:LoadAnimation(a)
                else
                    local newA = Instance.new("Animation")
                    newA.AnimationId = "rbxassetid://" .. tostring(animId)
                    curTrack = animator:LoadAnimation(newA)
                end
            else
                local newA = Instance.new("Animation")
                newA.AnimationId = "rbxassetid://" .. tostring(animId)
                curTrack = animator:LoadAnimation(newA)
            end
        else
            local newA = Instance.new("Animation")
            newA.AnimationId = animId
            curTrack = animator:LoadAnimation(newA)
        end
        
        if curTrack then
            curTrack.Looped = true
            curTrack:Play()
        end
    end

    local function stopAnim()
        if curTrack then
            curTrack:Stop()
            curTrack:Destroy()
            curTrack = nil
        end
    end

    local function startFling()
        if flingConn then return end
        
        isFlinging = true
        
        if isPunch then
            playAnim()
        end
        
        local char = plr.Character
        if char then
            disableCol(char, false)
        end
        
        local movel = 0.1
        local pwr = getPwr()
        
        flingConn = runS.Heartbeat:Connect(function()
            local char = plr.Character
            local root = getRoot(char)
            
            if not (char and char.Parent and root and root.Parent) then 
                return 
            end
            
            if not char:FindFirstChild("MatrixHitboxVisual") and isFlinging then
                updateHbox(true)
            end
            
            if isFlinging then
                disableCol(char, false)
            end
            
            local lastVel = root.AssemblyLinearVelocity
            root.AssemblyLinearVelocity = Vector3.new(pwr, pwr/2, pwr)
            
            runS.RenderStepped:Wait()
            if char and char.Parent and root and root.Parent then
                root.AssemblyLinearVelocity = lastVel
            end
            
            runS.Stepped:Wait()
            if char and char.Parent and root and root.Parent then
                root.AssemblyLinearVelocity = lastVel + Vector3.new(0, movel, 0)
                movel = movel * -1
            end
        end)
        
        updateBtnVis()
    end

    local function stopFling()
        if flingConn then
            flingConn:Disconnect()
            flingConn = nil
        end
        isFlinging = false
        
        stopAnim()
        
        local char = plr.Character
        if char then
            disableCol(char, true)
        end
        
        updateBtnVis()
    end

    local function toggleFling()
        if isFlinging then
            stopFling()
        else
            startFling()
        end
    end

    local function togglePnch()
        isPunch = not isPunch
        updatePnchBtn()
        
        if isFlinging then
            stopFling()
            startFling()
        end
    end

    pwrBox.FocusLost:Connect(function()
        local v = tonumber(pwrBox.Text)
        if not v or v < 1 then
            pwrBox.Text = "1"
        end
        if isFlinging then
            stopFling()
            startFling()
        end
    end)

    plr.CharacterAdded:Connect(function(char)
        if isFlinging then
            task.wait(0.1)
            disableCol(char, false)
            if isPunch then
                stopAnim()
                playAnim()
            end
        end
    end)

    updateBtnVis()
    updatePnchBtn()
    
    btn.MouseButton1Click:Connect(toggleFling)
    pnchBtn.MouseButton1Click:Connect(togglePnch)
end

setupUI()

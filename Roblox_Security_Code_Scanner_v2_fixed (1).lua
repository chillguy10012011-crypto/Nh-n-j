--[==[
    Roblox Security Code Scanner v2
    Defensive static analyzer for authorized Roblox game audits.

    Input format:
    --[[FILE: ServerScriptService/Combat.server.lua]]
    <source code>

    --[[FILE: ReplicatedStorage/CombatModule.lua]]
    <source code>

    The scanner classifies scripts:
      HIGH    = inspect first
      MEDIUM  = inspect after HIGH
      LOW     = usually safe to skip initially

    It also detects basic require() dependencies between supplied source blocks.
    This is heuristic/static analysis only; it does NOT prove a vulnerability.
]==]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local function getParent()
    local ok, result = pcall(function()
        if gethui then return gethui() end
        return CoreGui
    end)
    return ok and result or CoreGui
end

local parent = getParent()

local old = parent:FindFirstChild("SecurityScannerV2")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "SecurityScannerV2"
gui.ResetOnSpawn = false
gui.Parent = parent

local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = obj
end

local function stroke(obj)
    local s = Instance.new("UIStroke")
    s.Thickness = 1
    s.Transparency = 0.35
    s.Parent = obj
end

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(760, 520)
main.Position = UDim2.new(0.5, -380, 0.5, -260)
main.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
main.BorderSizePixel = 0
main.Parent = gui
corner(main, 10)
stroke(main)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 0, 42)
title.Position = UDim2.fromOffset(15, 0)
title.BackgroundTransparency = 1
title.Text = "Security Code Scanner v2"
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(235, 235, 240)
title.Parent = main

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(34, 30)
close.Position = UDim2.new(1, -42, 0, 6)
close.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
close.Text = "X"
close.TextSize = 15
close.Font = Enum.Font.GothamBold
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.Parent = main
corner(close, 7)
close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- Dragging
do
    local dragging = false
    local dragStart, startPos

    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end)
end

local help = Instance.new("TextLabel")
help.Size = UDim2.new(1, -30, 0, 36)
help.Position = UDim2.fromOffset(15, 43)
help.BackgroundTransparency = 1
help.Text = "Paste multiple scripts using --[[FILE: path/name.lua]] markers."
help.TextSize = 13
help.Font = Enum.Font.Gotham
help.TextColor3 = Color3.fromRGB(165, 165, 175)
help.TextXAlignment = Enum.TextXAlignment.Left
help.Parent = main

local input = Instance.new("TextBox")
input.Size = UDim2.new(1, -30, 0, 155)
input.Position = UDim2.fromOffset(15, 82)
input.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
input.TextColor3 = Color3.fromRGB(225, 225, 230)
input.PlaceholderColor3 = Color3.fromRGB(115, 115, 125)
input.PlaceholderText = "--[[FILE: ServerScriptService/MyScript.server.lua]]"
input.Text = ""
input.ClearTextOnFocus = false
input.MultiLine = true
input.TextWrapped = false
input.TextXAlignment = Enum.TextXAlignment.Left
input.TextYAlignment = Enum.TextYAlignment.Top
input.TextSize = 13
input.Font = Enum.Font.Code
input.Parent = main
corner(input, 8)
stroke(input)

local scan = Instance.new("TextButton")
scan.Size = UDim2.fromOffset(125, 34)
scan.Position = UDim2.fromOffset(15, 247)
scan.BackgroundColor3 = Color3.fromRGB(55, 115, 220)
scan.Text = "SCAN"
scan.TextSize = 14
scan.Font = Enum.Font.GothamBold
scan.TextColor3 = Color3.fromRGB(255, 255, 255)
scan.Parent = main
corner(scan, 7)

local clear = Instance.new("TextButton")
clear.Size = UDim2.fromOffset(125, 34)
clear.Position = UDim2.fromOffset(150, 247)
clear.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
clear.Text = "CLEAR"
clear.TextSize = 14
clear.Font = Enum.Font.GothamBold
clear.TextColor3 = Color3.fromRGB(255, 255, 255)
clear.Parent = main
corner(clear, 7)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -290, 0, 34)
status.Position = UDim2.fromOffset(285, 247)
status.BackgroundTransparency = 1
status.Text = "Chưa quét."
status.TextSize = 13
status.Font = Enum.Font.Gotham
status.TextColor3 = Color3.fromRGB(170, 170, 180)
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = main

local results = Instance.new("ScrollingFrame")
results.Size = UDim2.new(1, -30, 0, 215)
results.Position = UDim2.fromOffset(15, 290)
results.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
results.BorderSizePixel = 0
results.ScrollBarThickness = 6
results.CanvasSize = UDim2.new()
results.AutomaticCanvasSize = Enum.AutomaticSize.Y
results.Parent = main
corner(results, 8)
stroke(results)

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = results

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 8)
pad.PaddingBottom = UDim.new(0, 8)
pad.PaddingLeft = UDim.new(0, 8)
pad.PaddingRight = UDim.new(0, 8)
pad.Parent = results

local function clearResults()
    for _, child in ipairs(results:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
end

local function addResult(text, priority)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -5, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundColor3 =
        priority == "HIGH" and Color3.fromRGB(75, 35, 38)
        or priority == "MEDIUM" and Color3.fromRGB(72, 60, 35)
        or Color3.fromRGB(38, 48, 60)

    label.Text = text
    label.TextSize = 13
    label.Font = Enum.Font.Code
    label.TextColor3 = Color3.fromRGB(235, 235, 240)
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Parent = results
    corner(label, 6)

    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, 7)
    p.PaddingBottom = UDim.new(0, 7)
    p.PaddingLeft = UDim.new(0, 8)
    p.PaddingRight = UDim.new(0, 8)
    p.Parent = label
end

local function lower(s)
    return string.lower(s or "")
end

local function containsAny(s, words)
    s = lower(s)
    for _, word in ipairs(words) do
        if string.find(s, lower(word), 1, true) then
            return true
        end
    end
    return false
end

local function countMatches(s, pattern)
    local n = 0
    for _ in string.gmatch(s, pattern) do
        n += 1
    end
    return n
end

local function classify(path, source)
    local s = lower(source)
    local p = lower(path)

    local score = 0
    local reasons = {}
    local deps = {}

    local function add(points, reason)
        score += points
        table.insert(reasons, reason)
    end

    -- Highest-priority server trust boundaries.
    if containsAny(s, {"onserverevent", "onserverinvoke"}) then
        add(60, "nhận dữ liệu từ client qua Remote")
    end

    if containsAny(s, {"remotefunction", "remoteevent"}) then
        add(35, "có RemoteEvent/RemoteFunction")
    end

    if containsAny(s, {
        "money", "coins", "cash", "currency", "leaderstats",
        "inventory", "item", "give", "reward", "datastore",
        "savedata", "purchase", "trade"
    }) then
        add(25, "liên quan dữ liệu/kinh tế/người chơi")
    end

    if containsAny(s, {
        "damage", "health", "humanoid", "walkspeed", "jumppower",
        "cframe", "pivotto", "teleport", "position"
    }) then
        add(22, "liên quan combat/di chuyển/trạng thái")
    end

    if containsAny(s, {
        "admin", "rank", "permission", "authorized", "isadmin",
        "kick", "ban", "shutdown"
    }) then
        add(25, "liên quan quyền hạn/admin")
    end

    if containsAny(s, {"loadstring", "getfenv", "setfenv"}) then
        add(35, "có cơ chế thực thi/tải code động")
    end

    if containsAny(s, {"fireserver", "invokeserver"}) then
        add(10, "client gọi server")
    end

    if containsAny(s, {
        "debounce", "cooldown", "ratelimit", "rate_limit",
        "os.clock", "tick()"
    }) then
        add(5, "có dấu hiệu rate limit/cooldown")
    end

    -- Dependency hints.
    for req in string.gmatch(source, "[Rr]equire%s*%((.-)%)") do
        table.insert(deps, req)
    end

    -- Server-side scripts deserve more attention than pure client UI.
    if string.find(p, ".server.lua", 1, true)
        or string.find(p, "serverscriptservice", 1, true) then
        add(12, "nằm ở khu vực server")
    end

    -- Client scripts with Remotes are still relevant.
    if string.find(p, ".client.lua", 1, true)
        or string.find(p, "localscript", 1, true)
        or string.find(p, "starterplayerscripts", 1, true)
        or string.find(p, "startergui", 1, true) then
        if score > 0 then
            add(4, "client có liên quan logic/network")
        end
    end

    local uiOnly =
        containsAny(s, {
            "screengui", "textlabel", "textbutton", "uicorner",
            "uistroke", "tweenservice", "mousebutton1click",
            "imagelabel", "frames"
        })
        and not containsAny(s, {
            "onserverevent", "onserverinvoke", "fireserver",
            "invokeserver", "money", "damage", "teleport",
            "admin", "datastore"
        })

    if uiOnly and score < 30 then
        score -= 20
        table.insert(reasons, "chủ yếu là GUI/UI")
    end

    local priority
    if score >= 55 then
        priority = "HIGH"
    elseif score >= 25 then
        priority = "MEDIUM"
    else
        priority = "LOW"
    end

    if #reasons == 0 then
        table.insert(reasons, "không thấy pattern nhạy cảm rõ ràng")
    end

    return {
        path = path,
        source = source,
        score = math.max(score, 0),
        priority = priority,
        reasons = reasons,
        deps = deps,
    }
end

local function parseFiles(raw)
    local files = {}
    local markerPattern = "%-%-%[%[FILE:%s*(.-)%]%]"
    local positions = {}

    for startPos, path in string.gmatch(raw, "()%-%-%[%[FILE:%s*(.-)%]%]") do
        table.insert(positions, {start = startPos, path = path})
    end

    if #positions == 0 then
        return {
            {
                path = "PastedCode.lua",
                source = raw
            }
        }
    end

    for i, item in ipairs(positions) do
        local sourceStart = item.start
        local nextStart = positions[i + 1] and positions[i + 1].start
        local markerEnd = string.find(raw, "]]", sourceStart, true)

        if markerEnd then
            local sourceEnd = nextStart and (nextStart - 1) or #raw
            local source = string.sub(raw, markerEnd + 1, sourceEnd)

            table.insert(files, {
                path = item.path,
                source = source
            })
        end
    end

    return files
end

local function runScan()
    clearResults()

    local raw = input.Text or ""
    if #raw < 2 then
        status.Text = "Chưa có code để quét."
        return
    end

    local files = parseFiles(raw)
    local classified = {}

    for _, file in ipairs(files) do
        table.insert(classified, classify(file.path, file.source))
    end

    table.sort(classified, function(a, b)
        local rank = {HIGH = 3, MEDIUM = 2, LOW = 1}
        if rank[a.priority] ~= rank[b.priority] then
            return rank[a.priority] > rank[b.priority]
        end
        return a.score > b.score
    end)

    local counts = {HIGH = 0, MEDIUM = 0, LOW = 0}

    for _, result in ipairs(classified) do
        counts[result.priority] += 1

        local reasonText = table.concat(result.reasons, "; ")
        local depText = #result.deps > 0
            and ("\nRequires: " .. table.concat(result.deps, ", "))
            or ""

        addResult(
            string.format(
                "[%s]  %s  | score=%d\n%s%s",
                result.priority,
                result.path,
                result.score,
                reasonText,
                depText
            ),
            result.priority
        )
    end

    status.Text = string.format(
        "Đã phân loại %d script  |  HIGH: %d  MEDIUM: %d  LOW: %d",
        #classified, counts.HIGH, counts.MEDIUM, counts.LOW
    )
end

scan.MouseButton1Click:Connect(runScan)

clear.MouseButton1Click:Connect(function()
    input.Text = ""
    clearResults()
    status.Text = "Đã xoá."
end)

--[==[
    Roblox Vulnerability Scanner v3
    Công cụ PHÂN TÍCH TĨNH (chỉ đọc code) để audit game có sự cho phép của chủ game.
    - Không gọi / không gửi Remote nào, không sửa gì trong game.
    - Kết quả chỉ là gợi ý (heuristic), KHÔNG chứng minh có lỗ hổng.

    QUÉT GAME (1): liệt kê Remote + đọc script client/module mà executor đọc được,
                   rồi xếp hạng script/remote nghi ngờ.
    QUÉT CODE (2): phân tích code bạn dán vào khung (có thể dán nhiều file bằng
                   dòng  --[[FILE: ServerScriptService/Combat.server.lua]]  ).
                   Nếu khung trống và có file  scan_input.lua  trong thư mục workspace
                   của executor thì sẽ đọc file đó.

    LƯU Ý: Script SERVER (ServerScriptService...) client KHÔNG đọc được. Muốn kiểm tra
    phần server, hãy dán code server (bạn của bạn đưa) vào khung rồi bấm QUÉT CODE.
]==]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

----------------------------------------------------------------------
-- GUI
----------------------------------------------------------------------
local GUI_NAME = "VulnScannerV3"

local function tryGetParent()
    local ok, result = pcall(function()
        if typeof(gethui) == "function" then
            return gethui()
        end
        return CoreGui
    end)
    if ok and result then
        return result
    end
    return nil
end

-- xoá bản cũ nếu có
do
    local places = {tryGetParent(), Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui")}
    for _, place in pairs(places) do
        pcall(function()
            local old = place:FindFirstChild(GUI_NAME)
            if old then old:Destroy() end
        end)
    end
end

local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local parented = pcall(function()
    gui.Parent = tryGetParent() or error("no parent")
end)
if not parented or not gui.Parent then
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function make(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do
        o[k] = v
    end
    if parent then
        o.Parent = parent
    end
    return o
end

local function corner(obj, r)
    make("UICorner", {CornerRadius = UDim.new(0, r or 8)}, obj)
end

local function stroke(obj)
    make("UIStroke", {Thickness = 1, Transparency = 0.35}, obj)
end

local function padding(obj, t, b, l, r)
    make("UIPadding", {
        PaddingTop = UDim.new(0, t),
        PaddingBottom = UDim.new(0, b),
        PaddingLeft = UDim.new(0, l),
        PaddingRight = UDim.new(0, r),
    }, obj)
end

local FONT = Enum.Font.SourceSans
local FONT_BOLD = Enum.Font.SourceSansBold

local main = make("Frame", {
    Size = UDim2.fromScale(0.7, 0.85),
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Color3.fromRGB(24, 24, 28),
    BorderSizePixel = 0,
}, gui)
make("UISizeConstraint", {MinSize = Vector2.new(380, 320), MaxSize = Vector2.new(820, 620)}, main)
corner(main, 10)
stroke(main)

local title = make("TextLabel", {
    Size = UDim2.new(1, -60, 0, 38),
    Position = UDim2.fromOffset(14, 0),
    BackgroundTransparency = 1,
    Text = "Vulnerability Scanner v3  (chỉ đọc – không gọi Remote)",
    TextSize = 19,
    Font = FONT_BOLD,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(235, 235, 240),
}, main)

local closeBtn = make("TextButton", {
    Size = UDim2.fromOffset(34, 28),
    Position = UDim2.new(1, -42, 0, 5),
    BackgroundColor3 = Color3.fromRGB(55, 55, 62),
    Text = "X",
    TextSize = 16,
    Font = FONT_BOLD,
    TextColor3 = Color3.fromRGB(255, 255, 255),
}, main)
corner(closeBtn, 7)
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- kéo thả bằng thanh tiêu đề
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

    UserInputService.InputChanged:Connect(function(input)
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

-- hàng nút
local buttonRow = make("Frame", {
    Size = UDim2.new(1, -24, 0, 72),
    Position = UDim2.fromOffset(12, 40),
    BackgroundTransparency = 1,
}, main)
make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Wraps = true,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, buttonRow)

local function makeButton(text, color, order)
    local b = make("TextButton", {
        Size = UDim2.fromOffset(0, 32),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = color,
        Text = text,
        TextSize = 16,
        Font = FONT_BOLD,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        LayoutOrder = order,
    }, buttonRow)
    padding(b, 0, 0, 14, 14)
    corner(b, 7)
    return b
end

local scanGameBtn = makeButton("QUÉT GAME (1)", Color3.fromRGB(55, 115, 220), 1)
local scanCodeBtn = makeButton("QUÉT CODE (2)", Color3.fromRGB(46, 150, 96), 2)
local scanFolderBtn = makeButton("QUÉT THƯ MỤC (3)", Color3.fromRGB(150, 100, 40), 3)
local exportBtn = makeButton("XUẤT BÁO CÁO", Color3.fromRGB(110, 80, 170), 4)
local filterBtn = makeButton("LỌC: TẤT CẢ", Color3.fromRGB(60, 90, 110), 5)
local clearBtn = makeButton("XOÁ", Color3.fromRGB(70, 70, 78), 6)

local status = make("TextLabel", {
    Size = UDim2.new(1, -24, 0, 20),
    Position = UDim2.fromOffset(12, 116),
    BackgroundTransparency = 1,
    Text = "Chưa quét.",
    TextSize = 15,
    Font = FONT,
    TextColor3 = Color3.fromRGB(170, 170, 180),
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, main)

local input = make("TextBox", {
    Size = UDim2.new(1, -24, 0.22, 0),
    Position = UDim2.fromOffset(12, 140),
    BackgroundColor3 = Color3.fromRGB(15, 15, 18),
    TextColor3 = Color3.fromRGB(225, 225, 230),
    PlaceholderColor3 = Color3.fromRGB(115, 115, 125),
    PlaceholderText = "Dán code vào đây (nhiều file: dùng --[[FILE: path]] ) rồi bấm QUÉT CODE (2). Nhiều script: bỏ vào thư mục scan_input rồi bấm (3)",
    Text = "",
    ClearTextOnFocus = false,
    MultiLine = true,
    TextWrapped = false,
    ClipsDescendants = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextSize = 14,
    Font = Enum.Font.Code,
}, main)
corner(input, 8)
stroke(input)
padding(input, 4, 4, 6, 6)

local results = make("ScrollingFrame", {
    Size = UDim2.new(1, -24, 0.78, -160),
    Position = UDim2.new(0, 12, 0.22, 148),
    BackgroundColor3 = Color3.fromRGB(15, 15, 18),
    BorderSizePixel = 0,
    ScrollBarThickness = 6,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, main)
corner(results, 8)
stroke(results)
make("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, results)
padding(results, 8, 8, 8, 8)

local SEV_COLOR = {
    HIGH = Color3.fromRGB(95, 40, 44),
    MEDIUM = Color3.fromRGB(88, 70, 34),
    LOW = Color3.fromRGB(40, 52, 66),
}

local nextOrder = 1

local function setStatus(text)
    status.Text = text
end

local function clearResults()
    for _, child in ipairs(results:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    nextOrder = 1
end

-- mỗi mục: tiêu đề bấm được, bấm để mở/đóng chi tiết
local function addItem(headerText, sev, detailText, expanded)
    local holder = make("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = nextOrder,
    }, results)
    nextOrder += 1

    make("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, holder)

    local prefix = ""
    if detailText then
        prefix = expanded and "[-] " or "[+] "
    end

    local header = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = SEV_COLOR[sev] or SEV_COLOR.LOW,
        Text = prefix .. headerText,
        TextSize = 15,
        Font = FONT_BOLD,
        TextColor3 = Color3.fromRGB(240, 240, 245),
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        AutoButtonColor = true,
        LayoutOrder = 1,
    }, holder)
    corner(header, 6)
    padding(header, 6, 6, 8, 8)

    if detailText then
        local detail = make("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Color3.fromRGB(28, 28, 34),
            Text = detailText,
            TextSize = 15,
            Font = FONT,
            TextColor3 = Color3.fromRGB(215, 215, 222),
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Visible = expanded and true or false,
            LayoutOrder = 2,
        }, holder)
        corner(detail, 6)
        padding(detail, 6, 6, 10, 8)

        header.MouseButton1Click:Connect(function()
            detail.Visible = not detail.Visible
            header.Text = (detail.Visible and "[-] " or "[+] ") .. headerText
        end)
    end
end

----------------------------------------------------------------------
-- BỘ PHÂN TÍCH TĨNH
----------------------------------------------------------------------
local SEV_RANK = {HIGH = 3, MEDIUM = 2, LOW = 1}
local SEV_SCORE = {HIGH = 30, MEDIUM = 12, LOW = 3}

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function countWord(s, w)
    local n = 0
    for _ in s:gmatch("%f[%w_]" .. w .. "%f[^%w_]") do
        n += 1
    end
    return n
end

local function hasWord(s, w)
    return s:find("%f[%w_]" .. w .. "%f[^%w_]") ~= nil
end

local function hasAny(text, tokens)
    text = text:lower()
    for _, t in ipairs(tokens) do
        if text:find(t) then
            return true
        end
    end
    return false
end

local function matchesAny(text, pats)
    for _, p in ipairs(pats) do
        if text:find(p) then
            return true
        end
    end
    return false
end

-- bỏ chuỗi và comment 1 dòng để phân tích
local function cleanLine(line)
    line = line:gsub('"[^"]*"', '""')
    line = line:gsub("'[^']*'", "''")
    line = line:gsub("%-%-.*$", "")
    return line
end

local function parseLines(src)
    src = src:gsub("\r\n", "\n")
    src = src:gsub("\r", "\n")
    local lines = {}
    local inBlock = false
    for raw in (src .. "\n"):gmatch("([^\n]*)\n") do
        local c
        if inBlock then
            local e = raw:find("]]", 1, true)
            if e then
                inBlock = false
                c = cleanLine(raw:sub(e + 2))
            else
                c = ""
            end
        else
            local s = raw:find("--[[", 1, true)
            if s then
                local e = raw:find("]]", s + 4, true)
                if e then
                    c = cleanLine(raw:sub(1, s - 1) .. " " .. raw:sub(e + 2))
                else
                    c = cleanLine(raw:sub(1, s - 1))
                    inBlock = true
                end
            else
                c = cleanLine(raw)
            end
        end
        lines[#lines + 1] = {raw = raw, clean = c}
    end
    return lines
end

local function parseParams(str)
    local names = {}
    for part in str:gmatch("[^,]+") do
        local name = trim(part):match("^([%a_][%w_]*)")
        if name then
            names[#names + 1] = name
        end
    end
    return names
end

-- ước lượng dòng kết thúc thân hàm (đếm function/then/do ... end)
local function findBodyEnd(lines, startIdx)
    local depth = 0
    local maxIdx = math.min(#lines, startIdx + 150)
    for i = startIdx, maxIdx do
        local c = lines[i].clean
        local opens = countWord(c, "function") + countWord(c, "then") - countWord(c, "elseif")
            + countWord(c, "do") + countWord(c, "repeat")
        local closes = countWord(c, "end") + countWord(c, "until")
        depth += opens - closes
        if depth <= 0 then
            return i
        end
    end
    return maxIdx
end

local SINKS = {
    {key = "damage", label = "sát thương / máu", sev = "HIGH",
        pats = {"TakeDamage", "%.Health", "BreakJoints"},
        fix = "Server tự tính sát thương từ vũ khí/tầm đánh; chỉ nhận ID mục tiêu rồi kiểm tra hợp lệ."},
    {key = "economy", label = "tiền / dữ liệu / DataStore", sev = "HIGH",
        pats = {"leaderstats", "[Cc]ash", "[Mm]oney", "[Cc]oins?", "[Gg]old", "[Gg]ems?",
            "SetAsync", "UpdateAsync", "IncrementAsync", "%.Value%s*[%+%-]?=[^=]"},
        fix = "Không cộng/trừ theo số client gửi; server tự tra giá/phần thưởng từ bảng cố định."},
    {key = "move", label = "vị trí / dịch chuyển", sev = "HIGH",
        pats = {"CFrame", "PivotTo", "%.Position", "MoveTo", "Teleport"},
        fix = "Không đặt vị trí theo dữ liệu client; kiểm tra khoảng cách/tốc độ hợp lý ở server."},
    {key = "speed", label = "WalkSpeed / JumpPower", sev = "HIGH",
        pats = {"WalkSpeed", "JumpPower", "JumpHeight"},
        fix = "Không đặt tốc độ/nhảy từ giá trị client; server tự đặt giá trị cố định."},
    {key = "item", label = "tạo/chuyển vật phẩm", sev = "MEDIUM",
        pats = {":Clone%(", "Backpack", "%.Parent%s*=", "Instance%.new"},
        fix = "Kiểm tra quyền sở hữu / whitelist vật phẩm trước khi tạo hoặc chuyển."},
    {key = "destroy", label = "xoá/huỷ Instance", sev = "MEDIUM",
        pats = {":Destroy%(", ":Remove%("},
        fix = "Chỉ cho huỷ vật thể thuộc quyền người chơi; kiểm tra tên/vị trí/chủ sở hữu."},
    {key = "admin", label = "hành động quản trị (kick/ban/shutdown)", sev = "HIGH",
        pats = {":Kick%(", "BanAsync", "%.Ban%(", ":Ban%(", "Shutdown"},
        fix = "Kiểm tra quyền (UserId / rank group) ở server trước khi thực hiện."},
    {key = "exec", label = "thực thi code động", sev = "HIGH",
        pats = {"loadstring", "require%s*%("},
        fix = "Không thực thi/require theo dữ liệu từ client."},
}

local ARG_VALIDATION = {"typeof", "type%(", "assert", "clamp", ":isa%(", "tonumber", "table%.find", "isfinite"}
local RATE_TOKENS = {"os%.clock", "tick%(", "os%.time", "cooldown", "debounce", "ratelimit", "lastfire", "lastuse", "lastattack", "lasttime"}
local DIST_TOKENS = {"magnitude", "distancefromcharacter", "raycast", "getpartboundsinradius", "getpartsinpart", "getpartboundsinbox"}
local AUTH_TOKENS = {"userid", "getrankingroup", "isingroup", "isadmin", "admin", "whitelist", "getroleingroup", "%.rank"}

local SENSITIVE_ARG_WORDS = {
    "damage", "dmg", "health", "hp", "money", "cash", "coins", "coin", "gold", "gems",
    "price", "reward", "amount",
}

local function analyzeHandler(lines, idx, paramStr, add)
    local params = parseParams(paramStr)
    local endIdx = findBodyEnd(lines, idx)

    local parts = {}
    for i = idx, endIdx do
        parts[#parts + 1] = lines[i].clean
    end
    local body = table.concat(parts, "\n")

    local first = params[1]
    local args = {}
    for i = 2, #params do
        args[#args + 1] = params[i]
    end

    -- A. tham số đầu của OnServerEvent/OnServerInvoke luôn là Player
    if first then
        local fl = first:lower()
        local looksLikePlayer = fl == "_" or fl == "p" or fl == "ply"
            or fl:find("play") or fl:find("plr") or fl:find("user")
            or fl:find("client") or fl:find("sender") or fl:find("caller")
        if not looksLikePlayer then
            add(idx, "MEDIUM",
                string.format("Tham số đầu tiên của OnServerEvent/OnServerInvoke luôn là Player do Roblox điền, nhưng đang đặt tên '%s' (dễ bị nhầm là dữ liệu client).", first),
                "Đặt tham số đầu là player; dữ liệu client bắt đầu từ tham số thứ 2.")
        end
    end

    -- B. truy vết tham số từ client (kèm alias qua 'local x = ...')
    local tracked = {}
    for _, a in ipairs(args) do
        tracked[a] = a
    end
    for i = idx + 1, endIdx do
        local c = lines[i].clean
        local name, expr = c:match("^%s*local%s+([%a_][%w_]*)%s*=%s*(.+)$")
        if name and not expr:find("clamp") then
            local origin
            for tname, o in pairs(tracked) do
                if hasWord(expr, tname) then
                    origin = o
                    break
                end
            end
            if origin then
                tracked[name] = origin
            end
        end
    end

    local sinkHit = {}
    local reported = {}
    for i = idx + 1, endIdx do
        local c = lines[i].clean
        for _, sink in ipairs(SINKS) do
            if matchesAny(c, sink.pats) then
                sinkHit[sink.key] = true
                if not (c:find("clamp") or c:find("Magnitude")) then
                    for tname, origin in pairs(tracked) do
                        if hasWord(c, tname) then
                            local k = origin .. "|" .. sink.key
                            if not reported[k] then
                                reported[k] = true
                                local who = (tname == origin) and ("'" .. origin .. "'")
                                    or ("'" .. tname .. "' (lấy từ tham số '" .. origin .. "')")
                                add(i, sink.sev,
                                    string.format("Dữ liệu client %s được dùng trực tiếp cho %s mà không thấy bị giới hạn/kiểm tra.", who, sink.label),
                                    sink.fix)
                            end
                        end
                    end
                end
            end
        end
    end

    -- C. thiếu kiểm tra kiểu/phạm vi
    if #args > 0 and not hasAny(body, ARG_VALIDATION) then
        add(idx, "MEDIUM",
            "Không thấy kiểm tra kiểu/phạm vi cho tham số từ client: " .. table.concat(args, ", ") .. ".",
            "Kiểm tra typeof(), math.clamp(), IsA() và giá trị hợp lệ trước khi dùng.")
    end

    -- D. thiếu cooldown / rate limit
    local risky = sinkHit.damage or sinkHit.economy or sinkHit.item or sinkHit.move or sinkHit.destroy
    if risky and not hasAny(body, RATE_TOKENS) then
        local sev = sinkHit.economy and "HIGH" or "MEDIUM"
        add(idx, sev,
            "Handler thực hiện hành động nhạy cảm nhưng không thấy cooldown/rate limit (có thể bị gọi lặp liên tục).",
            "Lưu thời điểm gọi gần nhất cho từng player (os.clock) và từ chối nếu gọi quá nhanh.")
    end

    -- E. combat không kiểm tra khoảng cách
    if sinkHit.damage and not hasAny(body, DIST_TOKENS) then
        add(idx, "MEDIUM",
            "Có gây sát thương nhưng không thấy kiểm tra khoảng cách/raycast ở server (có thể đánh từ xa).",
            "Dùng (vị trí người đánh - vị trí mục tiêu).Magnitude hoặc raycast ở server để xác nhận tầm đánh.")
    end

    -- F. hành động quản trị không kiểm tra quyền
    if sinkHit.admin and not hasAny(body, AUTH_TOKENS) then
        add(idx, "HIGH",
            "Handler có hành động quản trị nhưng không thấy kiểm tra quyền của người gửi.",
            "Kiểm tra player.UserId nằm trong danh sách admin hoặc rank group ở server.")
    end
end

local SENSITIVE_FIRE_PATTERN = {":FireServer%s*%((.*)%)", ":InvokeServer%s*%((.*)%)"}

local function analyze(source)
    local lines = parseLines(source)
    local findings = {}

    local function add(lineNo, sev, msg, fix)
        local code
        if lineNo and lines[lineNo] then
            code = trim(lines[lineNo].raw)
            if #code > 100 then
                code = code:sub(1, 100) .. "..."
            end
        end
        findings[#findings + 1] = {line = lineNo, sev = sev, msg = msg, fix = fix, code = code}
    end

    local fullClean = {}
    for i, l in ipairs(lines) do
        fullClean[i] = l.clean
    end
    local allText = table.concat(fullClean, "\n")
    local isServerLogic = allText:find("OnServerEvent") or allText:find("OnServerInvoke")
    local usesLocalPlayer = allText:find("LocalPlayer") ~= nil

    -- quy tắc theo từng dòng
    for i, l in ipairs(lines) do
        local c = l.clean

        if hasWord(c, "loadstring") then
            add(i, "MEDIUM",
                "Dùng loadstring: nếu chuỗi đến từ client/Remote thì cho phép chạy code tuỳ ý.",
                "Không dùng loadstring với dữ liệu ngoài; dùng bảng hàm whitelist.")
        end

        if hasWord(c, "getfenv") or hasWord(c, "setfenv") then
            add(i, "LOW", "Dùng getfenv/setfenv (can thiệp môi trường script).",
                "Tránh dùng; thiết kế lại bằng module.")
        end

        if c:find(":InvokeClient%s*%(") then
            add(i, "MEDIUM",
                "InvokeClient: client có thể không trả lời, làm luồng server bị treo vô hạn.",
                "Tránh InvokeClient; dùng RemoteEvent hai chiều kèm timeout.")
        end

        -- client gửi giá trị nhạy cảm lên server (dùng raw để thấy tên biến trong tham số)
        for _, pat in ipairs(SENSITIVE_FIRE_PATTERN) do
            local argText = l.raw:match(pat)
            if argText and not trim(l.raw):find("^%-%-") then
                local low = argText:lower()
                for _, w in ipairs(SENSITIVE_ARG_WORDS) do
                    if hasWord(low, w) then
                        add(i, "HIGH",
                            string.format("Client gửi giá trị nhạy cảm '%s' lên server (client-authoritative): nếu server tin giá trị này thì có thể bị giả mạo.", w),
                            "Chỉ gửi ID hành động (vd 'Attack'); server tự tính damage/giá/phần thưởng.")
                        break
                    end
                end
            end
        end

        if c:find("LocalPlayer") and c:lower():find("admin") then
            add(i, "MEDIUM",
                "Kiểm tra quyền admin ở phía client (client có thể bị sửa/bỏ qua).",
                "Mọi kiểm tra quyền phải làm ở server.")
        end

        if (not isServerLogic) and usesLocalPlayer
            and (c:find("WalkSpeed%s*=") or c:find("JumpPower%s*=")) then
            add(i, "LOW",
                "Client đổi WalkSpeed/JumpPower: nếu server không kiểm tra tốc độ thực tế thì có thể bị lạm dụng.",
                "Server nên giám sát tốc độ di chuyển bất thường (anti-speed).")
        end

        -- anti-cheat đặt ở client
        if (not isServerLogic) and usesLocalPlayer and c:find(":Kick%s*%(") then
            add(i, "MEDIUM",
                "Anti-cheat kick từ client: kẻ gian có thể xoá/vô hiệu hoá script này nên không đáng tin.",
                "Quyết định kick/ban phải nằm ở server; client chỉ gửi tín hiệu phụ.")
        end

        if (not isServerLogic) and usesLocalPlayer and c:find("WalkSpeed%s*[<>~]") then
            add(i, "MEDIUM",
                "Phát hiện speed bằng so sánh ở client: có thể bị vô hiệu hoá hoặc đánh lừa.",
                "Đo tốc độ/vị trí thực tế ở server (khoảng cách giữa các lần cập nhật).")
        end

        do
            local lowRaw = l.raw:lower()
            if lowRaw:find(":fireserver", 1, true)
                and (lowRaw:find("cheat", 1, true) or lowRaw:find("exploit", 1, true)
                    or lowRaw:find("hack", 1, true) or hasWord(lowRaw, "ban"))
                and not trim(l.raw):find("^%-%-") then
                add(i, "MEDIUM",
                    "Client tự báo cáo gian lận lên server: kẻ gian có thể chặn Remote này hoặc spam báo cáo giả.",
                    "Server tự phát hiện; coi báo cáo từ client chỉ là tín hiệu phụ, không ban tự động.")
            end
        end
    end

    -- handler Remote
    for i, l in ipairs(lines) do
        local c = l.clean
        local p1 = c:match("OnServerEvent%s*:%s*Connect%s*%(%s*function%s*%(([^)]*)%)")
        local p2 = c:match("OnServerInvoke%s*=%s*function%s*%(([^)]*)%)")
        if p1 then
            analyzeHandler(lines, i, p1, add)
        elseif p2 then
            analyzeHandler(lines, i, p2, add)
        else
            local named = c:match("OnServerEvent%s*:%s*Connect%s*%(%s*([%a_][%w_%.]*)%s*%)")
                or c:match("OnServerInvoke%s*=%s*([%a_][%w_%.]*)%s*$")
            if named then
                local esc = named:gsub("%p", "%%%0")
                local found = false
                for j, l2 in ipairs(lines) do
                    local c2 = l2.clean
                    local ps = c2:match("function%s+" .. esc .. "%s*%(([^)]*)%)")
                        or c2:match(esc .. "%s*=%s*function%s*%(([^)]*)%)")
                    if ps then
                        analyzeHandler(lines, j, ps, add)
                        found = true
                        break
                    end
                end
                if not found then
                    add(i, "LOW",
                        "Handler '" .. named .. "' được nối vào Remote nhưng không tìm thấy định nghĩa trong code đã cung cấp.",
                        "Dán thêm file/module chứa hàm này để quét tiếp.")
                end
            end
        end
    end

    table.sort(findings, function(a, b)
        if SEV_RANK[a.sev] ~= SEV_RANK[b.sev] then
            return SEV_RANK[a.sev] > SEV_RANK[b.sev]
        end
        return (a.line or 0) < (b.line or 0)
    end)

    return findings
end

local function summarize(findings)
    local score, top = 0, "LOW"
    for _, f in ipairs(findings) do
        score += SEV_SCORE[f.sev]
        if SEV_RANK[f.sev] > SEV_RANK[top] then
            top = f.sev
        end
    end
    return score, top
end

local function formatFindings(findings, limit)
    local out = {}
    for i, f in ipairs(findings) do
        if i > limit then
            out[#out + 1] = string.format("... và %d phát hiện khác (đã ẩn bớt).", #findings - limit)
            break
        end
        local where = f.line and ("dòng " .. f.line) or "chung"
        out[#out + 1] = string.format("- [%s] %s: %s", f.sev, where, f.msg)
        if f.code and f.code ~= "" then
            out[#out + 1] = "    > " .. f.code
        end
        if f.fix then
            out[#out + 1] = "    -> Cách sửa: " .. f.fix
        end
    end
    return table.concat(out, "\n")
end

----------------------------------------------------------------------
-- KẾT QUẢ: lưu / hiển thị / lọc / xuất
----------------------------------------------------------------------
local lastEntries = {}
local filterMode = 1
local FILTER_LABELS = {"LỌC: TẤT CẢ", "LỌC: HIGH+MEDIUM", "LỌC: CHỈ HIGH"}
local MAX_SHOWN = 250
local busy = false

local function render()
    clearResults()
    local minRank = (filterMode == 1 and 1) or (filterMode == 2 and 2) or 3
    local shown, hidden = 0, 0
    for _, e in ipairs(lastEntries) do
        if e.pinned or SEV_RANK[e.sev] >= minRank then
            if shown < MAX_SHOWN then
                addItem(e.header, e.sev, e.detail, e.expand == true)
                shown += 1
            else
                hidden += 1
            end
        end
    end
    if hidden > 0 then
        addItem(string.format("... còn %d mục chưa hiển thị. Dùng LỌC hoặc XUẤT BÁO CÁO để xem đủ.", hidden), "LOW", nil, false)
    end
end

local function sortEntries(entries)
    table.sort(entries, function(a, b)
        if SEV_RANK[a.sev] ~= SEV_RANK[b.sev] then
            return SEV_RANK[a.sev] > SEV_RANK[b.sev]
        end
        return a.score > b.score
    end)
end

local function cleanSummary(clean)
    if #clean == 0 then
        return nil
    end
    local shown = {}
    for i = 1, math.min(#clean, 80) do
        shown[i] = clean[i]
    end
    local extra = ""
    if #clean > 80 then
        extra = "\n... và " .. (#clean - 80) .. " mục khác"
    end
    return {
        sev = "LOW", score = -1,
        header = string.format("[LOW] %d script không thấy pattern đáng ngờ", #clean),
        detail = table.concat(shown, "\n") .. extra,
    }
end

-- files = { {path=, source=}, ... }
local function analyzeFiles(files)
    local entries, clean = {}, {}
    local counts = {HIGH = 0, MEDIUM = 0, LOW = 0}

    for i, f in ipairs(files) do
        if i % 10 == 1 then
            setStatus(string.format("Đang phân tích %d/%d ...", i, #files))
        end

        local ok, findings = pcall(analyze, f.source)
        if not ok then
            findings = {{sev = "LOW", msg = "Lỗi khi phân tích: " .. tostring(findings)}}
        end

        if #findings == 0 then
            clean[#clean + 1] = f.path
        else
            local score, top = summarize(findings)
            counts[top] += 1
            entries[#entries + 1] = {
                sev = top, score = score,
                header = string.format("[%s] %s\nscore %d | %d phát hiện", top, f.path, score, #findings),
                detail = formatFindings(findings, 40),
                full = string.format("[%s] %s | score %d | %d phát hiện\n%s",
                    top, f.path, score, #findings, formatFindings(findings, 1000)),
            }
        end

        if i % 5 == 0 then
            task.wait()
        end
    end

    return entries, counts, clean
end

local function exportReport()
    if #lastEntries == 0 then
        setStatus("Chưa có kết quả để xuất.")
        return
    end

    local out = {"Vulnerability Scanner v3 - báo cáo " .. os.date("%Y-%m-%d %H:%M:%S"), ""}
    for _, e in ipairs(lastEntries) do
        local block = e.full
        if not block then
            block = e.header
            if e.detail then
                block = block .. "\n" .. e.detail
            end
        end
        out[#out + 1] = block
        out[#out + 1] = ""
    end
    local text = table.concat(out, "\n")

    local fname = "scan_report_" .. os.time() .. ".txt"
    local saved, copied = false, false
    if typeof(writefile) == "function" then
        saved = pcall(writefile, fname, text)
    end
    if typeof(setclipboard) == "function" then
        copied = pcall(setclipboard, text)
    end

    if saved and copied then
        setStatus("Đã lưu '" .. fname .. "' (thư mục workspace) và copy vào clipboard.")
    elseif saved then
        setStatus("Đã lưu '" .. fname .. "' trong thư mục workspace của executor.")
    elseif copied then
        setStatus("Không ghi được file; đã copy báo cáo vào clipboard.")
    else
        setStatus("Executor không hỗ trợ writefile/setclipboard nên không xuất được.")
    end
end

----------------------------------------------------------------------
-- QUÉT CODE (2): code trong khung nhập
----------------------------------------------------------------------
local function splitFiles(raw)
    raw = raw:gsub("\r\n", "\n")
    local files, cur = {}, nil
    for line in (raw .. "\n"):gmatch("([^\n]*)\n") do
        local path = line:match("^%s*%-%-%[%[FILE:%s*(.-)%s*%]%]")
        if path then
            cur = {path = path, lines = {}}
            files[#files + 1] = cur
        else
            if not cur then
                cur = {path = "Code đã dán", lines = {}}
                files[#files + 1] = cur
            end
            cur.lines[#cur.lines + 1] = line
        end
    end
    for _, f in ipairs(files) do
        f.source = table.concat(f.lines, "\n")
    end
    return files
end

local function readInput()
    local raw = input.Text or ""
    if #trim(raw) > 0 then
        return raw
    end
    if typeof(isfile) == "function" and typeof(readfile) == "function" then
        local ok, content = pcall(function()
            if isfile("scan_input.lua") then
                return readfile("scan_input.lua")
            end
        end)
        if ok and typeof(content) == "string" and #content > 0 then
            return content
        end
    end
    return ""
end

local function finishCodeScan(files)
    local entries, counts, clean = analyzeFiles(files)
    sortEntries(entries)
    if #files == 1 and entries[1] then
        entries[1].expand = true
    end
    local cs = cleanSummary(clean)
    if cs then
        entries[#entries + 1] = cs
    end
    lastEntries = entries
    render()
    setStatus(string.format("Đã quét %d file | HIGH: %d  MEDIUM: %d  LOW: %d  | không phát hiện: %d",
        #files, counts.HIGH, counts.MEDIUM, counts.LOW, #clean))
end

local function scanCode()
    if busy then return end
    local raw = readInput()
    if #trim(raw) < 2 then
        setStatus("Chưa có code để quét (dán vào khung hoặc tạo file scan_input.lua).")
        return
    end
    busy = true
    clearResults()
    task.spawn(function()
        local ok, err = pcall(function()
            finishCodeScan(splitFiles(raw))
        end)
        if not ok then
            setStatus("Lỗi khi quét: " .. tostring(err))
        end
        busy = false
    end)
end

----------------------------------------------------------------------
-- QUÉT THƯ MỤC (3): đọc nhiều file trong workspace/scan_input
----------------------------------------------------------------------
local FOLDER = "scan_input"
local MAX_FILE_BYTES = 1500000

local function listFilesRecursive(folder, out, depth)
    if depth > 8 then return end
    local ok, items = pcall(listfiles, folder)
    if not ok or typeof(items) ~= "table" then return end
    for _, p in ipairs(items) do
        local isDir = false
        pcall(function()
            isDir = isfolder(p) == true
        end)
        if isDir then
            listFilesRecursive(p, out, depth + 1)
        else
            local low = p:lower()
            if low:match("%.lua$") or low:match("%.luau$") or low:match("%.txt$") then
                out[#out + 1] = p
            end
        end
    end
end

local function scanFolder()
    if busy then return end

    if typeof(listfiles) ~= "function" or typeof(readfile) ~= "function" or typeof(isfolder) ~= "function" then
        setStatus("Executor không hỗ trợ listfiles/readfile/isfolder nên không quét thư mục được.")
        return
    end

    local okF, exists = pcall(isfolder, FOLDER)
    if not okF or not exists then
        if typeof(makefolder) == "function" then
            pcall(makefolder, FOLDER)
        end
        setStatus("Chưa có thư mục '" .. FOLDER .. "' - đã tạo trong workspace của executor. Bỏ file .lua/.txt vào đó rồi bấm lại.")
        return
    end

    busy = true
    clearResults()
    setStatus("Đang liệt kê file trong '" .. FOLDER .. "' ...")

    task.spawn(function()
        local ok, err = pcall(function()
            local paths = {}
            listFilesRecursive(FOLDER, paths, 0)

            if #paths == 0 then
                setStatus("Thư mục '" .. FOLDER .. "' đang trống (cần file .lua / .luau / .txt).")
                return
            end

            local files, skipped = {}, 0
            for i, p in ipairs(paths) do
                if i % 10 == 1 then
                    setStatus(string.format("Đang đọc file %d/%d ...", i, #paths))
                end
                local okR, content = pcall(readfile, p)
                local label = (p:gsub("\\", "/"))
                if okR and typeof(content) == "string" and #content > 0 and #content <= MAX_FILE_BYTES then
                    local parts = splitFiles(content)
                    for _, part in ipairs(parts) do
                        local path = part.path
                        if #parts == 1 and path == "Code đã dán" then
                            path = label
                        end
                        files[#files + 1] = {path = path, source = part.source}
                    end
                else
                    skipped += 1
                end
                if i % 10 == 0 then
                    task.wait()
                end
            end

            finishCodeScan(files)
            if skipped > 0 then
                setStatus(status.Text .. string.format("  (bỏ qua %d file lỗi/quá lớn)", skipped))
            end
        end)
        if not ok then
            setStatus("Lỗi khi quét thư mục: " .. tostring(err))
        end
        busy = false
    end)
end

----------------------------------------------------------------------
-- QUÉT GAME (1)
----------------------------------------------------------------------
local REMOTE_KEYS = {
    {"kinh tế / vật phẩm", {"give", "reward", "buy", "purchase", "sell", "cash", "money", "coin", "gold", "gem", "claim", "redeem", "trade", "shop", "inventory"}},
    {"combat / sát thương", {"damage", "attack", "shoot", "kill", "heal", "hurt", "punch", "swing", "weapon", "combat", "hitbox"}},
    {"di chuyển / dịch chuyển", {"teleport", "warp", "speed", "fly", "noclip"}},
    {"quản trị", {"admin", "kick", "ban", "command", "cmd", "rank", "permission"}},
}

local DEFAULT_SCRIPT_NAMES = {
    PlayerModule = true, ChatScript = true, BubbleChat = true, PlayerScriptsLoader = true,
    RbxCharacterSounds = true,
}

local function classifyRemote(name)
    local low = name:lower()
    for _, group in ipairs(REMOTE_KEYS) do
        for _, key in ipairs(group[2]) do
            if low:find(key, 1, true) then
                return group[1]
            end
        end
    end
    return nil
end

local function safeFullName(inst)
    local ok, name = pcall(function()
        return inst:GetFullName()
    end)
    return ok and name or tostring(inst)
end

local function isUnderCoreGui(inst)
    local ok, r = pcall(function()
        return inst:IsDescendantOf(CoreGui)
    end)
    return ok and r
end

local function collectRemotes()
    local list = {}
    for _, d in ipairs(game:GetDescendants()) do
        local cn = d.ClassName
        if cn == "RemoteEvent" or cn == "RemoteFunction" or cn == "UnreliableRemoteEvent" then
            if not isUnderCoreGui(d) then
                list[#list + 1] = d
            end
        end
    end
    return list
end

local function collectScripts()
    local list, seen = {}, {}
    local function add(s)
        if typeof(s) == "Instance" and not seen[s] and s:IsA("LuaSourceContainer") then
            seen[s] = true
            if not isUnderCoreGui(s) and not DEFAULT_SCRIPT_NAMES[s.Name]
                and not s:FindFirstAncestor("PlayerModule")
                and not s:FindFirstAncestor("ChatScript")
                and not s:FindFirstAncestor("BubbleChat") then
                list[#list + 1] = s
            end
        end
    end

    if typeof(getscripts) == "function" then
        pcall(function()
            for _, s in ipairs(getscripts()) do add(s) end
        end)
    end
    if typeof(getloadedmodules) == "function" then
        pcall(function()
            for _, s in ipairs(getloadedmodules()) do add(s) end
        end)
    end
    for _, d in ipairs(game:GetDescendants()) do
        if d:IsA("LuaSourceContainer") then
            add(d)
        end
    end
    return list
end

local function readSource(s)
    if typeof(decompile) == "function" then
        local ok, src = pcall(decompile, s)
        if ok and typeof(src) == "string" and #src > 0 then
            return src
        end
    end
    local ok2, src2 = pcall(function()
        return s.Source
    end)
    if ok2 and typeof(src2) == "string" and #src2 > 0 then
        return src2
    end
    return nil
end

-- đọc source có giới hạn thời gian (decompile đôi khi bị treo)
local function readSourceTimeout(s, timeout)
    local result, done = nil, false
    task.spawn(function()
        result = readSource(s)
        done = true
    end)
    local t0 = os.clock()
    while not done and os.clock() - t0 < timeout do
        task.wait()
    end
    return result
end

local MAX_SCRIPTS = 800

local function scanGame()
    if busy then return end
    busy = true
    clearResults()
    setStatus("Đang thu thập Remote và script...")

    task.spawn(function()
        local ok, err = pcall(function()
            local remotes = collectRemotes()
            local scripts = collectScripts()

            local truncated = false
            if #scripts > MAX_SCRIPTS then
                truncated = true
                for i = #scripts, MAX_SCRIPTS + 1, -1 do
                    scripts[i] = nil
                end
            end

            local files, unreadable = {}, {}
            for i, s in ipairs(scripts) do
                local path = safeFullName(s)
                if i % 5 == 1 then
                    setStatus(string.format("Đang đọc script %d/%d ...", i, #scripts))
                end
                local src = readSourceTimeout(s, 6)
                if src then
                    files[#files + 1] = {path = path .. " (" .. s.ClassName .. ")", source = src}
                else
                    unreadable[#unreadable + 1] = path
                end
                task.wait()
            end

            local entries, counts, clean = analyzeFiles(files)

            -- Remote
            local lowRemotes = {}
            for _, r in ipairs(remotes) do
                local path = safeFullName(r)
                local category = classifyRemote(r.Name)

                local refs = {}
                if #r.Name >= 3 then
                    for _, f in ipairs(files) do
                        if f.source:find(r.Name, 1, true) then
                            refs[#refs + 1] = f.path
                        end
                    end
                end

                if category then
                    counts.MEDIUM += 1
                    local lines = {
                        "Tên Remote gợi ý chức năng: " .. category .. ".",
                        "Server phải xác thực người gửi và mọi tham số (kiểu, phạm vi, quyền, cooldown, khoảng cách).",
                        "Hãy mở handler OnServerEvent/OnServerInvoke của remote này trong code server, rồi dán vào khung hoặc thư mục và quét.",
                    }
                    if #refs > 0 then
                        lines[#lines + 1] = "Được nhắc trong " .. #refs .. " script đọc được:"
                        for i = 1, math.min(#refs, 6) do
                            lines[#lines + 1] = "  - " .. refs[i]
                        end
                    end
                    entries[#entries + 1] = {
                        sev = "MEDIUM", score = 20 + #refs,
                        header = string.format("[MEDIUM] Remote: %s (%s)\nnhắc trong %d script", path, r.ClassName, #refs),
                        detail = table.concat(lines, "\n"),
                    }
                else
                    lowRemotes[#lowRemotes + 1] = string.format("%s (%s, %d script nhắc)", path, r.ClassName, #refs)
                end
            end

            sortEntries(entries)

            local ordered = {{
                pinned = true, sev = "LOW", score = 0,
                header = "Lưu ý: script SERVER client không đọc được. Muốn kiểm tra phần server, dùng QUÉT CODE (2) hoặc QUÉT THƯ MỤC (3) với code server. Kết quả chỉ là gợi ý.",
            }}
            for _, e in ipairs(entries) do
                ordered[#ordered + 1] = e
            end

            if #lowRemotes > 0 then
                counts.LOW += 1
                ordered[#ordered + 1] = {
                    sev = "LOW", score = -1,
                    header = string.format("[LOW] %d Remote khác (tên không gợi ý chức năng nhạy cảm)", #lowRemotes),
                    detail = table.concat(lowRemotes, "\n"),
                }
            end

            local cs = cleanSummary(clean)
            if cs then
                ordered[#ordered + 1] = cs
            end

            if #unreadable > 0 then
                local shown = {}
                for i = 1, math.min(#unreadable, 80) do
                    shown[i] = unreadable[i]
                end
                ordered[#ordered + 1] = {
                    sev = "LOW", score = -2,
                    header = string.format("[LOW] %d script KHÔNG đọc được (executor không hỗ trợ decompile hoặc bị chặn)", #unreadable),
                    detail = table.concat(shown, "\n"),
                }
            end

            lastEntries = ordered
            render()

            local msg = string.format("Xong: %d script đọc được / %d không đọc được | %d remote | HIGH: %d  MEDIUM: %d  LOW: %d",
                #files, #unreadable, #remotes, counts.HIGH, counts.MEDIUM, counts.LOW)
            if truncated then
                msg = msg .. string.format("  (chỉ quét %d script đầu)", MAX_SCRIPTS)
            end
            setStatus(msg)
        end)

        if not ok then
            setStatus("Lỗi khi quét: " .. tostring(err))
        end
        busy = false
    end)
end

----------------------------------------------------------------------
-- NÚT
----------------------------------------------------------------------
scanGameBtn.MouseButton1Click:Connect(scanGame)
scanCodeBtn.MouseButton1Click:Connect(scanCode)
scanFolderBtn.MouseButton1Click:Connect(scanFolder)
exportBtn.MouseButton1Click:Connect(exportReport)

filterBtn.MouseButton1Click:Connect(function()
    filterMode = filterMode % 3 + 1
    filterBtn.Text = FILTER_LABELS[filterMode]
    render()
end)

clearBtn.MouseButton1Click:Connect(function()
    if busy then return end
    input.Text = ""
    lastEntries = {}
    clearResults()
    setStatus("Đã xoá.")
end)

setStatus("Sẵn sàng. (1) quét game | (2) quét code trong khung | (3) quét thư mục workspace/scan_input")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

-- Clean existing UI
if CoreGui:FindFirstChild("MafiaWarsHub") then CoreGui.MafiaWarsHub:Destroy() end
if player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("MafiaWarsHub") then player.PlayerGui.MafiaWarsHub:Destroy() end

local parentContainer
local success = pcall(function() parentContainer = CoreGui end)
if not success or not parentContainer then parentContainer = player:WaitForChild("PlayerGui") end

-- Locate Remotes
local MW = ReplicatedStorage:WaitForChild("MW", 5)
local Remotes = MW and MW:WaitForChild("Remotes", 5)
local doJobRemote = Remotes and Remotes:WaitForChild("DoJob", 5)
local depositRemote = Remotes and Remotes:WaitForChild("Deposit", 5)

-- Helper: Get Cash Label from UI
local function getLiveCashLabel()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    
    local topBar = playerGui:FindFirstChild("MafiaWarsUI") 
        and playerGui.MafiaWarsUI:FindFirstChild("Root") 
        and playerGui.MafiaWarsUI.Root:FindFirstChild("TopBar")
        
    if topBar then
        local cashCluster = topBar:FindFirstChild("CashCluster")
        if cashCluster then
            return cashCluster:FindFirstChild("CashValue")
        end
    end
    return nil
end

-- Helper: Convert Cash text (e.g., "$50k" -> 50000)
local function getLiveCashValue()
    local cashLabel = getLiveCashLabel()
    if not cashLabel or not cashLabel:IsA("TextLabel") then return nil end
    
    local rawText = cashLabel.Text
    local cleanStr = string.gsub(rawText, "[%$,%s]", "")
    
    local num, suffix = string.match(cleanStr, "(%d+%.?%d*)([kKmMbB]?)")
    if num then
        local val = tonumber(num)
        if not val then return nil end
        
        suffix = string.lower(suffix or "")
        if suffix == "k" then val = val * 1000
        elseif suffix == "m" then val = val * 1000000
        elseif suffix == "b" then val = val * 1000000000 end
        return val
    end
    return nil
end

-- Helper: Get Jobs Scroller
local function getJobsScroller()
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        local jobsPanel = playerGui:FindFirstChild("MafiaWarsUI")
            and playerGui.MafiaWarsUI:FindFirstChild("Root")
            and playerGui.MafiaWarsUI.Root:FindFirstChild("Content")
            and playerGui.MafiaWarsUI.Root.Content:FindFirstChild("JobsPanel")
        if jobsPanel and jobsPanel:FindFirstChild("Scroller") then
            return jobsPanel.Scroller
        end
    end
    return nil
end

-- ScreenGui Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MafiaWarsHub"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999999999
screenGui.Parent = parentContainer

-- Main Frame (Compact 240x300 Size)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 240, 0, 300)
mainFrame.Position = UDim2.new(0.5, -120, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Title Bar Container (Draggable Handle)
local titleFrame = Instance.new("Frame")
titleFrame.Name = "TitleFrame"
titleFrame.Size = UDim2.new(1, 0, 0, 28)
titleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
titleFrame.BorderSizePixel = 0
titleFrame.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleFrame

-- Title Text
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.Position = UDim2.new(0.05, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Idle Mafia Hub"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 12
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleFrame

-- Top Right Exit Button
local exitButton = Instance.new("TextButton")
exitButton.Name = "ExitButton"
exitButton.Size = UDim2.new(0, 20, 0, 20)
exitButton.Position = UDim2.new(1, -24, 0, 4)
exitButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
exitButton.Text = "X"
exitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
exitButton.TextSize = 11
exitButton.Font = Enum.Font.SourceSansBold
exitButton.Parent = titleFrame

local exitCorner = Instance.new("UICorner")
exitCorner.CornerRadius = UDim.new(0, 4)
exitCorner.Parent = exitButton

-- Live Cash Tracker Display
local liveCashLabel = Instance.new("TextLabel")
liveCashLabel.Name = "LiveCashTracker"
liveCashLabel.Size = UDim2.new(0.9, 0, 0, 22)
liveCashLabel.Position = UDim2.new(0.05, 0, 0, 34)
liveCashLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
liveCashLabel.Text = "Cash: Reading..."
liveCashLabel.TextColor3 = Color3.fromRGB(0, 255, 160)
liveCashLabel.TextSize = 11
liveCashLabel.Font = Enum.Font.SourceSansBold
liveCashLabel.Parent = mainFrame

local trackerCorner = Instance.new("UICorner")
trackerCorner.CornerRadius = UDim.new(0, 4)
trackerCorner.Parent = liveCashLabel

-- Keep Amount Box
local amountBox = Instance.new("TextBox")
amountBox.Name = "AmountBox"
amountBox.Size = UDim2.new(0.9, 0, 0, 22)
amountBox.Position = UDim2.new(0.05, 0, 0, 60)
amountBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
amountBox.PlaceholderText = "Keep Amount (e.g. 50000)"
amountBox.Text = "50000"
amountBox.TextColor3 = Color3.fromRGB(255, 255, 255)
amountBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
amountBox.TextSize = 11
amountBox.Font = Enum.Font.SourceSans
amountBox.Parent = mainFrame

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 4)
boxCorner.Parent = amountBox

-- Auto Deposit Button
local depositButton = Instance.new("TextButton")
depositButton.Name = "DepositButton"
depositButton.Size = UDim2.new(0.9, 0, 0, 24)
depositButton.Position = UDim2.new(0.05, 0, 0, 86)
depositButton.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
depositButton.Text = "Auto Deposit: OFF"
depositButton.TextColor3 = Color3.fromRGB(255, 255, 255)
depositButton.TextSize = 11
depositButton.Font = Enum.Font.SourceSansBold
depositButton.Parent = mainFrame

local btnCorner1 = Instance.new("UICorner")
btnCorner1.CornerRadius = UDim.new(0, 4)
btnCorner1.Parent = depositButton

-- Job Selector Title
local jobSelectTitle = Instance.new("TextLabel")
jobSelectTitle.Name = "JobSelectTitle"
jobSelectTitle.Size = UDim2.new(0.9, 0, 0, 14)
jobSelectTitle.Position = UDim2.new(0.05, 0, 0, 114)
jobSelectTitle.BackgroundTransparency = 1
jobSelectTitle.Text = "Selected Job: None"
jobSelectTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
jobSelectTitle.TextSize = 10
jobSelectTitle.Font = Enum.Font.SourceSansBold
jobSelectTitle.TextXAlignment = Enum.TextXAlignment.Left
jobSelectTitle.Parent = mainFrame

-- Job Scroll List
local jobScroller = Instance.new("ScrollingFrame")
jobScroller.Name = "JobScroller"
jobScroller.Size = UDim2.new(0.9, 0, 0, 65)
jobScroller.Position = UDim2.new(0.05, 0, 0, 130)
jobScroller.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
jobScroller.BorderSizePixel = 0
jobScroller.ScrollBarThickness = 4
jobScroller.CanvasSize = UDim2.new(0, 0, 0, 0)
jobScroller.Parent = mainFrame

local scrollerCorner = Instance.new("UICorner")
scrollerCorner.CornerRadius = UDim.new(0, 4)
scrollerCorner.Parent = jobScroller

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = jobScroller
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 3)

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    jobScroller.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 6)
end)

-- Auto Job Toggle Button
local jobButton = Instance.new("TextButton")
jobButton.Name = "JobButton"
jobButton.Size = UDim2.new(0.9, 0, 0, 24)
jobButton.Position = UDim2.new(0.05, 0, 0, 200)
jobButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
jobButton.Text = "Auto Job: OFF"
jobButton.TextColor3 = Color3.fromRGB(255, 255, 255)
jobButton.TextSize = 11
jobButton.Font = Enum.Font.SourceSansBold
jobButton.Parent = mainFrame

local jobBtnCorner = Instance.new("UICorner")
jobBtnCorner.CornerRadius = UDim.new(0, 4)
jobBtnCorner.Parent = jobButton

-- Debug Console Box
local debugBox = Instance.new("ScrollingFrame")
debugBox.Name = "DebugBox"
debugBox.Size = UDim2.new(0.9, 0, 0, 65)
debugBox.Position = UDim2.new(0.05, 0, 0, 228)
debugBox.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
debugBox.BorderSizePixel = 0
debugBox.ScrollBarThickness = 4
debugBox.CanvasSize = UDim2.new(0, 0, 0, 0)
debugBox.Parent = mainFrame

local debugCorner = Instance.new("UICorner")
debugCorner.CornerRadius = UDim.new(0, 4)
debugCorner.Parent = debugBox

local debugLayout = Instance.new("UIListLayout")
debugLayout.Parent = debugBox
debugLayout.SortOrder = Enum.SortOrder.LayoutOrder
debugLayout.Padding = UDim.new(0, 2)

debugLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    debugBox.CanvasSize = UDim2.new(0, 0, 0, debugLayout.AbsoluteContentSize.Y + 6)
    debugBox.CanvasPosition = Vector2.new(0, debugLayout.AbsoluteContentSize.Y)
end)

-- Non-blocking Logging
local function logDebug(msg)
    task.spawn(function()
        if not debugBox or not debugBox.Parent then return end
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -6, 0, 14)
        lbl.BackgroundTransparency = 1
        lbl.Text = "[" .. os.date("%X") .. "] " .. tostring(msg)
        lbl.TextColor3 = Color3.fromRGB(0, 255, 180)
        lbl.TextSize = 10
        lbl.Font = Enum.Font.Code
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = debugBox
    end)
end

logDebug("Hub Ready.")

-- DRAGGABLE LOGIC
local dragging, dragStart, startPos
titleFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position

        local conn
        conn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                if conn then conn:Disconnect() end
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- State Variables
local isRunning = true
local isAutoDeposit = false
local isAutoJob = false
local selectedJobName = nil
local selectedJobCardName = nil

-- Exit Handler
exitButton.MouseButton1Click:Connect(function()
    isRunning = false
    isAutoDeposit = false
    isAutoJob = false
    screenGui:Destroy()
end)

-- Toggles
depositButton.MouseButton1Click:Connect(function()
    isAutoDeposit = not isAutoDeposit
    if isAutoDeposit then
        depositButton.Text = "Auto Deposit: ON"
        depositButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        logDebug("Deposit ON")
    else
        depositButton.Text = "Auto Deposit: OFF"
        depositButton.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
        logDebug("Deposit OFF")
    end
end)

jobButton.MouseButton1Click:Connect(function()
    isAutoJob = not isAutoJob
    if isAutoJob then
        jobButton.Text = "Auto Job: ON"
        jobButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        logDebug("Auto Job ON")
    else
        jobButton.Text = "Auto Job: OFF"
        jobButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        logDebug("Auto Job OFF")
    end
end)

-- Job Discovery Refresh
local knownJobs = {}
local function refreshJobScrollList()
    local gameScroller = getJobsScroller()
    if not gameScroller then return end
    
    for _, child in ipairs(gameScroller:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "JobCardTemplate" then
            local jobLabel = child:FindFirstChild("JobName", true) or child:FindFirstChild("Title", true)
            if jobLabel and jobLabel:IsA("TextLabel") and jobLabel.Text ~= "" then
                local jobTitle = jobLabel.Text
                local cardName = child.Name
                
                if not knownJobs[jobTitle] then
                    knownJobs[jobTitle] = cardName
                    
                    local btn = Instance.new("TextButton")
                    btn.Size = UDim2.new(1, -4, 0, 20)
                    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
                    btn.Text = jobTitle
                    btn.TextColor3 = Color3.fromRGB(230, 230, 230)
                    btn.TextSize = 10
                    btn.Font = Enum.Font.SourceSans
                    btn.Parent = jobScroller
                    
                    local btnC = Instance.new("UICorner")
                    btnC.CornerRadius = UDim.new(0, 3)
                    btnC.Parent = btn
                    
                    btn.MouseButton1Click:Connect(function()
                        selectedJobName = jobTitle
                        selectedJobCardName = cardName
                        jobSelectTitle.Text = "Selected: " .. jobTitle
                        logDebug("Selected: " .. jobTitle)
                        
                        for _, childBtn in ipairs(jobScroller:GetChildren()) do
                            if childBtn:IsA("TextButton") then 
                                childBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 42) 
                            end
                        end
                        btn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
                    end)
                end
            end
        end
    end
end

-- Asynchronous Non-blocking Core Loop
task.spawn(function()
    while isRunning do
        task.wait(1)
        if not isRunning then break end
        
        -- Non-blocking Cash & Deposit
        task.spawn(function()
            local currentCash = getLiveCashValue()
            if currentCash then
                liveCashLabel.Text = "Cash: $" .. tostring(currentCash)
            else
                liveCashLabel.Text = "Cash: Reading..."
            end
            
            if isAutoDeposit and depositRemote then
                local keepAmount = tonumber(amountBox.Text)
                if keepAmount and keepAmount >= 0 and currentCash and currentCash > keepAmount then
                    local depositAmount = currentCash - keepAmount
                    if depositAmount > 0 then
                        pcall(function()
                            if depositRemote:IsA("RemoteFunction") then
                                depositRemote:InvokeServer(depositAmount)
                            elseif depositRemote:IsA("RemoteEvent") then
                                depositRemote:FireServer(depositAmount)
                            end
                        end)
                        logDebug("Deposited $" .. tostring(depositAmount))
                    end
                end
            end
        end)

        -- Non-blocking Auto Job
        task.spawn(function()
            refreshJobScrollList()
            if isAutoJob then
                if not selectedJobName then
                    logDebug("WARN: Select a job!")
                elseif not doJobRemote then
                    logDebug("ERROR: Remote missing!")
                else
                    local rawJobId = string.gsub(selectedJobCardName or "", "^Card_", "")
                    local success, result = pcall(function()
                        if doJobRemote:IsA("RemoteFunction") then
                            return doJobRemote:InvokeServer(rawJobId)
                        elseif doJobRemote:IsA("RemoteEvent") then
                            doJobRemote:FireServer(rawJobId)
                            return "Fired Event"
                        end
                    end)
                    if success then
                        logDebug("Done (" .. rawJobId .. "): " .. tostring(result))
                    else
                        logDebug("Failed Job (" .. rawJobId .. ")")
                    end
                end
            end
        end)
    end
end)

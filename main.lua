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

-- Main Frame (Dynamic Resizable Base Container)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 360, 0, 580) -- Change this Size anytime; all children scale automatically!
mainFrame.Position = UDim2.new(0.5, -180, 0.5, -290)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.02, 0)
corner.Parent = mainFrame

-- Dynamic UI Scale Component to handle proportional font & size scaling
local uiScale = Instance.new("UIScale")
uiScale.Parent = mainFrame

-- Title Bar Container
local titleFrame = Instance.new("Frame")
titleFrame.Name = "TitleFrame"
titleFrame.Size = UDim2.new(1, 0, 0.08, 0)
titleFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
titleFrame.BorderSizePixel = 0
titleFrame.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0.2, 0)
titleCorner.Parent = titleFrame

-- Title Text
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(0.8, 0, 1, 0)
titleLabel.Position = UDim2.new(0.04, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Idle Mafia V1"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Scaled = true
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleFrame

local titleConstraint = Instance.new("UITextSizeConstraint")
titleConstraint.MaxTextSize = 22
titleConstraint.MinTextSize = 10
titleConstraint.Parent = titleLabel

-- Top Right Exit / Kill Button
local exitButton = Instance.new("TextButton")
exitButton.Name = "ExitButton"
exitButton.Size = UDim2.new(0.1, 0, 0.7, 0)
exitButton.Position = UDim2.new(0.88, 0, 0.15, 0)
exitButton.BackgroundColor3 = Color3.fromRGB(210, 45, 45)
exitButton.Text = "X"
exitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
exitButton.TextScaled = true
exitButton.Font = Enum.Font.SourceSansBold
exitButton.Parent = titleFrame

local exitCorner = Instance.new("UICorner")
exitCorner.CornerRadius = UDim.new(0.2, 0)
exitCorner.Parent = exitButton

-- Live Cash Tracker Display
local liveCashLabel = Instance.new("TextLabel")
liveCashLabel.Name = "LiveCashTracker"
liveCashLabel.Size = UDim2.new(0.92, 0, 0.07, 0)
liveCashLabel.Position = UDim2.new(0.04, 0, 0.10, 0)
liveCashLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
liveCashLabel.Text = "Cash on Hand: Reading..."
liveCashLabel.TextColor3 = Color3.fromRGB(0, 255, 160)
liveCashLabel.TextScaled = true
liveCashLabel.Font = Enum.Font.SourceSansBold
liveCashLabel.Parent = mainFrame

local trackerCorner = Instance.new("UICorner")
trackerCorner.CornerRadius = UDim.new(0.15, 0)
trackerCorner.Parent = liveCashLabel

-- Keep Amount Box
local amountBox = Instance.new("TextBox")
amountBox.Name = "AmountBox"
amountBox.Size = UDim2.new(0.92, 0, 0.07, 0)
amountBox.Position = UDim2.new(0.04, 0, 0.18, 0)
amountBox.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
amountBox.PlaceholderText = "Keep Amount (e.g. 50000)"
amountBox.Text = "50000"
amountBox.TextColor3 = Color3.fromRGB(255, 255, 255)
amountBox.PlaceholderColor3 = Color3.fromRGB(160, 160, 160)
amountBox.TextScaled = true
amountBox.Font = Enum.Font.SourceSans
amountBox.Parent = mainFrame

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0.15, 0)
boxCorner.Parent = amountBox

-- Auto Deposit Button
local depositButton = Instance.new("TextButton")
depositButton.Name = "DepositButton"
depositButton.Size = UDim2.new(0.92, 0, 0.07, 0)
depositButton.Position = UDim2.new(0.04, 0, 0.26, 0)
depositButton.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
depositButton.Text = "Start Auto Deposit (Keep Amount)"
depositButton.TextColor3 = Color3.fromRGB(255, 255, 255)
depositButton.TextScaled = true
depositButton.Font = Enum.Font.SourceSansBold
depositButton.Parent = mainFrame

local btnCorner1 = Instance.new("UICorner")
btnCorner1.CornerRadius = UDim.new(0.15, 0)
btnCorner1.Parent = depositButton

-- Job Selector Header Label
local jobSelectTitle = Instance.new("TextLabel")
jobSelectTitle.Name = "JobSelectTitle"
jobSelectTitle.Size = UDim2.new(0.92, 0, 0.04, 0)
jobSelectTitle.Position = UDim2.new(0.04, 0, 0.35, 0)
jobSelectTitle.BackgroundTransparency = 1
jobSelectTitle.Text = "Selected Job: None"
jobSelectTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
jobSelectTitle.TextScaled = true
jobSelectTitle.Font = Enum.Font.SourceSansBold
jobSelectTitle.TextXAlignment = Enum.TextXAlignment.Left
jobSelectTitle.Parent = mainFrame

-- Job ScrollList
local jobScroller = Instance.new("ScrollingFrame")
jobScroller.Name = "JobScroller"
jobScroller.Size = UDim2.new(0.92, 0, 0.22, 0)
jobScroller.Position = UDim2.new(0.04, 0, 0.40, 0)
jobScroller.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
jobScroller.BorderSizePixel = 0
jobScroller.ScrollBarThickness = 6
jobScroller.CanvasSize = UDim2.new(0, 0, 0, 0)
jobScroller.Parent = mainFrame

local scrollerCorner = Instance.new("UICorner")
scrollerCorner.CornerRadius = UDim.new(0.05, 0)
scrollerCorner.Parent = jobScroller

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = jobScroller
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 5)

-- Auto Job Toggle Button
local jobButton = Instance.new("TextButton")
jobButton.Name = "JobButton"
jobButton.Size = UDim2.new(0.92, 0, 0.07, 0)
jobButton.Position = UDim2.new(0.04, 0, 0.64, 0)
jobButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
jobButton.Text = "Start Auto Job"
jobButton.TextColor3 = Color3.fromRGB(255, 255, 255)
jobButton.TextScaled = true
jobButton.Font = Enum.Font.SourceSansBold
jobButton.Parent = mainFrame

local jobBtnCorner = Instance.new("UICorner")
jobBtnCorner.CornerRadius = UDim.new(0.15, 0)
jobBtnCorner.Parent = jobButton

-- Debug Console Box
local debugBox = Instance.new("ScrollingFrame")
debugBox.Name = "DebugBox"
debugBox.Size = UDim2.new(0.92, 0, 0.22, 0)
debugBox.Position = UDim2.new(0.04, 0, 0.73, 0)
debugBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
debugBox.BorderSizePixel = 0
debugBox.ScrollBarThickness = 6
debugBox.CanvasSize = UDim2.new(0, 0, 0, 0)
debugBox.Parent = mainFrame

local debugCorner = Instance.new("UICorner")
debugCorner.CornerRadius = UDim.new(0.05, 0)
debugCorner.Parent = debugBox

local debugLayout = Instance.new("UIListLayout")
debugLayout.Parent = debugBox
debugLayout.SortOrder = Enum.SortOrder.LayoutOrder
debugLayout.Padding = UDim.new(0, 3)

-- Function to print debug log
local function logDebug(msg)
    if not debugBox or not debugBox.Parent then return end
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -8, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Text = "[" .. os.date("%X") .. "] " .. tostring(msg)
    lbl.TextColor3 = Color3.fromRGB(0, 255, 180)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.Code
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = debugBox
    
    debugBox.CanvasSize = UDim2.new(0, 0, 0, debugLayout.AbsoluteContentSize.Y + 10)
    debugBox.CanvasPosition = Vector2.new(0, debugLayout.AbsoluteContentSize.Y)
end

logDebug("Automation Hub loaded.")

-- Draggable Logic
local dragging, dragInput, dragStart, startPos
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
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

-- Kill / Exit Script Logic
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
        logDebug("Auto Deposit turned ON")
    else
        depositButton.Text = "Start Auto Deposit (Keep Amount)"
        depositButton.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
        logDebug("Auto Deposit turned OFF")
    end
end)

jobButton.MouseButton1Click:Connect(function()
    isAutoJob = not isAutoJob
    if isAutoJob then
        jobButton.Text = "Auto Job: ON"
        jobButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        logDebug("Auto Job turned ON")
    else
        jobButton.Text = "Start Auto Job"
        jobButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        logDebug("Auto Job turned OFF")
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
                    btn.Size = UDim2.new(1, -8, 0, 28)
                    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
                    btn.Text = jobTitle
                    btn.TextColor3 = Color3.fromRGB(240, 240, 240)
                    btn.TextSize = 14
                    btn.Font = Enum.Font.SourceSans
                    btn.Parent = jobScroller
                    
                    local btnC = Instance.new("UICorner")
                    btnC.CornerRadius = UDim.new(0, 4)
                    btnC.Parent = btn
                    
                    btn.MouseButton1Click:Connect(function()
                        selectedJobName = jobTitle
                        selectedJobCardName = cardName
                        jobSelectTitle.Text = "Selected: " .. jobTitle
                        logDebug("Selected: " .. jobTitle)
                        
                        for _, childBtn in ipairs(jobScroller:GetChildren()) do
                            if childBtn:IsA("TextButton") then childBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50) end
                        end
                        btn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
                    end)
                end
            end
        end
    end
    jobScroller.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
end

-- Main Loop (Executes Auto Job & Keep-Deposit every 1 second)
task.spawn(function()
    while isRunning do
        task.wait(1)
        if not isRunning then break end
        
        -- 1. Live Cash Display Update
        local currentCash = getLiveCashValue()
        if currentCash then
            liveCashLabel.Text = "Cash on Hand: $" .. tostring(currentCash)
        else
            liveCashLabel.Text = "Cash on Hand: Reading..."
        end
        
        -- 2. Keep Amount Auto Deposit Logic
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
                    logDebug("Deposited $" .. tostring(depositAmount) .. " (Kept $" .. tostring(keepAmount) .. ")")
                end
            end
        end

        -- 3. Auto Job Logic
        refreshJobScrollList()
        if isAutoJob then
            if not selectedJobName then
                logDebug("WARN: Select a job from the list!")
            elseif not doJobRemote then
                logDebug("ERROR: Remotes.DoJob missing!")
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
                    logDebug("Job (" .. rawJobId .. "): " .. tostring(result))
                else
                    logDebug("Failed Job (" .. rawJobId .. ")")
                end
            end
        end
    end
end)

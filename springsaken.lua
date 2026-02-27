-- springsaken.lua
-- Made by mentallyinsane_idiot on Discord
-- Built for: Roblox Forsaken — Entanglement & Mass Infection Auto-Aim

local Rayfield         = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

-- =====================
--      WINDOW
-- =====================

local Window = Rayfield:CreateWindow({
   Name = "springsaken",
   LoadingTitle = "springsaken",
   LoadingSubtitle = "by mentallyinsane_idiot | Forsaken",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "springsaken",
      FileName = "springsaken-forsaken"
   },
   Discord = { Enabled = false },
   KeySystem = false,
})

-- =====================
--       TABS
-- =====================

local KillerTab = Window:CreateTab("Killer", 4483362458)
local MiscTab   = Window:CreateTab("Misc",   4483362458)

-- =====================
--      CONFIG
-- =====================

local Config = {
   EntanglementEnabled   = true,
   EntanglementDuration  = 0.9,
   EntanglementCooldown  = 16,

   MassInfectionEnabled  = true,
   MassInfectionDuration = 1.9,
   MassInfectionCooldown = 14,

   BasePrediction = 2.5,
   BaseDistance   = 10,
   AimSmoothing   = 0.18,
   AimMode        = "Camera", -- "Camera" or "HRP"
}

-- =====================
--      KILLER UI
-- =====================

KillerTab:CreateSection("Entanglement  [E]")

KillerTab:CreateToggle({
   Name = "Enable Entanglement Auto-Aim",
   CurrentValue = true,
   Flag = "EntanglementEnabled",
   Callback = function(val) Config.EntanglementEnabled = val end,
})

KillerTab:CreateSlider({
   Name = "Entanglement Aim Duration",
   Range = {0.1, 5},
   Increment = 0.1,
   CurrentValue = 0.9,
   Flag = "EntanglementDuration",
   Callback = function(val) Config.EntanglementDuration = val end,
})

KillerTab:CreateSection("Mass Infection  [Q]")

KillerTab:CreateToggle({
   Name = "Enable Mass Infection Auto-Aim",
   CurrentValue = true,
   Flag = "MassInfectionEnabled",
   Callback = function(val) Config.MassInfectionEnabled = val end,
})

KillerTab:CreateSlider({
   Name = "Mass Infection Aim Duration",
   Range = {0.1, 5},
   Increment = 0.1,
   CurrentValue = 1.9,
   Flag = "MassInfectionDuration",
   Callback = function(val) Config.MassInfectionDuration = val end,
})

KillerTab:CreateSection("Shared Settings")

KillerTab:CreateSlider({
   Name = "Base Velocity Prediction",
   Range = {0, 10},
   Increment = 0.1,
   CurrentValue = 2.5,
   Flag = "BasePrediction",
   Callback = function(val) Config.BasePrediction = val end,
})

KillerTab:CreateSlider({
   Name = "Base Distance (studs)",
   Range = {1, 50},
   Increment = 1,
   CurrentValue = 10,
   Flag = "BaseDistance",
   Callback = function(val) Config.BaseDistance = val end,
})

KillerTab:CreateSlider({
   Name = "Aim Smoothing",
   Range = {0.01, 1},
   Increment = 0.01,
   CurrentValue = 0.18,
   Flag = "AimSmoothing",
   Callback = function(val) Config.AimSmoothing = val end,
})

-- =====================
--       MISC UI
-- =====================

MiscTab:CreateSection("Aim Mode")

MiscTab:CreateDropdown({
   Name = "Aim Target",
   Options = {"Camera", "HRP"},
   CurrentOption = {"Camera"},
   Flag = "AimMode",
   Callback = function(val)
      Config.AimMode = type(val) == "table" and val[1] or val
      Rayfield:Notify({
         Title = "Aim Mode",
         Content = "Set to: " .. Config.AimMode,
         Duration = 2,
         Image = 4483362458,
      })
   end,
})

MiscTab:CreateSection("Utility")

MiscTab:CreateButton({
   Name = "Rejoin",
   Callback = function()
      game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
   end,
})

MiscTab:CreateSection("Info")
MiscTab:CreateLabel("springsaken | by mentallyinsane_idiot")
MiscTab:CreateLabel("Forsaken — Entanglement [E] & Mass Infection [Q]")

-- =====================
--     CORE STATE
-- =====================

local aimActive     = false
local aimEndTime    = 0
local currentTarget = nil  -- cached HumanoidRootPart

-- Velocity tracking: only store the ONE active target's prev position
local targetPrevPos  = nil
local targetPrevTime = 0

-- Per-ability cooldown timestamps
local cooldowns = {
   Entanglement  = 0,
   MassInfection = 0,
}

-- Cache of player characters for fast NPC exclusion (avoids per-frame GetPlayers())
local playerChars = {}
Players.PlayerAdded:Connect(function(p)
   p.CharacterAdded:Connect(function(c) playerChars[c] = true end)
   p.CharacterRemoving:Connect(function(c) playerChars[c] = nil end)
   if p.Character then playerChars[p.Character] = true end
end)
Players.PlayerRemoving:Connect(function(p)
   if p.Character then playerChars[p.Character] = nil end
end)
for _, p in ipairs(Players:GetPlayers()) do
   if p.Character then playerChars[p.Character] = true end
end

-- =====================
--   VELOCITY TRACKING
--   (Heartbeat — only runs when aiming)
-- =====================

local heartbeatConn = nil

local function startTracking(hrp)
   targetPrevPos  = hrp.Position
   targetPrevTime = tick()
   if heartbeatConn then heartbeatConn:Disconnect() end
   heartbeatConn = RunService.Heartbeat:Connect(function()
      if not aimActive or not hrp or not hrp.Parent then
         heartbeatConn:Disconnect()
         heartbeatConn  = nil
         targetPrevPos  = nil
         return
      end
      targetPrevPos  = hrp.Position
      targetPrevTime = tick()
   end)
end

local function getVelocity(hrp)
   if targetPrevPos then
      local dt = tick() - targetPrevTime
      if dt > 0 then
         return (hrp.Position - targetPrevPos) / dt
      end
   end
   local ok, vel = pcall(function() return hrp.AssemblyLinearVelocity end)
   return ok and vel or Vector3.zero
end

-- =====================
--   NEAREST TARGET
--   (called once per trigger, not every frame)
-- =====================

local function getNearestTarget()
   local myChar = LocalPlayer.Character
   if not myChar then return nil, 0 end
   local myHRP = myChar:FindFirstChild("HumanoidRootPart")
   if not myHRP then return nil, 0 end
   local myPos = myHRP.Position

   local closestHRP, closestDist = nil, math.huge

   -- Players
   for _, p in ipairs(Players:GetPlayers()) do
      if p ~= LocalPlayer then
         local char = p.Character
         if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
               local d = (myPos - hrp.Position).Magnitude
               if d < closestDist then
                  closestDist = d
                  closestHRP  = hrp
               end
            end
         end
      end
   end

   -- NPCs: iterate workspace children only (not full descendants — much faster)
   for _, obj in ipairs(workspace:GetChildren()) do
      if obj:IsA("Model") and not playerChars[obj] then
         local hrp = obj:FindFirstChild("HumanoidRootPart")
         local hum = obj:FindFirstChildOfClass("Humanoid")
         if hrp and hum and hum.Health > 0 then
            local d = (myPos - hrp.Position).Magnitude
            if d < closestDist then
               closestDist = d
               closestHRP  = hrp
            end
         end
      end
   end

   return closestHRP, closestDist
end

-- =====================
--   AIM LOOP
--   PreRender = runs right before each frame is drawn
--   (tightest possible timing for camera control)
-- =====================

local lastCF       = nil
local baseDistSafe = 0.001 -- avoids repeated math.max calls in hot loop

RunService.PreRender:Connect(function(dt)
   if not aimActive then
      if lastCF then lastCF = nil end
      return
   end

   local now = tick()

   -- Expire check
   if now > aimEndTime then
      aimActive     = false
      currentTarget = nil
      lastCF        = nil
      return
   end

   local target = currentTarget
   if not target or not target.Parent then
      aimActive     = false
      currentTarget = nil
      lastCF        = nil
      return
   end

   local myChar = LocalPlayer.Character
   if not myChar then return end
   local myHRP = myChar:FindFirstChild("HumanoidRootPart")
   if not myHRP then return end

   -- Velocity prediction scaled by distance
   local tPos     = target.Position
   local dist     = (myHRP.Position - tPos).Magnitude
   local predMult = Config.BasePrediction * (dist / (Config.BaseDistance + baseDistSafe))
   local vel      = getVelocity(target)
   local predicted = tPos + vel * predMult

   local smoothing = Config.AimSmoothing

   if Config.AimMode == "Camera" then
      local camPos = Camera.CFrame.Position
      local dir    = predicted - camPos
      if dir.Magnitude < 0.001 then return end
      local targetCF = CFrame.lookAt(camPos, camPos + dir.Unit)
      local newCF    = lastCF and lastCF:Lerp(targetCF, smoothing) or targetCF
      Camera.CFrame  = newCF
      lastCF         = newCF

   elseif Config.AimMode == "HRP" then
      local origin = myHRP.Position
      local dir    = Vector3.new(predicted.X - origin.X, 0, predicted.Z - origin.Z)
      if dir.Magnitude < 0.001 then return end
      local targetCF  = CFrame.lookAt(origin, origin + dir.Unit)
      myHRP.CFrame    = myHRP.CFrame:Lerp(targetCF, smoothing)
      lastCF          = nil -- not needed for HRP mode
   end
end)

-- =====================
--   TRIGGER FUNCTION
-- =====================

local function triggerAim(abilityName, duration, cooldown, enabled)
   if not enabled then return end

   local now     = tick()
   local elapsed = now - cooldowns[abilityName]
   if elapsed < cooldown then
      Rayfield:Notify({
         Title = abilityName .. " on Cooldown",
         Content = string.format("Ready in %.0fs.", cooldown - elapsed),
         Duration = 2,
         Image = 4483362458,
      })
      return
   end
   cooldowns[abilityName] = now

   local target, dist = getNearestTarget()
   if not target then return end

   currentTarget = target
   aimActive     = true
   aimEndTime    = now + duration
   lastCF        = nil

   startTracking(target)

   local pred = Config.BasePrediction * (dist / (Config.BaseDistance + baseDistSafe))
   Rayfield:Notify({
      Title = abilityName .. " Locked!",
      Content = string.format("%.0f studs | Pred: %.2fx | %s", dist, pred, Config.AimMode),
      Duration = 2,
      Image = 4483362458,
   })
end

-- =====================
--   KEY DETECTION
-- =====================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
   if gameProcessed then return end
   if input.KeyCode == Enum.KeyCode.E then
      triggerAim("Entanglement",  Config.EntanglementDuration,  Config.EntanglementCooldown,  Config.EntanglementEnabled)
   elseif input.KeyCode == Enum.KeyCode.Q then
      triggerAim("MassInfection", Config.MassInfectionDuration, Config.MassInfectionCooldown, Config.MassInfectionEnabled)
   end
end)

-- =====================
--   GUI BUTTON DETECTION
-- =====================

local hookedButtons = {} -- prevent double-hooking same button

local function identifyAbility(obj)
   local function check(o)
      local name = o.Name:lower()
      if name:find("entanglement") then return "Entanglement" end
      if name:find("mass.?infection") then return "MassInfection" end
      if o:IsA("TextLabel") or o:IsA("TextButton") then
         local t = o.Text:lower()
         if t:find("entanglement") then return "Entanglement" end
         if t:find("mass.?infection") then return "MassInfection" end
      end
   end

   local found = check(obj)
   if found then return found end
   for _, child in ipairs(obj:GetDescendants()) do
      found = check(child)
      if found then return found end
   end
end

local function hookButton(obj)
   if hookedButtons[obj] then return end
   if not (obj:IsA("TextButton") or obj:IsA("ImageButton")) then return end
   hookedButtons[obj] = true

   obj.MouseButton1Click:Connect(function()
      local ability = identifyAbility(obj)
      if ability == "Entanglement" then
         triggerAim("Entanglement",  Config.EntanglementDuration,  Config.EntanglementCooldown,  Config.EntanglementEnabled)
      elseif ability == "MassInfection" then
         triggerAim("MassInfection", Config.MassInfectionDuration, Config.MassInfectionCooldown, Config.MassInfectionEnabled)
      end
   end)

   -- Clean up hook reference when button is destroyed
   obj.Destroying:Connect(function() hookedButtons[obj] = nil end)
end

local function hookGui(gui)
   for _, obj in ipairs(gui:GetDescendants()) do
      hookButton(obj)
   end
   gui.DescendantAdded:Connect(function(obj)
      task.wait()
      hookButton(obj)
   end)
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

for _, gui in ipairs(PlayerGui:GetChildren()) do
   if gui:IsA("ScreenGui") then hookGui(gui) end
end

PlayerGui.ChildAdded:Connect(function(child)
   if child:IsA("ScreenGui") then
      task.wait(0.1)
      hookGui(child)
   end
end)

-- =====================
--   WELCOME NOTIFY
-- =====================

Rayfield:Notify({
   Title = "springsaken loaded!",
   Content = "Hey " .. LocalPlayer.Name .. "!  E = Entanglement  |  Q = Mass Infection",
   Duration = 5,
   Image = 4483362458,
})

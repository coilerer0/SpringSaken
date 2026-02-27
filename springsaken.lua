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

local KillerTab  = Window:CreateTab("Killer",   4483362458)
local AimTab     = Window:CreateTab("Aim",       4483362458)
local MiscTab    = Window:CreateTab("Misc",      4483362458)

-- =====================
--      CONFIG
-- =====================

local Config = {
   -- Entanglement [E]
   EntanglementEnabled   = true,
   EntanglementDuration  = 0.9,
   EntanglementCooldown  = 16,

   -- Mass Infection [Q]
   MassInfectionEnabled  = true,
   MassInfectionDuration = 1.9,
   MassInfectionCooldown = 14,

   -- Aim core
   AimMode        = "Camera",   -- "Camera" | "HRP"
   AimSmoothing   = 0.18,       -- lerp factor per frame (0.01 = very smooth, 1 = instant)
   AimInstant     = false,      -- bypass smoothing entirely

   -- Prediction
   BasePrediction    = 1.0,     -- base prediction strength
   BaseDistance      = 10,      -- reference distance for prediction scaling
   PredictionEnabled = true,    -- toggle velocity prediction on/off
   PredictionCap     = 5,       -- max prediction multiplier (hard ceiling)

   -- Target filtering
   MaxTargetDistance = 200,     -- ignore targets further than this (studs, 0 = unlimited)
   TargetBodyPart    = "HRP",   -- "HRP" | "Head" — which part to aim at

   -- HRP-only: vertical aim offset
   VerticalOffset = 0,          -- studs up/down from target part (e.g. 2 = aim at chest)
}

-- =====================
--      KILLER UI
-- =====================

KillerTab:CreateSection("Entanglement  [E]")

KillerTab:CreateToggle({
   Name = "Enable Auto-Aim",
   CurrentValue = true,
   Flag = "EntanglementEnabled",
   Callback = function(val) Config.EntanglementEnabled = val end,
})

KillerTab:CreateSlider({
   Name = "Aim Duration (s)",
   Range = {0.1, 5},
   Increment = 0.1,
   CurrentValue = 0.9,
   Flag = "EntanglementDuration",
   Callback = function(val) Config.EntanglementDuration = val end,
})

KillerTab:CreateSection("Mass Infection  [Q]")

KillerTab:CreateToggle({
   Name = "Enable Auto-Aim",
   CurrentValue = true,
   Flag = "MassInfectionEnabled",
   Callback = function(val) Config.MassInfectionEnabled = val end,
})

KillerTab:CreateSlider({
   Name = "Aim Duration (s)",
   Range = {0.1, 5},
   Increment = 0.1,
   CurrentValue = 1.9,
   Flag = "MassInfectionDuration",
   Callback = function(val) Config.MassInfectionDuration = val end,
})

-- =====================
--      AIM TAB UI
-- =====================

AimTab:CreateSection("Mode")

AimTab:CreateDropdown({
   Name = "Aim Mode",
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

AimTab:CreateDropdown({
   Name = "Target Body Part",
   Options = {"HRP", "Head"},
   CurrentOption = {"HRP"},
   Flag = "TargetBodyPart",
   Callback = function(val)
      Config.TargetBodyPart = type(val) == "table" and val[1] or val
   end,
})

AimTab:CreateSection("Smoothing")

AimTab:CreateToggle({
   Name = "Instant Aim (no smoothing)",
   CurrentValue = false,
   Flag = "AimInstant",
   Callback = function(val) Config.AimInstant = val end,
})

AimTab:CreateSlider({
   Name = "Aim Smoothing",
   Range = {0.01, 1},
   Increment = 0.01,
   CurrentValue = 0.18,
   Flag = "AimSmoothing",
   Callback = function(val) Config.AimSmoothing = val end,
})

AimTab:CreateSection("Prediction")

AimTab:CreateToggle({
   Name = "Velocity Prediction",
   CurrentValue = true,
   Flag = "PredictionEnabled",
   Callback = function(val) Config.PredictionEnabled = val end,
})

AimTab:CreateSlider({
   Name = "Base Prediction Multiplier",
   Range = {0, 10},
   Increment = 0.1,
   CurrentValue = 1.0,
   Flag = "BasePrediction",
   Callback = function(val) Config.BasePrediction = val end,
})

AimTab:CreateSlider({
   Name = "Base Distance (studs)",
   Range = {1, 100},
   Increment = 1,
   CurrentValue = 10,
   Flag = "BaseDistance",
   Callback = function(val) Config.BaseDistance = val end,
})

AimTab:CreateSlider({
   Name = "Prediction Cap (max multiplier)",
   Range = {1, 50},
   Increment = 0.5,
   CurrentValue = 5,
   Flag = "PredictionCap",
   Callback = function(val) Config.PredictionCap = val end,
})

AimTab:CreateSection("Targeting")

AimTab:CreateSlider({
   Name = "Max Target Distance (studs)",
   Range = {0, 500},
   Increment = 5,
   CurrentValue = 200,
   Flag = "MaxTargetDistance",
   Callback = function(val) Config.MaxTargetDistance = val end,
})

AimTab:CreateSlider({
   Name = "Vertical Aim Offset",
   Range = {-5, 5},
   Increment = 0.1,
   CurrentValue = 0,
   Flag = "VerticalOffset",
   Callback = function(val) Config.VerticalOffset = val end,
})

-- =====================
--       MISC UI
-- =====================

MiscTab:CreateSection("Utility")

MiscTab:CreateButton({
   Name = "Recommended Settings",
   Callback = function()
      -- Apply recommended settings
      Config.AimMode        = "HRP"
      Config.PredictionCap  = 5
      Config.BasePrediction = 1.0
      Config.AimSmoothing   = 0.18
      Config.AimInstant     = false
      Config.PredictionEnabled = true
      Rayfield:SaveConfiguration()
      Rayfield:Notify({
         Title = "Recommended Settings Applied",
         Content = "Aim: HRP | Pred Cap: 5 | Base Pred: 1.0",
         Duration = 3,
         Image = 4483362458,
      })
   end,
})

MiscTab:CreateButton({
   Name = "Reset Cooldowns",
   Callback = function()
      cooldowns.Entanglement  = 0
      cooldowns.MassInfection = 0
      Rayfield:Notify({
         Title = "Cooldowns Reset",
         Content = "Both abilities are ready.",
         Duration = 2,
         Image = 4483362458,
      })
   end,
})

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
local currentTarget = nil

local targetPrevPos  = nil
local targetPrevTime = 0

local cooldowns = {
   Entanglement  = 0,
   MassInfection = 0,
}

-- Player character cache (avoids GetPlayers() in hot paths)
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
-- =====================

local heartbeatConn = nil

local function startTracking(hrp)
   targetPrevPos  = hrp.Position
   targetPrevTime = tick()
   if heartbeatConn then heartbeatConn:Disconnect() end
   heartbeatConn = RunService.Heartbeat:Connect(function()
      if not aimActive or not hrp or not hrp.Parent then
         heartbeatConn:Disconnect()
         heartbeatConn = nil
         targetPrevPos = nil
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
--   TARGET PART RESOLVE
-- =====================

local function getTargetPosition(hrp)
   local part = hrp
   if Config.TargetBodyPart == "Head" then
      local head = hrp.Parent and hrp.Parent:FindFirstChild("Head")
      if head then part = head end
   end
   return part.Position + Vector3.new(0, Config.VerticalOffset, 0)
end

-- =====================
--   NEAREST TARGET
-- =====================

local function getNearestTarget()
   local myChar = LocalPlayer.Character
   if not myChar then return nil, 0 end
   local myHRP = myChar:FindFirstChild("HumanoidRootPart")
   if not myHRP then return nil, 0 end
   local myPos = myHRP.Position
   local maxD  = Config.MaxTargetDistance > 0 and Config.MaxTargetDistance or math.huge

   local closestHRP, closestDist = nil, maxD

   -- Track player HRPs to skip them during NPC scan
   local playerHRPs = {}

   -- Scan players
   for _, p in ipairs(Players:GetPlayers()) do
      if p ~= LocalPlayer then
         local char = p.Character
         if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
               playerHRPs[hrp] = true
               local d = (myPos - hrp.Position).Magnitude
               if d < closestDist then
                  closestDist = d
                  closestHRP  = hrp
               end
            end
         end
      end
   end

   -- Scan ALL humanoids in workspace (catches NPCs inside folders/nested models)
   for _, hum in ipairs(workspace:GetDescendants()) do
      if hum:IsA("Humanoid") and hum.Health > 0 then
         local char = hum.Parent
         if char and char ~= myChar then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and not playerHRPs[hrp] then
               local d = (myPos - hrp.Position).Magnitude
               if d < closestDist then
                  closestDist = d
                  closestHRP  = hrp
               end
            end
         end
      end
   end

   return closestHRP, closestDist
end

-- =====================
--   AIM LOOP (PreRender)
-- =====================

local lastCF = nil

RunService.PreRender:Connect(function()
   if not aimActive then
      lastCF = nil
      return
   end

   local now = tick()
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

   -- Resolve aim point with body part + vertical offset
   local aimPos = getTargetPosition(target)

   -- Velocity prediction
   if Config.PredictionEnabled then
      local dist     = (myHRP.Position - target.Position).Magnitude
      -- Square root scaling: grows slowly with distance, stays gentle at range
      local rawMult  = Config.BasePrediction * math.sqrt(dist / math.max(Config.BaseDistance, 0.001))
      local predMult = math.min(rawMult, Config.PredictionCap)
      local vel      = getVelocity(target)
      aimPos         = aimPos + vel * predMult
   end

   local smoothing = Config.AimInstant and 1 or Config.AimSmoothing

   if Config.AimMode == "Camera" then
      local camPos = Camera.CFrame.Position
      -- XZ only: flatten both positions to the same Y before computing direction
      local dir = Vector3.new(aimPos.X - camPos.X, 0, aimPos.Z - camPos.Z)
      if dir.Magnitude < 0.001 then return end
      local targetCF = CFrame.lookAt(camPos, camPos + dir.Unit)
      local newCF    = lastCF and lastCF:Lerp(targetCF, smoothing) or targetCF
      Camera.CFrame  = newCF
      lastCF         = newCF

   elseif Config.AimMode == "HRP" then
      local origin = myHRP.Position
      local dir    = Vector3.new(aimPos.X - origin.X, 0, aimPos.Z - origin.Z)
      if dir.Magnitude < 0.001 then return end
      local targetCF = CFrame.lookAt(origin, origin + dir.Unit)
      myHRP.CFrame   = myHRP.CFrame:Lerp(targetCF, smoothing)
      lastCF         = nil
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
   if not target then
      Rayfield:Notify({
         Title = abilityName,
         Content = "No valid target found.",
         Duration = 2,
         Image = 4483362458,
      })
      return
   end

   currentTarget = target
   aimActive     = true
   aimEndTime    = now + duration
   lastCF        = nil
   startTracking(target)

   local rawMult  = Config.BasePrediction * math.sqrt(dist / math.max(Config.BaseDistance, 0.001))
   local predMult = math.min(rawMult, Config.PredictionCap)
   Rayfield:Notify({
      Title = abilityName .. " Locked!",
      Content = string.format("%.0f studs | Pred: %.2fx | %s | %s",
         dist, predMult, Config.AimMode, Config.TargetBodyPart),
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

local hookedButtons = {}

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
   obj.Destroying:Connect(function() hookedButtons[obj] = nil end)
end

local function hookGui(gui)
   for _, obj in ipairs(gui:GetDescendants()) do hookButton(obj) end
   gui.DescendantAdded:Connect(function(obj) task.wait() hookButton(obj) end)
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
for _, gui in ipairs(PlayerGui:GetChildren()) do
   if gui:IsA("ScreenGui") then hookGui(gui) end
end
PlayerGui.ChildAdded:Connect(function(child)
   if child:IsA("ScreenGui") then task.wait(0.1) hookGui(child) end
end)

-- =====================
--   LOAD SAVED CONFIG
--   Must come AFTER all UI elements are defined so Rayfield
--   can fire each element Callback with its stored value,
--   which syncs everything back into Config automatically.
-- =====================

Rayfield:LoadConfiguration()

-- =====================
--   WELCOME NOTIFY
-- =====================

Rayfield:Notify({
   Title = "springsaken loaded!",
   Content = "Hey " .. LocalPlayer.Name .. "!  E = Entanglement  |  Q = Mass Infection",
   Duration = 5,
   Image = 4483362458,
})

--==========================================================
-- SCRIPT 2: Message Hub (PREMIUM)
-- ==========================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")

--[ Bootstrap ]--
if not game:IsLoaded() then
game.Loaded:Wait()
end

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
LocalPlayer = Players.LocalPlayer
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Clean previous instances
for _, name in ipairs({"PlasmaDuelsGUI","PlasmaMobileButtons","PlasmaOpenClose","AutoStartMenu","MessageHudBar"}) do
local old = PlayerGui:FindFirstChild(name)
if old then old:Destroy() end
end

--[ Colors: BLACK & WHITE ]--
local C_BG = Color3.new(0, 0, 0)
local C_BG2 = Color3.new(0.05, 0.05, 0.05)
local C_BG3 = Color3.new(0.1, 0.1, 0.1)
local C_BG4 = Color3.new(0.15, 0.15, 0.15)
local C_ACCENT = Color3.new(1, 1, 1)
local C_WHITE = Color3.new(1, 1, 1)
local C_GREY = Color3.new(0.6, 0.6, 0.6)
local C_DARK = Color3.new(0.05, 0.05, 0.05)
local C_TEXTDIM = Color3.new(0.7, 0.7, 0.7)
local C_TOFF = Color3.new(0.1, 0.1, 0.1)

--[ Settings ]--
local S = {
ReturnSpeed=29, GotoSpeed=58.5, SimpleAutoSpeed=60,
GalaxyGravity=70, HopPower=50, AimbotRadius=5, BatAimbotSpeed=55,
MedusaRadius=10, SpinSpeed=15,
GUIScale=100, StealRadius=7.7, StealDelay=0,
}

--[ Keybinds ]--
local KB = {
AutoLeft=Enum.KeyCode.Q, AutoRight=Enum.KeyCode.E,
AutoSteal=Enum.KeyCode.V, BatAimbot=Enum.KeyCode.Z, Drop=Enum.KeyCode.F,
AntiRagdoll=Enum.KeyCode.X, NoAnim=Enum.KeyCode.N, Spinbot=Enum.KeyCode.T,
TPDown=Enum.KeyCode.G, Ungrab=Enum.KeyCode.C,
Taunt=nil, ToggleUI=Enum.KeyCode.U, BodyAimbot=nil,
}

--[ Feature States ]--
local EN = {
AutoPlay=false, AutoStart=false, AutoLeft=false, AutoRight=false,
TPBrainrot=false, Drop=false, Ungrab=false, AntiCollision=false,
AutoSteal=false, BatAimbot=false, AutoMedusa=false, Galaxy=false, Optimizer=false,
AntiRagdoll=false, NoAnimations=false, Spinbot=false, TPDown=false,
MobileSupport=false, LockMobile=false, Taunt=false, BodyAimbot=false,
}

--[ Mobile Positions Dictionary ]--
local MobilePositions = {}

-- ══════════════════════════════════════════════════════════
-- CONFIG SYSTEM
-- ══════════════════════════════════════════════════════════
local FileName = "Message_Hub_Config.json"

local function SaveConfig()
local data = {Settings = S, Keybinds = {}, Features = {}, MobilePositions = MobilePositions}
for k, v in pairs(KB) do
data.Keybinds[k] = v and v.Name or nil
end
for k, v in pairs(EN) do
data.Features[k] = v
end
local success, encoded = pcall(function() return HttpService:JSONEncode(data) end)
if success then
if writefile then
writefile(FileName, encoded)
end
end
end

local function LoadConfig()
if isfile and isfile(FileName) then
local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(FileName)) end)
if success then
if decoded.Settings then
for k, v in pairs(decoded.Settings) do S[k] = v end
end
if decoded.Keybinds then
for k, v in pairs(decoded.Keybinds) do
if v then KB[k] = Enum.KeyCode[v] end
end
end
if decoded.Features then
for k, v in pairs(decoded.Features) do
EN[k] = v
end
end
if decoded.MobilePositions then
for k, v in pairs(decoded.MobilePositions) do
MobilePositions[k] = v
end
end
end
end
end
LoadConfig()

--[ Waypoints ]--
local PL1=Vector3.new(-476.48,-6.28,92.73); local PLEND=Vector3.new(-483.12,-4.95,94.80)
local PLFINAL=Vector3.new(-473.38,-8.40,22.34); local PR1=Vector3.new(-476.16,-6.52,25.62)
local PREND=Vector3.new(-483.04,-5.09,23.14); local PRFINAL=Vector3.new(-476.17,-7.91,97.91)

local TP_MID=Vector3.new(-472.60,-7.00,57.52); local TP_L1=Vector3.new(-483.59,-5.04,104.24)
local TP_R1=Vector3.new(-483.51,-5.10,18.89);
local TP_LB=Vector3.new(-472.65,-7.00,95.69)
local TP_RB=Vector3.new(-471.76,-7.00,26.22)

local VisualSetters={};local KeyLabelRefs={};local waitingForKey=nil;local guiVisible=true

--[ Helper For Steal Bar Progress (assigned later) ]--
local UpdateStealProgress = function(pct) end

--[ Character Helpers ]--
local function getHRP() local c=LocalPlayer.Character;return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c=LocalPlayer.Character;return c and c:FindFirstChildOfClass("Humanoid") end

-- ══════════════════════════════════════════════════════════
-- FEATURE LOGIC
-- ══════════════════════════════════════════════════════════

local function tpStep(pos) local h=getHRP();if not h then return end;h.CFrame=CFrame.new(pos);h.AssemblyLinearVelocity=Vector3.zero end
local function doTPLeft() task.spawn(function() tpStep(TP_MID);task.wait(0.08);tpStep(TP_LB);task.wait(0.08);tpStep(TP_L1) end) end
local function doTPRight() task.spawn(function() tpStep(TP_MID);task.wait(0.08);tpStep(TP_RB);task.wait(0.08);tpStep(TP_R1) end) end
local function doDropBrainrot()
local h=getHRP();if not h then return end
task.spawn(function()
local t,DUR=0,0.19;local c1
c1=RunService.Heartbeat:Connect(function(dt)
if not h or not h.Parent then c1:Disconnect();return end
t=t+dt
if t>=DUR then
h.AssemblyLinearVelocity=Vector3.new(h.AssemblyLinearVelocity.X,0,h.AssemblyLinearVelocity.Z)
c1:Disconnect();task.wait(0.02);local c2
c2=RunService.Heartbeat:Connect(function()
if not h or not h.Parent then c2:Disconnect();return end
local ray=workspace:Raycast(h.Position,Vector3.new(0,-50,0),RaycastParams.new())
local dist=ray and ray.Distance or 999
if dist<=4 then h.AssemblyLinearVelocity=Vector3.new(h.AssemblyLinearVelocity.X,0,h.AssemblyLinearVelocity.Z);c2:Disconnect()
else h.AssemblyLinearVelocity=Vector3.new(h.AssemblyLinearVelocity.X,-120,h.AssemblyLinearVelocity.Z) end
end);return
end
h.AssemblyLinearVelocity=Vector3.new(h.AssemblyLinearVelocity.X,120,h.AssemblyLinearVelocity.Z)
end)
end)
end

-- Drop Logic
local function doDrop()
local hrp = getHRP()
if not hrp then return end

-- Pop up in the air
hrp.AssemblyLinearVelocity = Vector3.new(0, 125, 0)
task.wait(0.4)

if hrp and hrp.Parent then
local dropConn
dropConn = RunService.Heartbeat:Connect(function()
if not hrp or not hrp.Parent then
if dropConn then dropConn:Disconnect() end
return
end

-- Check for the ground beneath the player
local rayParams = RaycastParams.new()
rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local ray = workspace:Raycast(hrp.Position, Vector3.new(0, -100, 0), rayParams)
local dist = ray and ray.Distance or 999

if dist <= 6 then
-- Close to the ground: cancel the massive velocity to stop the bounce
hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
dropConn:Disconnect()
else
-- High up: keep shooting down
hrp.AssemblyLinearVelocity = Vector3.new(0, -600, 0)
end
end)

-- Fallback to prevent memory leaks if something interrupts the drop
task.delay(1.5, function()
if dropConn then dropConn:Disconnect() end
end)
end
end

-- Taunt Logic
local function doTaunt()
local msg = "Message Hub on top"
local tcs = game:GetService("TextChatService")
local rs = game:GetService("ReplicatedStorage")
local defaultChat = rs:FindFirstChild("DefaultChatSystemChatEvents")

pcall(function()
if tcs and tcs.ChatVersion == Enum.ChatVersion.TextChatService then
-- Modern Roblox Chat
local channel = tcs.TextChannels:FindFirstChild("RBXGeneral")
if channel then
channel:SendAsync(msg)
end
elseif defaultChat and defaultChat:FindFirstChild("SayMessageRequest") then
-- Legacy Roblox Chat
defaultChat.SayMessageRequest:FireServer(msg, "All")
end
end)
end

local autoWalkConn,autoRightConn;local aplPhase,aprPhase=1,1

local function stopAutoWalk()
if autoWalkConn then autoWalkConn:Disconnect();autoWalkConn=nil end
aplPhase=1;EN.AutoLeft=false
local hum=getHum();if hum then hum:Move(Vector3.zero,false) end
local h=getHRP();if h then h.AssemblyLinearVelocity=Vector3.new(0,h.AssemblyLinearVelocity.Y,0) end
if VisualSetters.AutoLeft then VisualSetters.AutoLeft(false) end
end

local function stopAutoRight()
if autoRightConn then autoRightConn:Disconnect();autoRightConn=nil end
aprPhase=1;EN.AutoRight=false
local hum=getHum();if hum then hum:Move(Vector3.zero,false) end
local h=getHRP();if h then h.AssemblyLinearVelocity=Vector3.new(0,h.AssemblyLinearVelocity.Y,0) end
if VisualSetters.AutoRight then VisualSetters.AutoRight(false) end
end

local function getAutoPhaseSpeed(phase)
if phase == 1 or phase == 2 then return S.GotoSpeed end
if phase == 3 then return S.SpeedWhileSteal or 30 end
return S.ReturnSpeed
end

local function startAutoWalk()
stopAutoRight();if autoWalkConn then autoWalkConn:Disconnect() end
aplPhase=1
local LT={PL1,PLEND,PL1,PLFINAL}

autoWalkConn=RunService.Heartbeat:Connect(function()
if not EN.AutoLeft then stopAutoWalk();return end
local h,hum=getHRP(),getHum();if not h or not hum then return end

if aplPhase>4 then stopAutoWalk();return end
local t=LT[aplPhase];local d=Vector3.new(t.X-h.Position.X,0,t.Z-h.Position.Z)
if d.Magnitude<1 then
aplPhase=aplPhase+1
if aplPhase==3 then hum:Move(Vector3.zero,false);h.AssemblyLinearVelocity=Vector3.new(0,h.AssemblyLinearVelocity.Y,0) end
return
end
local m=d.Unit;local spd=getAutoPhaseSpeed(aplPhase)
hum:Move(m,false);h.AssemblyLinearVelocity=Vector3.new(m.X*spd,h.AssemblyLinearVelocity.Y,m.Z*spd)
end)
end

local function startAutoRight()
stopAutoWalk();if autoRightConn then autoRightConn:Disconnect() end
aprPhase=1
local RT={PR1,PREND,PR1,PRFINAL}

autoRightConn=RunService.Heartbeat:Connect(function()
if not EN.AutoRight then stopAutoRight();return end
local h,hum=getHRP(),getHum();if not h or not hum then return end

if aprPhase>4 then stopAutoRight();return end
local t=RT[aprPhase];local d=Vector3.new(t.X-h.Position.X,0,t.Z-h.Position.Z)
if d.Magnitude<1 then
aprPhase=aprPhase+1
if aprPhase==3 then hum:Move(Vector3.zero,false);h.AssemblyLinearVelocity=Vector3.new(0,h.AssemblyLinearVelocity.Y,0) end
return
end
local m=d.Unit;local spd=getAutoPhaseSpeed(aprPhase)
hum:Move(m,false);h.AssemblyLinearVelocity=Vector3.new(m.X*spd,h.AssemblyLinearVelocity.Y,m.Z*spd)
end)
end

-- ================= ANTI RAGDOLL (REPLACED FROM CODE 2) =================
local arConn
local function startAntiRagdoll()
if arConn then arConn:Disconnect() end
arConn = RunService.Heartbeat:Connect(function()
if not EN.AntiRagdoll then return end
local char = LocalPlayer.Character
if not char then return end

local root = char:FindFirstChild("HumanoidRootPart")
local hum = char:FindFirstChildOfClass("Humanoid")

if hum then
local humState = hum:GetState()
if humState == Enum.HumanoidStateType.Physics or humState == Enum.HumanoidStateType.Ragdoll or humState == Enum.HumanoidStateType.FallingDown then
hum:ChangeState(Enum.HumanoidStateType.Running)
workspace.CurrentCamera.CameraSubject = hum
pcall(function()
if LocalPlayer.Character then
local PlayerModule = LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
if PlayerModule then
local ControlModule = PlayerModule:FindFirstChild("ControlModule")
if ControlModule then
local Controls = require(ControlModule)
if Controls and Controls.Enable then
Controls:Enable()
end
end
end
end
end)
if root then
root.Velocity = Vector3.new(0, 0, 0)
root.RotVelocity = Vector3.new(0, 0, 0)
end
end
end

for _, obj in ipairs(char:GetDescendants()) do
if obj:IsA("Motor6D") and obj.Enabled == false then
obj.Enabled = true
end
end
end)
end

local function stopAntiRagdoll()
if arConn then arConn:Disconnect(); arConn = nil end
end
-- =======================================================================

local spinBAV
local function startSpinbot()
local hrp=getHRP();if not hrp then return end
if spinBAV then spinBAV:Destroy() end
spinBAV=Instance.new("BodyAngularVelocity");spinBAV.Name="PlasmaSpinBAV"
spinBAV.MaxTorque=Vector3.new(0,math.huge,0);spinBAV.AngularVelocity=Vector3.new(0,S.SpinSpeed,0)
spinBAV.Parent=hrp
end
local function stopSpinbot()
if spinBAV then spinBAV:Destroy();spinBAV=nil end
local hrp=getHRP();if hrp then for _,v in ipairs(hrp:GetChildren()) do if v.Name=="PlasmaSpinBAV" then v:Destroy() end end end
end
RunService.Heartbeat:Connect(function() if EN.Spinbot and spinBAV and spinBAV.Parent then spinBAV.AngularVelocity=Vector3.new(0,S.SpinSpeed,0) end end)

local tpDownConn
local function startTPDown()
if tpDownConn then tpDownConn:Disconnect() end
tpDownConn = RunService.Heartbeat:Connect(function()
if not EN.TPDown then return end
local h = getHRP()
local hum = getHum()
if h and hum then
local state = hum:GetState()
-- Triggers automatically if you jump or fall
if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping then
local rayParams = RaycastParams.new()
rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
rayParams.FilterType = Enum.RaycastFilterType.Exclude

-- Raycast straight down
local ray = workspace:Raycast(h.Position, Vector3.new(0, -9000, 0), rayParams)
if ray then
-- Safely offsets the player right above the floor based on rig height to prevent clipping
local offset = hum.HipHeight > 0 and (hum.HipHeight + h.Size.Y/2) or 3
if ray.Distance > offset + 0.5 then
h.CFrame = CFrame.new(h.Position.X, ray.Position.Y + offset, h.Position.Z)
h.AssemblyLinearVelocity = Vector3.new(h.AssemblyLinearVelocity.X, 0, h.AssemblyLinearVelocity.Z)

-- Auto-deactivate after successfully teleporting down
EN.TPDown = false
if VisualSetters.TPDown then
VisualSetters.TPDown(false)
end
if tpDownConn then
tpDownConn:Disconnect()
tpDownConn = nil
end
end
end
end
end
end)
end

local function stopTPDown()
if tpDownConn then tpDownConn:Disconnect(); tpDownConn = nil end
end

local galaxyVF,galaxyAtt
local function startGalaxy()
local c=LocalPlayer.Character;if not c then return end
local hrp=c:FindFirstChild("HumanoidRootPart");if not hrp then return end
if galaxyVF then galaxyVF:Destroy() end;if galaxyAtt then galaxyAtt:Destroy() end
galaxyAtt=Instance.new("Attachment");galaxyAtt.Parent=hrp
galaxyVF=Instance.new("VectorForce");galaxyVF.Attachment0=galaxyAtt
galaxyVF.ApplyAtCenterOfMass=true;galaxyVF.RelativeTo=Enum.ActuatorRelativeTo.World
galaxyVF.Force=Vector3.zero;galaxyVF.Parent=hrp
end

local function stopGalaxy()
if galaxyVF then galaxyVF:Destroy();galaxyVF=nil end;if galaxyAtt then galaxyAtt:Destroy();galaxyAtt=nil end
local hum=getHum();if hum then hum.JumpPower=50 end
end
RunService.Heartbeat:Connect(function()
if not EN.Galaxy or not galaxyVF or not galaxyVF.Parent then return end
local c=LocalPlayer.Character;if not c then return end
local mass=0;for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then mass=mass+p:GetMass() end end
local ratio=S.GalaxyGravity/100;local cancel=mass*workspace.Gravity*(1-ratio)
local cur=galaxyVF.Force.Y;galaxyVF.Force=Vector3.new(0,cur+(cancel-cur)*0.25,0)
local hum=c:FindFirstChildOfClass("Humanoid");if hum then hum.JumpPower=50*math.sqrt(ratio) end
end)
UserInputService.JumpRequest:Connect(function()
if not EN.Galaxy then return end
local h=getHRP();if not h then return end
h.AssemblyLinearVelocity=Vector3.new(h.AssemblyLinearVelocity.X,S.HopPower,h.AssemblyLinearVelocity.Z)
end)

local noAnimConn
local function startNoAnimations()
local c=LocalPlayer.Character;if not c then return end
local hum=c:FindFirstChildOfClass("Humanoid")
if hum then local a=hum:FindFirstChildOfClass("Animator");if a then for _,t in ipairs(a:GetPlayingAnimationTracks()) do t:Stop(0) end end end
local as=c:FindFirstChild("Animate");if as then as.Disabled=true end
if noAnimConn then noAnimConn:Disconnect() end
noAnimConn=RunService.Heartbeat:Connect(function()
if not EN.NoAnimations then noAnimConn:Disconnect();noAnimConn=nil;return end
local c2=LocalPlayer.Character;if not c2 then return end
local h2=c2:FindFirstChildOfClass("Humanoid");if not h2 then return end
local a2=h2:FindFirstChildOfClass("Animator");if a2 then for _,t in ipairs(a2:GetPlayingAnimationTracks()) do t:Stop(0) end end
end)
end
local function stopNoAnimations()
if noAnimConn then noAnimConn:Disconnect();noAnimConn=nil end
local c=LocalPlayer.Character;if not c then return end
local as=c:FindFirstChild("Animate");if as then as.Disabled=false end
end

local ungrabConn
local function startUngrab()
if ungrabConn then return end
ungrabConn=RunService.Heartbeat:Connect(function()
if not EN.Ungrab then ungrabConn:Disconnect();ungrabConn=nil;return end
local c=LocalPlayer.Character;if not c then return end
for _,obj in ipairs(c:GetDescendants()) do
if obj:IsA("WeldConstraint") or obj:IsA("RopeConstraint") or obj:IsA("BallSocketConstraint") or obj:IsA("HingeConstraint") then
local n=obj.Name:lower()
if n:find("grab") or n:find("carry") or n:find("hold") then pcall(function() obj:Destroy() end) end
end
end
local h=c:FindFirstChild("HumanoidRootPart")
if h and h.AssemblyLinearVelocity.Magnitude>200 then h.AssemblyLinearVelocity=h.AssemblyLinearVelocity.Unit*80 end
end)
end
local function stopUngrab() if ungrabConn then ungrabConn:Disconnect();ungrabConn=nil end end

local ncConn
local function startAntiCollision()
if ncConn then ncConn:Disconnect();ncConn=nil end
-- Using Stepped to effectively pass through players without excessive instances/lag
ncConn=RunService.Stepped:Connect(function()
if not EN.AntiCollision then return end
local myChar=LocalPlayer.Character;if not myChar then return end
for _,p in ipairs(Players:GetPlayers()) do
if p~=LocalPlayer and p.Character then
for _,part in ipairs(p.Character:GetDescendants()) do
if part:IsA("BasePart") then
part.CanCollide = false
end
end
end
end
end)
end

local function stopAntiCollision()
if ncConn then ncConn:Disconnect();ncConn=nil end
end

local stealConn=nil;local stealCache={}
local currentStealTarget=nil;local currentStealTime=0

local function isMyPlot(pn)
local plots=workspace:FindFirstChild("Plots");if not plots then return false end
local plot=plots:FindFirstChild(pn);if not plot then return false end
local sign=plot:FindFirstChild("PlotSign");if not sign then return false end
local yb=sign:FindFirstChild("YourBase")
return yb and yb:IsA("BillboardGui") and yb.Enabled
end
local function findNearestPrompt()
local hrp=getHRP();if not hrp then return nil end
local best,bestD=nil,math.huge
local plots=workspace:FindFirstChild("Plots");if not plots then return nil end
for _,plot in ipairs(plots:GetChildren()) do
if not isMyPlot(plot.Name) then
local pods=plot:FindFirstChild("AnimalPodiums");if pods then
for _,pod in ipairs(pods:GetChildren()) do
pcall(function()
local base=pod:FindFirstChild("Base");local spawn=base and base:FindFirstChild("Spawn")
if spawn then
local dist=(spawn.Position-hrp.Position).Magnitude
if dist<bestD and dist<=S.StealRadius then
for _,ch in ipairs(spawn:GetDescendants()) do
if ch:IsA("ProximityPrompt") and ch.Enabled then best=ch;bestD=dist;break end
end
end
end
end)
end
end
end
end
return best
end
local function buildStealCBs(prompt)
if stealCache[prompt] then return end
local data={holdCBs={},trigCBs={},ready=true}
local ok1,c1=pcall(getconnections,prompt.PromptButtonHoldBegan)
if ok1 and type(c1)=="table" then for _,conn in ipairs(c1) do if type(conn.Function)=="function" then table.insert(data.holdCBs,conn.Function) end end end
local ok2,c2=pcall(getconnections,prompt.Triggered)
if ok2 and type(c2)=="table" then for _,conn in ipairs(c2) do if type(conn.Function)=="function" then table.insert(data.trigCBs,conn.Function) end end end
if #data.holdCBs>0 or #data.trigCBs>0 then stealCache[prompt]=data end
end
local function execSteal(prompt)
local data=stealCache[prompt];if not data or not data.ready then return end
data.ready=false
task.spawn(function()
for _,fn in ipairs(data.holdCBs) do task.spawn(fn) end;task.wait(0.2)
for _,fn in ipairs(data.trigCBs) do task.spawn(fn) end;task.wait(0.05)
data.ready=true;stealCache[prompt]=nil
end)
end
local function startAutoSteal()
if stealConn then return end
stealConn=RunService.Heartbeat:Connect(function(dt)
if not EN.AutoSteal then UpdateStealProgress(0); return end
local char=LocalPlayer.Character;if not char then return end
local hum=char:FindFirstChildOfClass("Humanoid");if not hum then return end
local st=hum:GetState()
if st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.FallingDown then return end

local prompt=findNearestPrompt()
if prompt and prompt.Parent then
if currentStealTarget ~= prompt then
currentStealTarget = prompt
currentStealTime = 0
end
currentStealTime = currentStealTime + dt
local delay = S.StealDelay or 0

if delay > 0 then
UpdateStealProgress(math.clamp(currentStealTime / delay, 0, 1))
else
UpdateStealProgress(1)
end

if currentStealTime >= delay then
buildStealCBs(prompt)
execSteal(prompt)
currentStealTime = 0
end
else
currentStealTarget = nil
currentStealTime = 0
UpdateStealProgress(0)
end
end)
end
local function stopAutoSteal()
if stealConn then stealConn:Disconnect();stealConn=nil end
currentStealTarget=nil;currentStealTime=0;UpdateStealProgress(0)
stealCache={}
end

-- ================= BAT AIMBOT (REPLACED FROM CODE 2) =================
local batAimbotConn
local batEquipLoop

local function getNearestPlayerForBat()
local character = LocalPlayer.Character
if not character then return nil end
local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
if not humanoidRootPart then return nil end

local nearestPlayer = nil
local nearestDistance = math.huge
local myPos = humanoidRootPart.Position

for _, p in pairs(Players:GetPlayers()) do
if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
local distance = (p.Character.HumanoidRootPart.Position - myPos).Magnitude
if distance < nearestDistance then
nearestDistance = distance
nearestPlayer = p
end
end
end

return nearestPlayer
end

local function startBatAimbot()
if EN.AutoLeft then stopAutoWalk() end
if EN.AutoRight then stopAutoRight() end
if EN.AutoPlay then
EN.AutoPlay = false
if VisualSetters.AutoPlay then VisualSetters.AutoPlay(false) end
end

if batAimbotConn then batAimbotConn:Disconnect() end
if batEquipLoop then task.cancel(batEquipLoop) end

batAimbotConn = RunService.Heartbeat:Connect(function()
if not EN.BatAimbot then return end

local character = LocalPlayer.Character
if not character then return end
local humanoid = character:FindFirstChildOfClass("Humanoid")
local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
if not humanoid or not humanoidRootPart then return end

local nearestPlayer = getNearestPlayerForBat()
if nearestPlayer and nearestPlayer.Character and nearestPlayer.Character:FindFirstChild("HumanoidRootPart") then
local targetPos = nearestPlayer.Character.HumanoidRootPart.Position
local direction = (targetPos - humanoidRootPart.Position).Unit

-- Hooking into your Code 1 Aimbot Speed Setting instead of static 55
humanoidRootPart.AssemblyLinearVelocity = direction * (S.BatAimbotSpeed or 55)
humanoid.PlatformStand = true
end
end)

batEquipLoop = task.spawn(function()
while EN.BatAimbot do
local character = LocalPlayer.Character
if character then
local humanoid = character:FindFirstChildOfClass("Humanoid")
if humanoid then
local bat = nil
for _,t in ipairs(character:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find("bat") then bat=t end end
if not bat then
local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
if bp then
for _,t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find("bat") then bat=t end end
end
end

if bat then
if bat.Parent ~= character then
humanoid:EquipTool(bat)
task.wait(0.1)
end
local equippedBat = nil
for _,t in ipairs(character:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find("bat") then equippedBat=t end end
if equippedBat then
equippedBat:Activate()
end
end
end
end
task.wait(0.15)
end
end)
end

local function stopBatAimbot()
if batAimbotConn then batAimbotConn:Disconnect(); batAimbotConn = nil end
if batEquipLoop then task.cancel(batEquipLoop); batEquipLoop = nil end

local character = LocalPlayer.Character
if character then
local humanoid = character:FindFirstChildOfClass("Humanoid")
if humanoid then
humanoid.PlatformStand = false
end
local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
if humanoidRootPart then
humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
end
end
end
-- =====================================================================

-- ================= BODY AIMBOT (NEW) =================
local AIMBOT_RANGE = 100
local AIMBOT_DISABLE_RANGE = 110
local bodyAimbotConn
local alignOri
local attach0

local function getClosestTargetBodyAimbot()
local char = LocalPlayer.Character
if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end

local hrp = char.HumanoidRootPart
local closest = nil
local shortestDistance = AIMBOT_RANGE

for _, plr in ipairs(Players:GetPlayers()) do
if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
local targetHrp = plr.Character.HumanoidRootPart
local dist = (targetHrp.Position - hrp.Position).Magnitude

if dist <= shortestDistance then
shortestDistance = dist
closest = targetHrp
end
end
end
return closest
end

local function startBodyAimbot()
if bodyAimbotConn then return end

local char = LocalPlayer.Character
if not char then return end

local hrp = char:FindFirstChild("HumanoidRootPart")
if not hrp then return end

local humanoid = char:FindFirstChildOfClass("Humanoid")
if humanoid then
humanoid.AutoRotate = false
end

attach0 = Instance.new("Attachment", hrp)

alignOri = Instance.new("AlignOrientation")
alignOri.Attachment0 = attach0
alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
alignOri.RigidityEnabled = false
alignOri.MaxTorque = math.huge
alignOri.Responsiveness = 250
alignOri.Parent = hrp

bodyAimbotConn = RunService.RenderStepped:Connect(function()
local target = getClosestTargetBodyAimbot()
if not target then return end

local dist = (target.Position - hrp.Position).Magnitude
if dist > AIMBOT_DISABLE_RANGE then return end

local lookPos = Vector3.new(target.Position.X, hrp.Position.Y, target.Position.Z)
alignOri.CFrame = CFrame.lookAt(hrp.Position, lookPos)
end)
end

local function stopBodyAimbot()
if bodyAimbotConn then
bodyAimbotConn:Disconnect()
bodyAimbotConn = nil
end

if alignOri then
alignOri:Destroy()
alignOri = nil
end

if attach0 then
attach0:Destroy()
attach0 = nil
end

local char = LocalPlayer.Character
if char then
local humanoid = char:FindFirstChildOfClass("Humanoid")
if humanoid then
humanoid.AutoRotate = true
end
end
end

local medusaConn
local function startAutoMedusa()
if medusaConn then return end
medusaConn=RunService.Heartbeat:Connect(function()
if not EN.AutoMedusa then medusaConn:Disconnect();medusaConn=nil;return end
local myChar=LocalPlayer.Character;if not myChar then return end
local myHRP=getHRP();if not myHRP then return end
local myTool=myChar:FindFirstChild("Medusa's Head") or myChar:FindFirstChildOfClass("Tool");if not myTool then return end
for _,p in ipairs(Players:GetPlayers()) do
if p~=LocalPlayer and p.Character then
local tHRP=p.Character:FindFirstChild("HumanoidRootPart")
if tHRP and (myHRP.Position-tHRP.Position).Magnitude<S.MedusaRadius then
pcall(function() myTool:Activate() end);break
end
end
end
end)
end
local function stopAutoMedusa() if medusaConn then medusaConn:Disconnect();medusaConn=nil end end

local function enableOptimizer()
pcall(function()
settings().Rendering.QualityLevel=Enum.QualityLevel.Level01
Lighting.GlobalShadows=false;Lighting.Brightness=3;Lighting.FogEnd=9e9;Lighting.FogStart=9e9
for _,fx in ipairs(Lighting:GetChildren()) do if fx:IsA("PostEffect") then fx.Enabled=false end end
end)
for _,obj in ipairs(workspace:GetDescendants()) do
pcall(function()
if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then obj.Enabled=false
elseif obj:IsA("BasePart") then obj.CastShadow=false;obj.Material=Enum.Material.Plastic
elseif obj:IsA("Sky") then obj:Destroy() end
end)
end
end
local function disableOptimizer()
pcall(function()
settings().Rendering.QualityLevel=Enum.QualityLevel.Automatic
Lighting.GlobalShadows=true;Lighting.FogEnd=100000;Lighting.FogStart=0
for _,fx in ipairs(Lighting:GetChildren()) do if fx:IsA("PostEffect") then fx.Enabled=true end end
end)
end

LocalPlayer.CharacterAdded:Connect(function()
task.wait(0.5)
if EN.AntiRagdoll then startAntiRagdoll() end
if EN.Spinbot then stopSpinbot();task.wait(0.1);startSpinbot() end
if EN.AutoSteal then startAutoSteal() end
if EN.BatAimbot then startBatAimbot() end
if EN.AutoMedusa then startAutoMedusa() end
if EN.AntiCollision then startAntiCollision() end
if EN.Galaxy then startGalaxy() end
if EN.AutoLeft then startAutoWalk() end
if EN.AutoRight then startAutoRight() end
if EN.BodyAimbot then startBodyAimbot() end
end)

-- ══════════════════════════════════════════════════════════
-- GUI CONSTRUCTION
-- ══════════════════════════════════════════════════════════
local function mkCorner(p,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 10);c.Parent=p end
local function mkStroke(p,col,th,tr)
local s=Instance.new("UIStroke");s.Color=col or C_ACCENT;s.Thickness=th or 2
s.Transparency=tr or 0;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=p
end
local function mkGrad(p)
local g=Instance.new("UIGradient")
g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(0.5,Color3.new(0.5,0.5,0.5)),ColorSequenceKeypoint.new(1,Color3.new(1,1,1))})
g.Rotation=45;g.Parent=p
end

local ScreenGui=Instance.new("ScreenGui",PlayerGui);ScreenGui.Name="PlasmaDuelsGUI"
ScreenGui.ResetOnSpawn=false;ScreenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling

local MainFrame=Instance.new("Frame",ScreenGui);MainFrame.Name="MainFrame"
MainFrame.Size=UDim2.new(0,340,0,480);MainFrame.Position=UDim2.new(0.5,-170,0.5,-240)
MainFrame.BackgroundColor3=C_BG;MainFrame.BorderSizePixel=0;MainFrame.Active=true;MainFrame.ClipsDescendants=true
mkCorner(MainFrame,16);mkStroke(MainFrame,C_ACCENT,2.5,0)

local UIScale=Instance.new("UIScale",MainFrame);UIScale.Scale=S.GUIScale/100

-- Galaxy Background Effect
local GalaxyFrame = Instance.new("Frame", MainFrame)
GalaxyFrame.Size = UDim2.new(1,0,1,0);
GalaxyFrame.BackgroundTransparency = 1; GalaxyFrame.ZIndex = 0
task.spawn(function()
local stars = {}
for i=1, 50 do
local s = Instance.new("Frame", GalaxyFrame)
s.Size = UDim2.new(0, math.random(1,2), 0, math.random(1,2))
s.Position = UDim2.new(math.random(), 0, math.random(), 0)
s.BackgroundColor3 = Color3.new(1,1,1)
s.BorderSizePixel = 0
mkCorner(s, 10)
stars[i] = {obj=s, speed=math.random(10,50)/1000}
end
RunService.RenderStepped:Connect(function()
for _, star in ipairs(stars) do
local newY = star.obj.Position.Y.Scale + star.speed
if newY > 1 then newY = -0.01 end
star.obj.Position = UDim2.new(star.obj.Position.X.Scale, 0, newY, 0)
end
end)
end)

local TitleBar=Instance.new("Frame",MainFrame);TitleBar.Name="TitleBar"
TitleBar.Size=UDim2.new(1,0,0,50);TitleBar.BackgroundColor3=C_BG2;TitleBar.BorderSizePixel=0;mkCorner(TitleBar,16)
local tbFix=Instance.new("Frame",TitleBar);tbFix.Size=UDim2.new(1,0,0.5,0);tbFix.Position=UDim2.new(0,0,0.5,0)
tbFix.BackgroundColor3=C_BG2;tbFix.BorderSizePixel=0
local TitleLbl=Instance.new("TextLabel",TitleBar);TitleLbl.Size=UDim2.new(1,0,1,0);TitleLbl.BackgroundTransparency=1
TitleLbl.Text="Message Hub (PREMIUM)";TitleLbl.Font=Enum.Font.GothamBlack;TitleLbl.TextSize=20;TitleLbl.TextColor3=C_ACCENT

-- Draggable MainFrame
do
local _drag,_dragStart,_startPos=false,nil,nil
TitleBar.InputBegan:Connect(function(i)
if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
_drag=true;_dragStart=i.Position;_startPos=MainFrame.Position
i.Changed:Connect(function()
if i.UserInputState==Enum.UserInputState.End then _drag=false end
end)
end
end)
UserInputService.InputChanged:Connect(function(i)
if not _drag then return end
if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
local delta=i.Position-_dragStart
MainFrame.Position=UDim2.new(_startPos.X.Scale,_startPos.X.Offset+delta.X,_startPos.Y.Scale,_startPos.Y.Offset+delta.Y)
end
end)
UserInputService.InputEnded:Connect(function(i)
if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then _drag=false end
end)
end

local DiscLbl=Instance.new("TextLabel",MainFrame);DiscLbl.Name="Discord"
DiscLbl.Size=UDim2.new(1,0,0,20);DiscLbl.Position=UDim2.new(0,0,1,-25)
DiscLbl.BackgroundTransparency=1;DiscLbl.Text="discord.gg/MessageSHUB"
DiscLbl.Font=Enum.Font.GothamBold;DiscLbl.TextSize=12;DiscLbl.TextColor3=C_ACCENT

local TabContainer=Instance.new("Frame",MainFrame);TabContainer.Name="TabContainer"
TabContainer.Size=UDim2.new(1,-20,0,35);TabContainer.Position=UDim2.new(0,10,0,60);TabContainer.BackgroundTransparency=1

local function makeTab(name,text,xOff)
local btn=Instance.new("TextButton",TabContainer);btn.Name=name
btn.Size=UDim2.new(0,72,1,0);btn.Position=UDim2.new(0,xOff,0,0)
btn.Text=text;btn.Font=Enum.Font.GothamBold;btn.TextSize=10
btn.TextColor3=C_GREY;btn.BackgroundColor3=C_BG4;btn.BorderSizePixel=0;mkCorner(btn,8);return btn
end
local FeaturesTab=makeTab("FeaturesTab","FEATURES",0);local KeybindsTab=makeTab("KeybindsTab","KEYBINDS",78)
local SettingsTab=makeTab("SettingsTab","CONFIG",156);local MobileTab=makeTab("MobileTab","MOBILE",234)
FeaturesTab.BackgroundColor3=C_ACCENT;FeaturesTab.TextColor3=C_BG

local function makeScroll(name,vis)
local sf=Instance.new("ScrollingFrame",MainFrame);sf.Name=name
sf.Size=UDim2.new(1,-20,1,-148);sf.Position=UDim2.new(0,10,0,108)
sf.BackgroundTransparency=1;sf.BorderSizePixel=0;sf.ScrollBarThickness=4
sf.ScrollBarImageColor3=C_ACCENT;sf.AutomaticCanvasSize=Enum.AutomaticSize.Y
sf.CanvasSize=UDim2.new(0,0,0,0);sf.Visible=vis
local ll=Instance.new("UIListLayout",sf);ll.SortOrder=Enum.SortOrder.LayoutOrder;ll.Padding=UDim.new(0,5)
local pad=Instance.new("UIPadding",sf);pad.PaddingTop=UDim.new(0,4);pad.PaddingBottom=UDim.new(0,8)
return sf
end
local FeaturesFrame=makeScroll("FeaturesFrame",true);local KeybindsFrame=makeScroll("KeybindsFrame",false)
local SettingsFrame=makeScroll("SettingsFrame",false);local MobileFrame=makeScroll("MobileFrame",false)

local allFrames={FeaturesFrame,KeybindsFrame,SettingsFrame,MobileFrame}
local allTabs={FeaturesTab,KeybindsTab,SettingsTab,MobileTab}
local function switchTab(idx)
for i,f in ipairs(allFrames) do
f.Visible=(i==idx);allTabs[i].BackgroundColor3=(i==idx) and C_ACCENT or C_BG4;allTabs[i].TextColor3=(i==idx) and C_BG or C_GREY
end
end
FeaturesTab.MouseButton1Click:Connect(function() switchTab(1) end)
KeybindsTab.MouseButton1Click:Connect(function() switchTab(2) end)
SettingsTab.MouseButton1Click:Connect(function() switchTab(3) end)
MobileTab.MouseButton1Click:Connect(function() switchTab(4) end)

local rowOrder=0
local function makeToggleRow(parent,label,eKey,cb)
rowOrder=rowOrder+1
local frame=Instance.new("Frame",parent);frame.Size=UDim2.new(1,0,0,40)
frame.BackgroundColor3=C_BG3;frame.BorderSizePixel=0;frame.LayoutOrder=rowOrder;mkCorner(frame,10)
local btn=Instance.new("TextButton",frame);btn.Size=UDim2.new(1,-10,1,0);btn.Position=UDim2.new(0,5,0,0)
btn.BackgroundTransparency=1;btn.Text=label;btn.TextColor3=C_GREY
btn.Font=Enum.Font.GothamBold;btn.TextSize=13;btn.TextXAlignment=Enum.TextXAlignment.Left;btn.AutoButtonColor=false
local on=EN[eKey] or false
local function refresh()
btn.BackgroundTransparency=on and 0.2 or 1;btn.BackgroundColor3=on and C_ACCENT or C_BG3;btn.TextColor3=on and C_WHITE or C_GREY
end
refresh()
VisualSetters[eKey]=function(state) on=state;EN[eKey]=state;refresh() end
btn.MouseButton1Click:Connect(function() on=not on;EN[eKey]=on;refresh();if cb then cb(on) end end)
return frame
end

-- ── Features Tab ────────────────────────────────────────────
makeToggleRow(FeaturesFrame,"Auto Play","AutoPlay",function(v)
EN.AutoLeft=v;if v then startAutoWalk() else stopAutoWalk() end
if VisualSetters.AutoLeft then VisualSetters.AutoLeft(v) end
end)
makeToggleRow(FeaturesFrame,"Auto Start","AutoStart",function(v)
local menu=PlayerGui:FindFirstChild("AutoStartMenu");if menu then menu.AutoStartMenuFrame.Visible=v end
end)
makeToggleRow(FeaturesFrame,"Restam Auto (Left)","AutoLeft",function(v)
if v then startAutoWalk() else stopAutoWalk() end
end)
makeToggleRow(FeaturesFrame,"Auto Right","AutoRight",function(v)
if v then startAutoRight() else stopAutoRight() end
end)
makeToggleRow(FeaturesFrame,"TP to Brainrot","TPBrainrot",function(v)
if v then doDropBrainrot();task.delay(0.6,function() EN.TPBrainrot=false;if VisualSetters.TPBrainrot then VisualSetters.TPBrainrot(false) end end) end
end)

makeToggleRow(FeaturesFrame,"Drop","Drop",function(v)
if v then
task.spawn(doDrop)
task.delay(0.4, function() EN.Drop = false;
if VisualSetters.Drop then VisualSetters.Drop(false) end end)
end
end)

makeToggleRow(FeaturesFrame,"Taunt","Taunt",function(v)
if v then

task.spawn(doTaunt)
-- Auto-turn off the UI toggle button after 0.4s so it acts like a click button
task.delay(0.4, function()
EN.Taunt = false
if VisualSetters.Taunt then VisualSetters.Taunt(false) end
end)
end
end)

makeToggleRow(FeaturesFrame,"Ungrab","Ungrab",function(v) if v then startUngrab() else stopUngrab() end end)
makeToggleRow(FeaturesFrame,"Anti Collision","AntiCollision",function(v)
if v then startAntiCollision() else stopAntiCollision() end
end)
makeToggleRow(FeaturesFrame,"Instant Grab","AutoSteal",function(v)
if v then startAutoSteal() else stopAutoSteal() end
end)
makeToggleRow(FeaturesFrame,"Bat Aimbot","BatAimbot",function(v)
if v then startBatAimbot() else stopBatAimbot() end
end)
makeToggleRow(FeaturesFrame,"Aimbot","BodyAimbot",function(v)
if v then startBodyAimbot() else stopBodyAimbot() end
end)
makeToggleRow(FeaturesFrame,"Auto Medusa","AutoMedusa",function(v)
if v then startAutoMedusa() else stopAutoMedusa() end
end)
makeToggleRow(FeaturesFrame,"Jump Power","Galaxy",function(v)
if v then startGalaxy() else stopGalaxy() end
end)
makeToggleRow(FeaturesFrame,"Performance","Optimizer",function(v)
if v then enableOptimizer() else disableOptimizer() end
end)
makeToggleRow(FeaturesFrame,"Anti Ragdoll","AntiRagdoll",function(v)
if v then startAntiRagdoll() else stopAntiRagdoll() end
end)
makeToggleRow(FeaturesFrame,"No Animations","NoAnimations",function(v)
if v then startNoAnimations() else stopNoAnimations() end
end)
makeToggleRow(FeaturesFrame,"Spinbot","Spinbot",function(v)
if v then startSpinbot() else stopSpinbot() end
end)
makeToggleRow(FeaturesFrame,"TP Down","TPDown",function(v)
if v then startTPDown() else stopTPDown() end
end)

-- ── Keybinds Tab ─────────────────────────────────────────
local function makeKeybindRow(parent,label,kKey)
rowOrder=rowOrder+1
local frame=Instance.new("Frame",parent);frame.Name=label.."Container"
frame.Size=UDim2.new(1,0,0,50);frame.BackgroundColor3=C_BG3;frame.BorderSizePixel=0;frame.LayoutOrder=rowOrder;mkCorner(frame,10)
local keyBtn=Instance.new("TextButton",frame);keyBtn.Size=UDim2.new(0,35,0,35);keyBtn.Position=UDim2.new(0,8,0.5,-17)
keyBtn.BackgroundColor3=C_BG4;keyBtn.BorderSizePixel=0;keyBtn.TextColor3=C_WHITE;keyBtn.Font=Enum.Font.GothamBlack;keyBtn.TextSize=14
keyBtn.Text=(KB[kKey] and KB[kKey].Name) or "NONE";mkCorner(keyBtn,8);mkGrad(keyBtn)
local tl=Instance.new("TextLabel",frame);tl.Size=UDim2.new(1,-55,1,0);tl.Position=UDim2.new(0,50,0,0)
tl.BackgroundTransparency=1;tl.Text=label;tl.TextSize=13;tl.TextColor3=C_WHITE
tl.TextXAlignment=Enum.TextXAlignment.Left;tl.Font=Enum.Font.GothamBold
KeyLabelRefs[kKey]=keyBtn
keyBtn.MouseButton1Click:Connect(function() waitingForKey=kKey;keyBtn.Text="..." end)
end
makeKeybindRow(KeybindsFrame,"Auto Left","AutoLeft");makeKeybindRow(KeybindsFrame,"Auto Right","AutoRight")
makeKeybindRow(KeybindsFrame,"Instant Grab","AutoSteal");makeKeybindRow(KeybindsFrame,"Bat Aimbot","BatAimbot")
makeKeybindRow(KeybindsFrame,"Aimbot","BodyAimbot");makeKeybindRow(KeybindsFrame,"Drop","Drop")
makeKeybindRow(KeybindsFrame,"Anti Ragdoll","AntiRagdoll");makeKeybindRow(KeybindsFrame,"No Anim","NoAnim")
makeKeybindRow(KeybindsFrame,"Spinbot","Spinbot");makeKeybindRow(KeybindsFrame,"TP Down","TPDown")
makeKeybindRow(KeybindsFrame,"Ungrab","Ungrab");makeKeybindRow(KeybindsFrame,"Taunt","Taunt")
makeKeybindRow(KeybindsFrame,"Toggle UI","ToggleUI")

-- ── Settings Tab ─────────────────────────────────────────
local function makeSettingRow(parent,label,sKey,default)
rowOrder=rowOrder+1
local frame=Instance.new("Frame",parent);frame.Size=UDim2.new(1,0,0,45)
frame.BackgroundColor3=C_BG3;frame.BorderSizePixel=0;frame.LayoutOrder=rowOrder;mkCorner(frame,10)
local lbl=Instance.new("TextLabel",frame);lbl.Size=UDim2.new(1,-100,1,0);lbl.Position=UDim2.new(0,10,0,0)
lbl.BackgroundTransparency=1;lbl.Text=label;lbl.TextColor3=C_WHITE;lbl.Font=Enum.Font.GothamBold
lbl.TextSize=12;lbl.TextXAlignment=Enum.TextXAlignment.Left
local vb=Instance.new("TextButton",frame);vb.Size=UDim2.new(0,80,0,30);vb.Position=UDim2.new(1,-88,0.5,-15)
vb.BackgroundColor3=C_BG4;vb.BorderSizePixel=0;vb.Text=tostring(S[sKey] or default);vb.TextColor3=C_WHITE
vb.Font=Enum.Font.GothamBlack;vb.TextSize=13;mkCorner(vb,8)
local vi=Instance.new("TextBox",frame);vi.Size=UDim2.new(0,80,0,30);vi.Position=UDim2.new(1,-88,0.5,-15)
vi.BackgroundColor3=C_BG4;vi.BorderSizePixel=0;vi.Text="";vi.TextColor3=C_WHITE
vi.Font=Enum.Font.GothamBlack;vi.TextSize=13;vi.ClearTextOnFocus=true;vi.Visible=false;mkCorner(vi,8)
vb.MouseButton1Click:Connect(function() vb.Visible=false;vi.Visible=true;vi:CaptureFocus() end)
vi.FocusLost:Connect(function()
local n=tonumber(vi.Text)
if n then
S[sKey]=n;vb.Text=tostring(n)
if sKey=="GUIScale" then UIScale.Scale=n/100 end
SaveConfig()
end
vi.Visible=false;vb.Visible=true
end)
end
makeSettingRow(SettingsFrame,"GUI Scale %","GUIScale",100)
makeSettingRow(SettingsFrame,"Return To Base Speed","ReturnSpeed",29)
makeSettingRow(SettingsFrame,"Goto Enemy Base Speed","GotoSpeed",58.5)
makeSettingRow(SettingsFrame,"Simple Auto L/R Speed","SimpleAutoSpeed",60)
makeSettingRow(SettingsFrame,"Gravity %","GalaxyGravity",70)
makeSettingRow(SettingsFrame,"Hop Power","HopPower",50)
makeSettingRow(SettingsFrame,"Aimbot Radius","AimbotRadius",5)
makeSettingRow(SettingsFrame,"Aimbot Speed","BatAimbotSpeed",55)
makeSettingRow(SettingsFrame,"Medusa Radius","MedusaRadius",10)
makeSettingRow(SettingsFrame,"Spinbot Speed","SpinSpeed",15)

-- Save Button Row
do
rowOrder=rowOrder+1
local sb=Instance.new("TextButton",SettingsFrame);sb.Size=UDim2.new(1,0,0,38)
sb.BackgroundColor3=C_BG4;sb.BorderSizePixel=0;sb.Text="SAVE CONFIGURATION"
sb.Font=Enum.Font.GothamBlack;sb.TextSize=14;sb.TextColor3=C_ACCENT;sb.LayoutOrder=rowOrder;mkCorner(sb,10)
sb.MouseButton1Click:Connect(function()
SaveConfig()
sb.Text = "SAVED!"
task.wait(1)
sb.Text = "SAVE CONFIGURATION"
end)
end

-- Reset Defaults
do
rowOrder=rowOrder+1
local rb=Instance.new("TextButton",SettingsFrame);rb.Size=UDim2.new(1,0,0,38)
rb.BackgroundColor3=C_ACCENT;rb.BorderSizePixel=0;rb.Text="RESET DEFAULTS"
rb.Font=Enum.Font.GothamBlack;rb.TextSize=14;rb.TextColor3=C_BG;rb.LayoutOrder=rowOrder;mkCorner(rb,10)
rb.MouseButton1Click:Connect(function()
S.ReturnSpeed=29;S.GotoSpeed=58.5;S.SimpleAutoSpeed=60
S.GalaxyGravity=70;S.HopPower=50;S.AimbotRadius=5;S.BatAimbotSpeed=55;S.MedusaRadius=10
S.SpinSpeed=15;S.GUIScale=100;S.StealRadius=7.7;S.StealDelay=0;UIScale.Scale=1
SaveConfig()
end)
end

-- ── Mobile Tab ───────────────────────────────────────────
do
rowOrder=rowOrder+1
local tl=Instance.new("TextLabel",MobileFrame);tl.Size=UDim2.new(1,-10,0,30)
tl.BackgroundTransparency=1;tl.Text="MOBILE BUTTONS";tl.TextColor3=C_ACCENT
tl.Font=Enum.Font.GothamBlack;tl.TextSize=14;tl.TextXAlignment=Enum.TextXAlignment.Left;tl.LayoutOrder=rowOrder
makeToggleRow(MobileFrame,"Show Mobile Buttons","MobileSupport",function(v)
local gui=PlayerGui:FindFirstChild("PlasmaMobileButtons");if gui then gui.Enabled=v end
end)
makeToggleRow(MobileFrame,"Lock Buttons","LockMobile")
end


-- ══════════════════════════════════════════════════════════
-- HUD BAR (FPS & PING)
-- ══════════════════════════════════════════════════════════
local HudGui = Instance.new("ScreenGui", PlayerGui)
HudGui.Name = "MessageHudBar"
HudGui.ResetOnSpawn = false

local HudBar = Instance.new("Frame", HudGui)
HudBar.Size = UDim2.new(0, 320, 0, 40)
HudBar.Position = UDim2.new(0.5, -160, 0, 2) -- Moved up to where Message icon was, slightly higher
HudBar.BackgroundColor3 = C_BG
HudBar.BorderSizePixel = 0
HudBar.ClipsDescendants = true
mkCorner(HudBar, 12)
mkStroke(HudBar, C_ACCENT, 2, 0.3)

-- HUD Stars Background
local hudStars = Instance.new("Frame", HudBar)
hudStars.Size = UDim2.new(1, 0, 1, 0)
hudStars.BackgroundTransparency = 1
hudStars.ClipsDescendants = true
hudStars.ZIndex = 1

task.spawn(function()
local stars = {}
for i = 1, 15 do
local s = Instance.new("Frame", hudStars)
s.Size = UDim2.new(0, math.random(1, 2), 0, math.random(1, 2))
s.Position = UDim2.new(math.random(), 0, math.random(), 0)
s.BackgroundColor3 = Color3.new(1, 1, 1)
s.BorderSizePixel = 0
s.ZIndex = 1
mkCorner(s, 10)
stars[i] = {obj = s, speed = math.random(10, 40) / 1000}
end
RunService.RenderStepped:Connect(function()
if not HudBar or not HudBar.Parent then return end
for _, star in ipairs(stars) do
local newY = star.obj.Position.Y.Scale + star.speed
if newY > 1 then newY = -0.01 end
star.obj.Position = UDim2.new(star.obj.Position.X.Scale, 0, newY, 0)
end
end)
end)

-- Middle Text (Title)
local HudTitle = Instance.new("TextLabel", HudBar)
HudTitle.Size = UDim2.new(1, 0, 1, 0)
HudTitle.BackgroundTransparency = 1
HudTitle.Text = "Message's duel hub"
HudTitle.TextColor3 = C_WHITE
HudTitle.Font = Enum.Font.GothamBlack
HudTitle.TextSize = 14
HudTitle.ZIndex = 2

-- Left Text (FPS)
local FpsText = Instance.new("TextLabel", HudBar)
FpsText.Size = UDim2.new(0.3, 0, 1, 0)
FpsText.Position = UDim2.new(0.05, 0, 0, 0)
FpsText.BackgroundTransparency = 1
FpsText.Text = "FPS: --"
FpsText.TextColor3 = C_GREY
FpsText.Font = Enum.Font.GothamBold
FpsText.TextSize = 12
FpsText.TextXAlignment = Enum.TextXAlignment.Left
FpsText.ZIndex = 2

-- Right Text (Ping)
local PingText = Instance.new("TextLabel", HudBar)
PingText.Size = UDim2.new(0.3, 0, 1, 0)
PingText.Position = UDim2.new(0.65, 0, 0, 0)
PingText.BackgroundTransparency = 1
PingText.Text = "Ping: --ms"
PingText.TextColor3 = C_GREY
PingText.Font = Enum.Font.GothamBold
PingText.TextSize = 12
PingText.TextXAlignment = Enum.TextXAlignment.Right
PingText.ZIndex = 2

-- HUD Tracker Logic
task.spawn(function()
local fpsCount = 0
local lastTick = tick()

RunService.RenderStepped:Connect(function()
fpsCount = fpsCount + 1
local currentTick = tick()

if currentTick - lastTick >= 1 then
-- Update FPS
FpsText.Text = "FPS: " .. tostring(fpsCount)
fpsCount = 0
lastTick = currentTick

-- Update Ping
local pingValue = 0
pcall(function()
-- Fetch network ping reliably
local networkStats = Stats:FindFirstChild("Network")
if networkStats and networkStats:FindFirstChild("ServerStatsItem") then
pingValue = math.floor(networkStats.ServerStatsItem["Data Ping"]:GetValue())
else
pingValue = math.floor(LocalPlayer:GetNetworkPing() * 1000)
end
end)
PingText.Text = "Ping: " .. tostring(pingValue) .. "ms"
end
end)
end)


-- ══════════════════════════════════════════════════════════
-- MOBILE BUTTONS GUI
-- ══════════════════════════════════════════════════════════
local MobileGui=Instance.new("ScreenGui",PlayerGui);MobileGui.Name="PlasmaMobileButtons";MobileGui.ResetOnSpawn=false;MobileGui.Enabled=false
local mobileData={
{text="TP\nDOWN", key="TPDown", pos=UDim2.new(0,15,0.5,-110),cb=function() EN.TPDown=not EN.TPDown;if EN.TPDown then startTPDown() else stopTPDown() end;if VisualSetters.TPDown then VisualSetters.TPDown(EN.TPDown) end end},
{text="AUTO\nLEFT", key="AutoLeft", pos=UDim2.new(0,15,0.5,-37),cb=function() EN.AutoLeft=not EN.AutoLeft;if EN.AutoLeft then startAutoWalk() else stopAutoWalk() end;if VisualSetters.AutoLeft then VisualSetters.AutoLeft(EN.AutoLeft) end end},
{text="AUTO\nRIGHT", key="AutoRight", pos=UDim2.new(0,15,0.5,36),cb=function() EN.AutoRight=not EN.AutoRight;if EN.AutoRight then startAutoRight() else stopAutoRight() end;if VisualSetters.AutoRight then VisualSetters.AutoRight(EN.AutoRight) end end},
{text="AIMBOT", key="BodyAimbot", pos=UDim2.new(0,15,0.5,109),cb=function() EN.BodyAimbot=not EN.BodyAimbot;if EN.BodyAimbot then startBodyAimbot() else stopBodyAimbot() end;if VisualSetters.BodyAimbot then VisualSetters.BodyAimbot(EN.BodyAimbot) end end},

{text="DROP", key="Drop", pos=UDim2.new(1,-80,0.5,-110),cb=function()
EN.Drop = true
if VisualSetters.Drop then VisualSetters.Drop(true) end
task.spawn(doDrop)
task.delay(0.4, function()
EN.Drop = false
if VisualSetters.Drop then VisualSetters.Drop(false) end
end)
end},

{text="BAT\nAIMBOT", key="BatAimbot", pos=UDim2.new(1,-80,0.5,-37),cb=function() EN.BatAimbot=not EN.BatAimbot;if EN.BatAimbot then startBatAimbot() else stopBatAimbot() end;if VisualSetters.BatAimbot then VisualSetters.BatAimbot(EN.BatAimbot) end end},
{text="SPIN\nBOT", key="Spinbot", pos=UDim2.new(1,-80,0.5,36),cb=function() EN.Spinbot=not EN.Spinbot;if EN.Spinbot then startSpinbot() else stopSpinbot() end;if VisualSetters.Spinbot then VisualSetters.Spinbot(EN.Spinbot) end end},

-- New Taunt Button! Added cleanly underneath Spinbot
{text="TAUNT", key="Taunt", pos=UDim2.new(1,-80,0.5,109),cb=function()
EN.Taunt = true
if VisualSetters.Taunt then VisualSetters.Taunt(true) end
task.spawn(doTaunt)

task.delay(0.4, function()
EN.Taunt = false
if VisualSetters.Taunt then VisualSetters.Taunt(false) end
end)
end},
}

for _,mb in ipairs(mobileData) do
local btn=Instance.new("TextButton",MobileGui);btn.Name=mb.key;btn.Size=UDim2.new(0,65,0,65)

-- Assign saved position if available
if MobilePositions[mb.key] then
local sp = MobilePositions[mb.key]
btn.Position = UDim2.new(sp[1], sp[2], sp[3], sp[4])
else
btn.Position = mb.pos
end

btn.BackgroundColor3=C_BG;btn.BorderSizePixel=0;btn.Text="" -- Text hidden here, moved to label below
btn.Active=true;btn.ClipsDescendants=true;mkCorner(btn,12);mkStroke(btn,C_ACCENT,2,0.3)

-- Text Label to stay strictly above stars
local btnLbl=Instance.new("TextLabel",btn);btnLbl.Size=UDim2.new(1,0,1,0)
btnLbl.BackgroundTransparency=1;btnLbl.Text=mb.text;btnLbl.TextSize=9;btnLbl.TextWrapped=true
btnLbl.TextColor3=C_WHITE;btnLbl.Font=Enum.Font.GothamBlack;btnLbl.ZIndex=2

-- Button Background Animated Stars
local bgStars=Instance.new("Frame",btn)
bgStars.Size=UDim2.new(1,0,1,0);bgStars.BackgroundTransparency=1;bgStars.ClipsDescendants=true;bgStars.ZIndex=1
mkCorner(bgStars,12)
task.spawn(function()
local stars={}
for i=1,12 do
local s=Instance.new("Frame",bgStars)
s.Size=UDim2.new(0,math.random(1,2),0,math.random(1,2))
s.Position=UDim2.new(math.random(),0,math.random(),0)
s.BackgroundColor3=Color3.new(1,1,1);s.BorderSizePixel=0;s.ZIndex=1
mkCorner(s,10);stars[i]={obj=s,speed=math.random(10,40)/1000}
end
RunService.RenderStepped:Connect(function()
if not btn or not btn.Parent then return end
for _,star in ipairs(stars) do
local newY=star.obj.Position.Y.Scale+star.speed
if newY>1 then newY=-0.01 end
star.obj.Position=UDim2.new(star.obj.Position.X.Scale,0,newY,0)
end
end)
end)

local dragging, dragStart, startPos = false, nil, nil
local activeColor = C_GREY
local inactiveColor = C_BG

local function updateColor()
btn.BackgroundColor3 = EN[mb.key] and activeColor or inactiveColor
end

local oldSetter = VisualSetters[mb.key]
VisualSetters[mb.key] = function(state)
if oldSetter then oldSetter(state) end
updateColor()
end

updateColor()

btn.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
btn.BackgroundColor3 = Color3.new(0.8, 0.8, 0.8)
if not EN.LockMobile then
dragging = true
dragStart = input.Position
startPos = btn.Position
end
end
end)

btn.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
updateColor()
dragging = false
end
end)

UserInputService.InputChanged:Connect(function(input)
if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
local delta = input.Position - dragStart
local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
btn.Position = newPos

-- Save location dynamically to the table so saving config remembers it
MobilePositions[mb.key] = {newPos.X.Scale, newPos.X.Offset, newPos.Y.Scale, newPos.Y.Offset}
end
end)

btn.MouseButton1Click:Connect(function()
mb.cb()
updateColor()
end)
end

-- ══════════════════════════════════════════════════════════
-- OPEN/CLOSE BUTTON
-- ══════════════════════════════════════════════════════════
local OpenCloseGui=Instance.new("ScreenGui",PlayerGui);OpenCloseGui.Name="PlasmaOpenClose";OpenCloseGui.ResetOnSpawn=false
local ocBtn=Instance.new("TextButton",OpenCloseGui);ocBtn.Size=UDim2.new(0,52,0,52)
ocBtn.Position=UDim2.new(0.5,-26,0,70) -- Moved to old HUD bar position
ocBtn.BackgroundColor3=C_BG;ocBtn.Text="Message";ocBtn.TextColor3=C_WHITE;ocBtn.TextSize=20;ocBtn.Font=Enum.Font.GothamBlack;ocBtn.Active=true;ocBtn.BorderSizePixel=0;mkCorner(ocBtn,14);mkStroke(ocBtn,C_ACCENT,2,0)
ocBtn.MouseButton1Click:Connect(function() guiVisible=not guiVisible;MainFrame.Visible=guiVisible end)
local _dd,_dds,_ddp=false,nil,nil
ocBtn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then _dd=true;_dds=i.Position;_ddp=ocBtn.Position end end)
ocBtn.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then _dd=false end end)
UserInputService.InputChanged:Connect(function(i)
if _dd and i.UserInputType==Enum.UserInputType.MouseMovement then
local d=i.Position-_dds;ocBtn.Position=UDim2.new(_ddp.X.Scale,_ddp.X.Offset+d.X,_ddp.Y.Scale,_ddp.Y.Offset+d.Y)
end
end)

-- ══════════════════════════════════════════════════════════
-- STEAL BAR GUI
-- ══════════════════════════════════════════════════════════
local StealBarUI=Instance.new("Frame",ScreenGui);StealBarUI.Name="StealBarUI"
StealBarUI.Size=UDim2.new(0,240,0,75);StealBarUI.Position=UDim2.new(0.5,-120,0.8,0) -- Locked Under Middle
StealBarUI.BackgroundColor3=C_BG;StealBarUI.BorderSizePixel=0;StealBarUI.Active=true
mkCorner(StealBarUI,12);mkStroke(StealBarUI,C_ACCENT,2,0)

-- Animated Stars for Steal Bar
local sbStars=Instance.new("Frame",StealBarUI)
sbStars.Size=UDim2.new(1,0,1,0);sbStars.BackgroundTransparency=1;sbStars.ClipsDescendants=true
mkCorner(sbStars,12)
task.spawn(function()
local stars={}
for i=1,20 do
local s=Instance.new("Frame",sbStars)
s.Size=UDim2.new(0,math.random(1,2),0,math.random(1,2))
s.Position=UDim2.new(math.random(),0,math.random(),0)
s.BackgroundColor3=Color3.new(1,1,1);s.BorderSizePixel=0
mkCorner(s,10);stars[i]={obj=s,speed=math.random(10,50)/1000}
end
RunService.RenderStepped:Connect(function()
for _,star in ipairs(stars) do
local newY=star.obj.Position.Y.Scale+star.speed
if newY>1 then newY=-0.01 end
star.obj.Position=UDim2.new(star.obj.Position.X.Scale,0,newY,0)
end
end)
end)

-- Progress Bar Elements
local pBg=Instance.new("Frame",StealBarUI)
pBg.Size=UDim2.new(1,-20,0,15);pBg.Position=UDim2.new(0,10,0,10)
pBg.BackgroundColor3=C_BG3;mkCorner(pBg,8)

local ProgFill=Instance.new("Frame",pBg)
ProgFill.Size=UDim2.new(0,0,1,0);ProgFill.BackgroundColor3=C_ACCENT;mkCorner(ProgFill,8)

UpdateStealProgress = function(pct)
if ProgFill then ProgFill.Size=UDim2.new(pct,0,1,0) end
end

-- Settings Inputs on Steal Bar
local function makeSBInput(xOff,labelTxt,sKey,defaultVal)
local lbl=Instance.new("TextLabel",StealBarUI)
lbl.Size=UDim2.new(0,50,0,20);lbl.Position=UDim2.new(0,xOff,0,40)
lbl.BackgroundTransparency=1;lbl.Text=labelTxt;lbl.TextColor3=C_GREY
lbl.Font=Enum.Font.GothamBold;lbl.TextSize=11

local box=Instance.new("TextBox",StealBarUI)
box.Size=UDim2.new(0,40,0,25);box.Position=UDim2.new(0,xOff+55,0,37)
box.BackgroundColor3=C_BG4;box.BorderSizePixel=0;box.TextColor3=C_WHITE
box.Font=Enum.Font.GothamBlack;box.TextSize=12
box.Text=tostring(S[sKey] or defaultVal)
mkCorner(box,6)

box.FocusLost:Connect(function()
local val=tonumber(box.Text)
if val then
S[sKey]=val;SaveConfig()
else
box.Text=tostring(S[sKey])
end
end)
end

makeSBInput(10,"RADIUS:", "StealRadius", 7.7)
makeSBInput(125,"DELAY:", "StealDelay", 0)

-- ══════════════════════════════════════════════════════════
-- AUTO START MENU
-- ══════════════════════════════════════════════════════════
local AutoStartGui=Instance.new("ScreenGui",PlayerGui);AutoStartGui.Name="AutoStartMenu";AutoStartGui.DisplayOrder=100;AutoStartGui.ResetOnSpawn=false
local asFrame=Instance.new("Frame",AutoStartGui);asFrame.Name="AutoStartMenuFrame"
asFrame.Size=UDim2.new(0,200,0,140);asFrame.Position=UDim2.new(0.5,-100,0.3,0)
asFrame.BackgroundColor3=Color3.new(0,0,0);asFrame.Visible=false;mkCorner(asFrame,12);mkStroke(asFrame,C_ACCENT,2,0)
local asTl=Instance.new("TextLabel",asFrame);asTl.Size=UDim2.new(1,0,0,24);asTl.Position=UDim2.new(0,0,0,8)
asTl.BackgroundTransparency=1;asTl.Text="Message Hub";asTl.TextColor3=C_ACCENT;asTl.Font=Enum.Font.GothamBlack;asTl.TextSize=16
local asSub=Instance.new("TextLabel",asFrame);asSub.Size=UDim2.new(1,0,0,20);asSub.Position=UDim2.new(0,0,0,32)
asSub.BackgroundTransparency=1;asSub.Text="Auto Start";asSub.TextColor3=C_GREY;asSub.Font=Enum.Font.GothamBold;asSub.TextSize=12
local function asSideBtn(text,y,action)
local btn=Instance.new("TextButton",asFrame);btn.Size=UDim2.new(0,170,0,30);btn.Position=UDim2.new(0,15,0,y)
btn.BackgroundColor3=C_TOFF;btn.BorderSizePixel=0;btn.Text=text;btn.TextColor3=C_WHITE;btn.Font=Enum.Font.GothamBold;btn.TextSize=13;mkCorner(btn,8)
btn.MouseButton1Click:Connect(function() asFrame.Visible=false;EN.AutoStart=false;if VisualSetters.AutoStart then VisualSetters.AutoStart(false) end;action() end)
end
asSideBtn("Left Side",60,function() EN.AutoLeft=true;startAutoWalk();if VisualSetters.AutoLeft then VisualSetters.AutoLeft(true) end end)
asSideBtn("Right Side",96,function() EN.AutoRight=true;startAutoRight();if VisualSetters.AutoRight then VisualSetters.AutoRight(true) end end)

-- ══════════════════════════════════════════════════════════
-- GLOBAL INPUT HANDLER
-- ══════════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gpe)
if waitingForKey then
if input.KeyCode~=Enum.KeyCode.Unknown then
local k=input.KeyCode
if k==Enum.KeyCode.Escape then
local ref=KeyLabelRefs[waitingForKey];if ref then ref.Text=(KB[waitingForKey] and KB[waitingForKey].Name) or "NONE" end
else
KB[waitingForKey]=k;local ref=KeyLabelRefs[waitingForKey];if ref then ref.Text=k.Name end
SaveConfig()
end
waitingForKey=nil
end
return
end
if gpe then return end

local function tog(enKey,startFn,stopFn)
EN[enKey]=not EN[enKey];if VisualSetters[enKey] then VisualSetters[enKey](EN[enKey]) end
if EN[enKey] then if startFn then startFn() end else if stopFn then stopFn() end end
end

if input.KeyCode==KB.ToggleUI then guiVisible=not guiVisible;MainFrame.Visible=guiVisible end
if input.KeyCode==KB.AutoLeft then tog("AutoLeft", startAutoWalk, stopAutoWalk) end
if input.KeyCode==KB.AutoRight then tog("AutoRight",startAutoRight,stopAutoRight) end
if input.KeyCode==KB.Spinbot then tog("Spinbot", startSpinbot, stopSpinbot) end
if input.KeyCode==KB.BatAimbot then tog("BatAimbot",startBatAimbot,stopBatAimbot) end
if input.KeyCode==KB.BodyAimbot then tog("BodyAimbot",startBodyAimbot,stopBodyAimbot) end
if input.KeyCode==KB.AntiRagdoll then tog("AntiRagdoll",startAntiRagdoll,stopAntiRagdoll) end
if input.KeyCode==KB.NoAnim then tog("NoAnimations",startNoAnimations,stopNoAnimations) end
if input.KeyCode==KB.Ungrab then tog("Ungrab", startUngrab, stopUngrab) end
end)

-- ══════════════════════════════════════════════════════════
-- APPLY SAVED CONFIGURATION
-- ══════════════════════════════════════════════════════════
task.spawn(function()
task.wait(0.5) -- Allow time for character and instances to be fully ready

if EN.AutoPlay then EN.AutoLeft = true; startAutoWalk() end
if EN.AutoLeft then startAutoWalk() end
if EN.AutoRight then startAutoRight() end
if EN.Ungrab then startUngrab() end
if EN.AntiCollision then startAntiCollision() end
if EN.AutoSteal then startAutoSteal() end
if EN.BatAimbot then startBatAimbot() end
if EN.BodyAimbot then startBodyAimbot() end
if EN.AutoMedusa then startAutoMedusa() end
if EN.Galaxy then startGalaxy() end
if EN.Optimizer then enableOptimizer() end
if EN.AntiRagdoll then startAntiRagdoll() end
if EN.NoAnimations then startNoAnimations() end
if EN.Spinbot then startSpinbot() end
if EN.TPDown then startTPDown() end

if EN.MobileSupport then
local gui = PlayerGui:FindFirstChild("PlasmaMobileButtons")
if gui then gui.Enabled = true end
end

if EN.AutoStart then
local menu = PlayerGui:FindFirstChild("AutoStartMenu")
if menu then menu.AutoStartMenuFrame.Visible = true end
end

-- Ensure one-time actions don't fire on inject to avoid random bouncing/chat messages
local resetOneTime = {"Drop", "Taunt", "TPBrainrot"}
for _, k in ipairs(resetOneTime) do
if EN[k] then
EN[k] = false
if VisualSetters[k] then VisualSetters[k](false) end
end
end
end)

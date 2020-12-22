local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local NPCProperties = require(script.Parent["Npc Properties"])
local NPCData = require(script.Parent["Npc Data"])
local StateHandler = require(ServerScriptService.SERVER.PlayerStates.StateHandler)

local NpcStorage = NPCProperties.Storage or ServerStorage.NPCS

local AggressiveMobs = {}
local PassiveMobs = {}

--|| Functions ||--
local MobCount = 0
local Methods = {}
Methods.__index = Methods

local function setCollisionGroup(Model, Group)
	if Model:IsA("Model") then
		local ModelDescendants = Model:GetDescendants()
		for i = 1 , #ModelDescendants do
			local Part = ModelDescendants[i]
			if Part:IsA("BasePart") then
				PhysicsService:SetPartCollisionGroup(Part, Group)
			end
		end
	else
		PhysicsService:SetPartCollisionGroup(Model, Group)
	end
end

local function LoadAnimations(AnimatorObj, AnimTable, Anims)
	for Name, Anim in next, Anims do
		if type(Anim) == "table" then
			AnimTable[Name] = {}
			LoadAnimations(AnimatorObj, AnimTable[Name], Anim)
		else
			local Animation = Instance.new("Animation")
			Animation.AnimationId = Anim
			AnimTable[Name] = AnimatorObj:LoadAnimation(Animation)
			Animation:Destroy()
		end
	end
end

local function tableCopy(Table)
	local Table2 = {}
	for Index, Value in next, Table do
		if type(Value) == "table" then
			Table2[Index] = tableCopy(Value)
		else
			Table2[Index] = Value
		end
	end
	return Table2
end

local function Death(NPC)
	wait(NPCData[NPC.Name].RespawnTime)
	if NPCData[NPC.Name].CustomDeath then
		NPCData[NPC.Name].CustomDeath()
		if NPC.Model then
			NPC.Model:Destroy()
		end
	end
	NPC:Respawn()
end

function Methods.new(Mob, Cframe)
	if not NPCData[Mob] or not NpcStorage:FindFirstChild(Mob) then warn("Mob not found in either the fodler or the data module") end

	--|| Setting up the animator and preparing the NPC ||--
	if not NpcStorage[Mob].Humanoid:FindFirstChild("Animator") then
		local Animator = Instance.new("Animator")
		Animator.Parent = NpcStorage[Mob].Humanoid
	end
	local NPC = NpcStorage[Mob]:Clone()
	NPC:SetPrimaryPartCFrame(Cframe)

	NPC.Humanoid.MaxHealth = NPCData[Mob].Health
	NPC.Humanoid.Health = NPCData[Mob].Health
	NPC.Humanoid.WalkSpeed = NPCData[Mob].WalkSpeed
	NPC.Humanoid.JumpPower = NPCData[Mob].JumpPower

	local BG = Instance.new("BodyGyro")
	BG.MaxTorque = Vector3.new(1,1,1) * 5e+5
	BG.D = 300
	BG.P = 2000
	BG.Name = "Orientator"
	BG.Parent = NPC.HumanoidRootPart
	
	StateHandler:New(NPC)
	StateHandler:ChangeValue(NPC,"Tag",true)
	
	if not NPCProperties.SelfCollision then
		setCollisionGroup(NPC, "NPCs")
	end

	for i = 1, #NPCProperties.DisabledHumanoidStates do
		local State = NPCProperties.DisabledHumanoidStates[i]
		NPC.Humanoid:SetStateEnabled(State, false)
	end
	
	

	--|| MetaTable voodoo stuffs ||--

	local Data = {}

	Data.Animations = {}
	local Animations = NPCData[Mob].Animations or {}
	NPC.Parent = workspace:FindFirstChild("Entities") or workspace
	LoadAnimations(NPC.Humanoid.Animator, Data.Animations, Animations)
	Data.Animations.Idle:Play()

	Data.Rewards = tableCopy(NPCData[Mob].Rewards)
	Data.lastUpdate = os.clock()
	Data.CFrame = Cframe
	Data.Name = Mob
	Data.lastAttack = os.clock()
	Data.lastCombo = 1
	Data.Model = NPC
	MobCount += 1
	Data.Id = MobCount
	Data.Dead = false
	Data.Connection = false

	local newNPC = setmetatable(Data, Methods)

	if NPCData[Mob].PassiveAggressive then
		AggressiveMobs[newNPC] = NPC
	else
		PassiveMobs[newNPC] = NPC
	end
	
	--|| Respawn stuff ||--
	newNPC.Connection = NPC.Humanoid.Died:Connect(function()
		wait(NPCData[Mob].RespawnTime)
		Data.Dead = true
		--Death(newNPC)
		--newNPC.Connection:Disconnect()
	end)

	return newNPC
end

function Methods:changeState(Data, State)
	if State == "Aggressive" then
		if PassiveMobs[self] then
			PassiveMobs[self] = nil
		end

		AggressiveMobs[self] = Data
	else
		if AggressiveMobs[self] then
			AggressiveMobs[self] = nil
		end

		PassiveMobs[self] = Data
	end
end

function Methods:getState()
	return (PassiveMobs[self] and "Passive") or (AggressiveMobs[self] and "Aggressive")
end

function Methods:Respawn()
	self = Methods.new(self.Name, self.CFrame)
end

return Methods

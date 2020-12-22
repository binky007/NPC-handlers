--|| Services ||--
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

--|| Physics ||--
PhysicsService:CreateCollisionGroup("NPCs")
PhysicsService:CollisionGroupSetCollidable("NPCs", "NPCs", false)

--|| Modules ||--
local NPCProperties = require(script["Npc Properties"])
local NPCMethods = require(script["Npc Methods"])
local NPCData = require(script["Npc Data"])

local StateHandler = require(ServerScriptService.SERVER.PlayerStates.StateHandler)
local DamageHandler = require(ServerScriptService.SERVER.Damage.DamageHandler)

local SavedSpawners = {}
local SavedNPCS = {}

local NonLoadedNPC = Instance.new("Folder")
NonLoadedNPC.Parent = game.ReplicatedStorage
NonLoadedNPC.Name = "NonLoadedNPCs"

local function ClosestEnemy(Origin, Radius)
	local Closest
	local PlayersTable = Players:GetPlayers()
	for i = 1, #PlayersTable do
		local Player = PlayersTable[i]
		local Character = Player.Character
		if Character and Character:FindFirstChild("HumanoidRootPart") and Character.Humanoid.Health >= 1 then
			local Distance = (Character.HumanoidRootPart.Position - Origin).Magnitude
			Closest = not Closest and {Character, Distance} or Distance < Closest[2] and {Character, Distance}
		end
	end
	if Closest and Closest[2] < Radius then
		return unpack(Closest)
	end
end

local function Visible(Origin, Radius)
	local PlayersTable = Players:GetPlayers()
	for i = 1, #PlayersTable do
		local Player = PlayersTable[i]
		local Character = Player.Character
		if Character and Character:FindFirstChild("HumanoidRootPart") then
			local Distance = (Character.HumanoidRootPart.Position - Origin).Magnitude
			if Distance < Radius then
				return true
			end
		end
	end
	return false
end

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

function Cast(Start, End, Ignore, Filter, Water)
	local Dir = (End - Start).Unit
	local Distance = (End-Start).Magnitude

	local Params = RaycastParams.new()
	Params.FilterDescendantsInstances = Ignore or {}
	Params.FilterType = Filter or Enum.RaycastFilterType.Blacklist
	Params.IgnoreWater = Water or true

	return workspace:Raycast(Start, Dir * Distance, Params)
end

local Spawners = (NPCProperties.Directory or Instance.new("Folder",workspace)):GetChildren()
for i = 1, #Spawners do
	local Folder = Spawners[i]
	local NPCName = Folder.Name

	SavedSpawners[Folder] = {}

	local SpawnFolder = SavedSpawners[Folder]

	SavedNPCS[Folder] = {}

	local NPCFolder = SavedNPCS[Folder]
	local Kids = Folder:GetChildren()
	for y = 1, #Kids do
		local Spawner = Kids[y]
		SpawnFolder[Spawner] = 0
		NPCFolder[Spawner] = {}
		for x = 1, NPCData[NPCName].StartingQuantity do
			local RandomPos = Spawner.Position + Vector3.new( math.random(-Spawner.Size.X/2, Spawner.Size.X/2), 0,  math.random(-Spawner.Size.Z/2, Spawner.Size.Z/2))
			local RayResult = Cast(RandomPos, RandomPos - Vector3.new(0, 100, 0), {NPCProperties.Directory})
			if RayResult then
				local NPC = NPCMethods.new(NPCName, CFrame.new(RayResult.Position)* CFrame.fromEulerAnglesXYZ(0,math.random(-360,360),0))
				NPCFolder[Spawner][NPC.Id] = NPC
			end
		end
	end
end

while true do
	for NPCName, Spawns in next, SavedNPCS do
		for Spawner, NPCs in next, Spawns do
			for Thing, NPC in next, NPCs do
				if NPC.Dead then
					local OldNPC = NPC
					NPCs[Thing] = NPCMethods.new(OldNPC.Name, OldNPC.CFrame)
					if OldNPC.Model then
						OldNPC.Model:Destroy()
					end
					NPC = NPCs[Thing]
				else
					local InRange = Visible(NPC.Model.HumanoidRootPart.Position, NPCProperties.VisibleRange)
					if InRange then
						NPC.Model.Parent = workspace:FindFirstChild("Entities") or workspace
					else
						NPC.Model.Parent = NonLoadedNPC
					end

					local NPCTing = NPCName.Name
					if os.clock() - NPC.lastUpdate >= NPCData[NPCTing].UpdateInterval and NPC:getState() == "Aggressive"  or (NPC.Model.Humanoid.Health > 0 and NPC.Model.Humanoid.Health < NPC.Model.Humanoid.MaxHealth) then --and NPC:getState() == "Aggressive"
						NPC.lastUpdate = os.clock()

						local Target, Distance = ClosestEnemy(NPC.Model.HumanoidRootPart.Position, NPCData[NPCTing].ScoutRange)
						if Target then
							local UnitVector = (Target.HumanoidRootPart.Position - NPC.Model.HumanoidRootPart.Position).Unit
							local NPCLook = NPC.Model.HumanoidRootPart.CFrame.LookVector
							local DotVector = UnitVector:Dot(NPCLook)
							
							--print(StateHandler:CheckValue(NPC.Model,"Stunned"))
							if StateHandler:CheckValue(NPC.Model,"Stunned") then
								if Distance <= NPCData[NPCTing].AttackRange and DotVector > .5 and os.clock() - NPC.lastAttack >= NPCData[NPCTing].AttackSpeed then
									NPC.Model.HumanoidRootPart.Orientator.CFrame = CFrame.new(NPC.Model.HumanoidRootPart.Position, Target.HumanoidRootPart.Position)
									--print("passed state check")
									NPC.Animations.Walk:Stop()

									if NPCData[NPCTing].CustomAttack then
										NPCData[NPCTing].AttackFunction(NPC, Target)
									else
										DamageHandler.Damage(Target.Humanoid,NPC.Model.Humanoid)
										
										if NPCData[NPCTing].RandomizedAttack then
											local RandomAnim = NPC.Animations.Attack[math.random(1, #NPC.Animations.Attack)]
											RandomAnim:Play()
										else
											NPC.lastCombo += 1
											if NPC.lastCombo >= #NPC.Animations.Attack then
												NPC.lastCombo = 1
												NPC.Model.Humanoid.WalkSpeed = 8
												delay(.3, function()
													NPC.Model.Humanoid.WalkSpeed = NPCData[NPCTing].WalkSpeed
												end)
												NPC.lastAttack = os.clock() + .5
											end
											local Animation = NPC.Animations.Attack[NPC.lastCombo]
											Animation:Play()
										end
									end
									NPC.lastAttack = os.clock()
								else
									if not NPC.Animations.Walk.IsPlaying then
										NPC.Animations.Walk:Play()
									end
									NPC.Model.Humanoid:MoveTo(Target.HumanoidRootPart.Position)
									NPC.Model.HumanoidRootPart.Orientator.CFrame = CFrame.new(NPC.Model.HumanoidRootPart.Position, Target.HumanoidRootPart.Position)

								end
							end
						end
					end
				end
			end
		end 
	end
	wait()
end

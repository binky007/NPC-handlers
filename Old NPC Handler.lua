--| Services |--
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--| Modules |--
local npcData = require(script["NPC Data"])
local npcProperties = require(script["NPC Properties"])
local npcLibrary = require(script["NPC Library"])

local Targets = {}

Players.PlayerAdded:Connect(function(Player)
	Targets[Player] = {}
	Player.CharacterAdded:Connect(function(Character)
		Targets[Player] = {}
	end)
end)

local updateTime = .25
local lastUpdate = tick()

--> Startup
npcLibrary:spawnNpcs()
npcLibrary:logPreloadedNpcs()

local function freezeNpc(NPC, data)
	if data.Animations.Walk.IsPlaying then
		data.Animations.Walk:Stop()
	end
	NPC["AlignOrientation"].Attachment1 = nil
	NPC.HumanoidRootPart.Anchored = true
end

local function checkForAssignedTarget(NPC)
	for Player, List in next, Targets do
		if List[NPC] then
			return Player
		end
	end
end

local function determineAction(NPC, data, Target, Distance)
	NPC.HumanoidRootPart.Anchored = false
	
	if Players[Target.Name].States.Pickedup.Value then
		Targets[Players[Target.Name]][NPC] = nil
	end
	
	if Distance <=npcData[NPC.Name].AttackRange + 1.5 then
		npcLibrary:attack(NPC, data, Target)
	elseif Distance <= npcData[NPC.Name].ScoutRange then
		if npcProperties.lockedTargets then
			Targets[Players:GetPlayerFromCharacter(Target)][NPC] = true
		end
		npcLibrary:move(NPC, data, Target, Distance)
	else
		if data.Animations.Walk.IsPlaying then
			data.Animations.Walk:Stop()
		end
	end
end

coroutine.wrap(function()
	while true do
		RunService.Stepped:Wait()
		if tick() - lastUpdate >= updateTime then
			lastUpdate = tick()
			local agressiveMobs = npcLibrary:getAgressiveMobs()
			local passiveMobs = npcLibrary:getPassiveMobs()
			
			--> loop through aggressive mobs
			for NPC, Data in next, agressiveMobs do
				if tick() - Data.lastUpdate >= npcData[NPC.Name].UpdateInterval and not Data.pathfinding then
					Data.lastUpdate = tick()
					
					if npcProperties.lockedTargets then
						local assignedTarget = checkForAssignedTarget(NPC)
						
						if assignedTarget and assignedTarget.Character and assignedTarget.Character:FindFirstChild("HumanoidRootPart") then
							local distance = (assignedTarget.Character.HumanoidRootPart.Position - NPC.HumanoidRootPart.Position).magnitude
							determineAction(NPC, Data, assignedTarget.Character, distance)
						elseif assignedTarget == nil then
							local closestEnemy, distance = npcLibrary:getClosestEnemy(NPC)
							if closestEnemy and distance <= npcData[NPC.Name].ScoutRange then
								Targets[Players:GetPlayerFromCharacter(closestEnemy)][NPC] = true
								npcLibrary:move(NPC, Data, closestEnemy, distance)
							elseif Data.Animations.Walk.IsPlaying then
								Data.Animations.Walk:Stop()
							end
						end
					elseif not npcProperties.lockedTargets then
						local closestEnemy, distance = npcLibrary:getClosestEnemy(NPC)
						--> If closest enemy
						if closestEnemy then
							if distance <= npcData[NPC.Name].ScoutRange * 4 then
								determineAction(NPC, Data, closestEnemy, distance)
							else
								freezeNpc(NPC, Data)
							end
						else
							freezeNpc(NPC, Data)
						end
					end
				end
			end
			for NPC, Data in next, passiveMobs do
				if tick() - Data.lastUpdate >= npcData[NPC.Name].UpdateInterval and not Data.pathfinding then
					Data.lastUpdate = tick()
					
					local closestEnemy, distance = npcLibrary:getClosestEnemy(NPC)
					if closestEnemy then
						if distance <= npcData[NPC.Name].ScoutRange * 4 then
							NPC.HumanoidRootPart.Anchored = false
						else
							NPC.HumanoidRootPart.Anchored = true
						end
					end
				end
			end
		end
	end
end)()


return Targets

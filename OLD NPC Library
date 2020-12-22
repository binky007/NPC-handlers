local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local npcProperties = require(script.Parent["NPC Properties"])
local npcData = require(script.Parent["NPC Data"])
local Globalfunctions = require(ReplicatedStorage.GlobalFunctions)

local npcFolderDirectory = ServerStorage.NPCS

local module = {}

local agressiveMobs = {}
local passiveMobs = {}

local newFolder = Instance.new("Folder")
newFolder.Name = "NPCAnimationStorage"
newFolder.Parent = ServerStorage

function module:preloadAnimations(Mob, anims)
	if not newFolder:FindFirstChild(Mob) then
		local Storage = Instance.new("Folder")
		Storage.Name = Mob
		Storage.Parent = newFolder
	end
	
	for index, Value in next, anims do
		if not newFolder[Mob]:FindFirstChild(index) then
			if typeof(Value) == "table" then
				module:preloadAnimations(Mob, Value)
			else
				local newAnim = Instance.new("Animation")
				newAnim.AnimationId = Value
				newAnim.Name = index
				newAnim.Parent = newFolder[Mob]
			end
			
		end
	end
end

function module.new(Mob, Cframe)
	if npcFolderDirectory then
		if npcFolderDirectory:FindFirstChild(Mob) then
			local newNPC = npcFolderDirectory[Mob]:Clone()
			for i = 1, #npcProperties.DisabledHumanoidStates do
				newNPC.Humanoid:SetStateEnabled(npcProperties.DisabledHumanoidStates[i], false)
			end
			newNPC.Humanoid.MaxHealth = npcData[Mob].Health
			newNPC.Humanoid.Health = newNPC.Humanoid.MaxHealth
			newNPC.Humanoid.WalkSpeed = npcData[Mob].WalkSpeed
			newNPC.Humanoid.JumpPower = npcData[Mob].JumpPower
			newNPC:SetPrimaryPartCFrame(Cframe * CFrame.new(0,newNPC.HumanoidRootPart.Size.y/2, 0))
			newNPC.Parent = npcData[Mob].Parent or game.Workspace
			
			local Part = Instance.new("Part")
			Part.Anchored = true
			Part.CanCollide = false
			Part.Transparency = 1
			Part.CFrame = Cframe
			Part.Name = "Guidence Part"
			Part.Parent = newNPC
			
			local Attachment = Instance.new("Attachment")
			Attachment.Parent = Part
			
			local CoreAttachment = Instance.new("Attachment")
			CoreAttachment.Parent = newNPC.HumanoidRootPart
			
			local AlignOrientation = Instance.new("AlignOrientation")
			AlignOrientation.Responsiveness = 100
			AlignOrientation.MaxTorque = 100000
			AlignOrientation.Attachment0 = CoreAttachment
			AlignOrientation.PrimaryAxisOnly = true
			AlignOrientation.Parent = newNPC
			
			local newNpcData = {}
			newNpcData.Animations = {}
			newNpcData.lastUpdate = tick()
			newNpcData.lastAttackAnim = 1
			newNpcData.lastAttack = tick()
			newNpcData.pathFinding = false
			
			module:preloadAnimations(Mob, npcData[Mob].Animations)
			newNpcData.Animations["Walk"] = newNPC.Humanoid:LoadAnimation(newFolder[Mob]["Walk"])
			newNpcData.Animations["Idle"] = newNPC.Humanoid:LoadAnimation(newFolder[Mob]["Idle"])
			newNpcData.Animations["Attack"] = {}
			
			for i =1 ,#npcData[Mob].Animations.Attack do
				newNpcData.Animations.Attack[i] = newNPC.Humanoid:LoadAnimation(newFolder[Mob][i])
			end
			
			newNpcData.Animations.Idle:Play()
			
			if npcData[Mob].PassiveAgressive then
				module:setState(newNPC, newNpcData, "Aggressive")
			else
				module:setState(newNPC, newNpcData, "Passive")
			end
			
			local HealthChange
			HealthChange = newNPC.Humanoid.HealthChanged:Connect(function(Health)
				
				module:setState(newNPC, newNpcData, "Aggressive")
				
				if Health <= 0 then
					HealthChange:Disconnect()
					HealthChange = nil
					module:death(newNPC, Cframe, Mob)
				end
			end)
		else
			warn("[NPC HANDLER]: ".. Mob.. "was not found in the npc directory")
		end
	else
		warn("[NPC HANDLER]: There was no npc directory set")
	end
end

function module:spawnNpcs()
	for npc, Data in next, npcData do
		print(npc)
		if Data.SpawnPart and Data.StartingQuantity > 0 then
			if Data.SpawnPart:IsA("Folder") then
				for _, spawnPart in next, Data.SpawnPart:GetChildren() do
					for i = 1, Data.StartingQuantity do
						local position = spawnPart.Position + Vector3.new(Globalfunctions.generateRandomNumber(-spawnPart.Size.X/2, spawnPart.Size.X/2, 1), spawnPart.Size.Y/2, Globalfunctions.generateRandomNumber(-spawnPart.Size.Z/2, spawnPart.Size.Z/2, 1) )
						local endPos = position - Vector3.new(0,200,0)
						
						local ray = Ray.new(position, (endPos - position).Unit * 200)
						local hit, pos = game.Workspace:FindPartOnRayWithIgnoreList(ray, {})
						if hit then
							module.new(npc, CFrame.new(pos) * CFrame.fromEulerAnglesXYZ(0, math.random(-360, 360), 0))
						else
							module.new(npc, CFrame.new(position) * CFrame.fromEulerAnglesXYZ(0, math.random(-360, 360), 0))
						end
					end
				end
	
			end
		else
			warn("[NPC HANDLER]: There was no spawn part set for ".. npc)
		end
	end
end

function module:getClosestEnemy(entity)
	local closest, distance = nil, nil
	for _, Player in next, Players:GetChildren() do
		if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character.Humanoid.Health > 0 then
			if entity:FindFirstChild("HumanoidRootPart") and Player:FindFirstChild("States") then
				local distanceFromEnemy = (Player.Character.HumanoidRootPart.Position - entity.HumanoidRootPart.Position).magnitude
				if closest == nil then
					closest = Player.Character
					distance = distanceFromEnemy
				elseif distanceFromEnemy < distance then
					closest = Player.Character
					distance = distanceFromEnemy
				end
			end
		end
	end
	
	return closest, distance
end

function module:death(newNPC, Cframe, Mob)
	if agressiveMobs[newNPC] then
		agressiveMobs[newNPC] = nil
	elseif passiveMobs[newNPC] then
		passiveMobs[newNPC] = nil
	end
	local npcChildren = newNPC:GetDescendants()
	for i = 1, #npcChildren do
		if npcChildren[i]:IsA("BasePart") then
			local Particle = script["Fade Particle"]:Clone()
			Particle.Parent = npcChildren[i]
			Particle:Emit(50)
			npcChildren[i].Transparency = 1
			local Trans = TweenService:Create(npcChildren[i], TweenInfo.new(1, Enum.EasingStyle.Back), {Transparency = 1})
			Trans:Play()
			Trans:Destroy()
			coroutine.wrap(function()
				wait(Particle.Lifetime.Max)
				newNPC:Destroy()
			end)()
		elseif npcChildren[i]:IsA("Decal") then
			npcChildren[i].Transparency = 1
		elseif npcChildren[i]:IsA("BillboardGui") then
			npcChildren[i]:Destroy()
		end
	end
	
	if npcData[Mob].Respawn then
		wait(npcData[Mob].RespawnTime)
		module.new(Mob, Cframe)
	end
end

function module:attack(NPC, data, closestEnemy)
	if tick() - data.lastAttack >= npcData[NPC.Name].AttackSpeed then
		data.lastAttack = tick()
		
		if data.Animations.Walk.IsPlaying then
			data.Animations.Walk:Stop()
		end
		
		if npcData[NPC.Name].CustomAttack then
			npcData[NPC.Name].AttackFunction(NPC, closestEnemy)
		else
			if npcData[NPC.Name].RandomizedAttack then
				local randomAttack = data.Animations.Attack[math.random(1, #data.Animations.Attack)]
				randomAttack:Play()
			end
			NPC["Guidence Part"].CFrame = CFrame.new(NPC.PrimaryPart.Position, closestEnemy.HumanoidRootPart.Position) * CFrame.new(0, 0, -3)
			NPC["AlignOrientation"].Attachment1 = NPC["Guidence Part"].Attachment
			local Target = closestEnemy.Humanoid
			if Target and Target.Parent and Players:FindFirstChild(Target.Parent.Name) then
				closestEnemy.Humanoid:TakeDamage(npcData[NPC.Name].Attack)
			end
		end
	end
end

function module:move(NPC, data, closestEnemy, distance)
	if not data.Animations.Walk.IsPlaying then
		data.Animations.Walk:Play()
	end
	local startPos = NPC.HumanoidRootPart.Position
	local endPos = closestEnemy.HumanoidRootPart.Position
	local difference = (startPos - endPos)
	local dir = difference.Unit
	local Pos = (endPos + dir * npcData[NPC.Name].AttackRange)
	NPC["Guidence Part"].CFrame = CFrame.new(startPos, endPos) * CFrame.new(0, 0, -2)
	NPC.Humanoid:MoveTo(Pos)
end

function module:getPassiveMobs()
	return passiveMobs
end

function module:getAgressiveMobs()
	return agressiveMobs
end

function module:logPreloadedNpcs()
	for NPC, Data in next, npcData do
		if Data.Parent then
			for _, Model in next, Data.Parent:GetChildren() do
				if Model:IsA("Model") and Model.Name == NPC then
					module.new(Model.Name, Model.HumanoidRootPart.CFrame)
					Model:Destroy()
				end
			end
		end
	end
end

function module:setState(NPC, Data, State)
	if State == "Aggressive" then
		if passiveMobs[NPC] then
			passiveMobs[NPC] = nil
		end
		
		agressiveMobs[NPC] = Data
	elseif State == "Passive" then
		
		if agressiveMobs[NPC] then
			agressiveMobs[NPC] = nil
		end
		
		passiveMobs[NPC] = Data
		
	end
end
return module

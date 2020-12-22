local module = {}
module.Bandit = {
	Attack = 15,
	Health = 150,
	["AttackSpeed"] = 1.5,
	['AttackRange'] = 5,
	
	["PassiveAgressive"] = false,
	["ScoutRange"] = 60,
	["UpdateInterval"] = 1/30,
	
	["WalkSpeed"] = 18,
	["JumpPower"] = 50,
	
	["SpawnPart"] = game.Workspace.World.Spawners.BanditSpawners,
	["StartingQuantity"] = 40,
	["Parent"] = workspace.World.Characters,
	
	Rewards = {
		Yen = 100,
		Rewards = {}
	},
	Difficulty = "D",
	
	["Respawn"] = true,
	["RespawnTime"] = 5,
	
	["RandomizedAttack"] = true,
	
	Animations = {
		Idle = "",
		Walk = "",
		Attack = {""},
	},
	
	CustomAttack = false,
	CustomDeath = false,
	AttackFunction = function()
		-- For CustomAttack Setting
	end,
	
}

return module

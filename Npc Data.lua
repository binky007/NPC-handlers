return {
	TestDummy = {
		Damage = 5,
		Health = 150,
		["AttackSpeed"] = 1.5,
		['AttackRange'] = 5,

		["PassiveAggressive"] = false,
		["ScoutRange"] = 60,
		["UpdateInterval"] = 1/30,

		["WalkSpeed"] = 18,
		["JumpPower"] = 50,

		["StartingQuantity"] = 10,

		Rewards = {
			Yen = 100,
			Rewards = {
				["FireCast"] = 5/10,
			}
		},
		Difficulty = "D",

		["Respawn"] = true,
		["RespawnTime"] = 3,

		["RandomizedAttack"] = false,

		Animations = {
			Idle = "rbxassetid://4970066667",
			Walk = "rbxassetid://6015414126",
			Attack = {"rbxassetid://6009855983","rbxassetid://6009858577","rbxassetid://6009863013","rbxassetid://6009866918"}
			--Attack = {"rbxassetid://6011013547", "rbxassetid://6011015701", "rbxassetid://6011065572", "rbxassetid://6011068354" }, --rbxassetid://6011068354
		},

		CustomAttack = false,
		CustomDeath = false,
		AttackFunction = function()
			-- For CustomAttack Setting
		end,
	}
}

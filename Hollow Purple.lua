local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local COOLDOWN_TIME = 5
local DAMAGE_AMOUNT = 100
local PROJECTILE_DISTANCE = 250

local AbilityState = {
	Idle = "Idle",
	Casting = "Casting",
	Charging = "Charging",
	Releasing = "Releasing",
	Cooldown = "Cooldown"
}

local cooldowns = {}

-- Returns character, humanoid, and root if the character is valid
local function getCharacterData(player)
	if not player then return nil end

	local character = player.Character
	if not character then return nil end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not root then
		return nil
	end

	return {
		Character = character,
		Humanoid = humanoid,
		Root = root
	}
end

-- Checks and updates the server-side cooldown
local function canActivate(player)
	local lastUse = cooldowns[player]
	if lastUse and os.clock() - lastUse < COOLDOWN_TIME then
		return false
	end

	cooldowns[player] = os.clock()
	return true
end

-- Tracks temporary instances so they can be destroyed safely
local function createCleanupTracker()
	local tracker = {}

	function tracker:Add(instance)
		table.insert(self, instance)
	end

	function tracker:Cleanup()
		for _, obj in ipairs(self) do
			if obj and obj.Parent then
				obj:Destroy()
			end
		end
		table.clear(self)
	end

	return tracker
end

-- Collects all particle emitters under a model
local function collectEmitters(container)
	local emitters = {}
	for _, d in ipairs(container:GetDescendants()) do
		if d:IsA("ParticleEmitter") then
			table.insert(emitters, d)
		end
	end
	return emitters
end

-- Gradually tweens particle colors over time using Heartbeat
local function tweenEmitterColor(emitters, targetColor, duration)
	local elapsed = 0
	local connection

	connection = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		local alpha = math.clamp(elapsed / duration, 0, 1)
		local eased = alpha * alpha

		for _, emitter in ipairs(emitters) do
			local start = emitter.Color.Keypoints[1].Value
			local newColor = Color3.new(
				start.R + (targetColor.R - start.R) * eased,
				start.G + (targetColor.G - start.G) * eased,
				start.B + (targetColor.B - start.B) * eased
			)
			emitter.Color = ColorSequence.new(newColor)
		end

		if alpha >= 1 then
			connection:Disconnect()
		end
	end)
end

-- Applies damage once per character inside the hitbox
local function applyDamage(hitbox, sourceCharacter)
	local hitRegistry = {}

	for _, part in ipairs(workspace:GetPartsInPart(hitbox)) do
		local targetChar = part:FindFirstAncestorOfClass("Model")
		if targetChar and targetChar ~= sourceCharacter and not hitRegistry[targetChar] then
			local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
			if humanoid then
				hitRegistry[targetChar] = true
				humanoid:TakeDamage(DAMAGE_AMOUNT)
			end
		end
	end
end

local Remote = script:WaitForChild("ActivateAbility")

Remote.OnServerEvent:Connect(function(player)
	if not canActivate(player) then
		return
	end

	local data = getCharacterData(player)
	if not data then
		return
	end

	local character = data.Character
	local humanoid = data.Humanoid
	local root = data.Root

	local cleanup = createCleanupTracker()
	local currentState = AbilityState.Casting

	-- Prevents player movement during the ability
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.AutoRotate = false
	root.Anchored = true

	-- Ensures cleanup if the player dies mid-cast
	humanoid.Died:Connect(function()
		cleanup:Cleanup()
	end)

	local projectile = Instance.new("Part")
	projectile.Size = Vector3.new(4, 4, 8)
	projectile.Shape = Enum.PartType.Ball
	projectile.Material = Enum.Material.Neon
	projectile.Color = Color3.fromRGB(170, 0, 255)
	projectile.Anchored = true
	projectile.CanCollide = false
	projectile.CFrame = root.CFrame * CFrame.new(0, 0, -8)
	projectile.Parent = workspace
	cleanup:Add(projectile)

	currentState = AbilityState.Charging

	local chargeTween = TweenService:Create(
		projectile,
		TweenInfo.new(1.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
		{ Size = Vector3.new(10, 10, 20) }
	)
	chargeTween:Play()
	chargeTween.Completed:Wait()

	currentState = AbilityState.Releasing

	local targetCF = projectile.CFrame * CFrame.new(0, 0, -PROJECTILE_DISTANCE)
	local releaseTween = TweenService:Create(
		projectile,
		TweenInfo.new(0.5, Enum.EasingStyle.Linear),
		{ CFrame = targetCF }
	)
	releaseTween:Play()

	local hitbox = Instance.new("Part")
	hitbox.Size = Vector3.new(8, 8, PROJECTILE_DISTANCE)
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.Transparency = 1
	hitbox.CFrame = root.CFrame * CFrame.new(0, 0, -PROJECTILE_DISTANCE / 2)
	hitbox.Parent = workspace
	cleanup:Add(hitbox)

	applyDamage(hitbox, character)

	releaseTween.Completed:Wait()

	currentState = AbilityState.Cooldown

	cleanup:Cleanup()

	-- Restores player movement after the ability
	humanoid.WalkSpeed = 16
	humanoid.JumpPower = 50
	humanoid.AutoRotate = true
	root.Anchored = false
end)

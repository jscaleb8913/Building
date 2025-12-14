-- Local Script
local player = game.Players.LocalPlayer
local char = player.Character
local UIS = game:GetService("UserInputService")

local remote = script.RemoteEvent

local debounce = false 
local CD = 5 -- cooldown

UIS.InputBegan:Connect(function(play,chat)
	if chat then return end --checks if player is using chat, if yes, then nothing happens
		if play.KeyCode == Enum.KeyCode.Z then --otherwise the following happens (do i rlly have to explain all this T-T)
		if debounce == false then
		debounce = true 
		remote:FireServer() 
		wait(CD) 
		debounce = false 
		end
	end
end)

--Server Script
script.Parent.OnServerEvent:Connect(function(Player)
	local ts = game:GetService("TweenService")
	local RunService = game:GetService("RunService")
	local char = Player.Character
	local hum = char:WaitForChild("Humanoid")	
	local root = char:WaitForChild("HumanoidRootPart")

    -- freeze player
	hum.WalkSpeed = 0
	hum.JumpPower = 0
	hum.AutoRotate = false
	root.Anchored = true

    -- idk i aint explaining the functions (pls js approve :(  )
	local function emitOnce(particleParent)
		for _, descendant in ipairs(particleParent:GetDescendants()) do
			if descendant:IsA("ParticleEmitter") then
				descendant.Rate = 0
				descendant.Enabled = true
				descendant:Emit(1)
				task.wait(0.1)
				descendant.Enabled = false
			end
		end
	end

	local function tweenParticlesToMagenta(model, duration)
		local emitters = {}
		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("ParticleEmitter") then
				table.insert(emitters, descendant)
			end
		end

		local elapsed = 0
		local connection
		connection = RunService.Heartbeat:Connect(function(step)
			elapsed = elapsed + step
			local alpha = math.clamp(elapsed / duration, 0, 1)
			local alphaCurve = alpha^2

			for _, emitter in ipairs(emitters) do
				local startColor = emitter.Color.Keypoints[1].Value
				local targetColor = Color3.fromRGB(255, 0, 255)
				local newColor = Color3.new(
					startColor.R + (targetColor.R - startColor.R) * alphaCurve,
					startColor.G + (targetColor.G - startColor.G) * alphaCurve,
					startColor.B + (targetColor.B - startColor.B) * alphaCurve
				)
				emitter.Color = ColorSequence.new(newColor)
			end

			if alpha >= 1 then
				connection:Disconnect()
			end
		end)
	end

	local function tweenBeamToMagenta(attachment, duration)
		local beams = {}
		for _, descendant in ipairs(attachment:GetDescendants()) do
			if descendant:IsA("Beam") then
				table.insert(beams, descendant)
			end
		end

		local elapsed = 0
		local connection
		connection = RunService.Heartbeat:Connect(function(step)
			elapsed = elapsed + step
			local alpha = math.clamp(elapsed / duration, 0, 1)
			local alphaCurve = alpha^2

			for _, beam in ipairs(beams) do
				local startColor = beam.Color.Keypoints[1].Value
				local targetColor = Color3.fromRGB(255, 0, 255)
				local newColor = Color3.new(
					startColor.R + (targetColor.R - startColor.R) * alphaCurve,
					startColor.G + (targetColor.G - startColor.G) * alphaCurve,
					startColor.B + (targetColor.B - startColor.B) * alphaCurve
				)
				beam.Color = ColorSequence.new(newColor)
			end

			if alpha >= 1 then
				connection:Disconnect()
			end
		end)
	end

	local function tweenBeamToTransparency(attachment, duration)
		local beams = {}
		for _, descendant in ipairs(attachment:GetDescendants()) do
			if descendant:IsA("Beam") then
				table.insert(beams, descendant)
			end
		end

		local elapsed = 0
		local connection
		connection = RunService.Heartbeat:Connect(function(step)
			elapsed = elapsed + step
			local alpha = math.clamp(elapsed / duration, 0, 1)
			local alphaCurve = alpha^2

			for _, beam in ipairs(beams) do
				local startSeq = beam.Transparency
				local keypoints = {}

				for _, kp in ipairs(startSeq.Keypoints) do
					local newVal = kp.Value + (1 - kp.Value) * alphaCurve
					table.insert(keypoints, NumberSequenceKeypoint.new(kp.Time, newVal, kp.Envelope))
				end

				beam.Transparency = NumberSequence.new(keypoints)
			end

			if alpha >= 1 then
				connection:Disconnect()
			end
		end)
	end

    -- clone red
	local red = script["Reversal Red"]:Clone()
	red.CFrame = root.CFrame * CFrame.new(10, 0, 10)
	red.beamend.CFrame = CFrame.new(15, 0, 0)
	red.Parent = char
	task.wait()
	emitOnce(red)
	red.VFX_Attachment.Blackhole:Emit(1)
	wait(1)
    
    --clone blue
	local blue = script["Amplification Blue"]:Clone()
	blue.CFrame = root.CFrame * CFrame.new(-10, 0, 10)
	blue.beamend.CFrame = CFrame.new(-15, 0, 0)
	blue.Parent = char
	task.wait()
	emitOnce(blue)
	blue.VFX_Attachment.Blackhole:Emit(1)
	wait(2)

	local redTargetCF = red.CFrame * CFrame.new(-10, 0, 0)
	local blueTargetCF = blue.CFrame * CFrame.new(10, 0, 0)
	local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	local redTween = ts:Create(red, tweenInfo, {CFrame = redTargetCF})
	local blueTween = ts:Create(blue, tweenInfo, {CFrame = blueTargetCF})
    
    --da tweens
	tweenParticlesToMagenta(red, 3)
	tweenParticlesToMagenta(blue, 3)
	tweenBeamToMagenta(red.beamend, 3)
	tweenBeamToMagenta(blue.beamend, 3)
    
	redTween:Play()
	blueTween:Play()


    -- da HOLOW PURPLE MWAHAHAHAHAHAHA (cmon if u watched jjk u can understand)
	local hp = script["Hollow Purple"]:Clone()
	hp.Parent = char
	hp.CFrame = root.CFrame * CFrame.new(0, 0, 10)
	for _, descendant in ipairs(hp.fx:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			descendant.Enabled = false
		end
	end

	wait(2.5)

    --make blue and red peace out
	for _, descendant in ipairs(red.VFX_Attachment:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			descendant.Enabled = false
		end
	end
	for _, descendant in ipairs(blue.VFX_Attachment:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			descendant.Enabled = false
		end
	end

    --more tweens/functions and buncha yapping
	tweenBeamToTransparency(red.beamend, 1)
	tweenBeamToTransparency(blue.beamend, 1)
	task.wait(1) -- wait for fade to finish

	red.beamend["Images/0009"].Enabled = false
	blue.beamend["Images/0009"].Enabled = false
	blue.Attachment["Images/Absorb_Wind_3"].Enabled = false
	red.Attachment["Images/Absorb_Wind_3"].Enabled = false

	hp["Images/Fixed_129"].Enabled = false
	hp.CFrame = root.CFrame * CFrame.new(0,5,-10)
	hp["Images/Fixed_129"].Enabled = true

	wait(1)

    --da hp fx
	for _, descendant in ipairs(hp.fx:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			descendant:Emit(1)
		end
	end

	wait(3)

    --more tweens :D
	local hpTargetCF = hp.CFrame * CFrame.new(0, 0, -250)
	local hpTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local hpTween = ts:Create(hp, hpTweenInfo, {CFrame = hpTargetCF})
	hpTween:Play()

    -- the hitbox for dmg
	local hitbox = Instance.new("Part")
	hitbox.Parent = char
	hitbox.Size = Vector3.new(5, 5, 100)
	hitbox.CFrame = root.CFrame * CFrame.new(0, 0, -50)
	hitbox.CanCollide = false
	hitbox.Anchored = true
	hitbox.Transparency = 1
	hitbox.BrickColor = BrickColor.new("Bright blue")
	hitbox.Material = Enum.Material.Neon

    --another function
	local function damagePlayers()
		local hitChars = {}
		for _, obj in pairs(workspace:GetPartsInPart(hitbox)) do
			local enemyChar = obj.Parent
			if enemyChar and enemyChar ~= char and not hitChars[enemyChar] then
				local enemyHum = enemyChar:FindFirstChildOfClass("Humanoid")
				if enemyHum then
					hitChars[enemyChar] = true
					enemyHum.WalkSpeed = 0
					enemyHum.JumpPower = 0
					enemyHum.AutoRotate = false
					enemyHum:TakeDamage(100)
					task.wait(1)
				end
			end
		end
	end
	damagePlayers()

    --reset user stats
	for _, obj in pairs(workspace:GetPartsInPart(hitbox)) do
		local enemyChar = obj.Parent
		if enemyChar and enemyChar ~= char then
			local enemyHum = enemyChar:FindFirstChildOfClass("Humanoid")
			if enemyHum then
				enemyHum.WalkSpeed = 16 
				enemyHum.JumpPower = 50 
				enemyHum.AutoRotate = true
			end
		end
	end

	wait(2)

    --make everything peace out
	for _, obj in pairs({red, hp, blue, hitbox}) do
		obj:Destroy()
	end

	hum.WalkSpeed = 16
	hum.JumpPower = 50
	hum.AutoRotate = true
	root.Anchored = false
end)
-- yh PLEASE APPROVE IT PLEASE I FAILED SCRIPTER APPLICATION 5 TIMES ALREADY PLEASE APPROVE IT

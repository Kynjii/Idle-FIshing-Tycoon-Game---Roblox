local Emitter = {}

function Emitter.AttachElement(parent: Instance, element: "Hydro" | "Frostreed" | "Cinder" | "Mossy")
	local attachment = Instance.new("Attachment")
	attachment.Name = "Attachment"

	if element == "Hydro" then
		local water30 = Instance.new("ParticleEmitter")
		water30.Name = "Water30"
		water30.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(76, 130, 201)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(2, 234, 255)),
		})
		water30.EmissionDirection = Enum.NormalId.Right
		water30.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
		water30.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
		water30.Lifetime = NumberRange.new(1)
		water30.LightEmission = 1
		water30.LightInfluence = 1
		water30.LockedToPart = true
		water30.Rate = 1
		water30.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 3),
			NumberSequenceKeypoint.new(1, 3),
		})
		water30.Speed = NumberRange.new(0)
		water30.Texture = "rbxassetid://16866073152"
		water30.ZOffset = 5
		water30.Parent = attachment
	end

	attachment.Parent = parent
end

return Emitter

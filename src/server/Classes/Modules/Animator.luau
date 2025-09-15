local Animator = {}
Animator.Animations = {}

local animAssets = {
	["WaterBob"] = "rbxassetid://104615638615761",
}

function Animator.LoadAnimations()
	for k, v in pairs(animAssets) do
		local animation: Animation = Instance.new("Animation")
		animation.AnimationId = v
		animation.Name = k

		Animator.Animations[k] = animation
	end
end

function Animator.GetAnimation(name: string): Animation
	return Animator.Animations[name]
end

return Animator

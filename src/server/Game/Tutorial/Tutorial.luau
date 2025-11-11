local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataService = require(ServerScriptService.Server.Services.DataService)
local Trove = require(ReplicatedStorage.Packages.Trove)
local FFGEnum = require(ReplicatedStorage.Shared.Enums.FFGEnum)

-- //SECTION - Tagged Entities within Workspace
local taggedBoats = CollectionService:GetTagged("Boat")
local taggedTenders = CollectionService:GetTagged("Tender")
local taggedStorage = CollectionService:GetTagged("Storage")
local taggedHelperShops = CollectionService:GetTagged("HelperShop")
-- //!SECTION

local Tutorial = {}
Tutorial.PlayerProgress = {}
Tutorial.PlayerTrove = {} :: { [string]: typeof(Trove.new()) }

local function FindBoatPB(teamId: number): Model?
	for _, taggedBoat in ipairs(taggedBoats) do
		local taggedBoatTier = taggedBoat:GetAttribute(FFGEnum.ATTRIBUTES.Tier)
		local taggedBoatTeamId = taggedBoat:GetAttribute(FFGEnum.ATTRIBUTES.TeamId)
		if taggedBoatTeamId == teamId and taggedBoatTier == 1 then
			local pb = taggedBoat:FindFirstChild("Purchase_Button")
			return pb
		end
	end

	return nil
end

local function FindTenderPB(teamId: number): Model?
	for _, taggedTender in ipairs(taggedTenders) do
		local taggedTenderTier = taggedTender:GetAttribute(FFGEnum.ATTRIBUTES.Tier)
		local taggedTenderTeamId = taggedTender:GetAttribute(FFGEnum.ATTRIBUTES.TeamId)
		if taggedTenderTeamId == teamId and taggedTenderTier == 1 then
			local pb = taggedTender:FindFirstChild("Purchase_Button")
			return pb
		end
	end

	return nil
end

local function FindStoragePB(teamId: number): Model?
	for _, taggedStorageUnit in ipairs(taggedStorage) do
		local taggedStorageUnitTier = taggedStorageUnit:GetAttribute(FFGEnum.ATTRIBUTES.Tier)
		local taggedStorageUnitTeamId = taggedStorageUnit:GetAttribute(FFGEnum.ATTRIBUTES.TeamId)
		if taggedStorageUnitTeamId == teamId and taggedStorageUnitTier == 1 then
			local pb = taggedStorageUnit:FindFirstChild("Purchase_Button")
			return pb
		end
	end

	return nil
end

local function FindHelperShop(teamId: number): Model?
	for _, taggedHelperShop in ipairs(taggedHelperShops) do
		local taggedHelperShopTeamId = taggedHelperShop:GetAttribute(FFGEnum.ATTRIBUTES.TeamId)
		if taggedHelperShopTeamId == teamId then return taggedHelperShop end
	end

	return nil
end

local function AssignBeam(player: Player, purchaseButton: Model)
	if not player or not purchaseButton then return end

	local character = player.Character
	local partToConnect = purchaseButton.PrimaryPart

	if character and partToConnect then
		local att0 = Tutorial.PlayerTrove[player]:Add(Instance.new("Attachment"))
		local att1 = Tutorial.PlayerTrove[player]:Add(Instance.new("Attachment"))

		att0.Parent = character
		att1.Parent = partToConnect

		local beam = Tutorial.PlayerTrove[player]:Add(Instance.new("Beam"))
		beam.Attachment0 = att0
		beam.Attachment1 = att1

		-- appearance properties
		beam.Color = ColorSequence.new({ -- a color sequence shifting from white to blue
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 255)),
		})
		beam.LightEmission = 1 -- use additive blending
		beam.LightInfluence = 0 -- beam not influenced by light
		beam.Texture = "rbxassetid://114900646651073"
		beam.TextureMode = Enum.TextureMode.Wrap -- wrap so length can be set by TextureLength
		beam.TextureLength = 2 -- repeating texture is 1 stud long
		beam.TextureSpeed = 1.5 -- slow texture speed
		beam.Transparency = NumberSequence.new({ -- beam fades out at the end
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.8, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		beam.ZOffset = 0 -- render at the position of the beam without offset

		-- shape properties
		beam.FaceCamera = true -- beam is visible from every angle
		beam.Segments = 10 -- default curve resolution
		beam.Width0 = 5 -- starts big
		beam.Width1 = 1 -- ends small

		-- parent beam
		beam.Enabled = true
		beam.Parent = att0
	end
end

function Tutorial.Show(player: Player, teamId: number, stageProgress: number)
	if not player or not teamId or not stageProgress then return end

	if not Tutorial.PlayerTrove[player] then Tutorial.PlayerTrove[player] = Trove.new() end

	-- Remove existing attachments
	Tutorial.PlayerTrove[player]:Clean()

	local models = {
		[1] = function()
			return FindBoatPB(teamId)
		end,
		[2] = function()
			return FindTenderPB(teamId)
		end,
		[3] = function()
			return FindStoragePB(teamId)
		end,
		[4] = function()
			return FindHelperShop(teamId)
		end,
	}

	local stage = stageProgress or 1

	if stage then Tutorial.PlayerProgress[player] = stage end

	local purchaseButton = models[stage]()
	AssignBeam(player, purchaseButton)
end

function Tutorial.CheckTutorialState(player: Player, class): boolean
	if not DataService.CompletedTutorial(player) then
		-- If the class is either a building or not tier 1, return
		if class.Tier ~= 1 or class.Entity == FFGEnum.CLASS.ENTITY_NAME.Building then return false end

		local tutorialOrder = {
			[1] = FFGEnum.CLASS.ENTITY_NAME.Boat,
			[2] = FFGEnum.CLASS.ENTITY_NAME.Tender,
			[3] = FFGEnum.CLASS.ENTITY_NAME.PortStorage,
			[4] = FFGEnum.CLASS.ENTITY_NAME.Shop,
		}

		-- Check to see if the entity matches the correct stage
		local currentTutorialStage = DataService.CurrentTutorialStage(player)
		if currentTutorialStage then
			local currentTutorialEntity = tutorialOrder[currentTutorialStage + 1]
			if currentTutorialEntity and class.Entity == currentTutorialEntity then
				return true
			else
				return false
			end
		else
			if class.Entity == FFGEnum.CLASS.ENTITY_NAME.Boat then
				return true
			else
				return false
			end
		end
	else
		return true
	end
end

function Tutorial.Update(player: Player, teamId: number?)
	if not player or not teamId then return end

	if not Tutorial.PlayerProgress[player] then error("No player found in tutorial player progress") end

	local currentStage = Tutorial.PlayerProgress[player]
	local maxStage = 4

	if currentStage == maxStage then
		Tutorial.PlayerTrove[player]:Destroy()
		Tutorial.PlayerProgress[player] = nil
	else
		Tutorial.PlayerProgress[player] += 1
		Tutorial.Show(player, teamId, Tutorial.PlayerProgress[player])
		currentStage = Tutorial.PlayerProgress[player]
	end

	DataService.SaveTutorialState(player, currentStage)
end

return Tutorial

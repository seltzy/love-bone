
local SHARED = require("boner.shared");
local newBone = require("boner.bone");
local SKELETON_ROOT_NAME = SHARED.SKELETON_ROOT_NAME;

--[[
	Skeleton
	A simple containment data structure for bones, animations, and skins.
	Actors hold a reference to a skeleton, which defines what animations and skins it can use.
--]]
local MSkeleton = SHARED.Meta.Skeleton;
MSkeleton.__index = MSkeleton;
local function newSkeleton()
	local skeleton = setmetatable({}, MSkeleton);
	skeleton.BoneNames = {};
	skeleton.Bones = {};
	skeleton.Bones[SKELETON_ROOT_NAME] = newBone(SKELETON_ROOT_NAME);
	skeleton.RenderOrder = {};
	skeleton.Valid = true;
	return skeleton;
end

function MSkeleton:IsValid()
	return self.Valid;
end

-- Checks all bones to see if parents are valid, and populates children lists.
function MSkeleton:Validate()
	self.Valid = true;
	for boneName, bone in pairs(self.Bones) do
		local parentName = bone:GetParent();
		if (parentName) then
			if (not self.Bones[parentName]) then
				print("Validation failed: Could not find parent '" .. parentName .. "' for bone '" .. boneName .. "'");
				self.Valid = false;
				break;
			else
				local parent = self.Bones[parentName];
				parent.Children = parent.Children or {};
				print("Adding child",boneName,"to",parentName);
				table.insert(parent.Children, boneName);
			end
		elseif (boneName ~= SKELETON_ROOT_NAME) then
			print("Validation failed: No parent found for bone '" .. boneName .. "'");
			self.Valid = false;
			break;
		end
	end
	if (self.Valid) then
		self:BuildRenderOrder();
	end
	return self.Valid;
end

-- Adds a bone to the skeleton.
function MSkeleton:AddBone(boneObj)
	if (not boneObj:GetName()) then
		error("Attempt to add nameless bone!", 2);
	end
	if (not boneObj:GetParent()) then
		boneObj:SetParent(SKELETON_ROOT_NAME);
	end
	self.Bones[boneObj:GetName()] = boneObj;
	self.Valid = false;
end

-- Rebuilds the rendering order of bones based on their current layer.
function MSkeleton:BuildRenderOrder()
	-- TODO: Validate?
	self.RenderOrder = {};
	for boneName, bone in pairs(self.Bones) do
		local i = 1;
		for _, v in pairs(self.RenderOrder) do
			if (self.Bones[v]:GetLayer() <= bone:GetLayer()) then
				i = i + 1;
			end
		end
		table.insert(self.RenderOrder, i, boneName);
	end
end

function MSkeleton:GetBoneNames()
	-- TODO: Validate?
	return {unpack(self.RenderOrder)};
end

-- Get a bone object.
function MSkeleton:GetBone(boneName)
	-- TODO: Validate?
	return self.Bones[boneName];
end

function MSkeleton:GetBoneTree(name, t)
	-- TODO: Validate?
	t = t or {};
	table.insert(t, name);
	local children = self:GetBone(name).Children;
	if (not children or #children == 0) then
		return t;
	end
	for i = 1, #children do
		self:GetBoneTree(children[i], t);
	end
	return t;
end

-- Returns the skeleton bind pose.
function MSkeleton:GetBindPose()
	-- TODO: Validate?
	-- TODO: Cache this?
	local pose = {};
	for boneName, bone in pairs(self.Bones) do
		local keyframe = {};
		keyframe.time = 0;
		keyframe.rotation = bone:GetDefaultRotation();
		keyframe.translation = {bone:GetDefaultTranslation()};
		keyframe.scale = {bone:GetDefaultScale()};
		--print("BindPos:".. boneName ..":",keyframe.time, keyframe.rotation, "[" .. keyframe.translation[1] .. "," .. keyframe.translation[2] .. "]");
		pose[boneName] = keyframe;
	end
	return pose;
end

return newSkeleton;
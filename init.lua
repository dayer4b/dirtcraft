--- Dirtcraft
-- @license MIT License
-- @author Sunil Chopra
-- @contributors VorTechnix

-- Initialize API container
dirtcraft = {}

-- Get the master mod, node and item lists from minetest
local all_mods = minetest.get_modnames()
local all_nodes = minetest.registered_nodes

-- Index all_mods for later and remove default if present
all_mods_index = {}
for i,v in ipairs(all_mods) do
  all_mods_index[v]=i
end
table.remove(all_mods,all_mods_index["default"])

-- Make a table of the surface nodes we want to target
dirtcraft.surface = {
  "dirt"
}

-- Function to reject nodes by type
local function reject(str)
  local set = {
    "stair", "slab",
    "slope", "micro",
    "panel", "footsteps",
    "cube", "light"
  }
  for k,v in pairs(set) do
    if str:find(v) then
      return true
    end
  end
  return false
end

-- Make a filter function to isolate the nodes that
-- contain "with" and do not contain matches of the "reject" set
local function node_filter(list,search)
  local ret = {}
  for k,_ in pairs(list) do
    for _,v in pairs(search) do
      if k:find(v) and k:find("with") and not reject(k) then
        table.insert(ret,k)
      end
    end
  end
  return ret
end

-- Make a function to quickly register recipes
-- TODO: add entries to craft guide
function dirtcraft.stack_recipe(node_name, ingredient1, ingredient2)
  
  -- minetest.log("$Mod: Dirtcraft: " .. node_name .. " can now be made with " .. ingredient2)
  -- Dissable above when not testing.
  
  -- NOTE: I am using a shaped recipe because I don't want to overwrite some
  -- of the known shapeless recipes from ethereal, for example
  local recipe = {
    output = node_name,
    recipe = {
      {ingredient2},
      {ingredient1}
    }
  }
  minetest.register_craft(recipe)
end

-- Attempt to figure out a reasonable recipe for dirt based on
-- the provided mod_name and other_ingredient.  this relies on some standard
-- suffixes to invoke leaves, moss, grass, etc.
function dirtcraft.sloppy_dirt(dirt_name,second_ingredient)
  -- Make local copy of all_mods so that we don't remove items from the original
  local mod_temp = all_mods
  
  -- Get mod name from dirt_name
  local mod_name = dirt_name:gsub("^(.*):.*","%1")
  
  -- Get first ingredient from dirt_name
  local first_ingredient = dirt_name:gsub("^(.*)_with.*$","%1")
  
  -- If not second_ingredient get from mod_name
  if not second_ingredient then
    second_ingredient = dirt_name:gsub("^.*with_(.*)$","%1")
  end
  
  -- Suffix list
  local suffixes = {
    "",
    "_1","_2","_3","_4","_5",
    "_leaves", "_moss",
    "leaves","grass"
  }
  
  -- Table to contain the hierarchy of mods to search for a compatible
  -- second ingredient in
  local mod_choices = {mod_name}
  table.remove(mod_temp,all_mods_index[mod_name])
  if mod_name ~= "default" then
    table.insert(mod_choices,"default")
  end
  
  -- Look for second ingredient candidates in mod_choices
  local candidate = false
  for i=1, #mod_choices do
    for n=1, #suffixes do
      local second_name = mod_choices[i] .. ":" .. second_ingredient .. suffixes[n]
      
      -- only register the craft recipe if the other ingredient really exists
      if all_nodes[second_name] ~= nil then
        dirtcraft.stack_recipe(dirt_name, first_ingredient, second_name)
        candidate = true
      end
    end
  end
  -- If candidate not found in mod_choices search mod_temp
  if not candidate then
    for i=1, #mod_temp do
      for n=1, #suffixes do
        local second_name = mod_temp[i] .. ":" .. second_ingredient .. suffixes[n]
        
        -- only register the craft recipe if the other ingredient really exists
        if all_nodes[second_name] ~= nil then
          dirtcraft.stack_recipe(dirt_name, first_ingredient, second_name)
          candidate = true
        end
      end
    end
  end
  -- If candidate cannot be found return error
  if not candidate then
    -- minetest.log("$Mod: Dirtcraft: " .. dirt_name .. " recipe cannot be made. No second ingredient found.")
    -- Dissable above when not testing.
  end
  
end

-- When all mods are loaded run recipe generator --
-- NOTE: Recipe registration function must be run before all other
-- registered_on_mods_loaded functions so that new recipes are visible to
-- the other mods that have search functions in registered_on_mods_loaded
table.insert(minetest.registered_on_mods_loaded, 1, function()
  -- WARNING: IF YOU ARE READING THIS DO NOT USE THE LINE ABOVE IN YOUR CODE!
  -- Instead use minetest.register_on_mods_loaded(function()...end)
  -- or
  -- table.insert(minetest.registered_on_mods_loaded, 2, function()...
  
  -- Look through all available registered nodes to find dirt blocks and then try
  -- to figure out the other ingredient for the dirt based on the name
  local surface_nodes = node_filter(all_nodes,dirtcraft.surface)
  for k,v in pairs(surface_nodes) do
    dirtcraft.sloppy_dirt(v)
  end
  
end)


-- Special cases:
dirtcraft.stack_recipe("default:dirt_with_rainforest_litter","default:dirt","default:jungleleaves")
dirtcraft.stack_recipe("default:dirt_with_rainforest_litter","default:dirt","default:junglesapling")
dirtcraft.stack_recipe("default:dirt_with_coniferous_litter","default:dirt","default:pine_sapling")
dirtcraft.stack_recipe("default:dirt_with_coniferous_litter","default:dirt","default:pine_needles")

dirtcraft.sloppy_dirt("ethereal:prairie_dirt","orange")
dirtcraft.sloppy_dirt("ethereal:grove_dirt","banana")
dirtcraft.sloppy_dirt("ethereal:grove_dirt","olive")
dirtcraft.sloppy_dirt("ethereal:grove_dirt","lemon")

dirtcraft.stack_recipe("default:permafrost_with_moss","default:permafrost","default:mossycobble")
dirtcraft.stack_recipe("default:permafrost_with_stones","default:permafrost","default:gravel")

dirtcraft.stack_recipe("default:dirt","default:dry_dirt","bucket:bucket_water")
minetest.register_craft({
    type = "cooking",
    output = "default:dry_dirt",
    recipe = "default:dirt",
	cooktime = 2,
})

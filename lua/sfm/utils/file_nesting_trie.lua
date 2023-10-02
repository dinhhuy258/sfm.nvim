-- Reference: https://github.com/microsoft/vscode/blob/main/src/vs/workbench/contrib/files/common/explorerFileNestingTrie.ts

local SubstitutionType = {
  capture = "capture",
}

---@class SubstitutionString
---@field tokens {}
local SubstitutionString = {}
SubstitutionString.__index = SubstitutionString

---@param pattern string
---@return SubstitutionString
function SubstitutionString.new(pattern)
  local self = setmetatable({}, SubstitutionString)
  self.tokens = {}

  local last_index = 1
  local i = 0

  while true do
    i = string.find(pattern, "%$[{(](capture)[)}]", i + 1)
    if i == nil then
      break
    end

    local prefix = pattern:sub(last_index, i - 1)
    table.insert(self.tokens, prefix)

    table.insert(self.tokens, { capture = "capture" })

    last_index = i + #"capture" + 3
  end

  if last_index <= #pattern then
    local suffix = pattern:sub(last_index)
    table.insert(self.tokens, suffix)
  end

  return self
end

---@param capture string|nil
---@return string
function SubstitutionString:substitute(capture)
  local result_tokens = {}
  for _, token in ipairs(self.tokens) do
    if type(token) == "string" then
      table.insert(result_tokens, token)
    else
      local tokenType = token.capture
      if tokenType == SubstitutionType.capture then
        table.insert(result_tokens, capture or "")
      else
        error("Unknown substitution type: " .. tokenType)
      end
    end
  end

  return table.concat(result_tokens)
end

---@class SufTrie
---@field star SubstitutionString[]
---@field epsilon SubstitutionString[]
---@field map table<string, SufTrie>
---@field has_items boolean
local SufTrie = {}
SufTrie.__index = SufTrie

function SufTrie.new()
  local self = setmetatable({}, SufTrie)
  self.star = {}
  self.epsilon = {}
  self.map = {}
  self.has_items = false

  return self
end

---@param key string
---@param value string
function SufTrie:add(key, value)
  self.has_items = true

  if key == "*" then
    table.insert(self.star, SubstitutionString.new(value))
  elseif key == "" then
    table.insert(self.epsilon, SubstitutionString.new(value))
  else
    local tail = key:sub(-1) -- get last character
    local rest = key:sub(1, -2) -- get all but last character

    if tail == "*" then
      error("Unexpected star in SufTrie key: " .. key)
    else
      if not self.map[tail] then
        self.map[tail] = SufTrie.new()
      end

      self.map[tail]:add(rest, value)
    end
  end
end

---@param key string
---@return string[]
function SufTrie:get(key)
  local results = {}

  if key == "" then
    for _, ss in ipairs(self.epsilon) do
      table.insert(results, ss:substitute(nil))
    end
  end

  for _, ss in ipairs(self.star) do
    table.insert(results, ss:substitute(key))
  end

  local tail = key:sub(-1)
  local rest = key:sub(1, -2)
  if self.map[tail] ~= nil then
    for _, v in ipairs(self.map[tail]:get(rest)) do
      table.insert(results, v)
    end
  end

  return results
end

---@class PreTrie
---@field value SufTrie
---@field map PreTrie[]
local PreTrie = {}
PreTrie.__index = PreTrie

function PreTrie.new()
  local self = setmetatable({}, PreTrie)
  self.value = SufTrie.new()
  self.map = {}

  return self
end

---@param key string
---@param value string
function PreTrie:add(key, value)
  if key == "" or key:sub(1, 1) == "*" then
    self.value:add(key, value)
  else
    local head = key:sub(1, 1)
    local rest = key:sub(2)
    if not self.map[head] then
      self.map[head] = PreTrie.new()
    end

    self.map[head]:add(rest, value)
  end
end

---@param key string
---@return string[]
function PreTrie:get(key)
  local results = {}

  for _, v in ipairs(self.value:get(key)) do
    table.insert(results, v)
  end

  local head = key:sub(1, 1)
  local rest = key:sub(2)
  if self.map[head] then
    for _, v in ipairs(self.map[head]:get(rest)) do
      table.insert(results, v)
    end
  end

  return results
end

---@class FileNestingTrie
---@field root PreTrie
local FileNestingTrie = {}
FileNestingTrie.__index = FileNestingTrie

---@param config table<string, string[]>
---@return FileNestingTrie
function FileNestingTrie.new(config)
  local self = setmetatable({}, FileNestingTrie)
  self.root = PreTrie.new()

  for _, entry in ipairs(config) do
    local parent_pattern, child_patterns = entry[1], entry[2]
    for _, child_pattern in ipairs(child_patterns) do
      self.root:add(parent_pattern, child_pattern)
    end
  end

  return self
end

---@param files string[]
---@return table<string, string[]>
function FileNestingTrie:nest(files)
  local parent_finder = PreTrie.new()

  for _, potential_parent in ipairs(files) do
    local children = self.root:get(potential_parent)

    for _, child in ipairs(children) do
      parent_finder:add(child, potential_parent)
    end
  end

  local find_all_root_ancestors

  find_all_root_ancestors = function(file, seen)
    seen = seen or {}
    if seen[file] then
      return {}
    end
    seen[file] = true

    local ancestors = parent_finder:get(file)

    if #ancestors == 0 or (#ancestors == 1 and ancestors[1] == file) then
      return { file }
    end

    local result = {}
    for _, a in ipairs(ancestors) do
      local root_ancestors = find_all_root_ancestors(a, seen)

      for _, ra in ipairs(root_ancestors) do
        table.insert(result, ra)
      end
    end

    return result
  end

  local result = {}
  for _, file in ipairs(files) do
    local ancestors = find_all_root_ancestors(file)
    if #ancestors == 0 then
      ancestors = { file }
    end

    for _, ancestor in ipairs(ancestors) do
      if not result[ancestor] then
        result[ancestor] = {}
      end

      if file ~= ancestor then
        table.insert(result[ancestor], file)
      end
    end
  end

  return result
end

local M = {
  FileNestingTrie = FileNestingTrie,
  PreTrie = PreTrie, -- for testing only
  SufTrie = SufTrie, -- for testing only
}

return M

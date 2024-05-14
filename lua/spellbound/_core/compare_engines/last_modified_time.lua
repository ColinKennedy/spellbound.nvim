--- Compare the OS "last modified" time between the dictionary and its parts.
---
--- @module 'spellbound._core.compare_engines.last_modified_time'
---

local M = {}

--- Check the OS "last modified" time of `path`.
---
--- @param path string An absolute file path on-disk.
--- @return number? # The "last modified time", if any.
---
local function _get_last_modified_time(path)
  local stat = vim.uv.fs_stat(path)

  if stat then
    return stat.mtime.sec
  else
    return nil
  end
end

--- Check if `path` has any changes. Check the pre-computed SHA for differences.
---
--- @param data CompareData
---     Compare-related arguments (input files, the output dictionary, etc).
--- @return boolean
---     If there's no difference between `data` and its computed SHA, return `false`.
---     If `data` could use a re-build, return `true`.
---
function M.compare(data)
  local last_modified = _get_last_modified_time(data.dictionary)

  if not last_modified then
    return true
  end

  for _, path in ipairs(data.parts) do
    local path_modified = _get_last_modified_time(path)

    if not path_modified then
      return true
    end

    if path_modified > last_modified then
      return true
    end
  end

  return false
end

return M

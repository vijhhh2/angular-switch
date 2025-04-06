--- @class Buffer
--- @field name string
--- @field id number

--- Get all currently loaded buffers
--- @return Buffer[] buffers : A list of all currently loaded buffers
local get_all_buffers = function()
  -- get all buffers
  local buffers = vim.api.nvim_list_bufs() --nvim_buf_get_name

  -- get all loaded buffers
  local loaded_buffers = vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_loaded(buf)
  end, buffers)

  -- -- get loaded buffers names
  local raw_buffer_names = vim.tbl_map(function(buf)
    return {
      name = vim.api.nvim_buf_get_name(buf),
      id = buf,
    }
  end, loaded_buffers)

  -- filter out empty names
  local buffer_names = vim.tbl_filter(function(buf)
    return buf.name ~= "" and buf.name ~= nil
  end, raw_buffer_names)
  return buffer_names
end

--- Attach to a buffer by its path
--- It will create a new buffer if it doesn't exist
--- @param path string: path to the buffer
--- @return boolean: true if the buffer was created or attached to
local attach_to_buff = function(path)
  local buffer_names = get_all_buffers()
  local buff = vim.tbl_filter(function(buf)
    return buf.name == path
  end, buffer_names)
  if #buff > 0 then
    vim.api.nvim_set_current_buf(buff[1].id)
    return true
  end

  local new_buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(new_buf, path)
  vim.api.nvim_set_current_buf(new_buf)
  vim.api.nvim_buf_call(new_buf, vim.cmd.edit)
  return true
end

---Get the current active buffer's filename
---@return (string | nil), (string | nil), (string | nil), (string | nil): filename of the current buffer
local get_current_filename = function(default)
  local path = default or vim.api.nvim_buf_get_name(0)
  if path == "" then
    return nil, nil, nil, nil
  end
  local filename = vim.fs.basename(path)
  if filename == "" then
    return path, nil, nil, nil
  end

  local dir = vim.fs.dirname(path)

  local split = vim.split(filename, "%.")
  local count = vim.tbl_count(split)

  local ext = count == 3 and (split[count] or "") or (split[count - 1] .. "." .. split[count])
  return path, filename, ext, dir
end

---Get the current file's directory and list all files in within it
---@param dir string: path to the directory
---@return fun():string?, string? | nil: table A list of files in the directory
local get_current_dir_files = function(dir)
  if not dir or dir == "" then
    return nil
  end
  local files = vim.fs.dir(dir)
  return files
end

---Get the component file name based on the current file's extension
---@param filename string: name of the current file
---@param extension string: extension of the current file
---@param expected_ext string | table: expected extension[s] of the component file
---@return string | table: name of the component file
local get_component_file = function(filename, extension, expected_ext)
  if type(expected_ext) == "table" and vim.islist(expected_ext) then
    -- find a better way to do this
    -- Like parsing angular.json file
    local component_files = vim.tbl_map(function(ext)
      local f = filename:gsub("%." .. extension, "." .. ext)
      return f
    end, expected_ext)
    return component_files
  end

  local component_file = filename:gsub("%." .. extension, "." .. expected_ext)
  return component_file
end

--- Swithc to component ts file
--- @param dir string: path to the directory
--- @param filename string: name of the current file
--- @param extension string: extension of the current file
--- @param files table: list of files in the directory
local switch_to_ts_file = function(dir, filename, extension, files)
  local expected_ext = "ts"
  if extension == expected_ext then
    return
  end

  local component_ts_file = get_component_file(filename, extension, expected_ext)

  if not vim.tbl_contains(files, component_ts_file) then
    return
  end
  local path = vim.fs.normalize(vim.fs.joinpath(dir, component_ts_file))
  attach_to_buff(path)
  vim.print("switched to ts file: " .. component_ts_file)
end

--- Swithc to component spec ts file
--- @param dir string: path to the directory
--- @param filename string: name of the current file
--- @param extension string: extension of the current file
--- @param files table: list of files in the directory
local switch_to_html_file = function(dir, filename, extension, files)
  local expected_ext = "html"
  if extension == expected_ext then
    return
  end

  local component_html_file = get_component_file(filename, extension, expected_ext)

  if not vim.tbl_contains(files, component_html_file) then
    return
  end
  local path = vim.fs.normalize(vim.fs.joinpath(dir, component_html_file))
  attach_to_buff(path)
  vim.print("switched to html file: " .. component_html_file)
end

--- Swithc to component spec ts file
--- @param dir string: path to the directory
--- @param filename string: name of the current file
--- @param extension string: extension of the current file
--- @param files table: list of files in the directory
local switch_to_spec_ts_file = function(dir, filename, extension, files)
  local expected_ext = "spec.ts"
  if extension == expected_ext then
    return
  end

  local component_spec_ts_file = get_component_file(filename, extension, expected_ext)

  if not vim.tbl_contains(files, component_spec_ts_file) then
    return
  end

  local path = vim.fs.normalize(vim.fs.joinpath(dir, component_spec_ts_file))
  attach_to_buff(path)
  vim.print("switched to spec ts file: " .. component_spec_ts_file)
end

--- Swithc to component style file
--- @param dir string: path to the directory
--- @param filename string: name of the current file
--- @param extension string: extension of the current file
--- @param files table: list of files in the directory
local switch_to_style_file = function(dir, filename, extension, files)
  -- Angular components can have multiple style files.
  -- In feature we can cycle through all of them if there are multiple

  local expected_exts = { "css", "scss", "less", "sass" }
  if vim.tbl_contains(expected_exts, extension) then
    return
  end

  local component_style_file = get_component_file(filename, extension, expected_exts)

  -- Below code is there for to satisfy the types
  if type(component_style_file) == "string" then
    component_style_file = { component_style_file }
  end

  local correct_file
  for _, file in ipairs(component_style_file) do
    if vim.tbl_contains(files, file) then
      correct_file = file
      break
    end
  end

  if not correct_file then
    return
  end

  local path = vim.fs.normalize(vim.fs.joinpath(dir, correct_file))
  attach_to_buff(path)
  vim.print("switched to style file: " .. correct_file)
end

--- get the current file's name and list of files in the directory
local get_filename_and_files = function()
  local path, filename, extension, dir = get_current_filename()

  if not path or not filename or not dir then
    return
  end

  local files = get_current_dir_files(dir)
  if not files then
    return
  end

  local files_list = {}
  local pattern = vim.glob.to_lpeg("*.component.*")

  for file, type in files do
    if type == "file" and pattern:match(file) then
      table.insert(files_list, file)
    end
  end

  return dir, path, filename, extension, files_list
end

local M = {}

M.get_filename_and_files = get_filename_and_files
M.switch_to_style_file = switch_to_style_file
M.switch_to_ts_file = switch_to_ts_file
M.switch_to_spec_ts_file = switch_to_spec_ts_file
M.switch_to_html_file = switch_to_html_file

return M

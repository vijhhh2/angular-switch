local M = {}

local mapFn = function(list, fn)
  local result = {}
  for _, item in ipairs(list) do
    table.insert(result, fn(item))
  end
  return result
end

local filterFn = function(list, fn)
  local result = {}
  for _, item in ipairs(list) do
    if fn(item) then
      table.insert(result, item)
    end
  end
  return result
end

local get_all_buffers = function()
  -- get all buffers
  local buffers = vim.api.nvim_list_bufs() --nvim_buf_get_name

  -- get all loaded buffers
  local loaded_buffers = filterFn(buffers, function(buf)
    return vim.api.nvim_buf_is_loaded(buf)
  end)

  -- get loaded buffers names
  local raw_buffer_names = mapFn(loaded_buffers, function(buf)
    return {
      name = vim.api.nvim_buf_get_name(buf),
      id = buf,
    }
  end)

  -- filter out empty names
  local buffer_names = filterFn(raw_buffer_names, function(buf)
    return buf.name ~= "" and buf.name ~= nil
  end)

  return buffer_names
end

local attach_to_buff = function(path)
  local buffer_names = get_all_buffers()
  local buff = vim.tbl_filter(function(buf)
    return buf.name == path
  end, buffer_names)
  vim.print(buff)
  if #buff > 0 then
    vim.api.nvim_set_current_buf(buff[1].id)
    return
  end

  local new_buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(new_buf, path)
  vim.api.nvim_set_current_buf(new_buf)
  vim.api.nvim_buf_call(new_buf, vim.cmd.edit)
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

local get_component_file = function(filename, extension, expected_ext)
  vim.print("Filename: " .. filename)
  if vim.islist(expected_ext) then
    -- find a better way to do this
    -- Like parsing angular.json file
    local component_files = vim.tbl_map(function(ext)
      return filename:gsub("%." .. extension, "." .. ext)
    end, expected_ext)
    return component_files
  end
  local component_file = filename:gsub("%." .. extension, "." .. expected_ext)
  return component_file
end

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
end

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
end

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
end

local switch_to_style_file = function(dir, filename, extension, files)
  -- Angular components can have multiple style files.
  -- In feature we can cycle through all of them if there are multiple

  local expected_exts = { "css", "scss", "less", "sass" }
  if vim.tbl_contains(expected_exts, extension) then
    vim.print("Already in a style file: " .. filename, extension)
    return
  end

  local component_style_file = get_component_file(filename, extension, expected_exts)

  local correct_file
  for _, file in ipairs(component_style_file) do
    if vim.tbl_contains(files, file) then
      correct_file = file
      break
    end
  end

  if not correct_file then
    vim.print("No style file found for: " .. filename)
    vim.print(correct_file)
    return
  end

  local path = vim.fs.normalize(vim.fs.joinpath(dir, correct_file))
  attach_to_buff(path)
end

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

local test_setup = function()
  local dir, path, filename, extension, files_list = get_filename_and_files()
  if not dir or not path or not filename or not extension then
    return
  end

  switch_to_style_file(dir, filename, extension, files_list)

  -- vim.print(files_list)
  -- vim.print("Current file: " .. filename)
  -- vim.print("File extension: " .. extension)

  -- vim.print(
  --   switch_to_style_file(
  --     "/Users/QCXG63/Documents/learning/Angular/ngx-animejs/src/app/app.component.spec.ts",
  --     "app.component.html",
  --     "html",
  --     { "test.component.ts", "test.component.html", "app.component.css", "test.component.spec.ts" }
  --   )
  -- )
end

M.setup = function()
  vim.api.nvim_create_user_command("AsSwitchToStyles", function()
    local dir, path, filename, extension, files_list = get_filename_and_files()
    if not dir or not path or not filename or not extension then
      return
    end

    switch_to_style_file(dir, filename, extension, files_list)
  end, { desc = "Swith to component styles" })

  vim.api.nvim_create_user_command("AsSwitchToTs", function()
    local dir, path, filename, extension, files_list = get_filename_and_files()
    if not dir or not path or not filename or not extension then
      return
    end

    switch_to_ts_file(dir, filename, extension, files_list)
  end, { desc = "Swith to component typescript file" })

  vim.api.nvim_create_user_command("AsSwitchToSpec", function()
    local dir, path, filename, extension, files_list = get_filename_and_files()
    if not dir or not path or not filename or not extension then
      return
    end

    switch_to_spec_ts_file(dir, filename, extension, files_list)
  end, { desc = "Swith to component spec file" })

  vim.api.nvim_create_user_command("AsSwitchToHtml", function()
    local dir, path, filename, extension, files_list = get_filename_and_files()
    if not dir or not path or not filename or not extension then
      return
    end

    switch_to_html_file(dir, filename, extension, files_list)
  end, { desc = "Swith to component html" })
end

return M

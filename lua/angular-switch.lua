local as = require("as")

local M = {}

M.setup = function()
  vim.api.nvim_create_user_command("AsSwitchToStyles", function()
    local dir, path, filename, extension, files_list = as.get_filename_and_files()
    if not dir or not path or not filename or not extension then
      return
    end

    if not files_list then
      return
    end

    as.switch_to_style_file(dir, filename, extension, files_list)
  end, { desc = "Swith to component styles" })

  vim.api.nvim_create_user_command("AsSwitchToTs", function()
    local dir, path, filename, extension, files_list = as.get_filename_and_files()
    if not dir or not path or not filename or not extension then
      return
    end

    if not files_list then
      return
    end

    as.switch_to_ts_file(dir, filename, extension, files_list)
  end, { desc = "Swith to component typescript file" })

  vim.api.nvim_create_user_command("AsSwitchToSpec", function()
    local dir, path, filename, extension, files_list = as.get_filename_and_files()
    if not dir or not path or not filename or not extension then
      return
    end

    if not files_list then
      return
    end

    as.switch_to_spec_ts_file(dir, filename, extension, files_list)
  end, { desc = "Swith to component spec file" })

  vim.api.nvim_create_user_command("AsSwitchToHtml", function()
    local dir, path, filename, extension, files_list = as.get_filename_and_files()
    if not dir or not path or not filename or not extension then
      return
    end

    if not files_list then
      return
    end

    as.switch_to_html_file(dir, filename, extension, files_list)
  end, { desc = "Swith to component html" })
end

return M

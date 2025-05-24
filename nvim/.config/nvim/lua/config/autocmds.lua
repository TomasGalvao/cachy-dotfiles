-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
vim.api.nvim_create_user_command("MAutoformat", function(opts)
  local start_line = opts.line1
  local end_line = opts.line2
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)

  -- Step 1: Comment pragma lines
  for i, line in ipairs(lines) do
    if line:match("^%s*#pragma +omp") or line:match("^%s*#pragma +simd") then
      lines[i] = line:gsub("^(%s*)#pragma", "%1// #pragma")
    end
  end
  vim.api.nvim_buf_set_lines(bufnr, start_line - 1, end_line, false, lines)

  -- Step 2: Format using clang-format
  local tmpfile = "/tmp/nvim_format_temp.c"
  local formatted = vim.fn.system({
    "clang-format",
    "--assume-filename=" .. vim.fn.expand("%:t"),
  }, table.concat(lines, "\n"))

  if vim.v.shell_error ~= 0 then
    vim.api.nvim_err_writeln("clang-format failed")
    return
  end

  -- Step 3: Replace buffer lines with formatted output
  local new_lines = vim.split(formatted, "\n", { plain = true })
  vim.api.nvim_buf_set_lines(bufnr, start_line - 1, end_line, false, new_lines)

  -- Step 4: Uncomment pragma lines
  local final_lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
  for i, line in ipairs(final_lines) do
    if line:match("^%s*//%s*#pragma +omp") or line:match("^%s*//%s*#pragma +simd") then
      final_lines[i] = line:gsub("^(%s*)//%s*#pragma", "%1#pragma")
    end
  end
  vim.api.nvim_buf_set_lines(bufnr, start_line - 1, end_line, false, final_lines)
end, {
  range = true,
  desc = "Safe clang-format with pragma handling",
})

vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function()
    if vim.bo.filetype ~= "c" then
      vim.lsp.buf.format()
    else
      vim.cmd("1,$MAutoformat")
    end
  end,
})

function Sad(line_nr, from, to, fname)
  vim.cmd(string.format("silent !sed -i '%ss/%s/%s/' %s", line_nr, from, to, fname))
end

function IncreasePadding()
  Sad("22", 0, 15, "~/.config/alacritty/alacritty.toml")
  Sad("23", 0, 15, "~/.config/alacritty/alacritty.toml")
end

function DecreasePadding()
  Sad("22", 15, 0, "~/.config/alacritty/alacritty.toml")
  Sad("23", 15, 0, "~/.config/alacritty/alacritty.toml")
end

vim.cmd([[
  augroup ChangeAlacrittyPadding
   au!
   au VimEnter * lua DecreasePadding()
   au VimLeavePre * lua IncreasePadding()
  augroup END
]])

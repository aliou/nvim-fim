-- Keymap handling for nvim-codestral
-- Sets up keymaps for accepting/dismissing suggestions

local config = require('fim.config')
local suggestion = require('fim.suggestion')

local M = {}

--- Setup keymaps for suggestion handling
function M.setup()
  -- Set up Insert mode keymaps
  vim.api.nvim_create_autocmd({"BufEnter"}, {
    group = vim.api.nvim_create_augroup("FimKeymaps", { clear = true }),
    callback = function()
      M.setup_buffer_keymaps()
    end
  })
end

--- Setup buffer-specific keymaps
function M.setup_buffer_keymaps()
  local bufnr = vim.api.nvim_get_current_buf()
  local opts = { buffer = bufnr, silent = true }
  
  -- Accept suggestion
  if config.options.keymaps.accept then
    vim.keymap.set('i', config.options.keymaps.accept, function()
      if suggestion.state.suggestion and suggestion.state.suggestion ~= "" then
        suggestion.accept_suggestion()
      else
        -- Fallback to normal Tab behavior
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", true)
      end
    end, { buffer = bufnr, noremap = true, silent = true, desc = "Accept codestral suggestion" })
  end
  
  -- Accept word
  if config.options.keymaps.accept_word then
    vim.keymap.set('i', config.options.keymaps.accept_word, function()
      suggestion.accept_word()
    end, opts)
  end
  
  -- Accept line
  if config.options.keymaps.accept_line then
    vim.keymap.set('i', config.options.keymaps.accept_line, function()
      suggestion.accept_line()
    end, opts)
  end
  
  -- Dismiss suggestion
  if config.options.keymaps.dismiss then
    vim.keymap.set('i', config.options.keymaps.dismiss, function()
      suggestion.clear_suggestion()
    end, opts)
  end
  
  -- Trigger completion manually
  if config.options.keymaps.trigger then
    vim.keymap.set('i', config.options.keymaps.trigger, function()
      require('fim').trigger_completion()
    end, opts)
  end
end

return M
-- Configuration handling for nvim-fim
-- Provides defaults and validation

local M = {}

---@class FimConfig
---@field provider string Active provider name
---@field codestral table|nil Codestral provider config
---@field context {prefix_lines:number,suffix_lines:number,max_prefix_chars:number,max_suffix_chars:number}
---@field debounce_ms number Debounce time in milliseconds
---@field highlight string Highlight group for ghost text
---@field keymaps {accept:string|false,accept_word:string|false,accept_line:string|false,dismiss:string|false,trigger:string|false}
---@field disabled_filetypes string[] Filetypes to disable completions for

--- Default configuration
M.defaults = {
  provider = nil,  -- Must be set by user
  
  -- Codestral provider defaults
  codestral = {
    -- Default: read from ~/.local/share/nvim/fim/codestral/api_key
    -- Users can override with custom function or env var
    api_key_provider = function()
      local codestral = require('fim.providers.codestral')
      return codestral.default_api_key_provider()
    end,
    endpoint = "https://codestral.mistral.ai/v1/fim/completions",
    model = "codestral-latest",
    max_tokens = 256,
    stop = nil,
  },
  
  -- Universal settings (apply to all providers)
  context = {
    prefix_lines = 100,
    suffix_lines = 30,
    max_prefix_chars = 4000,
    max_suffix_chars = 1000,
  },
  
  debounce_ms = 50,
  
  highlight = "Comment",
  
  keymaps = {
    accept = "<Tab>",
    accept_word = "<C-Right>",
    accept_line = "<C-e>",
    dismiss = "<C-]>",
    trigger = "<C-Space>",
  },
  
  disabled_filetypes = {},
}

--- Current configuration
M.options = nil

--- Setup and validate configuration
---@param user_config table User configuration
function M.setup(user_config)
  -- Merge defaults with user config
  M.options = vim.tbl_deep_extend("force", M.defaults, user_config or {})
  
  -- Validate configuration
  M.validate()
end

--- Validate the current configuration
function M.validate()
  -- Validate provider is set
  if not M.options.provider or M.options.provider == "" then
    error("nvim-fim: provider must be specified (e.g., 'codestral')")
  end
  
  -- Validate provider exists
  local providers = require('fim.providers')
  local ok, err = providers.validate(M.options.provider)
  if not ok then
    error("nvim-fim: " .. err)
  end
  
  -- Validate provider-specific config
  local provider = providers.get(M.options.provider)
  if provider.validate_config then
    local ok, err = provider.validate_config(M.options[M.options.provider])
    if not ok then
      error("nvim-fim: " .. err)
    end
  end
  
  -- Validate universal context settings
  if M.options.context.prefix_lines <= 0 then
    error("nvim-fim: context.prefix_lines must be positive")
  end
  if M.options.context.suffix_lines < 0 then
    error("nvim-fim: context.suffix_lines must be non-negative")
  end
  if M.options.context.max_prefix_chars <= 0 then
    error("nvim-fim: context.max_prefix_chars must be positive")
  end
  if M.options.context.max_suffix_chars < 0 then
    error("nvim-fim: context.max_suffix_chars must be non-negative")
  end
  
  -- Validate debounce
  if M.options.debounce_ms < 0 then
    error("nvim-fim: debounce_ms must be non-negative")
  end
end

return M

-- Provider interface for FIM completions
-- Allows multiple AI providers (Codestral, OpenAI, Anthropic, etc.)

local M = {}

---@class FimProvider
---@field name string Provider identifier
---@field request_completion fun(prefix: string, suffix: string, callback: fun(response: table|nil, err: string|nil)) Request a completion
---@field validate_config fun(config: table): boolean, string|nil Validate provider-specific config

--- Registry of available providers
M.providers = {}

--- Register a provider
---@param name string Provider name
---@param provider FimProvider Provider implementation
function M.register(name, provider)
  M.providers[name] = provider
end

--- Get a provider by name
---@param name string Provider name
---@return FimProvider|nil
function M.get(name)
  if not M.providers[name] then
    -- Lazy load provider
    local ok, provider = pcall(require, 'fim.providers.' .. name)
    if ok then
      M.register(name, provider)
    else
      return nil
    end
  end
  return M.providers[name]
end

--- Validate that a provider exists and has the required interface
---@param name string Provider name
---@return boolean, string|nil
function M.validate(name)
  local provider = M.get(name)
  
  if not provider then
    return false, "Provider '" .. name .. "' not found"
  end
  
  if type(provider.request_completion) ~= 'function' then
    return false, "Provider '" .. name .. "' missing request_completion function"
  end
  
  return true, nil
end

return M

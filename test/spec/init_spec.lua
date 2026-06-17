describe("fim.init", function()
  local fim
  local calls

  before_each(function()
    package.loaded["fim"] = nil
    package.loaded["fim.init"] = nil
    package.loaded["fim.config"] = nil
    package.loaded["fim.context"] = nil
    package.loaded["fim.suggestion"] = nil
    package.loaded["fim.render"] = nil
    package.loaded["fim.keymaps"] = nil
    package.loaded["fim.providers"] = nil

    calls = {
      config_setup = 0,
      suggestion_setup = 0,
      keymaps_setup = 0,
      request_completion = 0,
      login = 0,
    }

    package.loaded["fim.config"] = {
      options = { provider = "codestral", debounce_ms = 0, codestral = {} },
      setup = function(_)
        calls.config_setup = calls.config_setup + 1
      end,
    }

    package.loaded["fim.context"] = {
      get_current_context = function()
        return { prefix = "p", suffix = "s", cursor = { line = 0, col = 0 } }
      end,
    }

    package.loaded["fim.suggestion"] = {
      setup = function() calls.suggestion_setup = calls.suggestion_setup + 1 end,
      request_completion = function(_) calls.request_completion = calls.request_completion + 1 end,
      clear_suggestion = function() end,
      accept_suggestion = function() end,
      accept_word = function() end,
      accept_line = function() end,
    }

    package.loaded["fim.render"] = {}

    package.loaded["fim.keymaps"] = {
      setup = function() calls.keymaps_setup = calls.keymaps_setup + 1 end,
    }

    package.loaded["fim.providers"] = {
      get = function()
        return {
          validate_config = function() return true, nil end,
          login = function() calls.login = calls.login + 1 end,
        }
      end,
    }

    fim = require("fim")
  end)

  it("setup initializes config, suggestion, keymaps", function()
    fim.setup({ provider = "codestral" })
    assert.equals(1, calls.config_setup)
    assert.equals(1, calls.suggestion_setup)
    assert.equals(1, calls.keymaps_setup)
  end)

  it("trigger_completion requests completion only in insert mode", function()
    local orig_mode = vim.fn.mode

    vim.fn.mode = function() return "n" end
    fim.trigger_completion()
    assert.equals(0, calls.request_completion)

    vim.fn.mode = function() return "i" end
    fim.trigger_completion()
    assert.equals(1, calls.request_completion)

    vim.fn.mode = orig_mode
  end)

  it("registers FimLogin command when provider supports login", function()
    fim.setup({ provider = "codestral" })
    vim.cmd("FimLogin")
    assert.equals(1, calls.login)
  end)
end)

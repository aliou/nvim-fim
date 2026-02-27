describe("fim.keymaps", function()
  local keymaps
  local config

  before_each(function()
    package.loaded["fim.config"] = nil
    package.loaded["fim.providers"] = nil
    package.loaded["fim.providers.codestral"] = nil
    package.loaded["fim.suggestion"] = nil
    package.loaded["fim.keymaps"] = nil

    package.loaded["fim.suggestion"] = {
      state = { suggestion = nil },
      accept_suggestion = function() end,
      accept_word = function() end,
      accept_line = function() end,
      clear_suggestion = function() end,
    }

    config = require("fim.config")
    config.setup({
      provider = "codestral",
      codestral = { api_key_provider = function() return "test" end },
    })

    keymaps = require("fim.keymaps")
  end)

  local function has_buf_map(bufnr, lhs)
    vim.api.nvim_set_current_buf(bufnr)
    local info = vim.fn.maparg(lhs, "i", false, true)
    return type(info) == "table" and next(info) ~= nil and info.buffer == 1
  end

  it("sets default insert mode keymaps", function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)

    keymaps.setup_buffer_keymaps()

    assert.is_true(has_buf_map(bufnr, "<Tab>"))
    assert.is_true(has_buf_map(bufnr, "<C-Right>"))
    assert.is_true(has_buf_map(bufnr, "<C-e>"))
    assert.is_true(has_buf_map(bufnr, "<C-]>") )
    assert.is_true(has_buf_map(bufnr, "<C-Space>"))

    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  it("does not set disabled keymaps", function()
    config.setup({
      provider = "codestral",
      codestral = { api_key_provider = function() return "test" end },
      keymaps = {
        accept = false,
        accept_word = false,
        accept_line = false,
        dismiss = false,
        trigger = false,
      },
    })

    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)

    keymaps.setup_buffer_keymaps()

    assert.is_false(has_buf_map(bufnr, "<Tab>"))
    assert.is_false(has_buf_map(bufnr, "<C-Right>"))
    assert.is_false(has_buf_map(bufnr, "<C-e>"))
    assert.is_false(has_buf_map(bufnr, "<C-]>") )
    assert.is_false(has_buf_map(bufnr, "<C-Space>"))

    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)
end)

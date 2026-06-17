describe("fim.render", function()
  local render
  local config

  before_each(function()
    package.loaded["fim.config"] = nil
    package.loaded["fim.providers"] = nil
    package.loaded["fim.providers.codestral"] = nil
    package.loaded["fim.render"] = nil

    config = require("fim.config")
    config.setup({
      provider = "codestral",
      codestral = { api_key_provider = function() return "test" end },
      highlight = "Comment",
    })

    render = require("fim.render")
  end)

  local function get_mark_details(bufnr)
    local marks = vim.api.nvim_buf_get_extmarks(bufnr, render.ns_id, 0, -1, { details = true })
    if #marks == 0 then return nil end
    return marks[1][4]
  end

  it("renders inline when no text after cursor", function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "" })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    render.render_suggestion("xyz")

    local details = get_mark_details(bufnr)
    assert.is_not_nil(details)
    assert.equals("inline", details.virt_text_pos)

    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  it("renders at eol when text exists after cursor", function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "abcdef" })
    vim.api.nvim_win_set_cursor(0, { 1, 2 })

    render.render_suggestion("xyz")

    local details = get_mark_details(bufnr)
    assert.is_not_nil(details)
    assert.equals("eol", details.virt_text_pos)

    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  it("renders multiline suggestions using virt_lines", function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "abc" })
    vim.api.nvim_win_set_cursor(0, { 1, 3 })

    render.render_suggestion("first\nsecond\nthird")

    local details = get_mark_details(bufnr)
    assert.is_not_nil(details)
    assert.is_table(details.virt_lines)
    assert.equals(2, #details.virt_lines)

    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  it("clear_suggestion removes extmark", function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "abc" })
    vim.api.nvim_win_set_cursor(0, { 1, 3 })

    render.render_suggestion("xyz")
    render.clear_suggestion()

    local marks = vim.api.nvim_buf_get_extmarks(bufnr, render.ns_id, 0, -1, {})
    assert.equals(0, #marks)

    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)
end)

local M = {}
local U = require("task.utils")

M.config = {
  sections = {
    todo      = { label = "Todo", check_style = "[ ]", order = 1, color = "#ff9e64" },
    doing     = { label = "In Progress", check_style = "[/]", order = 2, color = "#7aa2f7" },
    done      = { label = "Completed", check_style = "[x]", order = 3, color = "#9ece6a" },
    archive   = { label = "Archive", check_style = "[b]", style = "~~", order = 4, color = "#565f89" },
    cancelled = { label = "Cancelled", check_style = "[-]", style = "~~", order = 5, color = "#444b6a" },
    wont      = { label = "Wont Do", check_style = "[d]", style = "~~", order = 6, color = "#f7768e" },
  },
  highlights = { metadata = { fg = "#565f89", italic = true } },
  types = {
    bug  = { style = "**", color = "#f7768e" },
    feat = { style = "_", color = "#bb9af7" },
    task = { style = "", color = "#7aa2f7" }
  },
  date_format = "%Y-%m-%d",
  default_type = "TASK"
}

function M.apply_highlights()
  for id, conf in pairs(M.config.sections) do
    if conf.color then
      local suffix = id:gsub("^%l", string.upper)
      vim.api.nvim_set_hl(0, "TaskGroup" .. suffix, { fg = conf.color, bold = true })
      vim.api.nvim_set_hl(0, "TaskCheck" .. suffix, { fg = conf.color })
      vim.cmd(string.format([[syntax match TaskGroup%s "@%s"]], suffix, id))
      vim.cmd(string.format([[syntax match TaskCheck%s "^\s*-\s*%s"]], suffix, U.pesc(conf.check_style)))
    end
  end

  local type_groups = {}
  for tid, tconf in pairs(M.config.types) do
    if tconf.color then
      local hl = "TaskType" .. tid:upper()
      table.insert(type_groups, hl)
      vim.api.nvim_set_hl(0, hl, { fg = tconf.color, bold = true })
      vim.cmd(string.format([[syntax match %s "\<%s\>" contained]], hl, tid:upper()))
    end
  end

  vim.api.nvim_set_hl(0, "TaskMetadata", M.config.highlights.metadata)
  local contains_list = table.concat(type_groups, ",")
  vim.cmd(string.format([[syntax match TaskMetadata "|[^ ]*|" contains=%s]], contains_list))
end

function M.sync_line()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_get_current_line()
  if not line:match("^%s*%- %[.%]") then return end
  local physical_id = U.get_physical_section_id(M.config, lnum)
  if not physical_id then return end

  local tag_id = line:match("@([%w]+)")
  if tag_id and M.config.sections[tag_id] and tag_id ~= physical_id then
    M.move_task(tag_id)
    return
  end

  local correct = U.format_line(M.config, line, physical_id, false)
  if correct ~= line then
    vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { correct })
  end
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  local seen_styles = {}
  for id, conf in pairs(M.config.sections) do
    if seen_styles[conf.check_style] then
      error(string.format("[task.nvim] Collision: '%s' & '%s' use '%s'", seen_styles[conf.check_style], id,
        conf.check_style))
    end
    seen_styles[conf.check_style] = id
  end

  local group = vim.api.nvim_create_augroup("TaskOrganizer", { clear = true })
  vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
    group = group, pattern = "*.md", callback = function() vim.schedule(M.sync_line) end,
  })
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter" }, {
    group = group,
    pattern = "*.md",
    callback = function()
      M.apply_highlights()
    end,
  })
end

return M

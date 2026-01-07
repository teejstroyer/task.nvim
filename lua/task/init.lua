--https://minimal.guide/checklists--
-- - [ ]	to-do
-- - [/]	incomplete
-- - [x]	done
-- - [-]	canceled
-- - [>]	forwarded
-- - [<]	scheduling
-- - [?]	question
-- - [!]	important
-- - [*]	star
-- - ["]	quote
-- - [l]	location
-- - [b]	bookmark
-- - [i]	information
-- - [S]	savings
-- - [I]	idea
-- - [p]	pros
-- - [c]	cons
-- - [f]	fire
-- - [k]	key
-- - [w]	win
-- - [u]	up
-- - [d]	down

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
  highlights = {
    metadata = { fg = "#565f89", italic = true }
  },
  types = {
    bug  = { style = "**", color = "#f7768e" },
    feat = { style = "_", color = "#bb9af7" },
    task = { style = "", color = "#7aa2f7" }
  },
  date_format = "%Y-%m-%d",
  default_type = "TASK"
}

local function perform_move(section_id, line_num)
  local section = M.config.sections[section_id]
  if not section then return end

  local curr_lnum = line_num or vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(0, curr_lnum - 1, curr_lnum, false)[1]

  if not line or not line:match("^%s*%- %[.%]") then return end

  local updated_line = U.format_task_line(
    line,
    section_id,
    section,
    M.config.sections,
    M.config.types,
    M.config.date_format,
    M.config.default_type,
    true
  )

  local target_h = U.find_header_line(section.label)

  if not target_h then
    local ins = U.get_smart_insert_pos(section_id, M.config.sections)
    vim.api.nvim_buf_set_lines(0, ins, ins, false, { "", "## " .. section.label, "" })
    target_h = U.find_header_line(section.label)
  end

  if not target_h then
    vim.notify("[task.nvim] Error: Could not resolve header for " .. section_id, 3)
    return
  end

  vim.api.nvim_buf_set_lines(0, target_h, target_h, false, { updated_line })
  local del_idx = (target_h <= curr_lnum) and curr_lnum or curr_lnum - 1
  vim.api.nvim_buf_set_lines(0, del_idx, del_idx + 1, false, {})

  if not line_num then
    vim.api.nvim_win_set_cursor(0, { target_h + 1, 0 })
  end
end

-- PUBLIC API --
function M.new_task(task_type)
  vim.ui.input({ prompt = "Description: " }, function(desc)
    if not desc or desc == "" then return end

    local first_id = nil
    local first_section = nil
    local min_order = math.huge

    for id, sec in pairs(M.config.sections) do
      if sec.order < min_order then
        min_order = sec.order
        first_id = id
        first_section = sec
      end
    end

    if not first_id or not first_section then return end

    local final_type = (task_type == nil or task_type == "") and M.config.default_type or task_type:upper()
    local date_str = os.date(M.config.date_format)

    local formatted_line = string.format("- %s %s @%s|%s|%s",
      first_section.check_style,
      desc,
      first_id,
      final_type,
      date_str
    )

    local target_h = U.find_header_line(first_section.label)

    if not target_h then
      local ins = U.get_smart_insert_pos(first_id, M.config.sections)
      vim.api.nvim_buf_set_lines(0, ins, ins, false, { "", "## " .. first_section.label, "" })
      target_h = U.find_header_line(first_section.label)
    end

    if target_h then
      vim.api.nvim_buf_set_lines(0, target_h, target_h, false, { formatted_line })
      vim.api.nvim_win_set_cursor(0, { target_h + 1, 0 })
    end
  end)
end

function M.move_task(section_id)
  local mode = vim.api.nvim_get_mode().mode
  if mode:match("[vV\22]") then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), 'nx', false)
    vim.schedule(function()
      local l1, l2 = vim.fn.line("'<"), vim.fn.line("'>")
      for i = l2, l1, -1 do perform_move(section_id, i) end
    end)
  else
    perform_move(section_id)
  end
end

function M.sync_line()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_get_current_line()
  if not line:match("^%s*%- %[.%]") then return end

  local physical_id = U.get_physical_section_id(lnum, M.config.sections)
  if not physical_id then return end

  -- Bidirectional Sync: @tag forces a move
  local tag_id = line:match("@([%w]+)")
  if tag_id and M.config.sections[tag_id] and tag_id ~= physical_id then
    perform_move(tag_id)
    return
  end

  for id, conf in pairs(M.config.sections) do
    if line:match("^%s*%- " .. U.pesc(conf.check_style)) and id ~= physical_id then
      perform_move(id)
      return
    end
  end

  -- Re-format text to match physical section
  local correct = U.format_task_line(
    line,
    physical_id,
    M.config.sections[physical_id],
    M.config.sections,
    M.config.types,
    M.config.date_format,
    M.config.default_type,
    false
  )

  if correct ~= line then
    vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { correct })
  end
end

function M.sync_buffer()
  local i = 1
  while i <= vim.api.nvim_buf_line_count(0) do
    local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
    if line and line:match("^%s*%- %[.%]") then
      local tag_id = line:match("@([%w]+)")
      local physical_id = U.get_physical_section_id(i, M.config.sections)
      if (tag_id and M.config.sections[tag_id] and tag_id ~= physical_id) then
        perform_move(tag_id, i)
      else
        i = i + 1
      end
    else
      i = i + 1
    end
  end
end

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

function M.select_move()
  local mode = vim.api.nvim_get_mode().mode
  local is_visual = mode:match("[vV\22]")
  local l1, l2

  if is_visual then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), 'nx', false)
    l1, l2 = vim.fn.line("'<"), vim.fn.line("'>")
  else
    l1 = vim.api.nvim_win_get_cursor(0)[1]
    l2 = l1
  end

  local line = vim.api.nvim_buf_get_lines(0, l1 - 1, l1, false)[1]
  if not line or not line:match("^%s*%- %[.%]") then return end

  local current_id = U.get_physical_section_id(l1, M.config.sections)

  local targets = {}
  for id, conf in pairs(M.config.sections) do
    if id ~= current_id then
      table.insert(targets, id)
    end
  end

  table.sort(targets, function(a, b)
    return M.config.sections[a].order < M.config.sections[b].order
  end)

  vim.ui.select(targets, {
    prompt = "Move task(s) to:",
    format_item = function(item)
      return M.config.sections[item].label
    end
  }, function(choice)
    if choice then
      vim.schedule(function()
        for i = l2, l1, -1 do
          perform_move(choice, i)
        end
      end)
    end
  end)
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  local seen = {}
  for id, conf in pairs(M.config.sections) do
    if seen[conf.check_style] then
      error("[task.nvim] Duplicate check_style: " .. id .. " and " .. seen[conf.check_style])
    end
    seen[conf.check_style] = id
  end

  local group = vim.api.nvim_create_augroup("TaskOrganizer", { clear = true })
  vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
    group = group, pattern = "*.md", callback = function() vim.schedule(M.sync_line) end,
  })
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter" }, {
    group = group,
    pattern = "*.md",
    callback = function()
      vim.schedule(function()
        M.sync_buffer(); M.apply_highlights()
      end)
    end,
  })

  vim.api.nvim_create_user_command("TaskSync", M.sync_buffer, {})
  vim.api.nvim_create_user_command("TaskNew", function(c) M.new_task(c.args ~= "" and c.args or nil) end, { nargs = "?" })
  vim.api.nvim_create_user_command("TaskMove", M.select_move, { range = true })

  for id, _ in pairs(M.config.sections) do
    local name = "Task" .. id:gsub("^%l", string.upper)
    vim.api.nvim_create_user_command(name, function(c)
      if c.range > 0 then
        for i = c.line2, c.line1, -1 do perform_move(id, i) end
      else
        perform_move(id)
      end
    end, { range = true })
  end
end

return M

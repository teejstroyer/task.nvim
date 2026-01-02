local U = {}

-- Pure helper for escaping regex characters
function U.pesc(str) return str:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") end

-- Finds the line number of a specific Markdown header
function U.find_header_line(header_text)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local pattern = "^#+%s+" .. U.pesc(header_text) .. "%s*$"
  for i, line in ipairs(lines) do
    if line:match(pattern) then return i end
  end
  return nil
end

-- Identifies which section ID a line physically belongs to based on the header above it
function U.get_physical_section_id(line_num, sections)
  local lnum = line_num
  local lines = vim.api.nvim_buf_get_lines(0, 0, lnum, false)
  for i = #lines, 1, -1 do
    local label = lines[i]:match("^#+%s+(.*)$")
    if label then
      for id, conf in pairs(sections) do
        if conf.label == label then return id end
      end
    end
  end
  return nil
end

-- Logic to determine where a task should be inserted based on 'order'
function U.get_smart_insert_pos(section_id, sections)
  local target_order = sections[section_id].order or 99
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local best_pos = #lines
  local found_higher = false

  for id, conf in pairs(sections) do
    local line_idx = U.find_header_line(conf.label)
    if line_idx then
      if (conf.order or 99) > target_order then
        if not found_higher or line_idx < best_pos then
          best_pos = line_idx - 1
          found_higher = true
        end
      end
    end
  end
  return best_pos
end

--- @param line_content string: The raw text of the task line
--- @param section_id string: The destination section ID (e.g., "todo")
--- @param target_section table: The config for the destination section
--- @param sections table: All section configs (needed to strip old styles)
--- @param types table: All type configs (needed to strip old styles)
--- @param date_format string: e.g., "%Y-%m-%d"
--- @param default_type string: e.g., "TASK"
--- @param force_today boolean: Whether to override existing date
function U.format_task_line(line_content, section_id, target_section, sections, types, date_format, default_type,
                            force_today)
  if not target_section then return line_content end

  -- 1. Extract existing Metadata
  local tag_pattern = "@([%w]+)|?([^%s|]*)%|?([^%s]*)"
  local _, current_type, current_date = line_content:match(tag_pattern)
  local manual_type = line_content:match("|([^%s|]+)|")

  -- 2. Resolve Type and Date
  local item_type = (manual_type or current_type or default_type):upper()
  local today = os.date(date_format)
  local final_date = (not force_today and current_date and current_date:match("%d%d%d%d%-")) and current_date or today

  -- 3. Clean line: Strip all possible markdown decorators from all sections/types
  local updated = line_content
  for _, s in pairs(sections) do
    if s.style and s.style ~= "" then updated = updated:gsub(U.pesc(s.style), "") end
  end
  for _, t in pairs(types) do
    if t.style and t.style ~= "" then updated = updated:gsub(U.pesc(t.style), "") end
  end

  -- 4. Apply Checkbox and Metadata
  updated = updated:gsub("^%s*%- %[.%]", "- " .. target_section.check_style)
  local metadata = "@" .. section_id .. "|" .. item_type .. "|" .. final_date

  if line_content:match("@%w+") then
    updated = updated:gsub("@%w+[^%s]*", metadata)
  else
    updated = updated .. " " .. metadata
  end

  -- 5. Re-apply Styles for the resolved type and section
  local t_conf = types[item_type:lower()]
  local s_style = target_section.style or ""
  local t_style = (t_conf and t_conf.style) or ""

  return updated:gsub("(%- %[.%]%s+)(.*)(%s+@)", function(p, d, s)
    return p .. s_style .. t_style .. d .. t_style .. s_style .. s
  end)
end

return U

local U = {}

function U.pesc(str) return str:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") end

function U.find_header_line(header_text)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local pattern = "^#+%s+" .. U.pesc(header_text) .. "%s*$"
  for i, line in ipairs(lines) do
    if line:match(pattern) then return i end
  end
  return nil
end

function U.get_physical_section_id(config, line_num)
  local lnum = line_num or vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, lnum, false)
  for i = #lines, 1, -1 do
    local label = lines[i]:match("^#+%s+(.*)$")
    if label then
      for id, conf in pairs(config.sections) do
        if conf.label == label then return id end
      end
    end
  end
  return nil
end

function U.format_line(config, line_content, section_id, force_today)
  local conf = config.sections[section_id]
  if not conf then return line_content end

  local tag_pattern = "@([%w]+)|?([^%s|]*)%|?([^%s]*)"
  local _, current_type, current_date = line_content:match(tag_pattern)
  local manual_type = line_content:match("|([^%s|]+)|")
  local item_type = (manual_type or current_type or config.default_type):upper()

  local today = os.date(config.date_format)
  local final_date = (not force_today and current_date and current_date:match("%d%d%d%d%-")) and current_date or today

  local updated = line_content
  for _, s in pairs(config.sections) do if s.style then updated = updated:gsub(U.pesc(s.style), "") end end
  for _, t in pairs(config.types) do if t.style then updated = updated:gsub(U.pesc(t.style), "") end end

  updated = updated:gsub("^%s*%- %[.%]", "- " .. conf.check_style)
  local metadata = "@" .. section_id .. "|" .. item_type .. "|" .. final_date
  if line_content:match("@%w+") then
    updated = updated:gsub("@%w+[^%s]*", metadata)
  else
    updated = updated .. " " .. metadata
  end

  local t_conf = config.types[item_type:lower()]
  local s_style, t_style = conf.style or "", (t_conf and t_conf.style) or ""

  return updated:gsub("(%- %[.%]%s+)(.*)(%s+@)", function(p, d, s)
    return p .. s_style .. t_style .. d .. t_style .. s_style .. s
  end)
end

return U

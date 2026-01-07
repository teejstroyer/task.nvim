# task.nvim 📝

> Early development beta plugin

A lightweight, native Neovim plugin for managing structured task lists directly in Markdown files. Designed for speed, flexibility, and zero-dependency efficiency.

## ✨ Features

* **Physical Task Movement**: Automatically moves tasks between Markdown headers (e.g., `## Todo` → `## Completed`) based on their status.
* **Bidirectional Syncing**: Changing a checkbox or adding a `@tag` automatically triggers a move to the correct section.
* **Customizable Workflow**: Define your own sections, priority orders, and highlight colors.
* **Auto-Formatting**: Ensures tasks are consistently formatted with dates and metadata (e.g., `|TASK|2026-01-07|`).
* **Native-First**: Built to leverage Neovim 0.12's native package and event systems.

---

## 📦 Installation

### [Built-in (0.12+) vim.pack](https://www.google.com/search?q=https://neovim.io/doc/user/pack.html%23vim.pack.add())

```lua
vim.pack.add({
  "https://github.com/teejstroyer/task.nvim",
})

require("task").setup({
    -- See Configuration section below for options
})

```

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "teejstroyer/task.nvim",
    ft = "markdown",
    config = function()
        require("task").setup({
            -- See Configuration section below for options
        })
    end
}

```

---

## 🚀 Usage

### Commands

| Command | Description |
| --- | --- |
| `:TaskNew` | Prompt for a description and create a new task in your first section. |
| `:TaskNew <TYPE>` |  - Specify task type on creation. |
| `:TaskSync` | Scans the current buffer and moves all tasks to their correct physical headers. |
| `:TaskMove` | `vim.ui.select()` based task movement. |
| `:TaskMove <SECTION>` | Move the task under user defined section. |


### Example Keybindings

```lua
local task = require("task")

vim.keymap.set('n', '<leader>tn', function() task.new_task('task') end, { desc = "Task: Quick New (default type)" })
vim.keymap.set('n', '<leader>tN', function()
  vim.ui.input({ prompt = "Task Type: " }, function(input)
    task.new_task(input)
  end)
end, { desc = "Task: New (Prompt for Type)" })
vim.keymap.set({ 'n', 'v' }, '<leader>tb', function() task.move_task("todo") end, { desc = "Task:Backlog" })
vim.keymap.set({ 'n', 'v' }, '<leader>tp', function() task.move_task("doing") end, { desc = "Task:Progress" })
vim.keymap.set({ 'n', 'v' }, '<leader>td', function() task.move_task("done") end, { desc = "Task:Completed" })
vim.keymap.set({ 'n', 'v' }, '<leader>ta', function() task.move_task("archive") end, { desc = "Task:Archive" })
vim.keymap.set({ 'n', 'v' }, '<leader>tw', function() task.move_task("wont") end, { desc = "Task:Wont Do" })
vim.keymap.set({ 'n', 'v' }, '<leader>tc', function() task.move_task("cancelled") end, { desc = "Task:Cancelled" })
vim.keymap.set({ 'n', 'v' }, '<leader>t<space>', function() task.select_move() end, { desc = "Task: Move" })
```

---

## 🎨 Configuration

The `setup()` function allows you to define the structure of your task lists.

| Field | Type | Description |
| --- | --- | --- |
| `sections` | `table` | Dictionary of status IDs (todo, done, etc.) with labels and icons. |
| `types` | `table` | Metadata tags (BUG, FEAT, TASK) with specific styles/colors. |
| `date_format` | `string` | The Lua `os.date` format for task timestamps. |

### Example Custom Section

> **Crucial Rule:** Every section **must** have a unique `check_style` to ensure deterministic state.

> [Minimal Checklists Styles](https://minimal.guide/checklists--)

```lua
--Default configuration
require("task").setup({
    sections = {
        todo      = { label = "Todo",        check_style = "[ ]", order = 1, color = "#ff9e64" },
        doing     = { label = "In Progress", check_style = "[/]", order = 2, color = "#7aa2f7" },
        done      = { label = "Completed",   check_style = "[x]", order = 3, color = "#9ece6a" },
        archive   = { label = "Archive",     check_style = "[b]", style = "~~", order = 4, color = "#565f89" },
        cancelled = { label = "Cancelled",   check_style = "[-]", style = "~~", order = 5, color = "#444b6a" },
        wont      = { label = "Wont Do",     check_style = "[d]", style = "~~", order = 6, color = "#f7768e" },
    },
    types = {
        bug  = { style = "**", color = "#f7768e" },
        feat = { style = "_",  color = "#bb9af7" },
        task = { style = "",   color = "#7aa2f7" }
    },
    highlights = { metadata = { fg = "#565f89", italic = true } },
    date_format = "%Y-%m-%d",
    default_type = "TASK"
})
```

## Todo
- [ ]	to-do @todo|TASK|2026-01-07
- [ ] Priority support @todo|TASK|2026-01-07
- [ ] Sub task support @todo|TASK|2026-01-07
- [ ] Create .task file for project specfic settings @todo|TASK|2026-01-07
- [ ] Fix extra white space on task creation and moving @todo|TASK|2026-01-07

## In Progress
- [/]incomplete @doing|TASK|2026-01-07
- [/]incomplete @doing|TASK|2026-01-07

## Completed
- [x] Custom user mappings  @done|TASK|2026-01-07
- [x] Custom user highlights  @done|TASK|2026-01-07
- [x] Custom user styling by task type  @done|TASK|2026-01-07

## Proposals
- [I] Consider removing checkbox logic and opting for tag only @idea|TASK|2026-01-07

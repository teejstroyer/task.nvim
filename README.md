# task.nvim

> Early development beta plugin

> A deterministic, header-first task management system for Neovim.

## The Philosophy: "Header as Source of Truth"

Most task plugins rely on brittle metadata tags or checkboxes as the primary source of state, leading to "ghost tasks," desyncs, and race conditions when you manually edit your file.

**task.nvim is different.** It treats the **physical Markdown header** the task sits under as the ultimate authority.

1. **Location = State:** If you use standard Vim motions to move a task under the `## Completed` header, the plugin automatically updates its metadata to match.
2. **Zero Ambiguity:** Every section must have a unique checkstyle (e.g., `[x]` vs `[b]`), mathematically preventing infinite loops or bouncing states.
3. **Type & Style Separation:** Task types like `BUG` or `FEAT` are nested inside the metadata, allowing their distinct colors to "pierce through" the generic metadata highlighting.

## ✨ Features

* **Bidirectional Sync:** Moving tasks physically updates state; changing state tags moves tasks physically.
* **Typed Tasks:** Distinguish between standard tasks, `BUG`s, and `FEAT`ures with unique visual styles and colors.
* **Loop Protection:** Built-in validation ensures your configuration cannot create conflicting states.
* **Dashboard Visuals:** Reversed header colors and distinct icons create a clear, scannable managerial view of your workload.
* **Automatic Maintenance:** Dates automatically update only when a task's primary state changes, preserving project history.

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

## ⚙️ Configuration

**Crucial Rule:** Every section **must** have a unique `check_style` to ensure deterministic state.

```lua
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

## 🚀 Usage

### Automatic Syncing

The plugin hooks into `InsertLeave` and `TextChanged` to format the line based on its header location. Manual type edits (e.g., changing `TASK` to `BUG`) refresh styles instantly without moving the line.

### Commands

| Command | Description |
| --- | --- |
| `:TaskNew [type]` | Prompts for description and creates a task under `## Todo`. |
| `:TaskSync` | Scans buffer to reconcile all metadata with physical locations. |
| `:Task<Id>` | Moves current line/selection to the specified section (e.g., `:TaskDone`). |

### Recommended Keymaps

```lua
local tasks = require("task")

-- Buffer-local mapping for Markdown files
vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
        local opts = { buffer = true, silent = true }

        -- New Tasks
        vim.keymap.set('n', '<localleader>tn', function() tasks.new_task('task') end, opts)
        vim.keymap.set('n', '<localleader>tN', function() tasks.new_task() end, opts)

        -- State Transitions (Normal & Visual)
        vim.keymap.set({ 'n', 'v' }, '<localleader>tb', ":TaskTodo<CR>", opts)
        vim.keymap.set({ 'n', 'v' }, '<localleader>tp', ":TaskDoing<CR>", opts)
        vim.keymap.set({ 'n', 'v' }, '<localleader>td', ":TaskDone<CR>", opts)
        vim.keymap.set({ 'n', 'v' }, '<localleader>ta', ":TaskArchive<CR>", opts)
    end,
})

```

## 🎨 Highlights & Integration

The plugin generates highlights based on your config colors:

* **Headers:** `TaskHeaderTodo`, etc. (Reversed for dashboard feel).
* **Metadata:** `TaskMetadata` (Italic/dimmed).
* **Types:** `TaskTypeBUG`, etc. (Contained within metadata pipes to maintain distinct colors).

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

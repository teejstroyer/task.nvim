# --- task.nvim Default Config Demo ---
# Demonstrates spatial task management & bidirectional sync

# Setup settings
Output demo.gif
Set Shell "zsh"
Set FontSize 18
Set FontFamily "FiraCode Nerd Font Mono"
Set Width 1200
Set Height 800
Set Padding 0
Set TypingSpeed 100ms

# Start with a fresh markdown file
Hide
Type "rm project_roadmap.md"
Enter
Type "nvim project_roadmap.md"
Enter
Sleep 1s
Show

# --- 1. Creating New Tasks ---
# :TaskNew finds the section with the smallest 'order' (Todo)
Type ":TaskNew"
Enter
Sleep 500ms
Type "Refactor the engine"
Enter
Sleep 1s

# Create a 'bug' type task
Type ":TaskNew bug"
Enter
Sleep 500ms
Type "Memory leak in perform_move"
Enter
Sleep 1s

# --- 2. Bidirectional Sync: Checkbox ---
# Simply checking a box moves the task physically
Type "/Refactor"
Enter
Type "0f["
Sleep 1s
# Change [ ] to [/] (In Progress)
Type "lr"
Type "/"
Sleep 2s
Escape
Sleep 1s
# The line jumps to '## In Progress' automatically

# --- 3. Bidirectional Sync: Tags ---
# Editing the @tag in the metadata also triggers a move
Type "/Memory leak"
Enter
Type "f@l"
# Change @todo to @done
Type "cwdone"
Escape
Sleep 2s
# The line jumps to '## Completed'

# --- 4. Visual Selection & Bulk Move ---
# Add a few quick tasks to show bulk movement
Type ":TaskNew"
Enter
Type "Update docs"
Enter
Type ":TaskNew"
Enter
Type "Write tests"
Enter
Sleep 500ms

# Visual select and move to 'archive'
Type "yy3p"
Sleep 500ms
Type "Vjjjj"
Sleep 1s
Type ":TaskMove archive"
Enter
Sleep 2s

# --- 5. Manual Selector (vim.ui.select) ---
# Use TaskMove without args to see the UI selection
Type "/Refactor"
Enter
Type ":TaskMove"
Enter
Sleep 1s
# Select 'Wont Do' using the UI
Type "wo"
Sleep 500ms
Enter
Sleep 2s

# Final look at the organized file
Type "gg"
Sleep 3s
Type ":wq"
Enter

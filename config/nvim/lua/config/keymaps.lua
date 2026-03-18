local map = vim.keymap.set

map("i", "jj", "<Esc>", { desc = "Exit insert mode" })
map("n", "<Esc>", "<cmd>noh<cr><Esc>", { desc = "Clear search highlight" })
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Write file" })
map("n", "<leader>q", "<cmd>qa<cr>", { desc = "Quit all" })
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

vim.api.nvim_create_user_command("Translate", function(args)
	require("translate").translate_cmd(args)
end, { range = true, nargs = "*" })

vim.api.nvim_create_user_command("Tr", function(args)
	require("translate").translate_cmd(args)
end, { range = true, nargs = "*" })

vim.api.nvim_create_user_command("TranslateTo", function(args)
	require("translate").translate_cmd(args)
end, { range = true, nargs = "*" })

vim.api.nvim_create_user_command("TrTo", function(args)
	require("translate").translate_cmd(args)
end, { range = true, nargs = "*" })

vim.api.nvim_create_user_command("TranslateToR", function(args)
	require("translate").replace_cmd(args)
end, { range = true, nargs = "*" })

vim.api.nvim_create_user_command("TrToR", function(args)
	require("translate").replace_cmd(args)
end, { range = true, nargs = "*" })

vim.api.nvim_create_user_command("TranslateR", function(args)
	require("translate").replace_cmd(args)
end, { range = true, nargs = "*" })

vim.api.nvim_create_user_command("TrR", function(args)
	require("translate").replace_cmd(args)
end, { range = true, nargs = "*" })

vim.api.nvim_create_user_command("TranslateToC", function(args)
	require("translate").copy_cmd(args)
end, { range = true, nargs = "*" })

vim.api.nvim_create_user_command("TrToC", function(args)
	require("translate").copy_cmd(args)
end, { range = true, nargs = "*" })

vim.api.nvim_create_user_command("TranslateC", function(args)
	require("translate").copy_cmd(args)
end, { range = true, nargs = "*" })

vim.api.nvim_create_user_command("TrC", function(args)
	require("translate").copy_cmd(args)
end, { range = true, nargs = "*" })

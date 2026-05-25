local M = {}

M.config = {
	default_backend = "google",
	default_target = "en",
	default_source = "auto",
	backends = {
		libretranslate = {
			url = "https://libretranslate.com",
		},
		mymemory = {
			email = "",
		},
	},
}

local backends = setmetatable({}, {
	__index = function(tbl, key)
		local ok, module = pcall(require, "translate.backends." .. key)
		if ok then
			tbl[key] = module
			return module
		end
		return nil
	end,
})

M.backends = backends

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

local function get_visual_selection()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local start_line = start_pos[2] - 1
	local start_col = start_pos[3] - 1
	local end_line = end_pos[2] - 1
	local end_col = end_pos[3]

	local start_line_content = vim.api.nvim_buf_get_lines(0, start_line, start_line + 1, false)[1] or ""
	local end_line_content = vim.api.nvim_buf_get_lines(0, end_line, end_line + 1, false)[1] or ""

	local mode = vim.fn.visualmode()
	if mode == "V" then
		start_col = 0
		end_col = #end_line_content
	else
		if start_col < 0 then
			start_col = 0
		end
		if start_col > #start_line_content then
			start_col = #start_line_content
		end
		if end_col < 0 then
			end_col = 0
		end
		if end_col > #end_line_content then
			end_col = #end_line_content
		end
	end

	local lines = vim.api.nvim_buf_get_text(0, start_line, start_col, end_line, end_col, {})
	return table.concat(lines, "\n"), start_line, start_col, end_line, end_col
end

local function get_text(args)
	if args.range > 0 then
		local start_pos = vim.fn.getpos("'<")
		local end_pos = vim.fn.getpos("'>")
		if start_pos[2] == args.line1 and end_pos[2] == args.line2 then
			return get_visual_selection()
		else
			local lines = vim.api.nvim_buf_get_lines(0, args.line1 - 1, args.line2, false)
			return table.concat(lines, "\n"), args.line1 - 1, 0, args.line2 - 1, #lines[#lines]
		end
	else
		local line_num = vim.api.nvim_win_get_cursor(0)[1] - 1
		local line_content = vim.api.nvim_buf_get_lines(0, line_num, line_num + 1, false)[1] or ""
		return line_content, line_num, 0, line_num, #line_content
	end
end

local function replace_visual_selection(start_line, start_col, end_line, end_col, translated_text)
	local lines = vim.split(translated_text, "\n")
	vim.api.nvim_buf_set_text(0, start_line, start_col, end_line, end_col, lines)
end

local function copy_to_registers(translated_text)
	vim.fn.setreg('"', translated_text)
	vim.fn.setreg("*", translated_text)
	vim.fn.setreg("+", translated_text)
end

local function run_translation(text, target, source, on_complete, attempt)
	attempt = attempt or 1
	local backend_name = M.config.default_backend
	local backend = M.backends[backend_name]
	if not backend then
		vim.notify("translate.nvim: Backend '" .. tostring(backend_name) .. "' not found.", vim.log.levels.ERROR)
		return
	end

	local backend_config = M.config.backends[backend_name] or {}
	local config_copy = vim.tbl_deep_extend("force", {}, backend_config)

	local has_more_urls = false
	if type(config_copy.url) == "table" then
		if attempt < #config_copy.url then
			has_more_urls = true
		end
		config_copy.url = config_copy.url[attempt]
	end

	local cmd = backend.get_cmd(text, target, source, config_copy)

	local stdout = {}
	local stderr = {}

	vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, data)
			stdout = data
		end,
		on_stderr = function(_, data)
			stderr = data
		end,
		on_exit = function(_, exit_code)
			local response = table.concat(stdout or {}, "\n")
			local translated = nil
			if exit_code == 0 then
				translated = backend.parse(response)
			end

			if not translated or translated == "" then
				if has_more_urls then
					run_translation(text, target, source, on_complete, attempt + 1)
				else
					local err_msg = table.concat(stderr or {}, "\n")
					if err_msg == "" and (not response or response == "") then
						err_msg = "Empty response or service unavailable"
					elseif not translated then
						err_msg = "Parse error"
					end
					vim.notify("translate.nvim: Translation failed. " .. err_msg, vim.log.levels.ERROR)
				end
				return
			end

			on_complete(translated)
		end,
	})
end

function M.translate_cmd(args)
	local text, start_line, start_col, end_line, end_col = get_text(args)
	if not text or text:match("^%s*$") then
		vim.notify("translate.nvim: No text selected or text is empty", vim.log.levels.WARN)
		return
	end
	local target = args.fargs[1] or M.config.default_target
	local source = args.fargs[2] or M.config.default_source

	run_translation(text, target, source, function(translated)
		vim.notify(translated, vim.log.levels.INFO, { title = "Translation (" .. source .. " -> " .. target .. ")" })
	end)
end

function M.replace_cmd(args)
	local text, start_line, start_col, end_line, end_col = get_text(args)
	if not text or text:match("^%s*$") then
		vim.notify("translate.nvim: No text selected or text is empty", vim.log.levels.WARN)
		return
	end
	local target = args.fargs[1] or M.config.default_target
	local source = args.fargs[2] or M.config.default_source
	local backend = M.config.default_backend

	run_translation(text, target, source, function(translated)
		replace_visual_selection(start_line, start_col, end_line, end_col, translated)
		vim.notify("Text replaced " .. backend .. " (" .. target .. ")", vim.log.levels.INFO)
	end)
end

function M.copy_cmd(args)
	local text, start_line, start_col, end_line, end_col = get_text(args)
	if not text or text:match("^%s*$") then
		vim.notify("translate.nvim: No text selected or text is empty", vim.log.levels.WARN)
		return
	end
	local target = args.fargs[1] or M.config.default_target
	local source = args.fargs[2] or M.config.default_source
	local backend = M.config.default_backend

	run_translation(text, target, source, function(translated)
		copy_to_registers(translated)
		vim.notify("Translation copied " .. backend .. " (" .. target .. ")", vim.log.levels.INFO)
	end)
end

local languages = {
	"en",
	"id",
	"es",
	"fr",
	"ja",
	"ko",
	"zh",
	"de",
	"ru",
	"ar",
	"it",
	"pt",
	"nl",
	"tr",
	"vi",
	"th",
	"ms",
}

function M.complete(arg_lead, cmd_line, cursor_pos)
	local parts = {}
	local cmd_to_cursor = cmd_line:sub(1, cursor_pos)
	for word in cmd_to_cursor:gmatch("%S+") do
		table.insert(parts, word)
	end

	local arg_index = #parts
	if cmd_to_cursor:sub(-1):match("%s") then
		arg_index = arg_index + 1
	end

	local cmd_arg_num = arg_index - 1

	local list = {}
	if cmd_arg_num == 1 then
		list = languages
	elseif cmd_arg_num == 2 then
		list = { "auto" }
		for _, lang in ipairs(languages) do
			table.insert(list, lang)
		end
	end

	local matches = {}
	for _, item in ipairs(list) do
		if item:sub(1, #arg_lead) == arg_lead then
			table.insert(matches, item)
		end
	end
	return matches
end

return M

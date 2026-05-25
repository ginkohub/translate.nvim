local M = {}

M.get_cmd = function(text, target, source, config)
	if source == "auto" then
		source = "autodetect"
	end
	local langpair = source .. "|" .. target
	local cmd = {
		"curl",
		"-G",
		"-s",
		"https://api.mymemory.translated.net/get",
		"--data",
		"langpair=" .. langpair,
		"--data-urlencode",
		"q=" .. text,
	}
	if config.email and config.email ~= "" then
		table.insert(cmd, "--data")
		table.insert(cmd, "de=" .. config.email)
	end
	return cmd
end

M.parse = function(response)
	local ok, data = pcall(vim.json.decode, response)
	if not ok or not data or not data.responseData or not data.responseData.translatedText then
		return nil
	end
	return data.responseData.translatedText
end

return M

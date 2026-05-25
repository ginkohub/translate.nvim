local M = {}

M.get_cmd = function(text, target, source, config)
	return {
		"curl",
		"-G",
		"-s",
		"https://translate.googleapis.com/translate_a/single",
		"--data",
		"client=gtx",
		"--data",
		"sl=" .. source,
		"--data",
		"tl=" .. target,
		"--data",
		"dt=t",
		"--data-urlencode",
		"q=" .. text,
	}
end

M.parse = function(response)
	local ok, data = pcall(vim.json.decode, response)
	if not ok or not data or not data[1] then
		return nil
	end
	local result = ""
	for _, item in ipairs(data[1]) do
		if item[1] then
			result = result .. item[1]
		end
	end
	return result
end

return M

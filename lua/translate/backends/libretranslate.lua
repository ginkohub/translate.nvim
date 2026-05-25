local M = {}

M.get_cmd = function(text, target, source, config)
	local url = config.url or "https://libretranslate.com"
	local post_data = vim.json.encode({
		q = text,
		source = source,
		target = target,
		api_key = config.api_key or "",
	})
	return {
		"curl",
		"-s",
		"-X",
		"POST",
		url .. "/translate",
		"-H",
		"Content-Type: application/json",
		"-d",
		post_data,
	}
end

M.parse = function(response)
	local ok, data = pcall(vim.json.decode, response)
	if not ok or not data or not data.translatedText then
		return nil
	end
	return data.translatedText
end

return M

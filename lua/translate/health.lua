local M = {}

local function is_reachable(url)
	if not url or url == "" then
		return false, "Empty URL"
	end
	local cmd = string.format("curl -s -o /dev/null -I -w '%%{http_code}' --connect-timeout 2 '%s'", url)
	local http_code = vim.fn.system(cmd)
	http_code = vim.trim(http_code)
	local code = tonumber(http_code)
	if code and code >= 200 and code < 450 then
		return true, "HTTP " .. code
	elseif code then
		return false, "HTTP " .. code
	else
		return false, "Connection failed / Timeout"
	end
end

M.check = function()
	local health = vim.health or require("health")
	health.start("translate.nvim report")

	if vim.fn.executable("curl") == 1 then
		health.ok("curl is installed and executable")
	else
		health.error("curl is not installed or not in PATH", {
			"Install curl via your package manager",
		})
		return
	end

	local translate = require("translate")
	local default_backend = translate.config.default_backend
	health.ok("default backend configured: " .. tostring(default_backend))

	local backend = translate.backends[default_backend]
	if backend then
		health.ok("backend module '" .. default_backend .. "' loaded successfully")
	else
		health.error("backend module '" .. default_backend .. "' could not be loaded", {
			"Verify default_backend in setup() config",
		})
	end

	health.start("translate.nvim connectivity check")

	local ok, msg = is_reachable("https://translate.googleapis.com")
	if ok then
		health.ok("Google Translate API: reachable (" .. msg .. ")")
	else
		health.warn("Google Translate API: unreachable (" .. msg .. ")")
	end

	local mymemory_ok, mymemory_msg = is_reachable("https://api.mymemory.translated.net")
	if mymemory_ok then
		health.ok("MyMemory API: reachable (" .. mymemory_msg .. ")")
	else
		health.warn("MyMemory API: unreachable (" .. mymemory_msg .. ")")
	end

	local urls = {}
	local uri = translate.config.backends.libretranslate.url
	if type(uri) == "string" then
		urls = { uri }
	elseif type(uri) == "table" then
		urls = uri
	end

	for _, url in ipairs(urls or {}) do
		local lt_ok, lt_msg = is_reachable(url)
		if lt_ok then
			health.ok("LibreTranslate mirror '" .. url .. "': reachable (" .. lt_msg .. ")")
		else
			health.warn("LibreTranslate mirror '" .. url .. "': unreachable (" .. lt_msg .. ")")
		end
	end
end

return M

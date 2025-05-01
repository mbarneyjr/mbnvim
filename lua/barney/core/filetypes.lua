local function starts_with(String, Start)
	return string.sub(String, 1, string.len(Start)) == Start
end

vim.filetype.add({
	extension = {
		jsonl = "json",
		tf = "terraform",
	},
	pattern = {
		[".*"] = {
			priority = math.huge,
			function(_, bufnr)
				-- check for github actions
				local path = vim.api.nvim_buf_get_name(bufnr)
				if string.find(path, ".asl.yml") or string.find(path, ".asl.yaml") then
					return "yaml.states"
				end
				if string.find(path, ".asl.json") then
					return "json.states"
				end
				if string.find(path, "docker%-compose") then
					return "yaml.docker-compose"
				end
				if string.find(path, "%.github/workflows") then
					return "yaml.github_actions"
				end
				-- check for cloudformation
				local line1 = vim.fn.getline(1)
				local line2 = vim.fn.getline(2)
				if starts_with(line1, "AWSTemplateFormatVersion") then
					return "yaml.cloudformation"
				elseif
					starts_with(line1, '"AWSTemplateFormatVersion"') or starts_with(line2, '"AWSTemplateFormatVersion"')
				then
					return "json.cloudformation"
				end
				-- check for amazon-states-language
				if starts_with(line1, "StartsAt") or starts_with(line1, "Comment") then
					return "yaml.states"
				elseif
					starts_with(line1, '"StartsAt"')
					or starts_with(line1, '"Comment"')
					or starts_with(line2, '"StartsAt"')
					or starts_with(line2, '"Comment"')
				then
					return "json.states"
				end
			end,
		},
	},
})

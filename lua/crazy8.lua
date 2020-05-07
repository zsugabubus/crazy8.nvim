-- LICENSE: GPLv3 or later
-- AUTHOR: zsugabubus
-- Detect options.
function Crazy8()
	-- We only care about the first 'textwidth' text.
	local textwidth = vim.api.nvim_buf_get_option(0, 'textwidth')
	if textwidth == 0 then
		textwidth = 80
	end

	local prev_lnum, prev_num_tabs, prev_num_spaces = -2, 0, 0
	local samples = 0
	local ts_samples, ts_stat = 0, {} -- Where tabs stop?
	local sw_samples, sw_stat, desw_stat = 0, {}, {} -- How big is an indentation?
	local use_tabs = false -- Do we really use tabs for 'tabstop's?

	for lnum, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, 1000, false)) do
		line = line:sub(0, textwidth)
		local tabs, spaces = line:match('^(\t*)( *)[^\t ]')
		if tabs == nil then
			goto skip
		end

		local num_tabs, num_spaces = #tabs, #spaces

		samples = samples + 1
		if prev_lnum + 1 ~= lnum then
			prev_num_tabs, prev_num_spaces = 0, 0
		end

		local diff_tabs = math.abs(num_tabs - prev_num_tabs)
		local any_tabs = num_tabs > 0 or prev_num_tabs > 0
		local diff_spaces = math.abs(num_spaces - prev_num_spaces)

		if diff_tabs == 0 and diff_spaces ~= 0 then
			if num_spaces > prev_num_spaces then
				-- Number of tabs remained, but spaces changed. => Ident used spaces.
				sw_stat[diff_spaces] = (sw_stat[diff_spaces] or 0) + 1
				sw_samples = sw_samples + 1
			else
				-- Indent decreased. But what size? One or two? Maybe three?
				desw_stat[diff_spaces] = (desw_stat[diff_spaces] or 0) + 1
			end
			if any_tabs then
				use_tabs = true
			end
		elseif diff_tabs ~= 0 and diff_spaces % diff_tabs == 0 then
			-- Tabs -> Spaces. => sw ~= ts
			-- Final value is best 'tabstop' + sw
			ts_stat[diff_spaces / diff_tabs] = (ts_stat[diff_spaces / diff_tabs] or 0) + 1
			ts_samples = ts_samples + 1
			use_tabs = true
		end

		if samples > 100 then
			break
		end

		::next::
		prev_lnum, prev_num_tabs, prev_num_spaces = lnum, num_tabs, num_spaces
		::skip::
	end

	local sw, ts = -1, -1

	for value, count in pairs(sw_stat) do
		for mul=value,textwidth - 1,value do
			count = count + (desw_stat[mul] or 0)
		end
		if sw_samples < count * 2 then
			sw = value
			break
		end
	end
	ts_stat[1] = nil -- Nobody wants one-sized tabs.
	for value, count in pairs(ts_stat) do
		if ts_samples < count * 2 then
			ts = value
			break
		end
	end

	-- We used tabs, but still do not know how much spaces are a tab.
	if ts <= 0 then
		local prev_lnum, prev_chunks = -2, {}

		-- Fill 'tabstop' entries with zeros that we are interested in.
		local ts_stat = {}
		for ts=2,textwidth - 1 do
			ts_stat[ts] = 0
		end

		for lnum, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, 1000, false)) do
			line = line:sub(0, textwidth)

			local chunks = {}
			for text, tabs in line:gfind('([^\t]*)(\t+)') do
				table.insert(chunks, {vim.api.nvim_strwidth(text), #tabs - 1})
			end
			if #chunks == 0 then
				goto skip
			end

			if prev_lnum + 1 ~= lnum then
				goto next
			end

			for ts, _ in pairs(ts_stat) do
				local nth = 0
				local curr, prev = 0, 0
				local currw, prevw = 0, 0

				while true do
					local cmp = currw - prevw
					if cmp == 0 then
						ts_stat[ts] = ts_stat[ts] + nth
						nth = nth + 1
					end

					if cmp <= 0 then
						curr = curr + 1
						if #chunks < curr then
							break
						end
						currw = currw + chunks[curr][1] + chunks[curr][2] * ts
						if currw >= textwidth then
							if curr == 1 then
								goto next
							else
								break
							end
						end
						currw = currw + (ts - (currw % ts))
					end

					if cmp >= 0 then
						prev = prev + 1
						if #prev_chunks < prev then
							break
						end
						prevw = prevw + prev_chunks[prev][1] + prev_chunks[prev][2] * ts
						if prevw >= textwidth then
							if prev == 1 then
								goto next
							else
								break
							end
						end
						prevw = prevw + (ts - (prevw % ts))
					end

				end
			end

			::next::
			prev_lnum = lnum
			prev_chunks = chunks
			::skip::
		end

		-- Prefer current value when find maximum.
		ts = vim.api.nvim_buf_get_option(0, 'tabstop')
		local max = ts_stat[ts] or 0

		for ts_, count in pairs(ts_stat) do
			if count > max then
				ts, max = ts_, count
			end
		end

		if max ~= 0 then
			-- There were no space indentation.
			if sw == -1 then
				use_tabs = true
				sw = ts
			end
		else
			ts = sw > 0 and sw or -1
		end
	elseif sw >= 0 then
		use_tabs = true
		ts = ts + sw
	end

	if ts > 0 then
		vim.api.nvim_command(
			('setlocal tabstop=%d'):format(ts)
		)
	end
	if sw > 0 then
		vim.api.nvim_command(
			('setlocal shiftwidth=%d softtabstop=%d'):format(sw, sw)
		)
		if not use_tabs then
			vim.api.nvim_command('setlocal expandtab')
		end
	end
	if use_tabs then
		vim.api.nvim_command('setlocal noexpandtab')
	end
end

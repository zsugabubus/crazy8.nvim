-- LICENSE: GPLv3 or later
-- AUTHOR: zsugabubus

-- Detect options.
function Crazy8()
	-- We only care about the first 'textwidth' text.
	local verbose = vim.api.nvim_get_option('verbose')

	local textwidth = vim.api.nvim_buf_get_option(0, 'textwidth')
	if textwidth == 0 then
		textwidth = 80
	end

	-- We make our decision on scientific, statistical bases.
	local prev_lnum, prev_num_tabs, prev_num_spaces = -2, 0, 0
	local samples = 0
	local ts_samples, ts_stat = 0, {} -- Where tabs stop?
	local sw_samples, sw_stat, desw_stat = 0, {}, {} -- How big is an indentation?
	local use_tabs = false -- Do we really use tabs for 'tabstop's?

	for lnum, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, 1000, false)) do
		line = line:sub(0, textwidth)
		local tabs, spaces = line:match('^(\t*)( *)[^\t ]')
		-- Line is not indented.
		if tabs == nil then
			goto skip
		end

		local num_tabs, num_spaces = #tabs, #spaces

		samples = samples + 1
		if prev_lnum + 1 ~= lnum then
			prev_num_tabs, prev_num_spaces = 0, 0
		end

		if num_tabs == 0 then
			-- vim.api.nvim_call_function('synIDattr', synIDtrans(synID(lnum, 1, 1)), "name") =~? 'comment|string'
		end

		local diff_tabs = math.abs(num_tabs - prev_num_tabs)
		local any_tabs = num_tabs > 0 or prev_num_tabs > 0
		local diff_spaces = math.abs(num_spaces - prev_num_spaces)

		if diff_tabs == 0 and diff_spaces ~= 0 then
			if num_spaces > prev_num_spaces then
				-- Number of tabs remained, but spaces changed. => Ident used spaces.
				sw_stat[diff_spaces] = (sw_stat[diff_spaces] or 0) + 1
			else
				-- Indent decreased. But what size? One or two? Maybe three?
				desw_stat[diff_spaces] = (desw_stat[diff_spaces] or 0) + 1
			end
			sw_samples = sw_samples + 1
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

		-- We must have collected enough samples to decide.
		if samples > 100 then
			break
		end

		prev_lnum, prev_num_tabs, prev_num_spaces = lnum, num_tabs, num_spaces
		::skip::
	end

	local sw, ts = -1, -1

	-- Find best shift width and tabstop.
	--
	-- However, we need be more sophisticated about shift width because a
	-- deindetation could skip more indentation levels so we cannot be sure what
	-- shift width are they really belonging to.
	-- For example if desw_stat = {6: 2} means that there were two lines where
	-- indentation jumped back six spaces. However searched shift width maybe 3
	-- and then it means that two levels were skipped back at once in these
	-- cases. For this reason, when considering shift width x, be also add to
	-- this number the count of deintetation shift widts of x,2*x,3*x...
	for value, count in pairs(sw_stat) do
		if value ~= 1 then
			for mul=value,textwidth - 1,value do
				count = count + (desw_stat[mul] or 0)
			end
		end
		if sw_samples < count * 2 then
			sw = value
			break
		end
	end
	ts_stat[1] = nil -- Nobody wants one-sized tabs. Here.
	for value, count in pairs(ts_stat) do
		if ts_samples < count * 2 then
			ts = value
			break
		end
	end

	if verbose > 0 then
		print('sw '..vim.inspect(sw_stat)..' => '..sw)
		print('desw '..vim.inspect(desw_stat))
		print('ts '..vim.inspect(ts_stat)..' => '..ts)
	end
	-- Tab width still unknown (maybe becase there were no leading tabs or if
	-- were there width can be any size) we have to use a little bit more
	-- expensive heuristics: We check lines one by one to figure out what tab
	-- size they are aligned to each other the best.
	if ts <= 0 then
		local prev_lnum, prev_splits, prev_has_tabs = -2, {}, false

		-- Fill 'tabstop' entries with zeros that we are interested in.
		local ts_stat = {}
		-- Width of tab could not be determined and shift width is junk.
		if ts == 0 then
			sw = -1
		end
		if sw <= 1 then
			for ts=2,textwidth - 1 do
				ts_stat[ts] = 0
			end
		else
			for ts=2*sw,textwidth - 1,sw do
				ts_stat[ts] = 0
			end
		end

		for lnum, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, 1000, false)) do
			line = line:sub(0, textwidth)

			local splits, has_tabs = {}, false
			for text, tabs, spaces in line:gfind('([^\t (]*)(\t*)([ (]*)') do
				if #tabs == 0 and #spaces == 0 then
					if #text == 0 then
						break
					else
						goto next_split
					end
				end
				table.insert(splits, {vim.api.nvim_strwidth(text), #tabs, #spaces})
				has_tabs = has_tabs or (#tabs > 0)
				::next_split::
			end
			if #splits == 0 then
				goto skip
			end

			-- Only consecutive lines are useful.
			if prev_lnum + 1 ~= lnum then
				goto next
			end
			-- If neither lines had tabs inside, there is not more we can do.
			if not has_tabs and not prev_has_tabs then
				goto next
			end

			-- Go for each tab size.
			for ts, _ in pairs(ts_stat) do
				local weight = 0
				local curr, prev = 0, 0
				local currw, prevw = 0, 0

				while true do
					local cmp = currw - prevw
					if cmp == 0 and curr > 0 and prev > 0  then
						-- tab+space|
						-- tab+space|
						--    OR
						-- tab|
						-- tab|
						--    OR something like this...
						if splits[curr][2] + prev_splits[prev][2] > 0 and ((splits[curr][3] > 0) == (0 < prev_splits[prev][3])) then
							weight = weight + 1
							ts_stat[ts] = ts_stat[ts] + weight
						end
					end

					if cmp <= 0 then
						curr = curr + 1
						if #splits < curr then
							break
						end
						currw = currw + splits[curr][1] + splits[curr][2] * ts
						currw = currw - (splits[curr][2] > 0 and currw % ts or 0) + splits[curr][3]
						-- Exit if we went past 'textwidth'. Nobody has tab size set larger
						-- than 'textwidth'. Or if has, go fsck yourself.
						if currw >= textwidth then
							-- If we went past 'textwidth' already at the first iteration we
							-- can finish the whole loop now because tab sizes are
							-- increasing, so if we went past, the next one will surely too.
							-- If you wonder if it helps a lot: yes. Becase we consider crazy
							-- 'tabsize's like 50.
							if curr == 1 then
								goto next
							else
								break
							end
						end
					end

					if cmp >= 0 then
						prev = prev + 1
						if #prev_splits < prev then
							break
						end
						prevw = prevw + prev_splits[prev][1] + prev_splits[prev][2] * ts
						prevw = prevw - (prev_splits[prev][2] > 0 and prevw % ts or 0) + prev_splits[prev][3]
						if prevw >= textwidth then
							if prev == 1 then
								goto next
							else
								break
							end
						end
					end

				end
			end

			::next::
			prev_lnum, prev_splits, prev_has_tabs = lnum, splits, has_tabs
			::skip::
		end

		-- Prefer current value of 'tabstop' when finding the best.
		ts = vim.api.nvim_buf_get_option(0, 'tabstop')
		local max = ts_stat[ts] or 0

		for ts_, count in pairs(ts_stat) do
			if count > max then
				ts, max = ts_, count
			end
		end

		if verbose > 0 then
			print('ts2 '..vim.inspect(ts_stat) .. ' => '..ts)
		end
		if max ~= 0 then
			-- There were no space indentation.
			if sw == -1 then
				use_tabs = true
				sw = ts
			end
		else
			-- No luck. Probably there were no tabs at all in the whole text.
			-- However, if we have shift width, use it as 'tabstop'. We maybe did not
			-- found any tabulators because 'expandtab' should be set and a shift
			-- width equals to 'tabsize'.
			ts = sw >= 1 and sw or -1
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

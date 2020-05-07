-- LICENSE: GPLv3 or later
-- AUTHOR: zsugabubus
function detect()
	local textwidth = vim.api.nvim_get_option('textwidth')
	if textwidth == 0 then
		textwidth = 80
	end

	local prev_lnum, prev_ntabs, prev_nspaces = -2, 0, 0
	local nsample = 0
	local swsum, swstat = 0, {}
	local stssum, stsstat = 0, {}

	local tabchunks = {}

	local et = 0

	for lnum, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, 1000, false)) do
		line = line:sub(0, textwidth)
		local tabs, spaces = line:match('^(\t*)( *)[^\t ]')
		if tabs == nil then
			goto skip
		end

		local ntabs, nspaces = #tabs, #spaces

		local dtabs = math.abs(ntabs - prev_ntabs)
		local dspaces = math.abs(nspaces - prev_nspaces)

		if prev_lnum + 1 ~= lnum then
			goto next
		end
		nsample = nsample + 1

		if ntabs == prev_ntabs then
			if dspaces ~= 0 then
				swsum = swsum + 1
				swstat[dspaces] = (swstat[dspaces] or 0) + 1
				et = et + 1
			end
		else
			if dspaces == 0 then
				if dtabs == 1 then
					et = et - 1
				end
			else
				if nspaces == 0 or prev_nspaces == 0 then
					stssum = stsum + 1
					stsstat[dspaces] = (stsstat[dspaces] or 1) + 1
				end
			end
		end

		if nspaces > 100 then
			break
		end

		::next::
		prev_lnum, prev_ntabs, prev_nspaces = lnum, ntabs, nspaces
		::skip::
	end

	local guess_ts = true

	if et < -nsample / 20 then
		vim.api.nvim_command('setlocal noexpandtab')
	elseif et > nsample / 20 then
		vim.api.nvim_command('setlocal expandtab')
		guess_ts = false
	end

	for sw, count in pairs(swstat) do
		if swsum >= count * 2 then
			goto next_sw
		end

		vim.api.nvim_command('setlocal shiftwidth='..sw)

		if et > nsample / 20 then
			vim.api.nvim_command(
				('setlocal tabstop=%d softtabstop=%d'):format(sw, sw)
			)
			guess_ts = false
		end

		for sts, count in pairs(stsstat) do
			if stssum >= count * 2 then
				goto next_sts
			end

			vim.api.nvim_command(
				('setlocal softtabstop=%d tabstop=%d noexpandtab'):format(sts + sw, sts + sw)
			)
			guess_ts = false

			::next_sts::
		end
		::next_sw::
	end

	if guess_ts then
		local nsample = 0
		local strwidth = vim.api.nvim_strwidth
		local prev_lnum, prev_chunks = -2, {}

		local tsstat = {}
		for ts=2,textwidth - 1 do
			tsstat[ts] = 0
		end

		for lnum, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, 1000, false)) do
			line = line:sub(0, textwidth)
			local chunks = {}
			for text, tabs in line:gfind('([^\t]+)(\t+)') do
				table.insert(chunks, {strwidth(text), #tabs - 1})
			end
			if #chunks == 0 then
				goto skip
			end
			if prev_lnum + 1 ~= lnum then
				goto next
			end
			nsample = nsample + 1

			for ts, _ in pairs(tsstat) do
				local nth = 0
				local curr, prev = 0, 0
				local currw, prevw = 0, 0

				while true do
					local cmp = currw - prevw
					if cmp == 0 then
						tsstat[ts] = tsstat[ts] + nth
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

		local maxts, max = 0, 0
		for ts=2,textwidth - 1 do
			if tsstat[ts] > max then
				maxts, max = ts, tsstat[ts]
			end
		end

		if maxts ~= 0 then
			vim.api.nvim_command(
				('setlocal tabstop=%d shiftwidth=%d softtabstop=%d noexpandtab'):format(maxts, maxts, maxts)
			)
		end

	end
end

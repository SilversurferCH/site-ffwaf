#!/usr/bin/lua

module('gluon.announce', package.seeall)

fs = require 'nixio.fs'
util = require 'gluon.util'
model_uci = require 'luci.model.uci'


local collect_dir

local function collect_entry(entry)
	if fs.stat(entry, 'type') == 'dir' then
		return collect_dir(entry)
	else
		return loadfile(entry)
	end
end

function collect_dir(dir)
	local fns = {}

	for entry in fs.dir(dir) do
		if entry:sub(1, 1) ~= '.' then
			collectgarbage()
			local fn, err = collect_entry(dir .. '/' .. entry)

			if fn then
				fns[entry] = fn
			else
				io.stderr:write(err, '\n')
			end
		end
	end

	return function ()
		local ret = { [{}] = true }

		for k, v in pairs(fns) do
			collectgarbage()
			local ok, val = pcall(setfenv(v, _M))

			if ok then
				ret[k] = val
			else
				io.stderr:write(val, '\n')
			end
		end

		collectgarbage()

		return ret
	end
end

function collect(dir)
	local f = collect_dir(dir)

	return function ()
		_M.uci = model_uci.cursor()
		ret = f()
		_M.uci = nil

		collectgarbage()

		return ret
	end
end

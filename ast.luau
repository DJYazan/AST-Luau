--TODO: Maybe add support for multiple variable declerations ('local a, b, c = foo()')
--TODO: Improve this code, its pretty chaotic
--this is prtty shit rn, will update it
--To remove useless variables completely, uncomment L97
--i'm adding a parser after this

local table_insert = table.insert
local table_concat = table.concat
local AST_m = {}

function AST_m.new(opt)
	local AST = {}
	opt = opt or {
		Instacall = false, -- from local v1 = loadstring('hi') v1() to loadstring('hi')() also it doesnt work
		IgnoreUselessVariables = true,
		RenameUselessVariables = false
	}
	function AST.prepare()
		local ____ = {}
		for __, ___ in pairs(AST) do
			if type(___) == 'table' then
				(____)[(__)] = (___)
			end
		end
		return (____)
	end
	local function replaceAllIndexes(tab, targetTab)
		for i, v in pairs(targetTab) do
			tab[i] = v
		end
	end
	local function trackVarAST(variableName)
		local __
		for _, ___ in pairs(AST.prepare()) do
			if ___.Variable == variableName and not ___.type:find('Move') then
				__ = ___
			end
		end
		return __
	end
	local function trackVarASTMove(variableName)
		local __
		for _, ___ in pairs(AST.prepare()) do
			if ___.Variable == variableName and ___.type:find('Move') then
				__ = ___
			end
		end
		return __
	end
	function AST.AddVariableDecleration(Variable, Value, IsGlobal)
		if type(Variable) ~= 'string' then
			error('Invalid argument to #1 (AddVariableDecleration) expected string, got ' .. type(Variable))
		end
		--if type(Value) ~= 'number' or type(Value) ~= 'string' then
		--	error('Invalid argument to #2 (AddVariableDecleration) expected string, got ' .. type(Value))
		--end
		if type(IsGlobal) ~= 'boolean' then
			error('Invalid argument to #3 (AddVariableDecleration) expected boolean, got ' .. type(Variable))
		end
		if trackVarAST(Variable) then
			table_insert(AST, {
				Variable = tostring(Variable),
				Value = Value,
				type = 'MoveVariableAssignment',
				isGlobal = IsGlobal,
			})
		else
			table_insert(AST, {
				Variable = tostring(Variable),
				Value = Value,
				type = 'VariableAssignment',
				isGlobal = IsGlobal,
			})
		end
		
	end
	function AST.AddCallDecleration(Variable, Tocall, Args)
		if type(Variable) ~= 'string' then
			error('Invalid argument to #1 (AddCallDecleration) expected string, got ' .. type(Variable))
		end
		--if type(Value) ~= 'number' or type(Value) ~= 'string' then
		--	error('Invalid argument to #2 (AddVariableDecleration) expected string, got ' .. type(Value))
		--end
		if trackVarAST(Variable) then
			table_insert(AST, {
				Variable = tostring(Variable),
				tocall = Tocall,
				type = 'MoveCallAssignment',
				args = Args,
			})
		else
			table_insert(AST, {
				Variable = tostring(Variable),
				tocall = Tocall,
				type = 'CallAssignment',
				args = Args,
			})
		end
	end
	
	function AST.AddNamecallDecleration(Variable, Tocall, k, Args)
		if type(Variable) ~= 'string' then
			error('Invalid argument to #1 (AddCallDecleration) expected string, got ' .. type(Variable))
		end
		--if type(Value) ~= 'number' or type(Value) ~= 'string' then
		--	error('Invalid argument to #2 (AddVariableDecleration) expected string, got ' .. type(Value))
		--end
		if trackVarAST(Variable) then
			table_insert(AST, {
				Variable = tostring(Variable),
				tocall = Tocall,
				k = k,
				type = 'MoveNamecallAssignment',
				args = Args,
			})
		else
			table_insert(AST, {
				Variable = tostring(Variable),
				tocall = Tocall,
				k = k,
				type = 'NamecallAssignment',
				args = Args,
			})
		end
		
	end
	AST.trackVarAST = trackVarAST
	function AST.optimize()
		local prepped = AST.prepare()
		for i, v in pairs(prepped) do
			if v.type == 'VariableAssignment' or v.type == 'MoveVariableAssignment' then
				v.used = false
			end
			if v.type == 'CallAssignment' or v.type == 'NamecallAssignment'  or v.type == 'MoveCallAssignment' or v.type == 'MoveNamecallAssignment' then
				v.ref = false
			end
		end
		for i, v in pairs(prepped) do
			if v.type == 'CallAssignment' then
				print(trackVarAST(v.tocall))
				if trackVarAST(v.tocall) ~= nil then
					v.tocall = trackVarAST(v.tocall).Value or v.tocall
					if trackVarAST(v.tocall) ~= nil then
						if trackVarAST(v.tocall).type == 'NamecallAssignment' or trackVarAST(v.tocall).type == 'CallAssignment' then
							--v.tocall = trackVarAST(v.tocall).tocall
							--print('g', trackVarAST(v.tocall))
							--v.k = trackVarAST(v.tocall).k
							--v.args = trackVarAST(v.tocall).args
							--v.type = 'NamecallDecleration'
							trackVarAST(v.tocall).ref = true
							--print('BREH CALL' .. tostring(trackVarAST(v.tocall)))
						end
					end
				end
				local args = {}
				local function getrealtimearg(arg)
					local arg_
					if trackVarAST(arg) then
						if trackVarAST(arg).type == 'VariableAssignment' then
							arg_ = trackVarAST(arg).Value
						elseif trackVarAST(arg).type == 'CallAssignment' then
							arg_ = tostring(trackVarAST(arg).tocall) .. '(' .. table_concat(trackVarAST(arg).args, ', ') .. ')'
						end
					else
						arg_ = arg
					end
					return arg_ or arg
				end
				for i, v in pairs(v.args) do
					args[i] = getrealtimearg(v)
				end
				v.args = args
			elseif v.type == 'NamecallAssignment' then
				print(trackVarAST(v.tocall))
				if trackVarAST(v.tocall) ~= nil then
					v.tocall = trackVarAST(v.tocall).Value or v.tocall
					if trackVarAST(v.tocall) ~= nil then
						if trackVarAST(v.tocall).type == 'NamecallAssignment' or trackVarAST(v.tocall).type == 'CallAssignment' then
							if opt.UseNamecallDirectly then
								v.tocall = trackVarAST(v.tocall).tocall
								v.k = trackVarAST(v.tocall).k
								v.args = trackVarAST(v.tocall).args
								v.type = 'NamecallDecleration'
							else
								trackVarAST(v.tocall).ref = true
							end
							--print('BREH CALL' .. tostring(trackVarAST(v.tocall)))
						end
					end
				end
				local args = {}
				local function getrealtimearg(arg)
					local arg_
					if trackVarAST(arg) then
						if trackVarAST(arg).type == 'VariableAssignment' then
							arg_ = trackVarAST(arg).Value
						elseif trackVarAST(arg).type == 'CallAssignment' then
							arg_ = tostring(trackVarAST(arg).tocall) .. '(' .. table_concat(trackVarAST(arg).args, ', ') .. ')'
						end
					else
						arg_ = arg
					end
					return arg_ or arg
				end
				for i, v in pairs(v.args) do
					args[i] = getrealtimearg(v)
				end
				v.args = args
			elseif v.type == 'MoveNamecallAssignment' then
				print(trackVarAST(v.tocall))
				trackVarAST(v.Variable).Value = v.Value
				if trackVarAST(v.tocall) ~= nil then
					v.tocall = trackVarAST(v.tocall).Value or v.tocall
					if trackVarAST(v.tocall) ~= nil then
						if trackVarAST(v.tocall).type == 'NamecallAssignment' or trackVarAST(v.tocall).type == 'CallAssignment' then
							if opt.UseNamecallDirectly then
								v.tocall = trackVarAST(v.tocall).tocall
								v.k = trackVarAST(v.tocall).k
								v.args = trackVarAST(v.tocall).args
								v.type = 'NamecallDecleration'
							else
								trackVarAST(v.tocall).ref = true
							end
							--print('BREH CALL' .. tostring(trackVarAST(v.tocall)))
						end
					end
				end
				local args = {}
				local function getrealtimearg(arg)
					local arg_
					if trackVarAST(arg) then
						if trackVarAST(arg).type == 'VariableAssignment' then
							arg_ = trackVarAST(arg).Value
						elseif trackVarAST(arg).type == 'CallAssignment' then
							arg_ = tostring(trackVarAST(arg).tocall) .. '(' .. table_concat(trackVarAST(arg).args, ', ') .. ')'
						end
					else
						arg_ = arg
					end
					return arg_ or arg
				end
				for i, v in pairs(v.args) do
					args[i] = getrealtimearg(v)
				end
				v.args = args
			elseif v.type == 'MoveCallAssignment' then
				print(trackVarAST(v.tocall))
				trackVarAST(v.Variable).Value = v.Value
				if trackVarAST(v.tocall) ~= nil then
					v.tocall = trackVarAST(v.tocall).Value or v.tocall
					if trackVarAST(v.tocall) ~= nil then
						if trackVarAST(v.tocall).type == 'NamecallAssignment' or trackVarAST(v.tocall).type == 'CallAssignment' then
							--v.tocall = trackVarAST(v.tocall).tocall
							--print('g', trackVarAST(v.tocall))
							--v.k = trackVarAST(v.tocall).k
							--v.args = trackVarAST(v.tocall).args
							--v.type = 'NamecallDecleration'
							trackVarAST(v.tocall).ref = true
							--print('BREH CALL' .. tostring(trackVarAST(v.tocall)))
						end
					end
				end
				local args = {}
				local function getrealtimearg(arg)
					local arg_
					if trackVarAST(arg) then
						if trackVarAST(arg).type == 'VariableAssignment' then
							arg_ = trackVarAST(arg).Value
						elseif trackVarAST(arg).type == 'CallAssignment' then
							arg_ = tostring(trackVarAST(arg).tocall) .. '(' .. table_concat(trackVarAST(arg).args, ', ') .. ')'
						end
					else
						arg_ = arg
					end
					return arg_ or arg
				end
				for i, v in pairs(v.args) do
					args[i] = getrealtimearg(v)
				end
				v.args = args
			elseif v.type == 'MoveVariableAssignment' then
				trackVarAST(v.Variable).Value = v.Value
			end
		end
		for i, v in pairs(prepped) do
			if v.used == false then
				if opt.IgnoreUselessVariables then
					v.ignore = true
				end
				if opt.RenameUselessVariables then
					v.Variable = "_"
				end
			end
		end
	end
	function AST.toLua(concat)
		local code = {}
		local indentation = 0
		local function GetIndentString()
			local __ = ""
			for ___ = 1, indentation do
				__ = __ .. "	"
			end
			return __ or ""
		end
		local function c(s)
			return GetIndentString() .. s
		end
		local AST_prepare = AST.prepare()
		for i, v in pairs(AST_prepare) do
			if v.ignore == true then continue end
			if v.type == 'VariableAssignment' then
				if v.isGlobal == false then
					table_insert(code, c(`local {v.Variable} = {v.Value};`))
				else
					table_insert(code, c(`{v.Variable} = {v.Value};`))
				end
			elseif v.type == 'CallAssignment' then
				if v.ref == false then
					table_insert(code, `{v.tocall}({table_concat(v.args, ', ')});`)
				else
					table_insert(code, `{v.Variable} = {v.tocall}({table_concat(v.args, ', ')});`)
				end
			elseif v.type == 'NamecallAssignment' then
				if v.ref == false then
					table_insert(code, `{v.tocall}:{v.k}({table_concat(v.args, ', ')});`)
				else
					table_insert(code, `{v.Variable} = {v.tocall}:{v.k}({table_concat(v.args, ', ')});`)
				end
			elseif v.type == 'MoveVariableAssignment' then
				trackVarAST(v.Variable).Value = v.Value
				if v.isGlobal == false then
					table_insert(code, c(`local {v.Variable} = {v.Value};`))
				else
					table_insert(code, c(`{v.Variable} = {v.Value};`))
				end
			elseif v.type == 'MoveCallAssignment' then
				trackVarAST(v.Variable).Value = v.Value
				if v.ref == false then
					table_insert(code, `{v.tocall}({table_concat(v.args, ', ')});`)
				else
					table_insert(code, `{v.Variable} = {v.tocall}({table_concat(v.args, ', ')});`)
				end
			end
		end
		if concat == true or concat == nil then
			return table.concat(code, '\n')
		else
			return code
		end
	end
	return AST
end

return AST_m

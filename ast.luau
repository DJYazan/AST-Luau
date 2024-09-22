--TODO: Maybe add support for multiple variable declerations ('local a, b, c = foo()')
--this is prtty shit rn, will update it
--To remove useless variables completely, uncomment L97

local table_insert = table.insert
local table_concat = table.concat
local AST_m = {}

function AST_m.new()
	local AST = {}
	function AST.prepare()
		local ____ = {}
		for __, ___ in pairs(AST) do
			if type(___) == 'table' then
				(____)[(__)] = (___)
			end
		end
		return (____)
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
		table_insert(AST, {
			Variable = tostring(Variable),
			Value = Value,
			type = 'VariableAssignment',
			isGlobal = IsGlobal,
		})
	end
	function AST.AddCallDecleration(Variable, Tocall, Args)
		if type(Variable) ~= 'string' then
			error('Invalid argument to #1 (AddCallDecleration) expected string, got ' .. type(Variable))
		end
		--if type(Value) ~= 'number' or type(Value) ~= 'string' then
		--	error('Invalid argument to #2 (AddVariableDecleration) expected string, got ' .. type(Value))
		--end
		table_insert(AST, {
			Variable = tostring(Variable),
			tocall = Tocall,
			type = 'CallAssignment',
			args = Args,
		})
	end
	
	function AST.AddNamecallDecleration(Variable, Tocall, k, Args)
		if type(Variable) ~= 'string' then
			error('Invalid argument to #1 (AddCallDecleration) expected string, got ' .. type(Variable))
		end
		--if type(Value) ~= 'number' or type(Value) ~= 'string' then
		--	error('Invalid argument to #2 (AddVariableDecleration) expected string, got ' .. type(Value))
		--end
		table_insert(AST, {
			Variable = tostring(Variable),
			tocall = Tocall,
			k = k,
			type = 'NamecallAssignment',
			args = Args,
		})
	end
	local function trackVarAST(variableName)
		local __
		for _, ___ in pairs(AST.prepare()) do
			if ___.Variable == variableName then
				__ = ___
			end
		end
		return __
	end
	AST.trackVarAST = trackVarAST
	function AST.optimize()
		local prepped = AST.prepare()
		for i, v in pairs(prepped) do
			if v.type == 'VariableAssignment' then
				v.used = false
			end
			if v.type == 'CallAssignment' then
				v.ref = false
			end
		end
		for i, v in pairs(prepped) do
			if v.type == 'CallAssignment' then
				print(trackVarAST(v.tocall))
				if trackVarAST(v.tocall) then
					v.tocall = trackVarAST(v.tocall).Value or v.tocall
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
				if trackVarAST(v.tocall) then
					v.tocall = trackVarAST(v.tocall).Value or v.tocall
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
			end
		end
		for i, v in pairs(prepped) do
			if v.used == false then
				v.ignore = true
				--v.Variable = "_"
			end
		end
	end
	function AST.toLua()
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
			end
		end
		return table.concat(code, '\n')
	end
	return AST
end

--[[local AST = AST_m.new()
AST.AddVariableDecleration('v1', 'print', false)
AST.AddVariableDecleration('u1', '"raw.gith"', false)
AST.AddNamecallDecleration('v5', 'game', 'HttpGet', {'u1'})
AST.AddVariableDecleration('v2', '"Hello World!"', false)
AST.AddCallDecleration('v3', 'v1', {'v2'})
AST.AddCallDecleration('v18', 'v5', {})
print(AST)
AST.optimize()
print(AST.toLua())--]]

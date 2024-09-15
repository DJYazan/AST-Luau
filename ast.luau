--TODO: Add Support for multiple Variables and add support for if statements and loops
--TODO: Fix all the bugs, its very buggy
local AST_Module = {}

function AST_Module.new()
	local AST = {}
	local indent = 0

	function AST:prepare()
		local newAST = {}
		for _, v in pairs(AST) do
			if type(v) ~= "function" then
				table.insert(newAST, v)
			end
		end
		return newAST
	end

	function AST:AddVariable(variableName, value, isGlobal)
		table.insert(AST, {
			type = "VariableAssignment",
			l = variableName,
			r = value,
			isGlobal = isGlobal,
			isLuauGlobal = isGlobal
		})
	end

	function AST:AddNamecall(variableName, namecall, namecallK, args)
		table.insert(AST, {
			type = "NamecallAssignment",
			l = variableName,
			r = namecall,
			NamecallK = namecallK,
			args = args,
			isGlobal = true
		})
	end
	function AST:AddCall(variableName, variableToCall, args)
		table.insert(AST, {
			type = "CallAssignment",
			l = variableName,
			r = variableToCall,
			args = args,
			isGlobal = true
		})
	end
	function AST:AddTableAssignment(variableName, value, tableIndex, assignType)
		table.insert(AST, {
			type = "TableAssignment",
			l = variableName,
			r = value,
			tableIndex = tableIndex,
			assignType = assignType
		})
	end
	function AST:AddReturn(args)
		table.insert(AST, {
			type = "ReturnInstruction",
			args = args
		})
	end
	function AST:AddClosure(closureName, args, transpiledAST)
		table.insert(AST, {
			type = "Closure",
			AST = transpiledAST,
			functionName = closureName,
			params = args,
		})
	end
	function AST:AddForIndexLoop(indexVar, index, indexVar2, indexVar3)
		table.insert(AST, {
			type = "ForIndexLoop",
			Index1 = indexVar,
			IndexIn = index,
			Index2 = indexVar2,
			Index3 = indexVar3
		})
	end
	function AST:AddEndLine(type)
		table.insert(AST, {
			type = "EndLine",
			EndLineType = type -- {"ForIndexLoop"}
		})
	end
	local function containsSpecialCharacters(str)
		local isOnlyNumbers = string.match(str, "^%d+$") ~= nil
		local hasSpecialChars = string.find(str, "[^%w_]") ~= nil
		return hasSpecialChars or isOnlyNumbers
	end
	local function findVariable(targetVariable)
		for _, v in pairs(AST:prepare()) do
			if v.l == targetVariable then
				return v
			end
		end
		return nil
	end
	function AST:MoveVariable(var, value)
		local targetAST = findVariable(var)
		if not targetAST then -- AST might not exist, so we reassign the variable
			table.insert(AST, {
				type = "VariableAssignment",
				l = var,
				r = value,
				isGlobal = true,
				isLuauGlobal = false
			})
		else
			targetAST.r = value
		end
	end
	local function getIndentString()
		local s = ""
		for i = 1, indent do
			s = s .. "	"
		end
		return s
	end
	function AST:Optimize()
		local AST = AST:prepare()
		local astb = {}
		for _, v in pairs(AST) do
			v.used = false
			v.ignore = false
		end

		for i, v in pairs(AST) do
			if v.type == "VariableAssignment" then
				astb[v.l] = v
				astb[v.l].index = i
			elseif v.type == "CallAssignment" then
				assert(astb[v.r], "Node does not exist.")
				local args = {}
				for _, arg in pairs(v.args) do
					local targetAST = findVariable(arg)
					if targetAST then
						if targetAST.r == "{}" then
							table.insert(args, targetAST.l)
						else
							if targetAST.type == "Closure" then
								table.insert(args, targetAST:ToLua() or targetAST.l or targetAST.functionName)
							else
								table.insert(args, targetAST.r or targetAST.l)
							end
						end
					else
						table.insert(args, arg)
					end
				end
				v.args = args
				if astb[v.r].isLuauGlobal then
					v.r = astb[v.r].r
				end
				v.used = true
			elseif v.type == "NamecallAssignment" then
				assert(astb[v.r], "Node does not exist.")
				local args = {}
				for _, arg in pairs(v.args) do
					local targetAST = findVariable(arg)
					if targetAST then
						table.insert(args, targetAST.r or targetAST.l)
					else
						table.insert(args, arg)
					end
				end
				v.args = args
				if astb[v.r].isLuauGlobal then
					v.r = astb[v.r].r
				end
				v.r = string.format("%s:%s(%s)", v.r, v.NamecallK, table.concat(args, ", "))
				v.used = true
			elseif v.type == "TableAssignment" then
				assert(astb[v.l], "Table Node does not exist.")
				assert(v.assignType, "assignType is not defined.")
				findVariable(v.l).used = true
				if v.assignType == "variable" then
					local targetAST = findVariable(v.tableIndex)
					if targetAST and (targetAST.type == "VariableAssignment") then
						v.tableIndex = targetAST.r
					end
				end
				local targetAST = findVariable(v.r)
				if targetAST and (targetAST.type == "VariableAssignment") then
					v.r = targetAST.r
				elseif targetAST and (targetAST.type == "Closure") then
					targetAST.AST:Optimize()
					v.r = targetAST.AST:ToLua()
				end
			elseif v.type == "Closure" then
				--ignore closure?
			elseif v.type == "ReturnInstruction" then
				local args = {}
				for i, v in pairs(v.args) do
					local targetAST = findVariable(v)
					if v then
						if v.type == "VariableAssignment" then
							table.insert(args, v.r)
						else
							table.insert(args, v.l)
						end
					end
				end
			elseif v.type == "ForIndexLoop" then
				local Index1
				local InIndex
				local Index2
				local Index3
				local Index1AST = findVariable(v.Index1)
				local Index2AST = findVariable(v.Index2)
				local InIndexAST = findVariable(v.IndexIn)
				local Index3AST = findVariable(v.Index3)
				if Index1AST then
					if Index1AST.r then
						Index1 = Index1AST.r
					else
						Index1 = v.Index1
					end
				end
				if Index2AST then
					if Index2AST.r then
						Index2 = Index2AST.r
					else
						Index2 = v.Index2
					end
				end
				if Index3AST then
					if Index3AST.r == Index1AST.r then
					else
						if Index3AST.r then
							Index3 = Index3AST.r
						else
							Index3 = v.Index3
						end
					end
				end
				if InIndexAST then
					if InIndexAST.r then
						InIndex = InIndexAST.r
					else
						InIndex = v.IndexIn
					end
				end
				v.IndexIn = InIndex
				v.Index2 = Index2
				v.Index3 = Index3
			end
		end
		for _, v in pairs(AST) do
			if not v.used then
				if v.type == "VariableAssignment" then
					v.l = "_"
					v.ignore = true
				elseif v.type == "CallAssignment" then
					v.instantcall = true
				end
			end
		end
	end
	function AST:ToLua()
		local AST = AST:prepare()
		local lua = {}
		for _, v in pairs(AST) do
			if v.ignore then
				-- Skip ignored variables, continue to the next one
				continue
			end

			if v.type == "VariableAssignment" then
				if v.isGlobal then
					table.insert(lua, string.format(getIndentString() .. "%s = %s", v.l, v.r))
				else
					table.insert(lua, string.format(getIndentString() .. "local %s = %s", v.l, v.r))
				end
			elseif v.type == "CallAssignment" then
				if v.instantcall then
					table.insert(lua, string.format(getIndentString() .. "%s(%s)", v.r, table.concat(v.args, ", ")))
				else
					if v.isGlobal then
						table.insert(lua, string.format(getIndentString() .. "%s = %s(%s)", v.l, v.r, table.concat(v.args, ", ")))
					else
						table.insert(lua, string.format(getIndentString() .. "local %s = %s(%s)", v.l, v.r, table.concat(v.args, ", ")))
					end
				end
			elseif v.type == "NamecallAssignment" then
				table.insert(lua, string.format(getIndentString() .. "%s = %s", v.l, v.r))
			elseif v.type == "TableAssignment" then
				if containsSpecialCharacters(v.tableIndex) then
					table.insert(lua, string.format(getIndentString() .. "%s[\"%s\"] = %s", v.l, v.tableIndex, v.r))
				else
					table.insert(lua, string.format(getIndentString() .. "%s.%s = %s", v.l, v.tableIndex, v.r))
				end
			elseif v.type == "Closure" then
				table.insert(lua, string.format(getIndentString() .. "local function %s(%s)", v.functionName, table.concat(v.params, ", ")))
				indent = indent + 1
				v.AST:Optimize()
				table.insert(lua, getIndentString() .. v.AST:ToLua())
				indent = indent - 1
				table.insert(lua, getIndentString() .. "end")
			elseif v.type == "ReturnInstruction" then
				table.insert(lua, getIndentString() .. `return {table.concat(v.args, ", ")}`)
			elseif v.type == "ForIndexLoop" then
				if v.Index3 == nil then
					table.insert(lua, `for {v.Index1} = {v.Index2}, {v.IndexIn} do`)
					indent = indent + 1
				else
					table.insert(lua, `for {v.Index1} = {v.Index2}, {v.IndexIn}, {v.Index3} do`)
					indent = indent + 1
				end
			elseif v.type == "EndLine" then
				indent = indent - 1
				table.insert(lua, "end")
			end
		end
		return table.concat(lua, "\n")
	end

	return AST
end

return AST_Module

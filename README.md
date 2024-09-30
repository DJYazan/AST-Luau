# ASTify

# What is this?
This Module is designed to improve Lua Source and make it less redundant and improve overall speeds.

# How do i use it?

You can require this module using require:
```lua
local ASTify = require("./ast.luau")
```
or loadstring it
```lua
local get = http.get or httpget -- Replace this function with the HTTPGET function.
local ASTify = loadstring(get('https://raw.githubusercontent.com/DJYazan/AST-Luau/refs/heads/main/ast.luau'))()
```
Or you can paste it in manually by wrapping it in a function
```lua
local ASTify = (function()
  --AST content here (copy from raw URL) ^^
end)()
```

# Functions
```module.new(opt)``` // Creates a new AST with the specified options (parser not included)


```ast.optimize()``` // Optimizes the AST


```ast.tolua()``` // Turn the AST back to Lua Source

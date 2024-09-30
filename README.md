# ASTify

# What is this?
This Module is designed to improve Lua Source and make it less redundant and improve overall speeds.

# How do i use it?

You can require this module using require:
```lua
local astModule = require("./ast.luau)
```
or loadstring it
```lua
local get = http.get or httpget -- Replace this function with the HTTPGET function.
local ASTify = loadstring(get('raw url here'))

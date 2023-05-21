local parser = require("parser")
local compiler = require("compiler")
local interpreter = require("interpreter")

local input = io.read("a")
local ast = parser.parse(input)
local code = compiler.compile(ast)
local mem = {}
local stack = {}
local result = interpreter.run(code, mem, stack, 0)
print("result: " .. result)

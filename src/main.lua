local parser = require("parser")
local compiler = require("compiler")
local interpreter = require("interpreter")

local input = io.read("a")
local ast = parser.parse(input)
local code = compiler.compile(ast)
local result = interpreter.run(code, {}, {}, 0)
print("result: " .. result)

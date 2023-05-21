require 'busted.runner' ()
local interpreter = require("interpreter")

describe("run", function()
  it("ret", function()
    local result = interpreter.run({ "ret", 3 }, {}, { 1, 2, 3, 4 }, 0)
    assert.are.equal(1, result)
  end)

  it("push", function()
    local result = interpreter.run({ "push", 5, "ret", 0 }, {}, {}, 0)
    assert.are.equal(5, result)
  end)

  it("pop", function()
    local result = interpreter.run({ "pop", 2, "ret", 0 }, {}, { 1, 2, 3 }, 3)
    assert.are.equal(1, result)
  end)

  it("add", function()
    local result = interpreter.run({ "add", "ret", 0 }, {}, { 1, 2 }, 2)
    assert.are.equal(3, result)
  end)

  it("sub", function()
    local result = interpreter.run({ "sub", "ret", 0 }, {}, { 2, 1 }, 2)
    assert.are.equal(1, result)
  end)

  it("mul", function()
    local result = interpreter.run({ "mul", "ret", 0 }, {}, { 2, 2 }, 2)
    assert.are.equal(4, result)
  end)

  it("div", function()
    local result = interpreter.run({ "div", "ret", 0 }, {}, { 8, 2 }, 2)
    assert.are.equal(4, result)
  end)

  it("rem", function()
    local result = interpreter.run({ "rem", "ret", 0 }, {}, { 9, 2 }, 2)
    assert.are.equal(1, result)
  end)

  it("exp", function()
    local result = interpreter.run({ "exp", "ret", 0 }, {}, { 2, 3 }, 2)
    assert.are.equal(8, result)
  end)

  it("eq", function()
    local result = interpreter.run({ "eq", "ret", 0 }, {}, { 2, 2 }, 2)
    assert.are.equal(1, result)

    result = interpreter.run({ "eq", "ret", 0 }, {}, { 2, 3 }, 2)
    assert.are.equal(0, result)
  end)

  it("neq", function()
    local result = interpreter.run({ "neq", "ret", 0 }, {}, { 2, 2 }, 2)
    assert.are.equal(0, result)

    result = interpreter.run({ "neq", "ret", 0 }, {}, { 2, 3 }, 2)
    assert.are.equal(1, result)
  end)

  it("lte", function()
    local lower = interpreter.run({ "lte", "ret", 0 }, {}, { 1, 2 }, 2)
    assert.are.equal(1, lower)

    local equal = interpreter.run({ "lte", "ret", 0 }, {}, { 2, 2 }, 2)
    assert.are.equal(1, equal)

    local greater = interpreter.run({ "lte", "ret", 0 }, {}, { 3, 2 }, 2)
    assert.are.equal(0, greater)
  end)

  it("gte", function()
    local greater = interpreter.run({ "gte", "ret", 0 }, {}, { 2, 1 }, 2)
    assert.are.equal(1, greater)

    local equal = interpreter.run({ "gte", "ret", 0 }, {}, { 2, 2 }, 2)
    assert.are.equal(1, equal)

    local lower = interpreter.run({ "gte", "ret", 0 }, {}, { 2, 3 }, 2)
    assert.are.equal(0, lower)
  end)

  it("lt", function()
    local lower = interpreter.run({ "lt", "ret", 0 }, {}, { 2, 3 }, 2)
    assert.are.equal(1, lower)

    local equal = interpreter.run({ "lt", "ret", 0 }, {}, { 2, 2 }, 2)
    assert.are.equal(0, equal)

    local greater = interpreter.run({ "lt", "ret", 0 }, {}, { 2, 1 }, 2)
    assert.are.equal(0, greater)
  end)

  it("gt", function()
    local greater = interpreter.run({ "gt", "ret", 0 }, {}, { 2, 1 }, 2)
    assert.are.equal(1, greater)

    local equal = interpreter.run({ "gt", "ret", 0 }, {}, { 2, 2 }, 2)
    assert.are.equal(0, equal)

    local lower = interpreter.run({ "gt", "ret", 0 }, {}, { 2, 3 }, 2)
    assert.are.equal(0, lower)
  end)

  it("not", function()
    local truthy = interpreter.run({ "not", "ret", 0 }, {}, { 2 }, 1)
    assert.are.equal(0, truthy)

    local falsy = interpreter.run({ "not", "ret", 0 }, {}, { 0 }, 1)
    assert.are.equal(1, falsy)
  end)

  it("store", function()
    local mem = {}
    interpreter.run({ "store", 1, "ret", 0 }, mem, { 2 }, 1)
    assert.are.equal(2, mem[1])
  end)

  it("load", function()
    local result = interpreter.run({ "load", 1, "ret", 0 }, { [1] = 2 }, {}, 0)
    assert.are.equal(2, result)
  end)

  it("storeL", function()
    local result = interpreter.run({ "storeL", 1, "ret", 0 }, {}, { 7, 3 }, 2)
    assert.are.equal(7, result)
  end)

  it("loadL", function()
    local result = interpreter.run({ "loadL", 1, "ret", 0 }, {}, { 2, 5, 7 }, 3)
    assert.are.equal(2, result)
  end)

  it("call", function()
    local result = interpreter.run({ "call", { "push", 2, "ret", 0 }, "ret", 0 }, {}, {}, 0)
    assert.are.equal(2, result)
  end)

  it("jmp", function()
    local result = interpreter.run({ "jmp", 2, "push", 2, "push", 3, "ret", 0 }, {}, {}, 0)
    assert.are.equal(3, result)
  end)

  it("jmpZ", function()
    local truthy = interpreter.run({ "jmpZ", 2, "push", 2, "push", 3, "ret", 0 }, {}, { 1 }, 1)
    assert.are.equal(2, truthy)

    local falsy = interpreter.run({ "jmpZ", 2, "push", 2, "push", 3, "ret", 0 }, {}, { 0 }, 1)
    assert.are.equal(3, falsy)
  end)

  it("jmpZP", function()
    local truthy = interpreter.run({ "jmpZP", 2, "push", 3, "ret", 0 }, {}, { 1 }, 1)
    assert.are.equal(3, truthy)

    local falsy = interpreter.run({ "jmpZP", 2, "push", 2, "ret", 0 }, {}, { 0 }, 1)
    assert.are.equal(0, falsy)
  end)

  it("jmpNZP", function()
    local truthy = interpreter.run({ "jmpNZP", 2, "push", 3, "ret", 0 }, {}, { 1 }, 1)
    assert.are.equal(1, truthy)

    local falsy = interpreter.run({ "jmpNZP", 2, "push", 2, "ret", 0 }, {}, { 0 }, 1)
    assert.are.equal(2, falsy)
  end)

  it("newarray", function()
    local result = interpreter.run({ "newarray", "ret", 0 }, {}, { "nil", 2 }, 2)
    assert.are.same({ size = 2 }, result)
  end)

  it("newarray multidimensional", function()
    local result = interpreter.run({ "push", "nil", "push", 2, "newarray", "push", 3, "newarray", "ret", 0 }, {}, {}, 0)
    assert.are.same({ { size = 2 }, { size = 2 }, { size = 2 }, size = 3 }, result)
  end)

  it("getarray", function()
    local result = interpreter.run({ "getarray", "ret", 0 }, {}, { { 2, 3, 4, size = 3 }, 3 }, 2)
    assert.are.equal(4, result)
  end)

  it("getarray out of bounds error", function()
    local result = function() interpreter.run({ "getarray", "ret", 0 }, {}, { { 2, 3, 4, size = 3 }, -1 }, 2) end
    assert.has.error(result, "array index out of bounds")

    result = function() interpreter.run({ "getarray", "ret", 0 }, {}, { { 2, 3, 4, size = 3 }, 4 }, 2) end
    assert.has.error(result, "array index out of bounds")
  end)

  it("setarray", function()
    local stack = { { size = 3 }, 3, 5 }
    local result = interpreter.run({ "setarray", "ret", 0 }, {}, stack, #stack)
    assert.are.equal(5, result[3])
  end)

  it("setarray out of bounds", function()
    local stack = { { size = 3 }, -1, 5 }
    local result = function() interpreter.run({ "setarray", "ret", 0 }, {}, stack, #stack) end
    assert.has.error(result, "array index out of bounds")


    stack = { { size = 3 }, 4, 5 }
    result = function() interpreter.run({ "setarray", "ret", 0 }, {}, stack, #stack) end
    assert.has.error(result, "array index out of bounds")
  end)

  it("prints number", function()
    stub(interpreter, "print")

    local result = interpreter.run({ "print", "ret", 0 }, {}, { 5 }, 1)

    assert.are.equal(5, result)
    assert.stub(interpreter.print).was_called_with(5)
  end)

  it("prints array", function()
    stub(interpreter, "print")

    local array = { 2, 3, 4, size = 3 }
    local result = interpreter.run({ "print", "ret", 0 }, {}, { array }, 1)

    assert.are.equal(array, result)
    assert.stub(interpreter.print).was_called_with("[2, 3, 4]")
  end)

  it("prints multidimensional array", function()
    stub(interpreter, "print")

    local array = { { size = 1 }, { 10, size = 1 }, size = 2 }
    local result = interpreter.run({ "print", "ret", 0 }, {}, { array }, 1)

    assert.are.equal(array, result)
    assert.stub(interpreter.print).was_called_with("[[], [10]]")
  end)


  it("unknown instruction", function()
    local result = function() interpreter.run({ "nothing" }, {}, {}, 0) end
    assert.has.error(result, "unknown instruction nothing")
  end)
end)

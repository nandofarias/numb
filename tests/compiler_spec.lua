require 'busted.runner' ()
local compiler = require("compiler")

local main = {
  block = {
    body = { tag = "ret", exp = { tag = "number", val = 2 } },
    tag = "block"
  },
  name = "main",
  params = {},
  tag = "function"
}

describe("compile", function()
  describe("functions", function()
    it("should fail without function main", function()
      assert.has.errors(function() compiler.compile({}) end, "no function 'main'")
    end)


    it("function main should have no parameters", function()
      local result = function()
        compiler.compile({ {
          block = {
            body = { tag = "ret", exp = { tag = "number", val = 2 } },
            tag = "block"
          },
          name = "main",
          params = { "a" },
          tag = "function"
        } })
      end
      assert.has.errors(result, "function 'main' must not have params")
    end)

    it("should compile a simple function", function()
      local result = compiler.compile({ {
        block = {
          body = { tag = "ret", exp = { tag = "number", val = 2 } },
          tag = "block"
        },
        name = "main",
        params = {},
        tag = "function"
      } })
      assert.are.same(
        result,
        { "push", 2, "ret", 0, "push", 0, "ret", 0 }
      )
    end)

    it("should compile multiple functions", function()
      local result = compiler.compile({ main, {
        block = {
          body = { tag = "ret", exp = { tag = "number", val = 2 } },
          tag = "block"
        },
        name = "bar",
        params = {},
        tag = "function"
      }, {
        block = {
          body = { tag = "ret", exp = { tag = "number", val = 2 } },
          tag = "block"
        },
        name = "foo",
        params = {},
        tag = "function"
      } })
      assert.are.same(
        result,
        { "push", 2, "ret", 0, "push", 0, "ret", 0 }
      )
    end)

    it("should allow function redefinitions", function()
      stub(compiler, "warn")

      local result = compiler.compile({ main, {
        block = {
          body = { tag = "ret", exp = { tag = "number", val = 2 } },
          tag = "block"
        },
        name = "foo",
        params = {},
        tag = "function"
      }, {
        block = {
          body = { tag = "ret", exp = { tag = "number", val = 3 } },
          tag = "block"
        },
        name = "foo",
        params = {},
        tag = "function"
      } })

      assert.are.same(
        result,
        { "push", 2, "ret", 0, "push", 0, "ret", 0 }
      )

      assert.stub(compiler.warn).was_called_with("WARN: Function foo is being redefined")
    end)

    it("should compile function with parameters", function()
      local result = compiler.compile({ main, {
        block = {
          body = { tag = "ret", exp = { tag = "number", val = 2 } },
          tag = "block"
        },
        name = "foo",
        params = { "a", "b" },
        tag = "function"
      } })
      assert.are.same(
        result,
        { "push", 2, "ret", 0, "push", 0, "ret", 0 }
      )
    end)
  end)

  describe("statements", function()
    it("should compile sequences", function()
      local result = compiler.compile({ {
        block = {
          body = {
            tag = "seq",
            st1 = { tag = "number", val = 1 },
            st2 = { tag = "number", val = 2 }
          },
          tag = "block"
        },
        name = "main",
        params = {},
        tag = "function"
      } })

      assert.are.same(
        result,
        { "push", 1, "push", 2, "push", 0, "ret", 0 }
      )
    end)

    it("should compile local declarations", function()
      local result = compiler.compile({ {
        block = {
          body = { tag = "local", name = "b", init = { tag = "number", val = 2 } },
          tag = "block"
        },
        name = "main",
        params = {},
        tag = "function"
      } })

      assert.are.same(
        result,
        { "push", 2, "pop", 1, "push", 0, "ret", 0 }
      )
    end)

    it("should compile global assignments", function()
      local result = compiler.compile({ {
        block = {
          body = {
            tag = "assign", lhs = { tag = "variable", var = "a" }, exp = { tag = "number", val = 2 }
          },
          tag = "block"
        },
        name = "main",
        params = {},
        tag = "function"
      } })

      assert.are.same(
        result,
        { "push", 2, "store", 1, "push", 0, "ret", 0 }
      )
    end)

    it("should compile local assignments", function()
      local result = compiler.compile({ {
        block = {
          body = {
            tag = "seq",
            st1 = { tag = "local", name = "b", init = { tag = "number", val = 2 } },
            st2 = { tag = "assign", lhs = { tag = "variable", var = "b" }, exp = { tag = "number", val = 3 } }
          },
          tag = "block"
        },
        name = "main",
        params = {},
        tag = "function"
      } })

      assert.are.same(
        result,
        { "push", 2, "push", 3, "storeL", 1, "pop", 1, "push", 0, "ret", 0 }
      )
    end)

    it("should error when local variable is already defined with same name", function()
      local result = function()
        compiler.compile({ {
          block = {
            body = {
              tag = "seq",
              st1 = { tag = "local", name = "b", init = { tag = "number", val = 2 } },
              st2 = { tag = "local", name = "b", init = { tag = "number", val = 2 } },
            },
            tag = "block"
          },
          name = "main",
          params = {},
          tag = "function"
        } })
      end

      assert.has.errors(result, "Local variable 'b' already defined")
    end)

    it("should error when local variable has the same name as a parameter", function()
      local result = function()
        compiler.compile({ main, {
          block = {
            body = {
              tag = "local", name = "b", init = { tag = "number", val = 2 }
            },
            tag = "block"
          },
          name = "foo",
          params = { "b" },
          tag = "function"
        } })
      end

      assert.has.errors(result, "Local variable 'b' already defined")
    end)

    it("should error with invalid lefthand side", function()
      local result = function()
        compiler.compile({ {
          block = {
            body =
            { tag = "assign", lhs = { tag = "number", val = 2 }, exp = { tag = "number", val = 2 } },
            tag = "block"
          },
          name = "main",
          params = {},
          tag = "function"
        } })
      end

      assert.has.errors(result, "Invalid left-hand side")
    end)

    it("should compile inner blocks", function()
      local result = compiler.compile({ {
        block = {
          body = {
            tag = "block", body = { tag = "block", body = { tag = "number", val = 2 } },
          },
          tag = "block"
        },
        name = "main",
        params = {},
        tag = "function"
      } })

      assert.are.same(
        result,
        { "push", 2, "push", 0, "ret", 0 }
      )
    end)

    it("should allow variable shadowing", function()
      local result =
          compiler.compile({ {
            block = {
              body = {
                tag = "seq",
                st1 = { tag = "local", name = "b", init = { tag = "number", val = 2 } },
                st2 = { tag = "block", body = { tag = "local", name = "b", init = { tag = "number", val = 2 } } },
              },
              tag = "block"
            },
            name = "main",
            params = {},
            tag = "function"
          } })

      assert.are.same(
        result,
        { "push", 2, "push", 2, "pop", 1, "push", 0, "ret", 1 }
      )
    end)

    it("should compile print statements", function()
      local result = compiler.compile({ {
        block = {
          body = {
            tag = "print", exp = { tag = "number", val = 2 }
          },
          tag = "block"
        },
        name = "main",
        params = {},
        tag = "function"
      } })

      assert.are.same(
        result,
        { "push", 2, "print", "push", 0, "ret", 0 }
      )
    end)

    it("should compile function calls", function()
      local result = compiler.compile({ {
        block = {
          body = { tag = "number", val = 2 },
          tag = "block"
        },
        name = "foo",
        params = {},
        tag = "function"
      }, {
        block = {
          body = { tag = "call", fname = "foo", args = {} },
          tag = "block"
        },
        name = "main",
        params = {},
        tag = "function"
      } })

      assert.are.same(
        result,
        { "call", { "push", 2, "push", 0, "ret", 0 }, "pop", 1, "push", 0, "ret", 0 }
      )
    end)

    it("should compile function calls with arguments", function()
      local result = compiler.compile({ {
        block = {
          body = { tag = "number", val = 2 },
          tag = "block"
        },
        name = "foo",
        params = { "a" },
        tag = "function"
      }, {
        block = {
          body = { tag = "call", fname = "foo", args = { { tag = "number", val = 2 } } },
          tag = "block"
        },
        name = "main",
        params = {},
        tag = "function"
      } })

      assert.are.same(
        result,
        { "push", 2, "call", { "push", 2, "push", 0, "ret", 1 }, "pop", 1, "push", 0, "ret", 0 }
      )
    end)

    it("should compile function calls using default last argument", function()
      local result = compiler.compile({ {
        block = {
          body = { tag = "number", val = 2 },
          tag = "block"
        },
        name = "foo",
        params = { { tag = "defaultParam", exp = { tag = "number", val = 2 } } },
        tag = "function"
      }, {
        block = {
          body = { tag = "call", fname = "foo", args = {} },
          tag = "block"
        },
        name = "main",
        params = {},
        tag = "function"
      } })

      assert.are.same(
        result,
        { "push", 2, "call", { "push", 2, "push", 0, "ret", 1 }, "pop", 1, "push", 0, "ret", 0 }
      )
    end)

    it("should error when calling an undefined function", function()
      local result = function()
        compiler.compile({ {
          block = {
            body = { tag = "call", fname = "foo", args = {} },
            tag = "block"
          },
          name = "main",
          params = {},
          tag = "function"
        } })
      end

      assert.has.errors(result, "Function 'foo' not defined")
    end)

    it("should error when calling a function with wrong number of arguments", function()
      local result = function()
        compiler.compile({ {
          block = {
            body = { tag = "number", val = 2 },
            tag = "block"
          },
          name = "foo",
          params = { "a", "b" },
          tag = "function"
        }, {
          block = {
            body = { tag = "call", fname = "foo", args = {} },
            tag = "block"
          },
          name = "main",
          params = {},
          tag = "function"
        } })
      end

      assert.has.errors(result, "Wrong number of arguments for function 'foo'")
    end)

    it("should compile return statements", function()
      local result = compiler.compile({
        {
          block = {
            body = { tag = "ret", exp = { tag = "number", val = 2 } },
            tag = "block"
          },
          name = "foo",
          params = {},
          tag = "function"
        }, {
        block = {
          body =
          { tag = "call", fname = "foo", args = {} },
          tag = "block"
        },
        name = "main",
        params = {},
        tag = "function"
      } })

      assert.are.same(
        result,
        { "call", { "push", 2, "ret", 0, "push", 0, "ret", 0 }, "pop", 1, "push", 0, "ret", 0 }
      )
    end)

    it("should compile while statements", function()
      local result = compiler.compile({ {
        block = {
          body = {
            tag = "while",
            cond = { tag = "number", val = 1 },
            block = { tag = "block", body = { tag = "number", val = 2 } }
          },
          tag = "block"
        },
        name = "main",
        params = {},
        tag = "function"
      } })

      assert.are.same(
        result,
        { "push", 1, "jmpZ", 4, "push", 2, "jmp", -8, "push", 0, "ret", 0 }
      )
    end)

    it("should compile if statements", function()
      local result = compiler.compile({ {
        block = {
          body = {
            tag = "if",
            cond = { tag = "number", val = 1 },
            block = { tag = "block", body = { tag = "number", val = 2 } }
          },
          tag = "block"
        },
        name = "main",
        params = {},
        tag = "function"
      } })

      assert.are.same(
        result,
        { "push", 1, "jmpZ", 2, "push", 2, "push", 0, "ret", 0 }
      )
    end)

    it("should compile if/else statements", function()
      local result = compiler.compile({ {
        block = {
          body = {
            tag = "if",
            cond = { tag = "number", val = 1 },
            block = { tag = "block", body = { tag = "number", val = 2 } },
            otherwise = { tag = "block", body = { tag = "number", val = 3 } }
          },
          tag = "block"
        },
        name = "main",
        params = {},
        tag = "function"
      } })

      assert.are.same(
        result,
        { "push", 1, "jmpZ", 4, "push", 2, "jmp", 2, "push", 3, "push", 0, "ret", 0 }
      )
    end)
  end)

  describe("expressions", function()
    it("should compile numbers", function()
      local result = compiler.compile({ {
        block = {
          body = { tag = "number", val = 2 },
          tag = "block"
        },
        name = "main",
        params = {},
        tag = "function"
      } })

      assert.are.same(
        result,
        { "push", 2, "push", 0, "ret", 0 }
      )
    end)

    it("should compile variables", function()
      local result = compiler.compile({ {
        block = {
          body =
          { tag = "assign", lhs = { tag = "variable", var = "a" }, exp = { tag = "number", val = 2 } },
          tag = "block"
        },
        name = "main",
        params = {},
        tag = "function"
      } })

      assert.are.same(
        result,
        { "push", 2, "store", 1, "push", 0, "ret", 0 }
      )
    end)

    it("should compile variables with call expression", function()
      local result = compiler.compile({
        {
          block = {
            body = { tag = "ret", exp = { tag = "number", val = 2 } },
            tag = "block"
          },
          name = "foo",
          params = {},
          tag = "function"
        }, {
        block = {
          body =
          { tag = "assign", lhs = { tag = "variable", var = "a" }, exp = { tag = "call", fname = "foo", args = {} } },
          tag = "block"
        },
        name = "main",
        params = {},
        tag = "function"
      } })

      assert.are.same(
        result,
        { "call", { "push", 2, "ret", 0, "push", 0, "ret", 0 }, "store", 1, "push", 0, "ret", 0 }
      )
    end)

    it("should compile variable access", function()
      local result = compiler.compile({ {
        block = {
          body = {
            tag = "seq",
            st1 = { tag = "assign", lhs = { tag = "variable", var = "a" }, exp = { tag = "number", val = 2 } },
            st2 = { tag = "variable", var = "a" }
          },
          tag = "block"
        },
        name = "main",
        params = {},
        tag = "function"
      } })

      assert.are.same(
        result,
        { "push", 2, "store", 1, "load", 1, "push", 0, "ret", 0 }
      )
    end)

    it("should error when acessing an undefined variable", function()
      local result = function()
        compiler.compile({ {
          block = {
            body = { tag = "indexed", array = { tag = "variable", var = "a" }, index = { tag = "number", val = 2 } },
            tag = "block"
          },
          name = "main",
          params = {},
          tag = "function"
        } })
      end

      assert.has.errors(result, "Variable 'a' not defined")
    end)

    it("should compile array constructors", function()
      local result = compiler.compile({ {
        block = {
          body = { tag = "new", size = { tag = "number", val = 2 } },
          tag = "block"
        },
        name = "main",
        params = {},
        tag = "function"
      } })

      assert.are.same(
        result,
        { "push", "nil", "push", 2, "newarray", "push", 0, "ret", 0 }
      )
    end)

    it("should compile multidimensional array constructors", function()
      local result = compiler.compile({ {
        block = {
          body = {
            tag = "new",
            size = { tag = "number", val = 2 },
            init = {
              tag = "new", size = { tag = "number", val = 4 }
            }
          },
          tag = "block"
        },
        name = "main",
        params = {},
        tag = "function"
      } })

      assert.are.same(
        result,
        { "push", "nil", "push", 4, "newarray", "push", 2, "newarray", "push", 0, "ret", 0 }
      )
    end)

    it("should compile array index access", function()
      local result = compiler.compile({ {
        block = {
          body = {
            tag = "seq",
            st1 = {
              tag = "assign",
              lhs = { tag = "variable", var = "a" },
              exp = { tag = "new", size = { tag = "number", val = 2 } },
            },
            st2 = { tag = "indexed", array = { tag = "variable", var = "a" }, index = { tag = "number", val = 2 } }
          },
          tag = "block"
        },
        name = "main",
        params = {},
        tag = "function"
      } })

      assert.are.same(
        result,
        { "push", "nil", "push", 2, "newarray", "store", 1, "load", 1, "push", 2, "getarray", "push", 0, "ret", 0 }
      )
    end)

    local supported_bin_ops = {
      ["+"] = "add",
      ["-"] = "sub",
      ["*"] = "mul",
      ["/"] = "div",
      ["%"] = "rem",
      ["^"] = "exp",
      ["=="] = "eq",
      ["!="] = "neq",
      ["<="] = "lte",
      [">="] = "gte",
      ["<"] = "lt",
      [">"] = "gt",
    }

    for key, value in pairs(supported_bin_ops) do
      it("should compile binary expressions: " .. key, function()
        local result = compiler.compile({ {
          block = {
            body = { tag = "binop", op = key, e1 = { tag = "number", val = 2 }, e2 = { tag = "number", val = 2 } },
            tag = "block"
          },
          name = "main",
          params = {},
          tag = "function"
        } })

        assert.are.same(
          result,
          { "push", 2, "push", 2, value, "push", 0, "ret", 0 }
        )
      end)
    end

    it("should compile logical expressions: and", function()
      local result = compiler.compile({ {
        block = {
          body = { tag = "logicalop", op = "and", e1 = { tag = "number", val = 2 }, e2 = { tag = "number", val = 3 } },
          tag = "block"
        },
        name = "main",
        params = {},
        tag = "function"
      } })

      assert.are.same(
        result,
        { "push", 2, "jmpZP", 2, "push", 3, "push", 0, "ret", 0 }
      )
    end)

    it("should compile logical expressions: or", function()
      local result = compiler.compile({ {
        block = {
          body = { tag = "logicalop", op = "or", e1 = { tag = "number", val = 2 }, e2 = { tag = "number", val = 3 } },
          tag = "block"
        },
        name = "main",
        params = {},
        tag = "function"
      } })

      assert.are.same(
        result,
        { "push", 2, "jmpNZP", 2, "push", 3, "push", 0, "ret", 0 }
      )
    end)

    it("should compile unary expressions", function()
      local result = compiler.compile({ {
        block = {
          body = { tag = "unary", sign = "-", exp = { tag = "number", val = 2 } },
          tag = "block"
        },
        name = "main",
        params = {},
        tag = "function"
      } })

      assert.are.same(
        result,
        { "push", -1, "push", 2, "mul", "push", 0, "ret", 0 }
      )
    end)

    it("should compile not expressions", function()
      local result = compiler.compile({ {
        block = {
          body = { tag = "not", exp = { tag = "number", val = 2 } },
          tag = "block"
        },
        name = "main",
        params = {},
        tag = "function"
      } })

      assert.are.same(
        result,
        { "push", 2, "not", "push", 0, "ret", 0 }
      )
    end)

    it("should error with invalid tree when passing an invalid expression", function()
      local result = function()
        compiler.compile({ {
          block = {
            body = { tag = "invalid", exp = { tag = "number", val = 2 } },
            tag = "block"
          },
          name = "main",
          params = {},
          tag = "function"
        } })
      end

      assert.has.errors(result, "Invalid tree")
    end)
  end)
end)

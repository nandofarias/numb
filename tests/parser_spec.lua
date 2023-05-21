require 'busted.runner' ()
local parser = require("parser")

describe("parse", function()
  describe("comments", function()
    it("should accept comment lines", function()
      local result = parser.parse([[ # this is a comment]])
      assert.are.same({}, result)
    end)

    it("should accept block comment lines", function()
      local result = parser.parse([[
      #{
      this is a comment
      this is another comment
      #}
      ]])
      assert.are.same({}, result)
    end)
  end)

  describe("functions", function()
    it("should parse function definitions", function()
      local result = parser.parse([[ function foo() { } ]])

      assert.are.same({
          tag = "function",
          name = "foo",
          params = {},
          block = { tag = 'block', body = '' }
        },
        result[1])
    end)

    it("should parse function declarations", function()
      local result = parser.parse([[ function foo() ]])

      assert.are.same({
          tag = "function",
          name = "foo",
          params = {},
        },
        result[1])
    end)

    it("should parse function declarations with parameters ", function()
      local result = parser.parse([[ function foo(a, b, c) {} ]])
      assert.are.same({
          tag = "function",
          name = "foo",
          params = { "a", "b", "c" },
          block = { tag = 'block', body = '' }
        },
        result[1])
    end)

    it("should parse function declarations with last default argument", function()
      local result = parser.parse([[ function foo(a, b, c = 3 ) {} ]])
      assert.are.same({
          tag = "function",
          name = "foo",
          params = { "a", "b", { tag = "defaultParam", name = "c", exp = { tag = "number", val = 3 } } },
          block = { tag = 'block', body = '' }
        },
        result[1])
    end)

    it("should parse function calls", function()
      local result = parser.parse([[
      function foo(a, b, c = 3 ) {}
      function bar {
        foo(1, 2);
        foo(1, 2, 3)
      }
      ]])

      assert.are.same(
        { tag = "call", fname = "foo", args = { { tag = "number", val = 1 }, { tag = "number", val = 2 } } },
        result[2].block.body.st1)
      assert.are.same({
          tag = "call",
          fname = "foo",
          args = { { tag = "number", val = 1 }, { tag = "number", val = 2 }, { tag = "number", val = 3 } }
        },
        result[2].block.body.st2)
    end)
  end)

  describe("statements", function()
    it("should parse sequences of statements", function()
      local result = parser.parse([[ function foo { 10; 20 } ]])
      assert.are.same({ tag = "seq", st1 = { tag = "number", val = 10 }, st2 = { tag = "number", val = 20 } },
        result[1].block.body)
    end)

    it("should parse sequence of empty statements", function()
      local result = parser.parse([[ function foo { ;;;; } ]])
      assert.are.equal('', result[1].block.body)
    end)

    it("should parse variable declaration", function()
      local result = parser.parse([[ function foo { var a = 1 } ]])
      assert.are.same({ tag = "local", name = "a", init = { tag = "number", val = 1 } },
        result[1].block.body)
    end)

    it("should parse array declaration", function()
      local result = parser.parse([[ function foo { var a = new[1] } ]])
      assert.are.same({ tag = "local", name = "a", init = { tag = "new", size = { tag = "number", val = 1 } } },
        result[1].block.body)
    end)

    it("should parse multidimensional array declaration", function()
      local result = parser.parse([[ function foo { var a = new[1][2] } ]])
      assert.are.same({
          tag = "local",
          name = "a",
          init = {
            tag = "new",
            size = { tag = "number", val = 1 },
            init = { tag = "new", size = { tag = "number", val = 2 } }
          }
        },
        result[1].block.body)
    end)

    it("should parse print statement", function()
      local result = parser.parse([[ function foo { @a } ]])
      assert.are.same({ tag = "print", exp = { tag = "variable", var = "a" } },
        result[1].block.body)
    end)

    it("should parse assign statement", function()
      local result = parser.parse([[ function foo { var a; a = 2; } ]])
      assert.are.same({ tag = "assign", lhs = { tag = "variable", var = "a" }, exp = { tag = "number", val = 2 } },
        result[1].block.body.st2)

      result = parser.parse([[ function foo { var a = new[1]; a[1] = 2; } ]])
      assert.are.same({
          tag = "assign",
          lhs = { tag = "indexed", array = { tag = "variable", var = "a" }, index = { tag = "number", val = 1 } },
          exp = { tag = "number", val = 2 }
        },
        result[1].block.body.st2)
    end)

    it("should parse return statement", function()
      local result = parser.parse([[ function foo { return 2 } ]])
      assert.are.same({ tag = "ret", exp = { tag = "number", val = 2 } },
        result[1].block.body)
    end)

    describe("if statements", function()
      it("should parse if statements", function()
        local result = parser.parse([[ function foo { if (1) { 2 } } ]])
        assert.are.same(
          { tag = "if", cond = { tag = "number", val = 1 }, block = { tag = "block", body = { tag = "number", val = 2 } } },
          result[1].block.body)
      end)

      it("should parse if else statements", function()
        local result = parser.parse([[ function foo { if (1) { 2 } else { 3 } } ]])
        assert.are.same({
            tag = "if",
            cond = { tag = "number", val = 1 },
            block = { tag = "block", body = { tag = "number", val = 2 } },
            otherwise = { tag = "block", body = { tag = "number", val = 3 } }
          },
          result[1].block.body)
      end)

      it("should parse if elseif else statements", function()
        local result = parser.parse([[ function foo { if (1) { 2 } elseif (3) { 4 } else { 5 } } ]])
        assert.are.same({
            tag = "if",
            cond = { tag = "number", val = 1 },
            block = { tag = "block", body = { tag = "number", val = 2 } },
            otherwise = {
              tag = "if",
              cond = { tag = "number", val = 3 },
              block = { tag = "block", body = { tag = "number", val = 4 } },
              otherwise = { tag = "block", body = { tag = "number", val = 5 } }
            }
          },
          result[1].block.body)
      end)
    end)

    it("should parse while loop", function()
      local result = parser.parse([[ function foo { while 1 { 2 } } ]])

      assert.are.same({
          tag = "while",
          cond = { tag = "number", val = 1 },
          block = { tag = "block", body = { tag = "number", val = 2 } }
        },
        result[1].block.body)
    end)
  end)

  describe("expressions", function()
    it("should parse decimal numbers", function()
      local result = parser.parse([[ function foo { return 10 } ]])
      assert.are.same({ tag = "number", val = 10 }, result[1].block.body.exp)
    end)

    it("should parse float numbers", function()
      local result = parser.parse([[ function foo { return 10.2 } ]])
      assert.are.same({ tag = "number", val = 10.2 }, result[1].block.body.exp)
    end)

    it("should parse hexadecimal numbers", function()
      local result = parser.parse([[ function foo { return 0xAA } ]])
      assert.are.same({ tag = "number", val = 170 }, result[1].block.body.exp)
    end)

    it("should parse scientific notation numbers", function()
      local result = parser.parse([[ function foo { return 1e2 } ]])
      assert.are.same({ tag = "number", val = 100.0 }, result[1].block.body.exp)
    end)

    it("should parse logical expressions", function()
      local result = parser.parse([[ function foo { return 10 and 2 } ]])
      assert.are.same(
        { tag = "logicalop", op = "and", e1 = { tag = "number", val = 10 }, e2 = { tag = "number", val = 2 } },
        result[1].block.body.exp)

      result = parser.parse([[ function foo { return 10 or 2 } ]])
      assert.are.same(
        { tag = "logicalop", op = "or", e1 = { tag = "number", val = 10 }, e2 = { tag = "number", val = 2 } },
        result[1].block.body.exp)
    end)

    it("should parse comparison expressions", function()
      local result = parser.parse([[ function foo { return 10 > 2 } ]])
      assert.are.same({ tag = "binop", op = ">", e1 = { tag = "number", val = 10 }, e2 = { tag = "number", val = 2 } },
        result[1].block.body.exp)

      result = parser.parse([[ function foo { return 10 >= 2 } ]])
      assert.are.same({ tag = "binop", op = ">=", e1 = { tag = "number", val = 10 }, e2 = { tag = "number", val = 2 } },
        result[1].block.body.exp)

      result = parser.parse([[ function foo { return 10 < 2 } ]])
      assert.are.same({ tag = "binop", op = "<", e1 = { tag = "number", val = 10 }, e2 = { tag = "number", val = 2 } },
        result[1].block.body.exp)

      result = parser.parse([[ function foo { return 10 <= 2 } ]])
      assert.are.same({ tag = "binop", op = "<=", e1 = { tag = "number", val = 10 }, e2 = { tag = "number", val = 2 } },
        result[1].block.body.exp)

      result = parser.parse([[ function foo { return 10 == 2 } ]])
      assert.are.same({ tag = "binop", op = "==", e1 = { tag = "number", val = 10 }, e2 = { tag = "number", val = 2 } },
        result[1].block.body.exp)

      result = parser.parse([[ function foo { return 10 != 2 } ]])
      assert.are.same({ tag = "binop", op = "!=", e1 = { tag = "number", val = 10 }, e2 = { tag = "number", val = 2 } },
        result[1].block.body.exp)
    end)

    it("should parse additive expressions", function()
      local result = parser.parse([[ function foo { return 10 + 2 } ]])
      assert.are.same({ tag = "binop", op = "+", e1 = { tag = "number", val = 10 }, e2 = { tag = "number", val = 2 } },
        result[1].block.body.exp)

      result = parser.parse([[ function foo { return 10 - 2 } ]])
      assert.are.same({ tag = "binop", op = "-", e1 = { tag = "number", val = 10 }, e2 = { tag = "number", val = 2 } },
        result[1].block.body.exp)
    end)

    it("should parse multiplicative expressions", function()
      local result = parser.parse([[ function foo { return 10 * 2 } ]])
      assert.are.same({ tag = "binop", op = "*", e1 = { tag = "number", val = 10 }, e2 = { tag = "number", val = 2 } },
        result[1].block.body.exp)

      result = parser.parse([[ function foo { return 10 / 2 } ]])
      assert.are.same({ tag = "binop", op = "/", e1 = { tag = "number", val = 10 }, e2 = { tag = "number", val = 2 } },
        result[1].block.body.exp)

      result = parser.parse([[ function foo { return 10 % 2 } ]])
      assert.are.same({ tag = "binop", op = "%", e1 = { tag = "number", val = 10 }, e2 = { tag = "number", val = 2 } },
        result[1].block.body.exp)
    end)

    it("should parse unary expressions", function()
      local result = parser.parse([[ function foo { return -1 } ]])
      assert.are.same({ tag = "unary", sign = "-", exp = { tag = "number", val = 1 } },
        result[1].block.body.exp)

      result = parser.parse([[ function foo { return +1 } ]])
      assert.are.same({ tag = "unary", sign = "+", exp = { tag = "number", val = 1 } },
        result[1].block.body.exp)
    end)

    it("should parse exponential expressions with right associative", function()
      local result = parser.parse([[ function foo { return 10 ^ 2 ^ 3 } ]])
      assert.are.same({
          tag = "binop",
          op = "^",
          e1 = { tag = "number", val = 10 },
          e2 = { tag = "binop", op = "^", e1 = { tag = "number", val = 2 }, e2 = { tag = "number", val = 3 } }
        },
        result[1].block.body.exp)
    end)

    it("should parse not expresssions", function()
      local result = parser.parse([[ function foo { return !2 } ]])
      assert.are.same({ tag = "not", exp = { tag = "number", val = 2 } },
        result[1].block.body.exp)
    end)

    it("comparison should take precedence over logical expressions", function()
      local result1 = parser.parse([[ function foo { return 2 == 1 or 2 } ]])
      local result2 = parser.parse([[ function foo { return  2 or 2 == 1 } ]])
      assert.are.same({
          tag = "logicalop",
          op = "or",
          e1 = { tag = "binop", op = "==", e1 = { tag = "number", val = 2 }, e2 = { tag = "number", val = 1 } },
          e2 = { tag = "number", val = 2 }
        },
        result1[1].block.body.exp)
      assert.are.same({
          tag = "logicalop",
          op = "or",
          e2 = { tag = "binop", op = "==", e1 = { tag = "number", val = 2 }, e2 = { tag = "number", val = 1 } },
          e1 = { tag = "number", val = 2 }
        },
        result2[1].block.body.exp)
    end)

    it("additive should take precedence over comparison expressions", function()
      local result1 = parser.parse([[ function foo { return 1 + 1 == 2 } ]])
      local result2 = parser.parse([[ function foo { return 2 == 1 + 1} ]])
      assert.are.same({
          tag = "binop",
          op = "==",
          e1 = { tag = "binop", op = "+", e1 = { tag = "number", val = 1 }, e2 = { tag = "number", val = 1 } },
          e2 = { tag = "number", val = 2 }
        },
        result1[1].block.body.exp)
      assert.are.same({
          tag = "binop",
          op = "==",
          e2 = { tag = "binop", op = "+", e1 = { tag = "number", val = 1 }, e2 = { tag = "number", val = 1 } },
          e1 = { tag = "number", val = 2 }
        },
        result2[1].block.body.exp)
    end)

    it("multiplicative should take precedence over additive expressions", function()
      local result1 = parser.parse([[ function foo { return 1 * 1 + 2 } ]])
      local result2 = parser.parse([[ function foo { return 1 + 2 * 1} ]])
      assert.are.same({
          tag = "binop",
          op = "+",
          e1 = { tag = "binop", op = "*", e1 = { tag = "number", val = 1 }, e2 = { tag = "number", val = 1 } },
          e2 = { tag = "number", val = 2 }
        },
        result1[1].block.body.exp)
      assert.are.same({
          tag = "binop",
          op = "+",
          e2 = { tag = "binop", op = "*", e1 = { tag = "number", val = 2 }, e2 = { tag = "number", val = 1 } },
          e1 = { tag = "number", val = 1 }
        },
        result2[1].block.body.exp)
    end)

    it("unary should take precedence over multiplicative expressions", function()
      local result1 = parser.parse([[ function foo { return 1 * -1 } ]])
      local result2 = parser.parse([[ function foo { return -1 * 1 } ]])
      assert.are.same({
          tag = "binop",
          op = "*",
          e1 = { tag = "number", val = 1 },
          e2 = { tag = "unary", sign = "-", exp = { tag = "number", val = 1 } },
        },
        result1[1].block.body.exp)
      assert.are.same({
          tag = "binop",
          op = "*",
          e2 = { tag = "number", val = 1 },
          e1 = { tag = "unary", sign = "-", exp = { tag = "number", val = 1 } },
        },
        result2[1].block.body.exp)
    end)

    it("unary should take precedence over multiplicative expressions", function()
      local result1 = parser.parse([[ function foo { return 1 * -1 } ]])
      local result2 = parser.parse([[ function foo { return -1 * 1 } ]])
      assert.are.same({
          tag = "binop",
          op = "*",
          e1 = { tag = "number", val = 1 },
          e2 = { tag = "unary", sign = "-", exp = { tag = "number", val = 1 } },
        },
        result1[1].block.body.exp)
      assert.are.same({
          tag = "binop",
          op = "*",
          e2 = { tag = "number", val = 1 },
          e1 = { tag = "unary", sign = "-", exp = { tag = "number", val = 1 } },
        },
        result2[1].block.body.exp)
    end)

    it("exponential should take precedence over unary expressions", function()
      local result = parser.parse([[ function foo { return -1 ^ 1 } ]])
      assert.are.same({
          tag = "unary",
          sign = "-",
          exp = { tag = "binop", op = "^", e1 = { tag = "number", val = 1 }, e2 = { tag = "number", val = 1 } },
        },
        result[1].block.body.exp)
    end)

    it("not expressions should take precedence over exponential expressions", function()
      local result = parser.parse([[ function foo { return !1 ^ 2 } ]])
      assert.are.same({
          tag = "binop",
          op = "^",
          e1 = { tag = "not", exp = { tag = "number", val = 1 } },
          e2 = { tag = "number", val = 2 },
        },
        result[1].block.body.exp)
    end)

    it("parenthesis should take precedence over any expressions", function()
      local result = parser.parse([[ function foo { return !(1 ^ 2) } ]])
      assert.are.same({
          tag = "not",
          exp = {
            tag = "binop",
            op = "^",
            e1 = { tag = "number", val = 1 },
            e2 = { tag = "number", val = 2 },
          }
        },
        result[1].block.body.exp)
    end)
  end)
end)

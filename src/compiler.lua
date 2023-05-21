local M = {}

function M.warn(msg)
  print(msg)
end

function M.compile(tree)
  local Compiler = { funcs = {}, vars = {}, nvars = 0, locals = {}, blockstart = 0 }

  function Compiler:addCode(op)
    local code = self.code
    code[#code + 1] = op
  end

  function Compiler:var2num(id)
    local num = self.vars[id]
    if not num then
      num = self.nvars + 1
      self.nvars = num
      self.vars[id] = num
    end
    return num
  end

  function Compiler:findLocal(name, til)
    til = til or 1
    local loc = self.locals
    for i = #loc, til, -1 do
      if name == loc[i] then
        return i
      end
    end
    local params = self.params
    for i = 1, #params do
      if name == params[i] or name == params[i].name then
        return -(#params - i)
      end
    end
    return nil
  end

  function Compiler:codeCall(ast)
    local func = self.funcs[ast.fname]
    if not func then
      error("Function '" .. ast.fname .. "' not defined")
    end
    local args = ast.args
    local lastParam = func.params[#func.params]
    local hasDefaultParam = lastParam and lastParam.tag == "defaultParam"
    if #args ~= #func.params and (not hasDefaultParam and #args ~= #func.params - 1) then
      error("Wrong number of arguments for function '" .. ast.fname .. "'")
    end
    for i = 1, #args do
      self:codeExp(args[i])
    end
    if hasDefaultParam then
      self:codeExp(lastParam.exp)
    end
    self:addCode("call")
    self:addCode(func.code)
  end

  function Compiler:codeNewArray(ast)
    if ast.init then
      self:codeNewArray(ast.init)
    else
      self:addCode("push")
      self:addCode("nil")
    end
    self:codeExp(ast.size)
    self:addCode("newarray")
  end

  local ops = {
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
  function Compiler:codeExp(ast)
    if ast.tag == "number" then
      self:addCode("push")
      self:addCode(ast.val)
    elseif ast.tag == "call" then
      self:codeCall(ast)
    elseif ast.tag == "variable" then
      local idx = self:findLocal(ast.var)
      if idx then
        self:addCode("loadL")
        self:addCode(idx)
      else
        self:addCode("load")
        local varnum = self.vars[ast.var]
        if not varnum then
          error("Variable '" .. ast.var .. "' not defined")
        else
          self:addCode(varnum)
        end
      end
    elseif ast.tag == "indexed" then
      self:codeExp(ast.array)
      self:codeExp(ast.index)
      self:addCode("getarray")
    elseif ast.tag == "new" then
      self:codeNewArray(ast)
    elseif ast.tag == "binop" then
      self:codeExp(ast.e1)
      self:codeExp(ast.e2)
      self:addCode(ops[ast.op])
    elseif ast.tag == "logicalop" then
      local opcode = ast.op == "and" and "jmpZP" or "jmpNZP"
      self:codeExp(ast.e1)
      local jmp = self:codeJmpF(opcode)
      self:codeExp(ast.e2)
      self:fixJmp2here(jmp)
    elseif ast.tag == "unary" then
      self:addCode("push")
      self:addCode(tonumber(ast.sign .. "1"))
      self:codeExp(ast.exp)
      self:addCode("mul")
    elseif ast.tag == "not" then
      self:codeExp(ast.exp)
      self:addCode("not")
    else
      error("Invalid tree")
    end
  end

  function Compiler:currentPosition()
    return #self.code
  end

  function Compiler:codeJmpB(op, label)
    self:addCode(op)
    self:addCode(label - self:currentPosition() - 1)
  end

  function Compiler:codeJmpF(op)
    self:addCode(op)
    self:addCode(0)
    return self:currentPosition()
  end

  function Compiler:fixJmp2here(jmp)
    self.code[jmp] = self:currentPosition() - jmp
  end

  function Compiler:codeAssign(ast)
    local lhs = ast.lhs
    if lhs.tag == "variable" then
      self:codeExp(ast.exp)

      local idx = self:findLocal(lhs.var)
      if idx then
        self:addCode("storeL")
        self:addCode(idx)
      else
        self:addCode("store")
        self:addCode(self:var2num(lhs.var))
      end
    elseif lhs.tag == "indexed" then
      self:codeExp(lhs.array)
      self:codeExp(lhs.index)
      self:codeExp(ast.exp)
      self:addCode("setarray")
    else
      error("Invalid left-hand side")
    end
  end

  function Compiler:codeStat(ast)
    if ast.tag == "assign" then
      self:codeAssign(ast)
    elseif ast.tag == "local" then
      if Compiler:findLocal(ast.name, self.blockstart + 1) then
        error("Local variable '" .. ast.name .. "' already defined")
      end
      if ast.init then
        self:codeExp(ast.init)
      else
        self:addCode("push")
        self:addCode(0)
      end
      self.locals[#self.locals + 1] = ast.name
    elseif ast.tag == "call" then
      self:codeCall(ast)
      self:addCode("pop")
      self:addCode(1)
    elseif ast.tag == "ret" then
      self:codeExp(ast.exp)
      self:addCode("ret")
      self:addCode(#self.locals + #self.params)
    elseif ast.tag == "print" then
      self:codeExp(ast.exp)
      self:addCode("print")
    elseif ast.tag == "block" then
      self:codeBlock(ast)
    elseif ast.tag == "seq" then
      self:codeStat(ast.st1)
      self:codeStat(ast.st2)
    elseif ast.tag == "if" then
      self:codeExp(ast.cond)
      local jmp = self:codeJmpF("jmpZ")
      self:codeStat(ast.block)
      if ast.otherwise == nil then
        self:fixJmp2here(jmp)
      else
        local jmp2 = self:codeJmpF("jmp")
        self:fixJmp2here(jmp)
        self:codeStat(ast.otherwise)
        self:fixJmp2here(jmp2)
      end
    elseif ast.tag == "while" then
      local ilabel = self:currentPosition()
      self:codeExp(ast.cond)
      local jmp = self:codeJmpF("jmpZ")
      self:codeStat(ast.block)
      self:codeJmpB("jmp", ilabel)
      self:fixJmp2here(jmp)
    else
      self:codeExp(ast)
    end
  end

  function Compiler:codeFunction(ast)
    local func = self.funcs[ast.name]
    if func and #func.code > 0 then
      M.warn("WARN: Function " .. ast.name .. " is being redefined")
    end

    local code = func and func.code or {}
    self.funcs[ast.name] = { code = code, params = ast.params }
    self.code = code
    self.params = ast.params

    if ast.block then
      self:codeStat(ast.block)
      self:addCode("push")
      self:addCode(0)
      self:addCode("ret")
      self:addCode(#self.locals + #self.params)
    end
  end

  function Compiler:codeBlock(ast)
    self.blockstart = #self.locals
    self:codeStat(ast.body)
    local diff = #self.locals - self.blockstart
    if diff > 0 then
      for _ = 1, diff do
        table.remove(self.locals)
      end

      self:addCode("pop")
      self:addCode(diff)
    end
  end

  for i = 1, #tree do
    Compiler:codeFunction(tree[i])
  end
  local main = Compiler.funcs["main"]
  if not main then
    error("no function 'main'")
  end
  if #main.params > 0 then
    error("function 'main' must not have params")
  end

  return main.code
end

return M

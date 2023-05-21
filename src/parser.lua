local lpeg = require("lpeg")
local M = {}

local function node(tag, ...)
  local labels = table.pack(...)
  return function(...)
    local result = { tag = tag }
    local params = table.pack(...)
    for i = 1, #labels do
      result[labels[i]] = params[i]
    end

    return result
  end
end

local function nodeSeq(st1, st2)
  if st2 == nil or st2 == "" then
    return st1
  else
    return { tag = "seq", st1 = st1, st2 = st2 }
  end
end

local function nodeExp(e1, op, e2)
  if op == nil then
    return e1
  else
    return { tag = "binop", e1 = e1, op = op, e2 = e2 }
  end
end

local alpha = lpeg.R("AZ", "az")
local digit = lpeg.R("09")
local allowedChars = lpeg.S("_")
local alnum = alpha + digit + allowedChars

local maxmatch = 0
local currentline = 1
local newline = "\n" * lpeg.P(function()
  currentline = currentline + 1
  return true
end)
local comment = "#" * (lpeg.P(1) - lpeg.P("\n")) ^ 0
local blockcomment = lpeg.P("#{") * (newline + lpeg.P(1) - "#") ^ 0 * "#}"
local space = lpeg.V("space")

local decimal = lpeg.R("09") ^ 1
local hexadecimal = (lpeg.P("0") * lpeg.S("xX") * (lpeg.R("09") + lpeg.R("AF", "af")) ^ 1)
local floating = lpeg.R("09") ^ 1 * "." * lpeg.R("09") ^ 0
local scientific = (floating + hexadecimal + decimal) * lpeg.S("Ee") * decimal
local numeral = (scientific + floating + hexadecimal + decimal) / tonumber / node("number", "val") * space

local reserved = { "var", "return", "if", "elseif", "else", "@", "while", "and", "or", "new", "function" }
local excluded = lpeg.P(false)
for i = 1, #reserved do
  excluded = excluded + reserved[i]
end
excluded = excluded * -alnum

local ID = lpeg.V("ID")
local var = ID / node("variable", "var")

local function T(t)
  return t * space
end

local function Rw(w)
  assert(excluded:match(w))
  return w * -alnum * space
end

local opC = lpeg.C(lpeg.S("<>") * lpeg.P("=") ^ -1 + "==" + "!=") * space
local opA = lpeg.C(lpeg.S("+-")) * space
local opM = lpeg.C(lpeg.S("*/%")) * space
local opE = lpeg.C("^") * space
local opU = lpeg.C(lpeg.S("+-"))
local opN = lpeg.P("!") * space
local opL = lpeg.C(lpeg.P("and") + lpeg.P("or")) * space

local function foldBin(lst)
  local tree = lst[1]
  for i = 2, #lst, 2 do
    tree = { tag = "binop", e1 = tree, op = lst[i], e2 = lst[i + 1] }
  end
  return tree
end

local function foldLogical(lst)
  local tree = lst[1]
  for i = 2, #lst, 2 do
    tree = { tag = "logicalop", e1 = tree, op = lst[i], e2 = lst[i + 1] }
  end
  return tree
end

local function foldIndex(lst)
  local tree = lst[1]
  for i = 2, #lst do
    tree = { tag = "indexed", array = tree, index = lst[i] }
  end
  return tree
end

local lhs = lpeg.V("lhs")
local call = lpeg.V("call")
local stats = lpeg.V("stats")
local stat = lpeg.V("stat")
local ifStat = lpeg.V("ifStat")
local elseIfStat = lpeg.V("elseIfStat")
local elseStat = lpeg.V("elseStat")
local whileStat = lpeg.V("whileStat")
local assignStat = lpeg.V("assignStat")
local returnStat = lpeg.V("returnStat")
local printStat = lpeg.V("printStat")
local varStat = lpeg.V("varStat")
local block = lpeg.V("block")
local exp = lpeg.V("exp")
local termL = lpeg.V("termL")
local termC = lpeg.V("termC")
local termA = lpeg.V("termA")
local termM = lpeg.V("termM")
local termE = lpeg.V("termE")
local termU = lpeg.V("termU")
local termN = lpeg.V("termN")
local factor = lpeg.V("factor")
local newArray = lpeg.V("newArray")
local funcDec = lpeg.V("funcDec")
local params = lpeg.V("params")
local defaultParam = lpeg.V("defaultParam")
local args = lpeg.V("args")

local grammar = lpeg.P({
  "prog",
  prog = space * lpeg.Ct(funcDec ^ 1) * -1,
  funcDec = Rw "function" * ID * lpeg.Ct((T "(" * params * T ")") ^ -1) * block ^ -1 * T ";" ^ -1 /
      node("function", "name", "params", "block"),
  params = (defaultParam + (ID * (T "," * params))) ^ -1,
  defaultParam = ID * T "=" * exp / node("defaultParam", "name", "exp"),
  stats = stat * (T ";" * stats) ^ -1 / nodeSeq,
  stat = block + call + assignStat + varStat + ifStat + whileStat + returnStat + printStat + space,
  ifStat = Rw "if" * exp * block * (elseIfStat + elseStat) ^ -1 / node("if", "cond", "block", "otherwise"),
  elseIfStat = Rw "elseif" * exp * block * elseIfStat ^ 0 * elseStat ^ -1 / node("if", "cond", "block", "otherwise"),
  elseStat = Rw "else" * block,
  whileStat = Rw "while" * exp * block / node("while", "cond", "block"),
  assignStat = lhs * T "=" * exp / node("assign", "lhs", "exp"),
  returnStat = Rw "return" * exp / node("ret", "exp"),
  printStat = T "@" * exp / node("print", "exp"),
  varStat = Rw "var" * ID * (T "=" * exp) ^ -1 / node("local", "name", "init"),
  block = T "{" * stats * T ";" ^ -1 * T "}" / node("block", "body"),
  exp = termL,
  termL = lpeg.Ct(termC * (opL * termC) ^ 0) / foldLogical,
  termC = lpeg.Ct(termA * (opC * termA) ^ 0) / foldBin,
  termA = lpeg.Ct(termM * (opA * termM) ^ 0) / foldBin,
  termM = lpeg.Ct(termU * (opM * termU) ^ 0) / foldBin,
  termU = opU * termE / node("unary", "sign", "exp") + termE,
  termE = termN * (opE * termE) ^ -1 / nodeExp,
  termN = opN * termN / node("neg", "exp") + factor,
  factor = newArray + numeral + T "(" * exp * T ")" + call + lhs,
  newArray = Rw "new" * lpeg.V("arraySize"),
  arraySize = T "[" * exp * T "]" * lpeg.V("arraySize") ^ -1 / node("new", "size", "init"),
  lhs = lpeg.Ct(var * (T "[" * exp * T "]") ^ 0) / foldIndex,
  call = ID * T "(" * args * T ")" / node("call", "fname", "args"),
  args = lpeg.Ct((exp * (T "," * exp) ^ 0) ^ -1),
  ID = (lpeg.C(alpha * alnum ^ 0) - excluded) * space,
  space = (lpeg.S(" \t") + newline + blockcomment + comment) ^ 0 * lpeg.P(function(_, p)
    maxmatch = math.max(maxmatch, p)
    return true
  end),
})

local function syntaxError(input, max)
  io.stderr:write("Syntax error on line " .. currentline .. "\n")
  io.stderr:write(string.sub(input, max - 8, max - 1) .. "|" .. string.sub(input, max, max + 11), "\n")
end

function M.parse(input)
  local res = grammar:match(input)
  if not res then
    syntaxError(input, maxmatch)
    os.exit(1)
  end

  return res
end

return M
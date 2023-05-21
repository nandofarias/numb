local M = {}

local function deepcopy(table)
  if type(table) ~= 'table' then return table end
  local copy = {}
  for key, value in pairs(table) do
    copy[key] = deepcopy(value)
  end
  return copy
end

local function inspect(value)
  local type = type(value)
  if type == "number" then
    return value
  elseif type == "table" then
    local result = "["
    for i = 1, #value do
      local separator = i == #value and "" or ", "
      result = result .. inspect(value[i]) .. separator
    end
    return result .. "]"
  end
end


local function run(code, mem, stack, top)
  local pc = 1
  local base = top
  while true do
    if code[pc] == "ret" then
      local n = code[pc + 1]
      stack[top - n] = stack[top]
      return top - n
    elseif code[pc] == "call" then
      pc = pc + 1
      top = run(code[pc], mem, stack, top)
    elseif code[pc] == "push" then
      pc = pc + 1
      top = top + 1
      stack[top] = code[pc]
    elseif code[pc] == "pop" then
      pc = pc + 1
      top = top - code[pc]
    elseif code[pc] == "add" then
      stack[top - 1] = stack[top - 1] + stack[top]
      top = top - 1
    elseif code[pc] == "sub" then
      stack[top - 1] = stack[top - 1] - stack[top]
      top = top - 1
    elseif code[pc] == "mul" then
      stack[top - 1] = stack[top - 1] * stack[top]
      top = top - 1
    elseif code[pc] == "div" then
      stack[top - 1] = stack[top - 1] / stack[top]
      top = top - 1
    elseif code[pc] == "rem" then
      stack[top - 1] = stack[top - 1] % stack[top]
      top = top - 1
    elseif code[pc] == "exp" then
      stack[top - 1] = stack[top - 1] ^ stack[top]
      top = top - 1
    elseif code[pc] == "eq" then
      stack[top - 1] = stack[top - 1] == stack[top] and 1 or 0
      top = top - 1
    elseif code[pc] == "neq" then
      stack[top - 1] = stack[top - 1] ~= stack[top] and 1 or 0
      top = top - 1
    elseif code[pc] == "lte" then
      stack[top - 1] = stack[top - 1] <= stack[top] and 1 or 0
      top = top - 1
    elseif code[pc] == "gte" then
      stack[top - 1] = stack[top - 1] >= stack[top] and 1 or 0
      top = top - 1
    elseif code[pc] == "lt" then
      stack[top - 1] = stack[top - 1] < stack[top] and 1 or 0
      top = top - 1
    elseif code[pc] == "gt" then
      stack[top - 1] = stack[top - 1] > stack[top] and 1 or 0
      top = top - 1
    elseif code[pc] == "not" then
      stack[top] = stack[top] == 0 and 1 or 0
    elseif code[pc] == "load" then
      pc = pc + 1
      local id = code[pc]
      top = top + 1
      stack[top] = mem[id]
    elseif code[pc] == "loadL" then
      pc = pc + 1
      local id = code[pc]
      top = top + 1
      stack[top] = stack[base + id]
    elseif code[pc] == "store" then
      pc = pc + 1
      local id = code[pc]
      mem[id] = stack[top]
      top = top - 1
    elseif code[pc] == "storeL" then
      pc = pc + 1
      local id = code[pc]
      stack[base + id] = stack[top]
      top = top - 1
    elseif code[pc] == "print" then
      M.print(inspect(stack[top]))
      top = top - 1
    elseif code[pc] == "jmp" then
      pc = pc + 1
      pc = pc + code[pc]
    elseif code[pc] == "jmpZ" then
      pc = pc + 1
      if stack[top] == 0 then
        pc = pc + code[pc]
      end
      top = top - 1
    elseif code[pc] == "jmpZP" then
      pc = pc + 1
      if stack[top] == 0 then
        pc = pc + code[pc]
      else
        top = top - 1
      end
    elseif code[pc] == "jmpNZP" then
      pc = pc + 1
      if stack[top] ~= 0 then
        pc = pc + code[pc]
      else
        top = top - 1
      end
    elseif code[pc] == "newarray" then
      local size = stack[top]
      local init = stack[top - 1]
      local newarray = { size = size }
      if init ~= "nil" then
        for i = 1, size do
          local copy = deepcopy(init)
          newarray[i] = copy
        end
      end
      top = top - 1
      stack[top] = newarray
    elseif code[pc] == "getarray" then
      local array = stack[top - 1]
      local index = stack[top]
      if index <= 0 or index > array.size then
        error("array index out of bounds")
      end
      stack[top - 1] = array[index]
      top = top - 1
    elseif code[pc] == "setarray" then
      local array = stack[top - 2]
      local index = stack[top - 1]
      local value = stack[top]
      if index <= 0 or index > array.size then
        error("array index out of bounds")
      end
      array[index] = value
      top = top - 3
    else
      error("unknown instruction " .. code[pc])
    end
    pc = pc + 1
  end
end

M.print = function(value)
  print(value)
end

M.run = function(code, mem, stack, top)
  run(code, mem, stack, top)
  return stack[1]
end

return M

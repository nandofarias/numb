rockspec_format = "3.0"
package = "numb"
version = "1.0.0-1"
source = {
  url = "https://github.com/nandofarias/numb"
}
description = {
  summary = "Numb Lang",
  detailed = "Numb is a programming language developed for the BPL Classpert course",
  homepage = "https://github.com/nandofarias/numb",
  license = "MIT"
}
dependencies = {
  "lua ~> 5.4"
}
test_dependencies = {
  "busted ~> 2.1"
}
build = {
  type = "builtin",
  modules = {
    compiler = "src/compiler.lua",
    interpreter = "src/interpreter.lua",
    main = "src/main.lua",
    parser = "src/parser.lua"
  }
}

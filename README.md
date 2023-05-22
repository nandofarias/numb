# Numb

A small language to work with NUMBers 🔟.

Numb is my project submission for the amazing Classpert course [Building a programming language](https://classpert.com/classpertx/courses/building-a-programming-language/cohort)

Naming things is harder than building a programming language (trust me), but I choose that name heavily inspired by one of my favorite songs of all time. https://www.youtube.com/watch?v=kXYiU_JCYtU.

## Installation

You must have Lua ~> 5.4 installed, the source code is inside of the src/ folder, but you can add bin/ to your path for convenience, which adds the numb script to your path.

Bash/Zsh:
```bash
export PATH=$PATH:$PWD/bin
```

Fish:
```bash
fish_add_path bin
```

And you'll be able to use:
```bash
numb example.nb
```

The examples/ folder has a lot of good examples of how to use/test the language.

```bash
numb examples/factorial.nb
```

Alternatively, you can just `cd src` and execute `lua main.lua < myprogram.nb`

## Development

Numb has 3 principal modules:


parser.lua -> which converts text to numb AST.

compiler.lua -> which converts numb AST to stack machine instructions.

interpreter.lua -> which read instructions and executes the program.


For each module we have tests inside of the tests/ folder, tests were written using https://lunarmodules.github.io/busted/ test framework.

You can install it using `luarocks install busted` or calling `make test`, which installs and run all test suite.

## Language Syntax

It all starts with numbers...

### Basic types

Numb only supports `numbers` and `arrays`.

Numbers:
```numb
12;   # integer
12.0; # float
12.;  # float
0x12; # hex
2e4;  # scientific notation
```

Arrays:
```numb
a = new[2];
a[1] = 10;
a[2] = 20;
```

Note: Arrays in numb are 1-based indexed, just like Lua.

Multidimensional arrays:
```numb
a = new[2][2];
a[1][1] = 10;
a[2][1] = 20;
```

### Basic operators

Numb supports all basic math operators:

```numb
1 + 1; # add
1 - 1; # sub
1 * 1; # mul
1 / 1; # div
1 % 1; # rem
1 ^ 1; # exp
```

It also provides unary, not and logical operators:

```numb
+(10 * 2); # unary +
-(10 * 2); # unary -
!2;        # returns 0 (falsy value in Numb)
!0;        # returns 1 (truthy value in Numb)
0 and 10;  # returns 0
1 and 10;  # returns 10
0 or 10;   # returns 10
1 or 10;   # returns 1
```

And comparison operators:
Numb considers 0 the same as false and anything > 0 as true.

```numb
2 == 2; # 1
2 != 2; # 0
2 <= 2; # 1
2 >= 2; # 1
2 < 3;  # 1
2 > 3;  # 0
```

### Comments

Comments can be expressed in two forms, single lines or blocks.
A single-line comment is expressed by the token `#`:

```numb
# this is a comment
var n = 2; # this is another comment
```

And the block comment expression is delimiter by `#{` and `#}`:
```numb
#{
Everything inside is a comment
#}
```

### Control structures

You can express logic with many different structures:

Basic `if/ifelse/else` blocks:
```numb
var result;
if 2 < 1 {
  result = 1
} elseif 2 < 2 {
  result = 2
} else {
  result = 3
}

# print result = 3
@ result
```

Ternaries:
```numb
if 2 == 2 ? 1 : 0
```

Unless:
```numb
unless 0 {
  return 1;
}
```

And short circuits with logical operators:
```numb
var a = 0 or 10;  # 10
var b = 1 and 10; # 10
```

### Loops

Currently, it only has two ways of looping `while` and function recursion

Let's say you want to loop 5 times:
```
var i = 5;
while i {
  @i;
  i = i -1;
}
# Prints 5 4 3 2 1
```

Or implement a factorial using recursion:
```numb
function factorial(n) {
  return if n == 0 ? 1 : n * factorial(n - 1);
}

function main {
  return factorial(3);
}
```

### Functions

Numb requires function main to be defined, it's the entry point to start executing statements and expressions:

```numb
function main() {
  return 1;
}
```

Note: parenthesis is optional for functions without params.

You can define as many functions as needed, just be aware that to use a function not yet defined, you will have to declare that function first, something we call a forward declaration.
Functions also accept default last arguments, which makes it optional when calling it:

```numb
function add(a, b = 0) {
  return a + b;
}

function main {
  add(1, 2);
  add(2)
  # both are valid expressions
}
```

Note: semicolon is optional on the last statement of a block.

### Variables

Numb supports both local and global variable declarations. Locals are defined by the reserved word `var` while globals are the default when you don't specify it as local.

```numb
a = 3;     # global a
var a = 2; # local a
```

It doesn't allow variable redeclarations but it has a nice variable shadowing feature:

```numb
function foo(a, b) {
  var a; # not allowed because there is already a variable 'a' as param
  a = 3; # global 'a' is allowed because only local variables can't be redeclared

  {
    var a;
    {
      var a;
    }
  } # both allowed since they are in different block scopes, that's variable shadowing
}
```

### Print

Last but not least, numb has a print statement defined by the token "@", you can print any data type supported by Numb.

Printing numbers:
```numb
@1
@1.1
@1e1
@0x1
```

Printing arrays:
```numb
var a = new[2];
a[1] = 1;
a[2] = 2;

@a;    # [1, 2]
@a[1]; # 1
@a[2]; # 2

var b = new[1][2];
b[1] = a;

@b;    # [[1, 2]]
@b[1]; # [1, 2]
```

## New Features/Changes

Two new features were added to language recently `unless` and ternary expressions.

### Unless

A new statement type was introduced to the parser `unlessStat` in src/parser.lua,
it is compiled very similar to if but introducing a new opcode `jmpNZ`, that jumps if the top of the stack is different than 0.

Example:
```numb
unless 0 {
  @ 10; # it will be executed
}

unless 10 {
  @ 10; # anything different than 0 will be skipped
}
```

### Ternary

Ternaries as statements are not very useful in my opinion, so ternary was introduced as an expression to the language.
That means it's possible to use ternaries on any kind of statement; assignments, returns, print etc.

Initial attempt was trying to implement in the format of `exp ? stat : stat`, but having a `exp` as the first thing on the parser
was causing recursive problems. So I decided to put an `if` reserved word to bypass that issue.

Example:
```numb
var a = if 1 ? 10 : 2;
```

## Future

Numb can be a good candidate to solve leetcode types of problems, being easy to read, and having a small subset allows programmers to focus on solving those types of algorithms without relying on stdlib.
That being said, it is missing some important features to reach that goal.

* Strings, char list support.
* Array initializers (`new[2]{ 1, 2 }`)
* Array size exp, similar to lua `#array`.
* Maybe booleans and `nil` values, maybe.
* Docs, a good export of the current docs using https://github.com/rust-lang/mdBook
* Treesitter parser for neovim users.
* Syntax highlights for vscode users.
* Better distribution model, starting with a homebrew formula.

## Self-assessment

### Language Completeness: 2/3

* All exercises have been incorporated into the language and two new features (`unless` and a ternary expression).
* It allows basic algorithms to be implemented in the language. Check examples/bubble-sort.nb

### Code Quality & Report: 2/3

* Code is split into different files, allowing each module to be tested independently and concurrently.
* Error handling shows line number information and position indicator, very much inspired by Rust.
* The language includes a suite of test cases.

### Originality & Scope: 2/3

* Numb has all the features covered by the course, it didn't go beyond that but it has a few differences based on my code style. I.e.: Allow colon on the last statement, optional parenthesis in functions without params.

## References

* https://www.inf.puc-rio.br/~roberto/lpeg/
* https://www.inf.puc-rio.br/~roberto/book/
* https://towardsdatascience.com/understanding-python-bytecode-e7edaae8734d
* https://medium.com/@gvanrossum_83706/peg-parsers-7ed72462f97c
* https://medium.com/@fxn/the-elixir-parallel-compiler-53a1be353049
* https://tree-sitter.github.io/tree-sitter/
* https://github.com/zevv/xpeg

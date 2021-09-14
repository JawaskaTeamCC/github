# github

A github require wrapper

## Installation

Just run `pastebin run iex4Tgeb`

## Usage

The usage is pretty straightforward, you use `github.require` or `github.import` like this:

```lua
local a, b, c = github.import 'abc#v1.0.0' { 'a', 'b', 'c' }
local project = github.require '@namespace/project'
```

The syntax for the require string (And the first argument in case of import) is:

```
@<namespace>/<project>#<release>
```

Without the `<>`, for example: `@octocat/good-times#v1.0.0`

Remember that the project name is **mandatory**, while the namespace and release are optional!

_What if the namespace is ommited?_ The `@JawaskaTeamCC` is used by default.

_What if the release tag is ommited?_ It defaults to `master` or `main` depending on the repository, so the latest commit of the main branch is picked.

Full working example:

```lua
local github = require 'github'
local class = github.import 'pandora#v1.0.0' { 'class' }
local sum = github.import 'test' { 'sum' }

local Greeter = class 'Greeter' {
  Greeter = function(self, name)
    self.name = name
  end,
  greet = function(self)
    print('Hello! I\'m ' .. self.name)
  end
}

local paco = Greeter 'Paco'
paco:greet()
print('test.sum(1, 2) = ' .. sum(1, 2))

```

As you can see, both use default namespace packages (The namespace is ommited).

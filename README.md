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

### Syntax

The syntax for the require string (And the first argument in case of import) is:

```
@<namespace>/<project>#<release>
```

Without the `<>`, for example: `@octocat/good-times#v1.0.0`

Remember that the project name is **mandatory**, while the namespace and release are optional!

_What if the namespace is ommited?_ The `@JawaskaTeamCC` is used by default.

_What if the release tag is ommited?_ It defaults to `master` or `main` depending on the repository, so the latest commit of the main branch is picked.

### Using private repostiories or bypassing API limits

**You should use a personal access token if...**

If you're about to install more than 60 packages in a single hour, the Github API will deny your requests past those 60 attempts.

Or if you want to access to private repostiories.

In both cases, this library comes with builtin _Personal Access Token_ auth flow.

#### Creating the token

First, create the token (You should customize it to your needs, if only the 60-request-per-hour limit is your concern, you can leave all the checkboxes in blank).

![imagen](https://user-images.githubusercontent.com/13834659/133247800-6c05bb25-38dc-424d-90ac-11e5f3d12285.png)

Then, name it in a way that you will remember, and take note that by default **tokens expire!** You can set it to never expiring, but **I would recommend at most one year!**

![imagen](https://user-images.githubusercontent.com/13834659/133247982-aea36f94-5890-43d5-ba90-e61b126500c2.png)

Once finished, just copy the token:

![imagen](https://user-images.githubusercontent.com/13834659/133248216-95552b59-41cd-46af-a222-e3262e86a5ad.png)

#### Using the token

Paste the token in a file named `.github` at the root of your computer, the library will detect and use it automagically.

### Example

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

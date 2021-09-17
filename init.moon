lib = {
  default_repository: 'JawaskaTeamCC'
}

local token
do
  f = io.open('.github', 'r')
  if f ~= nil
    token = f\read '*all'
    f\close!

-- Super simple key-value file
lib.KVFile = class KVFile
  open: (path, mode) ->
    file = KVFile(path, mode)
    if file.handle == nil
      return nil
    return file
  decode: (line) ->
    t, k, v = line\match '([tns])(.-) (.*)\n'
    if t == 't'
      v = textutils.unserializeJSON(v)
    elseif t == 'n'
      v = tonumber(v)
    return k, v
  new: (path, mode) =>
    @path = path
    @mode = mode
    @handle = io.open(path, mode)
  close: => @handle\close!
  write: (key, value) =>
    key = key\gsub " ", "_"
    t = type value
    local T
    if t == 'table'
      T = 't'
      value = textutils.serializeJSON(value)
    elseif t == 'number'
      T = 'n'
    else
      T = 's'
      value = tostring(value)
    @handle\write "#{T}#{key} #{value}\n"
  next_entry: =>
    line = @handle\read '*line'
    if line ~= nil
      return KVFile.decode line
  readAll: =>
    local line
    tbl = {}
    line = @handle\read '*line'
    while line ~= nil
      k, v = KVFile.decode line
      return tbl if k == nil
      tbl[k] = v
      line = @handle\read '*line'
    return tbl

-- Fetch JSON by GET
fetch = (url) ->
  local res
  if token == nil
    res = http.get url
  else
    res = http.get url, {
      Authorization: "token #{token}"
    }
  if res == nil
    error "Could not fetch #{url}!"
  return textutils.unserializeJSON res\readAll!
lib.fetch = fetch

-- Project version
lib.Version = class Version
  tag: "master"
  new: (project, tag) =>
    @project = project
    @tag = tag
  fetch: (file) =>
    http.get "https://raw.githubusercontent.com/#{@project.namespace.name}/#{@project.name}/#{@tag}/#{file}"
  json: (file) =>
    textutils.unserializeJSON (@fetch file)\readAll!
  path: =>
    "/lib/#{@project.namespace.name}/#{@project.name}/#{@tag}"
  -- Tells if the project version is apparently installed
  installed: => fs.exists @path!
  -- Looks up the commit sha of this tag, or latest if branch.
  commit: =>
    tags = @project\tags!
    for _, v in pairs tags
      if v.name == @tag
        return v.commit.sha
    branches = @project\branches!
    for _, v in pairs branches
      if v.name == @tag
        return v.commit.sha
  -- Store project metadata
  write_meta: =>
    file = @open_meta 'w'
    commit = @commit!
    file\write "commit", commit
    file\close!
  -- Check if commits are equal
  check_meta: =>
    meta = @open_meta 'r'
    if meta == nil
      return false
    info = meta\readAll!
    print(textutils.serialize info)
    meta\close!
    print "'#{info.commit}' <> '#{@commit!}'"
    return info.commit == @commit!
  -- Open the meta file handle
  open_meta: (mode) =>
    KVFile.open(fs.combine(@path!, '.meta'), mode)
  -- Clean
  clean: => fs.delete @path!
  -- Install the project version
  install: =>
    p = @path!
    info = @json 'project.json'
    if info.install
      if info.install.pre
        shell.run info.install.pre
      fs.makeDir p
    if not info.files
      error 'Malformed package! The package does not contain files.'
    for origin, dest in pairs info.files
      data = @fetch(origin)
      folder = fs.getDir dest
      fs.makeDir(fs.combine p, folder)
      file = io.open(fs.combine(p, dest), 'w')
      file\write data\readAll!
      file\close!
      data\close!
    if info.install and info.install.post
      shell.run info.install.post
    @write_meta!

-- Project
lib.Project = class Project
  name: "unknown"
  new: (namespace, name) =>
    @namespace = namespace
    @name = name
    @info = fetch "https://api.github.com/repos/#{@namespace.name}/#{@name}"
  version: (project, version) => Version @, version
  tags: => fetch @info.tags_url
  forks: => fetch @info.forks_url
  branches: => fetch @info.branches_url\gsub '{/branch}', ''
  releases: => fetch @info.releases_url
  issues: => fetch @info.issues_url
  language: => @info.language

-- Github namespace wrapper
lib.Namespace = class Namespace
  name: "unknown"
  new: (name) =>
    @name = name
  project: (name) => Project @, name

---
-- Gets the Github project data
---
get = (str) ->
  if str\match '@.-/.-#.+'
    ns, p, tg = str\match '@(.-)/(.-)#(.+)'
    return Namespace(ns)\project(p)\version tg
  elseif str\match '@.-/.+'
    ns, p = str\match '@(.-)/(.+)'
    return Namespace(ns)\project p
  elseif str\match '.-#.+'
    p, tg = str\match '(.-)#(.+)'
    return Namespace(lib.default_repository)\project(p)\version tg
  else
    return Namespace(lib.default_repository)\project str
lib.get = get

find = (of, what) ->
  for _, v in pairs of
    if what v
      return v
lib.find = find

---
-- Requires the project, if not found downloads and installs it.
---
g_require = (str) ->
  project = get str
  if project.__class == Project
    branches = project\branches!
    main = find branches, (branch) ->
      branch.name == 'main' or branch.name == 'master'
    if main == nil
      main = branch[0]
    if main == nil
      error "Repository #{str} does not contain branches!"
    project = project\version main.name
  -- Now we've selected latest release channel, check if installed.
  if not project\installed!
    print "#{str} is not installed"
    project\install!
  if not project\check_meta!
    print "#{str} metadata is outdated"
    project\clean!
    project\install!
  return require(project\path!)
lib.require = g_require

----
-- Import is like require but with destructuring
----
lib.import = (str) -> (tbl) ->
  mod = g_require str
  out = {}
  for k, v in pairs tbl
    out[#out + 1] = mod[v]
  return table.unpack out

return lib

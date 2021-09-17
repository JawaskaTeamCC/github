local lib = {
  default_repository = 'JawaskaTeamCC'
}
local token
do
  local f = io.open('.github', 'r')
  if f ~= nil then
    token = f:read('*all')
    f:close()
  end
end
local KVFile
do
  local _class_0
  local _base_0 = {
    open = function(path, mode)
      local file = KVFile(path, mode)
      if file.handle == nil then
        return nil
      end
      return file
    end,
    decode = function(line)
      local t, k, v = line:match('([tns])(.-) (.*)\n')
      if t == 't' then
        v = textutils.unserializeJSON(v)
      elseif t == 'n' then
        v = tonumber(v)
      end
      return k, v
    end,
    close = function(self)
      return self.handle:close()
    end,
    write = function(self, key, value)
      key = key:gsub(" ", "_")
      local t = type(value)
      local T
      if t == 'table' then
        T = 't'
        value = textutils.serializeJSON(value)
      elseif t == 'number' then
        T = 'n'
      else
        T = 's'
        value = tostring(value)
      end
      return self.handle:write(tostring(T) .. tostring(key) .. " " .. tostring(value) .. "\n")
    end,
    next_entry = function(self)
      local line = self.handle:read('*line')
      if line ~= nil then
        return KVFile.decode(line)
      end
    end,
    readAll = function(self)
      local line
      local tbl = { }
      line = self.handle:read('*line')
      while line ~= nil do
        local k, v = KVFile.decode(line)
        if k == nil then
          return tbl
        end
        tbl[k] = v
        line = self.handle:read('*line')
      end
      return tbl
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, path, mode)
      self.path = path
      self.mode = mode
      self.handle = io.open(path, mode)
    end,
    __base = _base_0,
    __name = "KVFile"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  KVFile = _class_0
  lib.KVFile = _class_0
end
local fetch
fetch = function(url)
  local res
  if token == nil then
    res = http.get(url)
  else
    res = http.get(url, {
      Authorization = "token " .. tostring(token)
    })
  end
  if res == nil then
    error("Could not fetch " .. tostring(url) .. "!")
  end
  return textutils.unserializeJSON(res:readAll())
end
lib.fetch = fetch
local Version
do
  local _class_0
  local _base_0 = {
    tag = "master",
    fetch = function(self, file)
      return http.get("https://raw.githubusercontent.com/" .. tostring(self.project.namespace.name) .. "/" .. tostring(self.project.name) .. "/" .. tostring(self.tag) .. "/" .. tostring(file))
    end,
    json = function(self, file)
      return textutils.unserializeJSON((self:fetch(file)):readAll())
    end,
    path = function(self)
      return "/lib/" .. tostring(self.project.namespace.name) .. "/" .. tostring(self.project.name) .. "/" .. tostring(self.tag)
    end,
    installed = function(self)
      return fs.exists(self:path())
    end,
    commit = function(self)
      local tags = self.project:tags()
      for _, v in pairs(tags) do
        if v.name == self.tag then
          return v.commit.sha
        end
      end
      local branches = self.project:branches()
      for _, v in pairs(branches) do
        if v.name == self.tag then
          return v.commit.sha
        end
      end
    end,
    write_meta = function(self)
      local file = self:open_meta('w')
      local commit = self:commit()
      file:write("commit", commit)
      return file:close()
    end,
    check_meta = function(self)
      local meta = self:open_meta('r')
      if meta == nil then
        return false
      end
      local info = meta:readAll()
      print(textutils.serialize(info))
      meta:close()
      print("'" .. tostring(info.commit) .. "' <> '" .. tostring(self:commit()) .. "'")
      return info.commit == self:commit()
    end,
    open_meta = function(self, mode)
      return KVFile.open(fs.combine(self:path(), '.meta'), mode)
    end,
    clean = function(self)
      return fs.delete(self:path())
    end,
    install = function(self)
      local p = self:path()
      local info = self:json('project.json')
      if info.install then
        if info.install.pre then
          shell.run(info.install.pre)
        end
        fs.makeDir(p)
      end
      if not info.files then
        error('Malformed package! The package does not contain files.')
      end
      for origin, dest in pairs(info.files) do
        local data = self:fetch(origin)
        local folder = fs.getDir(dest)
        fs.makeDir(fs.combine(p, folder))
        local file = io.open(fs.combine(p, dest), 'w')
        file:write(data:readAll())
        file:close()
        data:close()
      end
      if info.install and info.install.post then
        shell.run(info.install.post)
      end
      return self:write_meta()
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, project, tag)
      self.project = project
      self.tag = tag
    end,
    __base = _base_0,
    __name = "Version"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Version = _class_0
  lib.Version = _class_0
end
local Project
do
  local _class_0
  local _base_0 = {
    name = "unknown",
    version = function(self, project, version)
      return Version(self, version)
    end,
    tags = function(self)
      return fetch(self.info.tags_url)
    end,
    forks = function(self)
      return fetch(self.info.forks_url)
    end,
    branches = function(self)
      return fetch(self.info.branches_url:gsub('{/branch}', ''))
    end,
    releases = function(self)
      return fetch(self.info.releases_url)
    end,
    issues = function(self)
      return fetch(self.info.issues_url)
    end,
    language = function(self)
      return self.info.language
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, namespace, name)
      self.namespace = namespace
      self.name = name
      self.info = fetch("https://api.github.com/repos/" .. tostring(self.namespace.name) .. "/" .. tostring(self.name))
    end,
    __base = _base_0,
    __name = "Project"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Project = _class_0
  lib.Project = _class_0
end
local Namespace
do
  local _class_0
  local _base_0 = {
    name = "unknown",
    project = function(self, name)
      return Project(self, name)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, name)
      self.name = name
    end,
    __base = _base_0,
    __name = "Namespace"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Namespace = _class_0
  lib.Namespace = _class_0
end
local get
get = function(str)
  if str:match('@.-/.-#.+') then
    local ns, p, tg = str:match('@(.-)/(.-)#(.+)')
    return Namespace(ns):project(p):version(tg)
  elseif str:match('@.-/.+') then
    local ns, p = str:match('@(.-)/(.+)')
    return Namespace(ns):project(p)
  elseif str:match('.-#.+') then
    local p, tg = str:match('(.-)#(.+)')
    return Namespace(lib.default_repository):project(p):version(tg)
  else
    return Namespace(lib.default_repository):project(str)
  end
end
lib.get = get
local find
find = function(of, what)
  for _, v in pairs(of) do
    if what(v) then
      return v
    end
  end
end
lib.find = find
local g_require
g_require = function(str)
  local project = get(str)
  if project.__class == Project then
    local branches = project:branches()
    local main = find(branches, function(branch)
      return branch.name == 'main' or branch.name == 'master'
    end)
    if main == nil then
      main = branch[0]
    end
    if main == nil then
      error("Repository " .. tostring(str) .. " does not contain branches!")
    end
    project = project:version(main.name)
  end
  if not project:installed() then
    print(tostring(str) .. " is not installed")
    project:install()
  end
  if not project:check_meta() then
    print(tostring(str) .. " metadata is outdated")
    project:clean()
    project:install()
  end
  return require(project:path())
end
lib.require = g_require
lib.import = function(str)
  return function(tbl)
    local mod = g_require(str)
    local out = { }
    for k, v in pairs(tbl) do
      out[#out + 1] = mod[v]
    end
    return table.unpack(out)
  end
end
return lib

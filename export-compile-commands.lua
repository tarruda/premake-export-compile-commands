local p = premake

p.modules.export_compile_commands = {}
local m = p.modules.export_compile_commands

local workspace = p.workspace
local project = p.project

function m.getToolset(cfg)
  return p.tools[cfg.toolset or 'gcc']
end

function m.getIncludeDirs(cfg)
  local flags = {}
  for _, dir in ipairs(cfg.includedirs) do
    table.insert(flags, '-I' .. p.quoted(dir))
  end
  for _, dir in ipairs(cfg.sysincludedir or {}) do
    table.insert(result, '-isystem ' .. p.quoted(dir))
  end
  return flags
end

function m.getCommonFlags(cfg)
  local toolset = m.getToolset(cfg)
  local flags = toolset.getcppflags(cfg)
  flags = table.join(flags, toolset.getdefines(cfg.defines))
  flags = table.join(flags, toolset.getundefines(cfg.undefines))
  -- can't use toolset.getincludedirs because some tools that consume
  -- compile_commands.json have problems with relative include paths
  flags = table.join(flags, m.getIncludeDirs(cfg))
  return table.join(flags, cfg.buildoptions)
end

function m.getObjectPath(prj, cfg, node)
  return path.join(cfg.objdir, path.appendExtension(node.objname, '.o'))
end

function m.getDependenciesPath(prj, cfg, node)
  return path.join(cfg.objdir, path.appendExtension(node.objname, '.d'))
end

function m.getFileFlags(prj, cfg, node)
  return table.join(m.getCommonFlags(cfg), {
    '-o', m.getObjectPath(prj, cfg, node),
    '-MF', m.getDependenciesPath(prj, cfg, node),
    '-c', node.abspath
  })
end

function m.generateCompileCommand(prj, cfg, node)
  return {
    directory = prj.location,
    file = node.abspath, 
    command = 'cc '.. table.concat(m.getFileFlags(prj, cfg, node), ' ')
  }
end

function m.includeFile(prj, node, depth)
  return path.iscppfile(node.abspath)
end

function m.getConfig(prj)
  if _OPTIONS['config'] then
    return project.getconfig(prj, _OPTIONS['config'], _OPTIONS['platform'])
  end
  for cfg in project.eachconfig(prj) do
    -- just use the first configuration which is usually "Debug"
    return cfg
  end
end

function m.getProjectCommands(prj)
  local tr = project.getsourcetree(prj)
  local cfg = m.getConfig(prj)
  if not cfg then
    local cfg, plat = _OPTIONS['config'], _OPTIONS['platform']
    if plat then
      p.warn('No configuration %s/%s for project %s', cfg, plat, prj.name)
    else
      p.warn('No configuration %s for project %s', cfg, prj.name)
    end
    return
  end
  local toolset = m.getToolset(cfg)
  local flags = table.join(common_flags, toolset.getcppflags(cfg))
  flags = table.join(common_flags, toolset.getcflags(cfg), cfg.buildoptions)
  local cmds = {}
  p.tree.traverse(tr, {
    onleaf = function(node, depth)
      if not m.includeFile(prj, node, depth) then
        return
      end
      table.insert(cmds, m.generateCompileCommand(prj, cfg, node))
    end
  })
  return cmds
end

local function execute()
  for wks in p.global.eachWorkspace() do
    local wksCmds = {}
    for prj in workspace.eachproject(wks) do
      wksCmds = table.join(wksCmds, m.getProjectCommands(prj))
    end
    local outfile = _OPTIONS['output-file'] or 'compile_commands.json'
    p.generate(wks, outfile, function(wks)
      local jsonCmds = {}
      for i = 1, #wksCmds do
        local item = wksCmds[i]
        table.insert(jsonCmds, string.format([[
        {
          "directory": "%s",
          "file": "%s",
          "command": "%s"
        }]],
        item.directory,
        item.file,
        item.command:gsub('\\', '\\\\'):gsub('"', '\\"')))
      end
      p.w('[')
      p.w(table.concat(jsonCmds, ',\n'))
      p.w(']')
    end)
  end
end

newaction {
  trigger = 'export-compile-commands',
  description = 'Export compiler commands in JSON Compilation Database Format',
  execute = execute
}

newoption {
  trigger = 'config',
  value = nil,
  description = 'Configuration to use for compile_commands.json'
}

newoption {
  trigger = 'platform',
  value = nil,
  description = 'Platform to use for compile_commands.json'
}

newoption {
  trigger = 'output-file',
  description = 'Output file to use instead of compile_commands.json'
}

return m

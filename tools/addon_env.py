"""Load the addon's Lua files in a real Lua 5.1 runtime (the same Lua version WoW uses).

The WoW API is stubbed just enough for data and logic files to load. This lets the
build and test tools read the addon's data exactly as the game would, instead of
parsing Lua with regular expressions.

Requires: pip install -r tools/requirements.txt
"""

from __future__ import annotations

import re
from pathlib import Path

from lupa import lua51

ROOT = Path(__file__).resolve().parent.parent
ADDON_DIR = ROOT / "AdventureGuideForever"
ADDON_NAME = "AdventureGuideForever"
TOC = ADDON_DIR / f"{ADDON_NAME}_Forever.toc"

# Minimal WoW API: frames are inert objects whose methods do nothing.
STUBS = r"""
local inert = setmetatable({}, { __index = function() return function() end end })
local function newFrame() return setmetatable({}, { __index = function() return function() end end }) end
CreateFrame = function() return newFrame() end
CopyTable = function(t)
  local c = {}
  for k, v in pairs(t) do c[k] = type(v) == "table" and CopyTable(v) or v end
  return c
end
wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
strsplit = function(sep, s)
  local out = {}
  for part in (s .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do out[#out + 1] = part end
  return unpack(out)
end
print = function() end
SlashCmdList = {}
UISpecialFrames = {}
C_Timer = { After = function() end }
GetTime = function() return 0 end
UIParent = inert
"""


def toc_files(toc: Path = TOC) -> list[Path]:
    """The Lua files the TOC loads, in load order."""
    files = []
    for line in toc.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            files.append(ADDON_DIR / line.replace("\\", "/"))
    return files


def load_addon(include: re.Pattern[str] | None = None):
    """Run the addon's files in TOC order and return (lua runtime, AG namespace table).

    include: optional pattern on the file's relative path; only matching files run.
    Core.lua always runs, since every other file needs the namespace it creates.
    """
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(STUBS)
    ns = lua.table()
    for path in toc_files():
        rel = path.relative_to(ADDON_DIR).as_posix()
        if include and rel != "Core.lua" and not include.search(rel):
            continue
        chunk = lua.eval("function(src, name) return assert(loadstring(src, '@' .. name)) end")(
            path.read_text(encoding="utf-8"), rel
        )
        chunk(ADDON_NAME, ns)
    return lua, ns


def to_py(value):
    """Convert Lua tables into Python lists/dicts, recursively."""
    if lua51.lua_type(value) != "table":
        return value
    keys = list(value.keys())
    if keys and all(isinstance(k, int) for k in keys) and sorted(keys) == list(range(1, len(keys) + 1)):
        return [to_py(value[k]) for k in sorted(keys)]
    return {k: to_py(v) for k, v in value.items()}

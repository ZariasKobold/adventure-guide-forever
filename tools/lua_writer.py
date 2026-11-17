"""Writes Python data as clean, consistently formatted Lua table literals.

Output style matches the hand-written addon code: tabs for indentation, named fields
in a fixed order, short tables of scalars kept on one line.
"""

from __future__ import annotations

import re

_IDENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
RECORD_LIMIT = 150  # longest line a record of plain values may take before it is split


def lua_string(s: str) -> str:
    escaped = (
        s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\r", "")
    )
    return f'"{escaped}"'


def lua_key(k) -> str:
    if isinstance(k, str) and _IDENT.match(k):
        return k
    return f"[{lua_value(k, 0)}]"


def lua_value(v, indent: int, key_order: list[str] | None = None) -> str:
    if v is None:
        return "nil"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(v)
    if isinstance(v, str):
        return lua_string(v)
    if isinstance(v, (list, tuple)):
        return _table([(None, x) for x in v], indent, key_order)
    if isinstance(v, dict):
        return _table(_ordered_items(v, key_order), indent, key_order)
    raise TypeError(f"can't write {type(v).__name__} as Lua")


def _ordered_items(d: dict, key_order: list[str] | None):
    order: dict[str, int] = {}
    for k in key_order or []:
        order.setdefault(k, len(order))  # first mention wins
    items = [(k, v) for k, v in d.items() if v is not None and v != [] and v != {}]
    return sorted(items, key=lambda kv: (order.get(kv[0], len(order)), str(kv[0])))


def _entry(k, v, indent, key_order) -> str:
    val = lua_value(v, indent, key_order)
    return val if k is None else f"{lua_key(k)} = {val}"


def _is_scalar(v) -> bool:
    return v is None or isinstance(v, (bool, int, float, str))


def _is_flat(items) -> bool:
    """A record of scalars (and short scalar lists) is written on one line."""
    return all(
        _is_scalar(v) or (isinstance(v, (list, tuple)) and all(_is_scalar(x) for x in v))
        for _, v in items
    )


def _table(items, indent: int, key_order) -> str:
    if not items:
        return "{}"
    parts = [_entry(k, v, indent + 1, key_order) for k, v in items]
    one_line = "{ " + ", ".join(parts) + " }"
    # Short records of plain values stay on one line; anything holding records, or too long
    # to read at a glance, is split one field per line.
    if _is_flat(items) and len(one_line) + indent * 4 <= RECORD_LIMIT:
        return one_line
    pad = "\t" * (indent + 1)
    return "{\n" + "".join(f"{pad}{p},\n" for p in parts) + "\t" * indent + "}"

#!/usr/bin/env python3
"""
merge_gltf_animations.py
------------------------
Merges separate gltf animation clips into a single sequential timeline
so Luanti's gltf loader can play them using mobs_redo frame ranges.

Luanti plays gltf animations from a flat time-line.  Blockbench exports
each action as an independent clip (all starting at t=0).  This script
offsets each clip by the cumulative duration of all clips before it,
then merges all samplers/channels into one "all_animations" clip.

Result timeline for alpaca.gltf:
  stand : 0.000 →  2.000 s
  walk  : 2.000 →  4.000 s
  eat   : 4.000 →  6.500 s
  run   : 6.500 →  7.875 s

Usage:
  python3 merge_gltf_animations.py
"""

import json, struct, base64, copy, sys
from pathlib import Path

INPUT  = Path(__file__).parent / "models" / "alpaca.gltf"
OUTPUT = Path(__file__).parent / "models" / "alpaca.gltf"   # overwrite in place
BACKUP = Path(__file__).parent / "models" / "alpaca_original.gltf"

# ── load ─────────────────────────────────────────────────────────────────────
with open(INPUT) as f:
    gltf = json.load(f)

# ── back up original ──────────────────────────────────────────────────────────
if not BACKUP.exists():
    with open(BACKUP, "w") as f:
        json.dump(gltf, f, separators=(",", ":"))
    print(f"Backup saved → {BACKUP.name}")

# ── decode embedded binary buffer ─────────────────────────────────────────────
PREFIX = "data:application/octet-stream;base64,"
uri = gltf["buffers"][0]["uri"]
if not uri.startswith(PREFIX):
    sys.exit("ERROR: buffer is not a data URI – only embedded gltf is supported.")
buf = bytearray(base64.b64decode(uri[len(PREFIX):]))

accessors    = gltf["accessors"]
buffer_views = gltf["bufferViews"]
animations   = gltf["animations"]

# ── helpers ───────────────────────────────────────────────────────────────────
def read_floats(accessor_idx: int) -> list:
    acc = accessors[accessor_idx]
    bv  = buffer_views[acc["bufferView"]]
    off = bv["byteOffset"]
    return [struct.unpack_from("<f", buf, off + i * 4)[0]
            for i in range(acc["count"])]

def write_floats(accessor_idx: int, values: list):
    acc = accessors[accessor_idx]
    bv  = buffer_views[acc["bufferView"]]
    off = bv["byteOffset"]
    for i, v in enumerate(values):
        struct.pack_into("<f", buf, off + i * 4, v)
    acc["max"] = [max(values)]
    acc["min"] = [min(values)]

def clip_duration(anim: dict) -> float:
    return max(max(read_floats(s["input"])) for s in anim["samplers"])

# ── compute cumulative offsets & print table ──────────────────────────────────
print("\nAnimation timeline (after merge):")
print(f"  {'name':12s}  {'start':>7s}  {'end':>7s}")
print(f"  {'-'*12}  {'-'*7}  {'-'*7}")

offset = 0.0
durations = []
for anim in animations:
    dur = clip_duration(anim)
    durations.append(dur)
    name = anim.get("name", "?")
    print(f"  {name:12s}  {offset:7.3f}  {offset+dur:7.3f}")
    offset += dur

total = offset
print(f"  {'TOTAL':12s}  {'0.000':>7s}  {total:7.3f}\n")

# ── offset each clip's input (time) accessors ─────────────────────────────────
cumulative = 0.0
for i, anim in enumerate(animations):
    if cumulative > 0.0:
        for sampler in anim["samplers"]:
            times = read_floats(sampler["input"])
            write_floats(sampler["input"], [t + cumulative for t in times])
    cumulative += durations[i]

# ── merge all samplers & channels into one clip ───────────────────────────────
merged = {"name": "all_animations", "samplers": [], "channels": []}
sampler_idx_offset = 0
for anim in animations:
    for ch in anim["channels"]:
        new_ch = copy.deepcopy(ch)
        new_ch["sampler"] += sampler_idx_offset
        merged["channels"].append(new_ch)
    merged["samplers"].extend(copy.deepcopy(anim["samplers"]))
    sampler_idx_offset += len(anim["samplers"])

gltf["animations"] = [merged]

# ── re-encode buffer & write ──────────────────────────────────────────────────
gltf["buffers"][0]["uri"] = PREFIX + base64.b64encode(bytes(buf)).decode()

with open(OUTPUT, "w") as f:
    json.dump(gltf, f, separators=(",", ":"))

print(f"Done → {OUTPUT}")
print("Lua animation ranges to use in alpaca.lua:")
print("  stand_start=0.0,   stand_end=2.0")
print("  walk_start=2.0,    walk_end=4.0")
print("  stand1_start=4.0,  stand1_end=6.5   -- eat / graze")
print("  run_start=6.5,     run_end=7.875")

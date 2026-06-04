#!/usr/bin/env python3
"""
Parametric hockey-puck image-registration jig.

A mask plate that sits ON TOP of a grid of hockey pucks. Each cell has:
  * a circular POCKET (skirt) on the underside that drops over the puck top
    and registers it concentrically, and
  * a smaller circular APERTURE through the top, exposing a concentric circle
    of the puck face.

Because every puck is centred by its pocket and the aperture is concentric,
the masked ring (border) is identical on all pucks. Use it as a paint/print/
decal registration mask.

Standard hockey puck: 76.2 mm dia (3") x 25.4 mm (1") thick.

Output: watertight binary STL. No third-party dependencies.
"""

import struct
import math
import os
from collections import defaultdict

# ----------------------------------------------------------------------------
# Parameters (mm) -- edit here or override COLS/ROWS via env vars.
# ----------------------------------------------------------------------------
PUCK_DIA      = 76.2          # hockey puck diameter (3")
POCKET_CLEAR  = 0.6           # diametral clearance so the jig drops over a puck
BORDER        = 6.0           # masked border width on the puck face (uniform)
POCKET_DEPTH  = 6.0           # how far the skirt sleeves down over each puck
TOP_THICK     = 3.0           # plate thickness above the puck face
WALL          = 4.0           # wall between adjacent pockets
COLS = int(os.environ.get("COLS", 9))
ROWS = int(os.environ.get("ROWS", 9))
N    = 64                     # circle facets (must be a multiple of 8)

OUTPUT = os.environ.get("OUTPUT", f"hockey_puck_jig_{COLS}x{ROWS}.stl")

# ----------------------------------------------------------------------------
# Derived
# ----------------------------------------------------------------------------
rp = (PUCK_DIA + POCKET_CLEAR) / 2.0      # pocket radius
ra = (PUCK_DIA - 2 * BORDER) / 2.0        # aperture (window) radius
Hp = POCKET_DEPTH                         # pocket floor / ledge height
T  = POCKET_DEPTH + TOP_THICK             # total plate height
pitch = 2 * rp + WALL                     # cell pitch
h = pitch / 2.0                           # half cell

assert N % 8 == 0
TH = [2 * math.pi * k / N for k in range(N)]
COS = [math.cos(t) for t in TH]
SIN = [math.sin(t) for t in TH]

GRID_W = COLS * pitch
GRID_H = ROWS * pitch
GCX, GCY = GRID_W / 2.0, GRID_H / 2.0

tris = []          # (a, b, c, hint_normal)


def R(v):
    return (round(v[0], 4), round(v[1], 4), round(v[2], 4))


def emit(a, b, c, hint):
    tris.append((R(a), R(b), R(c), hint))


def quad(a, b, c, d, hint):
    emit(a, b, c, hint)
    emit(a, c, d, hint)


def circ(cx, cy, r, k, z):
    return (cx + r * COS[k], cy + r * SIN[k], z)


def sqp(cx, cy, k, z):
    """Project ray at angle k onto the cell's square boundary."""
    c, s = COS[k], SIN[k]
    t = h / max(abs(c), abs(s))
    return (cx + t * c, cy + t * s, z)


def cell(cx, cy):
    inward = lambda p: (cx - p[0], cy - p[1], 0.0)   # toward puck axis
    for k in range(N):
        kn = (k + 1) % N
        # top annulus (z=T): aperture(ra) -> square, normal +Z
        ai, ain = circ(cx, cy, ra, k, T), circ(cx, cy, ra, kn, T)
        so, son = sqp(cx, cy, k, T), sqp(cx, cy, kn, T)
        quad(ai, ain, son, so, (0, 0, 1))
        # bottom annulus (z=0): pocket(rp) -> square, normal -Z
        pi, pin = circ(cx, cy, rp, k, 0), circ(cx, cy, rp, kn, 0)
        bo, bon = sqp(cx, cy, k, 0), sqp(cx, cy, kn, 0)
        quad(pi, pin, bon, bo, (0, 0, -1))
        # ledge (z=Hp): ra -> rp, faces down (puck face presses up against it)
        li, lin = circ(cx, cy, ra, k, Hp), circ(cx, cy, ra, kn, Hp)
        lo, lon = circ(cx, cy, rp, k, Hp), circ(cx, cy, rp, kn, Hp)
        quad(lo, lon, lin, li, (0, 0, -1))
        # aperture wall ra, z=Hp..T (inward normal)
        a0, a1 = circ(cx, cy, ra, k, Hp), circ(cx, cy, ra, kn, Hp)
        a2, a3 = circ(cx, cy, ra, kn, T), circ(cx, cy, ra, k, T)
        mid = ((a0[0] + a2[0]) / 2, (a0[1] + a2[1]) / 2, 0)
        quad(a0, a1, a2, a3, inward(mid))
        # pocket wall rp, z=0..Hp (inward normal)
        p0, p1 = circ(cx, cy, rp, k, 0), circ(cx, cy, rp, kn, 0)
        p2, p3 = circ(cx, cy, rp, kn, Hp), circ(cx, cy, rp, k, Hp)
        mid = ((p0[0] + p2[0]) / 2, (p0[1] + p2[1]) / 2, 0)
        quad(p0, p1, p2, p3, inward(mid))


# build all cells
for r in range(ROWS):
    for c in range(COLS):
        cell((c + 0.5) * pitch, (r + 0.5) * pitch)

# --- perimeter walls from boundary detection (edges used once at z=T) ---
edge_count = defaultdict(int)
for a, b, c, _ in tris:
    for u, v in ((a, b), (b, c), (c, a)):
        edge_count[frozenset((u, v))] += 1

for a, b, c, _ in list(tris):
    for u, v in ((a, b), (b, c), (c, a)):
        if edge_count[frozenset((u, v))] == 1 and u[2] == T and v[2] == T:
            u0, v0 = (u[0], u[1], 0.0), (v[0], v[1], 0.0)
            mx, my = (u[0] + v[0]) / 2, (u[1] + v[1]) / 2
            quad(v, u, u0, v0, (mx - GCX, my - GCY, 0))   # outward

# ----------------------------------------------------------------------------
# Write binary STL with outward-oriented normals
# ----------------------------------------------------------------------------
def cross_n(a, b, c):
    ux, uy, uz = b[0]-a[0], b[1]-a[1], b[2]-a[2]
    vx, vy, vz = c[0]-a[0], c[1]-a[1], c[2]-a[2]
    nx, ny, nz = uy*vz-uz*vy, uz*vx-ux*vz, ux*vy-uy*vx
    m = math.sqrt(nx*nx+ny*ny+nz*nz) or 1.0
    return nx/m, ny/m, nz/m


with open(OUTPUT, "wb") as f:
    f.write(b"\0" * 80)
    f.write(struct.pack("<I", len(tris)))
    for a, b, c, hint in tris:
        n = cross_n(a, b, c)
        if n[0]*hint[0] + n[1]*hint[1] + n[2]*hint[2] < 0:   # flip to outward
            b, c = c, b
            n = cross_n(a, b, c)
        f.write(struct.pack("<3f", *n))
        for v in (a, b, c):
            f.write(struct.pack("<3f", *v))
        f.write(struct.pack("<H", 0))

print(f"Wrote {OUTPUT}: {len(tris)} triangles")
print(f"Grid:       {COLS} x {ROWS} = {COLS*ROWS} pucks")
print(f"Puck/pocket {PUCK_DIA:.1f} / {2*rp:.1f} mm dia | aperture {2*ra:.1f} mm "
      f"| border {BORDER:.1f} mm")
print(f"Skirt depth {POCKET_DEPTH:.1f} mm | total height {T:.1f} mm")
print(f"Footprint:  {GRID_W:.1f} x {GRID_H:.1f} x {T:.1f} mm")

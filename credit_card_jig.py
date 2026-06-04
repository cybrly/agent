#!/usr/bin/env python3
"""
Parametric 3D-printable credit-card jig.

Generates a watertight binary STL of a tray with a grid of recessed,
credit-card-sized pockets. Default is a 6 x 3 grid (18 cards).

Credit card spec: ISO/IEC 7810 ID-1 (CR80) = 85.60 x 53.98 x 0.76 mm.

No third-party dependencies (pure Python).
"""

import struct

# ----------------------------------------------------------------------------
# Parameters (all in millimetres) -- edit these to customise.
# ----------------------------------------------------------------------------
CARD_W = 85.60          # credit card long edge
CARD_H = 53.98          # credit card short edge

COLS = 6                # pockets across
ROWS = 3                # pockets down

ORIENTATION = "portrait"  # "portrait" -> cards stand tall, "landscape" -> wide

CLEARANCE = 0.40        # gap added to each side of the card (fit tolerance)
POCKET_DEPTH = 1.20     # how deep each pocket is recessed
FLOOR_THICK = 2.00      # solid material below each pocket
WALL = 4.00             # wall thickness between adjacent pockets
BORDER = 6.00           # outer frame thickness around the whole grid

OUTPUT = "credit_card_jig_6x3.stl"

# ----------------------------------------------------------------------------
# Derived pocket footprint
# ----------------------------------------------------------------------------
if ORIENTATION == "portrait":
    card_x, card_y = CARD_H, CARD_W          # short edge horizontal
else:
    card_x, card_y = CARD_W, CARD_H

POCKET_W = card_x + 2 * CLEARANCE
POCKET_H = card_y + 2 * CLEARANCE

TOP_Z = FLOOR_THICK + POCKET_DEPTH           # top surface height
FLOOR_Z = FLOOR_THICK                        # pocket floor height
BOT_Z = 0.0

TOTAL_W = 2 * BORDER + COLS * POCKET_W + (COLS - 1) * WALL
TOTAL_H = 2 * BORDER + ROWS * POCKET_H + (ROWS - 1) * WALL

# ----------------------------------------------------------------------------
# Mesh builder: collect triangles, write binary STL.
# ----------------------------------------------------------------------------
tris = []  # list of (v0, v1, v2) with outward-facing CCW winding


def quad(a, b, c, d):
    """Emit two triangles for quad a-b-c-d (must be given CCW from outside)."""
    tris.append((a, b, c))
    tris.append((a, c, d))


def top_rect(x0, y0, x1, y1, z):
    """Flat rectangle facing +Z."""
    quad((x0, y0, z), (x1, y0, z), (x1, y1, z), (x0, y1, z))


def bottom_rect(x0, y0, x1, y1, z):
    """Flat rectangle facing -Z."""
    quad((x0, y0, z), (x0, y1, z), (x1, y1, z), (x1, y0, z))


def pocket(x0, y0, x1, y1, ztop, zfloor):
    """Inner walls (facing into pocket) + floor for one recess."""
    # floor faces +Z
    top_rect(x0, y0, x1, y1, zfloor)
    # four side walls, normals pointing inward toward pocket centre
    # -X wall (normal +X)
    quad((x0, y0, zfloor), (x0, y1, zfloor), (x0, y1, ztop), (x0, y0, ztop))
    # +X wall (normal -X)
    quad((x1, y1, zfloor), (x1, y0, zfloor), (x1, y0, ztop), (x1, y1, ztop))
    # -Y wall (normal +Y)
    quad((x1, y0, zfloor), (x0, y0, zfloor), (x0, y0, ztop), (x1, y0, ztop))
    # +Y wall (normal -Y)
    quad((x0, y1, zfloor), (x1, y1, zfloor), (x1, y1, ztop), (x0, y1, ztop))


# Pocket opening edges
col_x0 = [BORDER + c * (POCKET_W + WALL) for c in range(COLS)]
row_y0 = [BORDER + r * (POCKET_H + WALL) for r in range(ROWS)]


def rnd(v):
    return round(v, 6)


# Build a consistent set of cut lines so every shared edge coincides
# (no T-junctions). Cut at every pocket edge plus the outer border.
xc = sorted({rnd(0.0), rnd(TOTAL_W)} |
            {rnd(x) for x in col_x0} | {rnd(x + POCKET_W) for x in col_x0})
yc = sorted({rnd(0.0), rnd(TOTAL_H)} |
            {rnd(y) for y in row_y0} | {rnd(y + POCKET_H) for y in row_y0})

pocket_xspans = {(rnd(x), rnd(x + POCKET_W)) for x in col_x0}
pocket_yspans = {(rnd(y), rnd(y + POCKET_H)) for y in row_y0}

# --- bottom + top, tiled cell by cell on the same grid ---
for i in range(len(xc) - 1):
    x0, x1 = xc[i], xc[i + 1]
    for j in range(len(yc) - 1):
        y0, y1 = yc[j], yc[j + 1]
        bottom_rect(x0, y0, x1, y1, BOT_Z)        # solid floor everywhere
        is_pocket = ((rnd(x0), rnd(x1)) in pocket_xspans and
                     (rnd(y0), rnd(y1)) in pocket_yspans)
        if is_pocket:
            pocket(x0, y0, x1, y1, TOP_Z, FLOOR_Z)
        else:
            top_rect(x0, y0, x1, y1, TOP_Z)        # frame top surface

# --- outer perimeter walls, split along the same cuts (z = 0 .. TOP_Z) ---
for i in range(len(xc) - 1):
    x0, x1 = xc[i], xc[i + 1]
    quad((x0, 0, 0), (x1, 0, 0), (x1, 0, TOP_Z), (x0, 0, TOP_Z))                  # -Y
    quad((x1, TOTAL_H, 0), (x0, TOTAL_H, 0), (x0, TOTAL_H, TOP_Z), (x1, TOTAL_H, TOP_Z))  # +Y
for j in range(len(yc) - 1):
    y0, y1 = yc[j], yc[j + 1]
    quad((TOTAL_W, y0, 0), (TOTAL_W, y1, 0), (TOTAL_W, y1, TOP_Z), (TOTAL_W, y0, TOP_Z))  # +X
    quad((0, y1, 0), (0, y0, 0), (0, y0, TOP_Z), (0, y1, TOP_Z))                  # -X


# ----------------------------------------------------------------------------
# Write binary STL
# ----------------------------------------------------------------------------
def normal(a, b, c):
    ux, uy, uz = b[0] - a[0], b[1] - a[1], b[2] - a[2]
    vx, vy, vz = c[0] - a[0], c[1] - a[1], c[2] - a[2]
    nx, ny, nz = uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx
    m = (nx * nx + ny * ny + nz * nz) ** 0.5 or 1.0
    return nx / m, ny / m, nz / m


with open(OUTPUT, "wb") as f:
    f.write(b"\0" * 80)
    f.write(struct.pack("<I", len(tris)))
    for a, b, c in tris:
        n = normal(a, b, c)
        f.write(struct.pack("<3f", *n))
        f.write(struct.pack("<3f", *a))
        f.write(struct.pack("<3f", *b))
        f.write(struct.pack("<3f", *c))
        f.write(struct.pack("<H", 0))

print(f"Wrote {OUTPUT}: {len(tris)} triangles")
print(f"Grid:        {COLS} x {ROWS} = {COLS*ROWS} pockets ({ORIENTATION})")
print(f"Pocket:      {POCKET_W:.2f} x {POCKET_H:.2f} x {POCKET_DEPTH:.2f} mm")
print(f"Footprint:   {TOTAL_W:.2f} x {TOTAL_H:.2f} x {TOP_Z:.2f} mm")

"""
Generates Play Store assets for LocateMeUp:
  - app_icon.png          512×512
  - feature_graphic.png  1024×500
  - screenshot_1..6.png  1080×1920  (phone, 9:16)
"""

from PIL import Image, ImageDraw, ImageFont
import math, os

OUT = os.path.dirname(__file__)

# ── Palette ────────────────────────────────────────────────────────────────
C_DARK   = (21,  101, 192)   # #1565C0
C_MID    = (30,  136, 229)   # #1E88E5
C_LIGHT  = (66,  165, 245)   # #42A5F5
C_ACCENT = (255, 193,   7)   # amber
C_WHITE  = (255, 255, 255)
C_OFFWH  = (236, 242, 255)
C_DARK2  = (13,   71, 161)   # #0D47A1
C_CARD   = (255, 255, 255)
C_TEXT   = (33,   33,  33)
C_SUB    = (117, 117, 117)
C_RED    = (229,  57,  53)
C_GREEN  = (67,  160,  71)

def v_gradient(draw, w, h, top, bottom):
    for y in range(h):
        t = y / (h - 1)
        r = int(top[0] + (bottom[0] - top[0]) * t)
        g = int(top[1] + (bottom[1] - top[1]) * t)
        b = int(top[2] + (bottom[2] - top[2]) * t)
        draw.line([(0, y), (w, y)], fill=(r, g, b))

def pin_path(cx, cy, r):
    """Return a location-pin polygon centred at (cx,cy) with radius r."""
    pts = []
    # top circle  (angles 210° → 330°  going through top)
    for deg in range(210, 331, 3):
        rad = math.radians(deg)
        pts.append((cx + r * math.cos(rad), cy - r * 0.95 - r * 0.05 + r * math.sin(rad)))
    # taper to bottom point
    pts.append((cx, cy + r * 1.05))
    return pts

def draw_pin(draw, cx, cy, size, color, inner=True):
    """Draw a filled map-pin."""
    r = size / 2
    # body: circle + triangle
    draw.ellipse([cx - r, cy - r * 1.9, cx + r, cy + r * 0.1 - r * 1.9 + r * 2], fill=color)
    # tail
    tail = [
        (cx - r * 0.55, cy - r * 0.55),
        (cx + r * 0.55, cy - r * 0.55),
        (cx, cy + r * 1.1),
    ]
    draw.polygon(tail, fill=color)
    if inner:
        ir = r * 0.42
        draw.ellipse([cx - ir, cy - r * 1.9 + r - ir, cx + ir, cy - r * 1.9 + r + ir],
                     fill=C_WHITE)

def draw_bell(draw, cx, cy, size, color):
    """Draw a simple bell shape."""
    r = size / 2
    # dome
    draw.pieslice([cx - r, cy - r * 1.2, cx + r, cy + r * 0.3], start=200, end=340, fill=color)
    # body
    draw.rectangle([cx - r, cy - r * 0.15, cx + r, cy + r * 0.5], fill=color)
    # clapper
    cr = r * 0.22
    draw.ellipse([cx - cr, cy + r * 0.45, cx + cr, cy + r * 0.45 + cr * 2], fill=color)
    # handle
    draw.arc([cx - r * 0.25, cy - r * 1.4, cx + r * 0.25, cy - r * 0.9],
             start=200, end=340, fill=color, width=max(2, int(r * 0.18)))

def rounded_rect(draw, xy, r, fill, outline=None, outline_width=0):
    x0, y0, x1, y1 = xy
    draw.rounded_rectangle([x0, y0, x1, y1], radius=r, fill=fill,
                            outline=outline, width=outline_width)

# ── font helpers ───────────────────────────────────────────────────────────
def font(size):
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", size)
    except Exception:
        return ImageFont.load_default()

def font_reg(size):
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", size)
    except Exception:
        return ImageFont.load_default()

def centred_text(draw, text, cx, y, fnt, fill):
    bb = draw.textbbox((0, 0), text, font=fnt)
    w = bb[2] - bb[0]
    draw.text((cx - w // 2, y), text, font=fnt, fill=fill)

# ══════════════════════════════════════════════════════════════════════════
# 1. APP ICON  512×512
# ══════════════════════════════════════════════════════════════════════════
def make_icon():
    W = H = 512
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # rounded-square background with gradient (simulate via bands)
    bg = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bg_d = ImageDraw.Draw(bg)
    for y in range(H):
        t = y / (H - 1)
        r = int(C_DARK[0] + (C_LIGHT[0] - C_DARK[0]) * t)
        g = int(C_DARK[1] + (C_LIGHT[1] - C_DARK[1]) * t)
        b = int(C_DARK[2] + (C_LIGHT[2] - C_DARK[2]) * t)
        bg_d.line([(0, y), (W, y)], fill=(r, g, b, 255))

    mask = Image.new("L", (W, H), 0)
    mask_d = ImageDraw.Draw(mask)
    mask_d.rounded_rectangle([0, 0, W, H], radius=110, fill=255)
    img.paste(bg, (0, 0), mask)
    draw = ImageDraw.Draw(img)

    # white pin  (large)
    px, py, ps = W // 2, H // 2 - 20, 280
    draw_pin(draw, px, py, ps, C_WHITE, inner=False)
    # blue inner hole
    ir = ps * 0.18
    draw.ellipse([px - ir, py - ps * 0.95 + ps * 0.5 - ir,
                  px + ir, py - ps * 0.95 + ps * 0.5 + ir], fill=C_MID)

    # amber bell inside pin hole area
    draw_bell(draw, px, py - 54, 68, C_ACCENT)

    img.save(os.path.join(OUT, "app_icon.png"))
    print("✓ app_icon.png")


# ══════════════════════════════════════════════════════════════════════════
# 2. FEATURE GRAPHIC  1024×500
# ══════════════════════════════════════════════════════════════════════════
def make_feature():
    W, H = 1024, 500
    img = Image.new("RGB", (W, H))
    draw = ImageDraw.Draw(img)
    v_gradient(draw, W, H, C_DARK2, C_LIGHT)

    # decorative circles
    for cx, cy, r, alpha in [(820, 80, 180, 40), (900, 400, 120, 30), (120, 420, 90, 25)]:
        overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        od = ImageDraw.Draw(overlay)
        od.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 255, 255, alpha))
        img.paste(Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB"))
        draw = ImageDraw.Draw(img)

    # pin graphic right side
    draw_pin(draw, 820, 220, 260, (255, 255, 255, 80) if False else (200, 225, 255), inner=False)
    ir = 260 * 0.18
    draw.ellipse([820 - ir, 220 - 260 * 0.95 + 260 * 0.5 - ir,
                  820 + ir, 220 - 260 * 0.95 + 260 * 0.5 + ir], fill=C_MID)
    draw_bell(draw, 820, 220 - 50, 72, C_ACCENT)

    # text
    centred_text(draw, "LocateMeUp", W // 2 - 80, 130, font(82), C_WHITE)
    centred_text(draw, "Location-Based Alarm", W // 2 - 80, 232, font_reg(38), C_OFFWH)
    centred_text(draw, "Never miss your stop again", W // 2 - 80, 296, font_reg(28), (180, 210, 255))

    # badges row
    badges = [("📍 Set location", 180), ("🔔 Auto alarm", 380), ("🗺  Search & go", 580)]
    for txt, bx in badges:
        rounded_rect(draw, [bx - 100, 370, bx + 100, 420], 24,
                     fill=(255, 255, 255, 50) if False else (255, 255, 255))
        bb = draw.textbbox((0, 0), txt, font=font_reg(22))
        tw = bb[2] - bb[0]
        draw.text((bx - tw // 2, 382), txt, font=font_reg(22), fill=C_DARK)

    img.save(os.path.join(OUT, "feature_graphic.png"))
    print("✓ feature_graphic.png")


# ══════════════════════════════════════════════════════════════════════════
# 3. PHONE SCREENSHOTS  1080×1920
# ══════════════════════════════════════════════════════════════════════════
SW, SH = 1080, 1920
BAR_H = 100   # status bar
APP_BAR = 160

def status_bar(draw, w=SW):
    draw.rectangle([0, 0, w, BAR_H], fill=C_DARK)
    draw.text((40, 32), "9:41", font=font(44), fill=C_WHITE)
    draw.text((w - 160, 32), "●●●", font=font(36), fill=C_WHITE)

def app_bar(draw, title, w=SW, back=False):
    draw.rectangle([0, BAR_H, w, BAR_H + APP_BAR], fill=C_DARK)
    x = 120 if back else 60
    if back:
        draw.text((50, BAR_H + 48), "←", font=font(56), fill=C_WHITE)
    draw.text((x, BAR_H + 44), title, font=font(52), fill=C_WHITE)

def phone_bg(draw):
    draw.rectangle([0, 0, SW, SH], fill=C_OFFWH)

def card(draw, y, h, title, sub, active=False, distance=None):
    fill = (232, 240, 254) if active else C_CARD
    border = C_MID if active else (224, 224, 224)
    rounded_rect(draw, [40, y, SW - 40, y + h], 28, fill=fill,
                 outline=border, outline_width=3 if active else 1)
    # icon circle
    ic = C_MID if active else (189, 189, 189)
    draw.ellipse([72, y + 24, 132, y + 84], fill=ic)
    draw_pin(draw, 102, y + 54, 48, C_WHITE, inner=False)
    draw.ellipse([102 - 6, y + 54 - 48 * 0.45 - 6,
                  102 + 6, y + 54 - 48 * 0.45 + 6], fill=ic)
    # text
    tf = font(42) if active else font_reg(42)
    tc = C_TEXT if active else C_SUB
    draw.text((156, y + 18), title, font=tf, fill=tc)
    draw.text((156, y + 72), sub, font=font_reg(30), fill=C_SUB)
    if distance:
        dc = C_MID if active else C_SUB
        draw.text((SW - 220, y + 38), distance, font=font(34), fill=dc)

def fab(draw):
    cx, cy, r = SW - 100, SH - 140, 72
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=C_MID)
    draw.text((cx - 22, cy - 32), "+", font=font(64), fill=C_WHITE)

# ── Screenshot 1: Alarm list (active alarm) ─────────────────────────────
def make_ss1():
    img = Image.new("RGB", (SW, SH))
    d = ImageDraw.Draw(img)
    phone_bg(d)
    status_bar(d)
    app_bar(d, "LocateMeUp")

    top = BAR_H + APP_BAR + 30
    d.text((60, top), "My Alarms", font=font(58), fill=C_TEXT)
    d.text((60, top + 70), "1 active", font=font_reg(34), fill=C_MID)
    top += 150

    card(d, top, 130, "Zurich HB", "Bahnhofplatz · 0.8 km", active=True, distance="800 m")
    top += 150
    card(d, top, 130, "Home", "Musterstrasse 12", active=False)
    top += 150
    card(d, top, 130, "Office", "Technopark · 2.1 km", active=False, distance="2.1 km")
    fab(d)
    img.save(os.path.join(OUT, "screenshot_1.png"))
    print("✓ screenshot_1.png")

# ── Screenshot 2: Alarm list (empty state) ──────────────────────────────
def make_ss2():
    img = Image.new("RGB", (SW, SH))
    d = ImageDraw.Draw(img)
    phone_bg(d)
    status_bar(d)
    app_bar(d, "LocateMeUp")

    cy = SH // 2
    r = 120
    d.ellipse([SW // 2 - r, cy - r - 60, SW // 2 + r, cy + r - 60], fill=(207, 226, 255))
    draw_pin(d, SW // 2, cy - 60, 160, C_MID, inner=False)
    ir = 160 * 0.18
    d.ellipse([SW // 2 - ir, cy - 60 - 160 * 0.95 + 160 * 0.5 - ir,
               SW // 2 + ir, cy - 60 - 160 * 0.95 + 160 * 0.5 + ir], fill=(207, 226, 255))

    centred_text(d, "No alarms yet", SW // 2, cy + 100, font(54), C_TEXT)
    centred_text(d, "Tap + to add your first location alarm", SW // 2, cy + 174, font_reg(32), C_SUB)
    fab(d)
    img.save(os.path.join(OUT, "screenshot_2.png"))
    print("✓ screenshot_2.png")

# ── Screenshot 3: Map screen with marker ────────────────────────────────
def make_ss3():
    img = Image.new("RGB", (SW, SH))
    d = ImageDraw.Draw(img)

    # map-like background
    d.rectangle([0, 0, SW, SH], fill=(242, 243, 244))
    # grid roads
    for x in range(0, SW, 120):
        d.rectangle([x - 6, 0, x + 6, SH], fill=(255, 255, 255))
    for y in range(0, SH, 120):
        d.rectangle([0, y - 6, SW, y + 6], fill=(255, 255, 255))
    # green park
    d.rectangle([200, 700, 600, 1050], fill=(197, 225, 165))
    d.rectangle([50, 1200, 350, 1480], fill=(197, 225, 165))
    # blue water
    d.rectangle([680, 900, SW, 1200], fill=(187, 222, 251))
    # block buildings
    for bx, by, bw, bh in [(80,400,140,120),(320,380,160,100),(640,500,180,140),
                            (100,1550,200,120),(500,1600,160,100),(800,1500,180,130)]:
        d.rectangle([bx, by, bx + bw, by + bh], fill=(220, 220, 220))
        d.rectangle([bx + 2, by + 2, bx + bw - 2, by + bh - 2], fill=(200, 200, 200))

    status_bar(d)
    app_bar(d, "Add Alarm", back=True)

    # marker
    mx, my = SW // 2, SH // 2 - 80
    draw_pin(d, mx, my, 120, C_RED, inner=False)
    ir = 120 * 0.18
    d.ellipse([mx - ir, my - 120 * 0.95 + 120 * 0.5 - ir,
               mx + ir, my - 120 * 0.95 + 120 * 0.5 + ir], fill=(255, 255, 255))

    # info bubble
    bw, bh = 500, 100
    bx, by = mx - bw // 2, my - 210
    rounded_rect(d, [bx, by, bx + bw, by + bh], 16, fill=C_WHITE)
    centred_text(d, "Zurich HB", mx, by + 12, font(38), C_TEXT)
    centred_text(d, "Bahnhofplatz, Zürich", mx, by + 58, font_reg(28), C_SUB)

    # save button
    rounded_rect(d, [80, SH - 220, SW - 80, SH - 100], 32, fill=C_MID)
    centred_text(d, "✓  Save alarm", SW // 2, SH - 196, font(52), C_WHITE)

    img.save(os.path.join(OUT, "screenshot_3.png"))
    print("✓ screenshot_3.png")

# ── Screenshot 4: Map with search overlay ───────────────────────────────
def make_ss4():
    img = Image.new("RGB", (SW, SH))
    d = ImageDraw.Draw(img)
    # map bg (same as ss3 but simpler)
    d.rectangle([0, 0, SW, SH], fill=(242, 243, 244))
    for x in range(0, SW, 120):
        d.rectangle([x - 6, 0, x + 6, SH], fill=(255, 255, 255))
    for y in range(0, SH, 120):
        d.rectangle([0, y - 6, SW, y + 6], fill=(255, 255, 255))
    d.rectangle([200, 700, 600, 1050], fill=(197, 225, 165))
    d.rectangle([680, 900, SW, 1200], fill=(187, 222, 251))
    for bx, by, bw, bh in [(80,400,140,120),(320,380,160,100),(640,500,180,140)]:
        d.rectangle([bx, by, bx + bw, by + bh], fill=(220, 220, 220))

    status_bar(d)
    app_bar(d, "Add Alarm", back=True)

    top = BAR_H + APP_BAR
    # search panel
    panel_h = 680
    d.rectangle([0, top, SW, top + panel_h], fill=C_WHITE)

    # search box
    rounded_rect(d, [30, top + 20, SW - 30, top + 110], 16,
                 fill=C_OFFWH, outline=(189, 189, 189), outline_width=2)
    d.text((70, top + 34), "🔍", font=font(44), fill=C_SUB)
    d.text((130, top + 34), "Zurich main station", font=font_reg(40), fill=C_TEXT)
    d.text((SW - 90, top + 34), "✕", font=font(44), fill=C_SUB)

    # progress bar
    d.rectangle([0, top + 112, SW // 3, top + 118], fill=C_MID)

    # results
    results = [
        ("Zürich Hauptbahnhof", "Bahnhofplatz, 8001 Zürich"),
        ("Zurich Airport HB", "Flughafen, 8058 Zürich"),
        ("Zurich Hardbrücke", "Hardstrasse, 8005 Zürich"),
        ("Zurich Stadelhofen", "Stadelhofen, 8001 Zürich"),
    ]
    ry = top + 140
    for i, (name, addr) in enumerate(results):
        if i > 0:
            d.line([(60, ry), (SW - 60, ry)], fill=(238, 238, 238), width=1)
        bg = C_OFFWH if i == 0 else C_WHITE
        d.rectangle([0, ry, SW, ry + 130], fill=bg)
        d.ellipse([50, ry + 28, 106, ry + 84], fill=(207, 226, 255))
        draw_pin(d, 78, ry + 56, 44, C_MID, inner=False)
        ir2 = 44 * 0.18
        d.ellipse([78 - ir2, ry + 56 - 44 * 0.95 + 44 * 0.5 - ir2,
                   78 + ir2, ry + 56 - 44 * 0.95 + 44 * 0.5 + ir2], fill=(207, 226, 255))
        d.text((130, ry + 18), name, font=font(36), fill=C_TEXT)
        d.text((130, ry + 68), addr, font=font_reg(28), fill=C_SUB)
        ry += 130

    img.save(os.path.join(OUT, "screenshot_4.png"))
    print("✓ screenshot_4.png")

# ── Screenshot 5: Alarm firing screen ───────────────────────────────────
def make_ss5():
    img = Image.new("RGB", (SW, SH))
    d = ImageDraw.Draw(img)
    v_gradient(d, SW, SH, C_DARK2, (21, 101, 192))
    status_bar(d)

    # pulsing rings
    for r, alpha in [(340, 18), (260, 30), (180, 50)]:
        overlay = Image.new("RGBA", (SW, SH), (0, 0, 0, 0))
        od = ImageDraw.Draw(overlay)
        od.ellipse([SW // 2 - r, SH // 3 - r, SW // 2 + r, SH // 3 + r],
                   outline=(255, 255, 255, alpha), width=4)
        img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
        d = ImageDraw.Draw(img)

    # large pin icon
    draw_pin(d, SW // 2, SH // 3, 240, C_WHITE, inner=False)
    ir = 240 * 0.18
    d.ellipse([SW // 2 - ir, SH // 3 - 240 * 0.95 + 240 * 0.5 - ir,
               SW // 2 + ir, SH // 3 - 240 * 0.95 + 240 * 0.5 + ir], fill=C_MID)

    # alarm text
    centred_text(d, "You've arrived!", SW // 2, SH // 3 + 220, font(72), C_WHITE)
    centred_text(d, "Zurich HB", SW // 2, SH // 3 + 318, font(82), C_ACCENT)
    centred_text(d, "Bahnhofplatz · 50 m away", SW // 2, SH // 3 + 426, font_reg(40), (180, 210, 255))

    # stop button
    rounded_rect(d, [120, SH - 320, SW - 120, SH - 180], 60, fill=C_WHITE)
    centred_text(d, "Stop Alarm", SW // 2, SH - 302, font(58), C_DARK)

    # dismiss label
    centred_text(d, "Swipe to dismiss", SW // 2, SH - 130, font_reg(34), (180, 210, 255))

    img.save(os.path.join(OUT, "screenshot_5.png"))
    print("✓ screenshot_5.png")

# ── Screenshot 6: Multi-alarm map ───────────────────────────────────────
def make_ss6():
    img = Image.new("RGB", (SW, SH))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, SW, SH], fill=(242, 243, 244))
    for x in range(0, SW, 120):
        d.rectangle([x - 6, 0, x + 6, SH], fill=(255, 255, 255))
    for y in range(0, SH, 120):
        d.rectangle([0, y - 6, SW, y + 6], fill=(255, 255, 255))
    d.rectangle([200, 600, 700, 1000], fill=(197, 225, 165))
    d.rectangle([720, 800, SW, 1150], fill=(187, 222, 251))
    for bx, by, bw, bh in [(60,350,140,120),(300,340,180,110),(680,450,160,140),
                            (80,1300,180,120),(450,1400,160,100),(750,1350,200,130)]:
        d.rectangle([bx, by, bx + bw, by + bh], fill=(220, 220, 220))

    status_bar(d)
    app_bar(d, "Add Alarm", back=True)

    # multiple markers
    for mx2, my2, col in [(280, 720, C_RED), (740, 950, C_MID), (500, 1350, C_GREEN)]:
        draw_pin(d, mx2, my2, 90, col, inner=False)
        ir3 = 90 * 0.18
        d.ellipse([mx2 - ir3, my2 - 90 * 0.95 + 90 * 0.5 - ir3,
                   mx2 + ir3, my2 - 90 * 0.95 + 90 * 0.5 + ir3], fill=C_WHITE)

    # save button  — 3 alarms
    rounded_rect(d, [80, SH - 220, SW - 80, SH - 100], 32, fill=C_MID)
    centred_text(d, "✓  Save 3 alarms", SW // 2, SH - 196, font(52), C_WHITE)

    img.save(os.path.join(OUT, "screenshot_6.png"))
    print("✓ screenshot_6.png")


if __name__ == "__main__":
    make_icon()
    make_feature()
    make_ss1()
    make_ss2()
    make_ss3()
    make_ss4()
    make_ss5()
    make_ss6()
    print("\nAll assets written to", OUT)

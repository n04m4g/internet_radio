from PIL import Image, ImageDraw
from pathlib import Path

out = Path(r"c:\Users\NoamRa\dev\internet_radio\assets\icon")
out.mkdir(parents=True, exist_ok=True)

TEAL = (0x1B, 0x6B, 0x5A, 255)
WHITE = (255, 255, 255, 255)
TEAL_DARK = (0x14, 0x52, 0x45, 255)


def draw_radio_mark(
    draw: ImageDraw.ImageDraw,
    cx: float,
    cy: float,
    scale: float,
    color=WHITE,
) -> None:
    """Broadcast-style mark: center disc + stem + concentric wave arcs."""
    r0 = 28 * scale
    draw.ellipse([cx - r0, cy - r0, cx + r0, cy + r0], fill=color)

    stem_w = 14 * scale
    stem_h = 70 * scale
    draw.rounded_rectangle(
        [cx - stem_w / 2, cy + r0 * 0.4, cx + stem_w / 2, cy + r0 + stem_h],
        radius=stem_w / 2,
        fill=color,
    )

    base_w = 70 * scale
    base_h = 16 * scale
    by = cy + r0 + stem_h - base_h / 2
    draw.rounded_rectangle(
        [cx - base_w / 2, by, cx + base_w / 2, by + base_h],
        radius=base_h / 2,
        fill=color,
    )

    for i, radius in enumerate([90, 140, 190]):
        r = radius * scale
        width = max(10, int(14 * scale - i * 1.5 * scale))
        bbox = [cx - r, cy - r, cx + r, cy + r]
        draw.arc(bbox, start=300, end=60, fill=color, width=width)
        draw.arc(bbox, start=120, end=240, fill=color, width=width)


size = 1024
icon = Image.new("RGBA", (size, size), TEAL)
draw = ImageDraw.Draw(icon)
margin = 48
draw.ellipse(
    [margin, margin, size - margin, size - margin],
    fill=TEAL_DARK,
)
draw.ellipse(
    [margin + 36, margin + 36, size - margin - 36, size - margin - 36],
    fill=TEAL,
)
draw_radio_mark(draw, size / 2, size / 2 - 20, scale=1.55)
icon_path = out / "app_icon.png"
icon.save(icon_path, "PNG")

fg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
fg_draw = ImageDraw.Draw(fg)
draw_radio_mark(fg_draw, size / 2, size / 2 - 10, scale=1.35, color=WHITE)
fg_path = out / "app_icon_foreground.png"
fg.save(fg_path, "PNG")

print("wrote", icon_path)
print("wrote", fg_path)

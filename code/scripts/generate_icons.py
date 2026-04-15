#!/usr/bin/env python3
"""
Generate minimalist app icon for MarkText Plus.
Design: A rounded-corner square with a gradient blue-to-teal background,
featuring a clean white "M" letterform composed of simple geometric strokes,
with a small cursor/caret accent.
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os
import struct
import math

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)


def draw_rounded_rect(draw, xy, radius, fill):
    """Draw a rounded rectangle."""
    x0, y0, x1, y1 = xy
    # Four corners
    draw.pieslice([x0, y0, x0 + 2*radius, y0 + 2*radius], 180, 270, fill=fill)
    draw.pieslice([x1 - 2*radius, y0, x1, y0 + 2*radius], 270, 360, fill=fill)
    draw.pieslice([x0, y1 - 2*radius, x0 + 2*radius, y1], 90, 180, fill=fill)
    draw.pieslice([x1 - 2*radius, y1 - 2*radius, x1, y1], 0, 90, fill=fill)
    # Rectangles to fill
    draw.rectangle([x0 + radius, y0, x1 - radius, y1], fill=fill)
    draw.rectangle([x0, y0 + radius, x1, y1 - radius], fill=fill)


def create_gradient(size, color1, color2, direction='diagonal'):
    """Create a gradient image."""
    img = Image.new('RGBA', (size, size))
    for y in range(size):
        for x in range(size):
            if direction == 'diagonal':
                t = (x + y) / (2 * size - 2)
            else:
                t = y / (size - 1)
            r = int(color1[0] + (color2[0] - color1[0]) * t)
            g = int(color1[1] + (color2[1] - color1[1]) * t)
            b = int(color1[2] + (color2[2] - color1[2]) * t)
            a = int(color1[3] + (color2[3] - color1[3]) * t) if len(color1) > 3 else 255
            img.putpixel((x, y), (r, g, b, a))
    return img


def generate_icon(size):
    """Generate the icon at a given size."""
    # Create transparent base
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Padding and corner radius
    pad = int(size * 0.04)
    radius = int(size * 0.18)

    # Background: gradient from blue to teal
    # First draw the shape as mask
    bg = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    bg_draw = ImageDraw.Draw(bg)
    draw_rounded_rect(bg_draw, (pad, pad, size - pad, size - pad), radius, (255, 255, 255, 255))

    # Create gradient
    color_top_left = (66, 133, 244)      # Google Blue
    color_bottom_right = (29, 185, 165)   # Teal
    gradient = create_gradient(size, color_top_left, color_bottom_right, 'diagonal')

    # Apply mask
    bg_gradient = Image.composite(gradient, Image.new('RGBA', (size, size), (0, 0, 0, 0)), bg)
    img = Image.alpha_composite(img, bg_gradient)
    draw = ImageDraw.Draw(img)

    # Draw the "M" mark — clean geometric style
    # The M is drawn as connected strokes
    white = (255, 255, 255, 255)
    stroke_w = max(int(size * 0.07), 2)

    # M position
    mx = size * 0.24   # left x
    my = size * 0.28   # top y
    mw = size * 0.52   # width
    mh = size * 0.44   # height

    # Five points of M: bottom-left, top-left, middle-bottom, top-right, bottom-right
    p1 = (mx, my + mh)              # bottom-left
    p2 = (mx, my)                   # top-left
    p3 = (mx + mw/2, my + mh*0.55) # middle-bottom (valley)
    p4 = (mx + mw, my)              # top-right
    p5 = (mx + mw, my + mh)         # bottom-right

    points = [p1, p2, p3, p4, p5]

    # Draw thick lines for M
    for i in range(len(points) - 1):
        draw.line([points[i], points[i+1]], fill=white, width=stroke_w)

    # Round the joints and endpoints with circles
    cap_r = stroke_w // 2
    for p in points:
        draw.ellipse([p[0]-cap_r, p[1]-cap_r, p[0]+cap_r, p[1]+cap_r], fill=white)

    # Small cursor/caret accent at bottom right
    cursor_x = mx + mw * 0.78
    cursor_y = my + mh + size * 0.06
    cursor_h = size * 0.1
    cursor_w = max(int(size * 0.025), 1)
    draw.rectangle([cursor_x - cursor_w//2, cursor_y,
                     cursor_x + cursor_w//2, cursor_y + cursor_h],
                    fill=(255, 255, 255, 200))

    return img


def create_ico(images, output_path):
    """Create a .ico file from a list of PIL Images."""
    # ICO format: header + directory entries + image data (PNG encoded)
    num_images = len(images)

    # Prepare PNG data for each image
    png_data_list = []
    for img in images:
        import io
        buf = io.BytesIO()
        img.save(buf, format='PNG')
        png_data_list.append(buf.getvalue())

    # ICO header: 3 x uint16 (reserved=0, type=1 for ICO, count)
    header = struct.pack('<HHH', 0, 1, num_images)

    # Calculate offsets
    dir_entry_size = 16
    data_offset = 6 + dir_entry_size * num_images

    directory = b''
    all_data = b''
    current_offset = data_offset

    for i, img in enumerate(images):
        w = img.width if img.width < 256 else 0
        h = img.height if img.height < 256 else 0
        png_data = png_data_list[i]
        data_size = len(png_data)

        # Directory entry
        entry = struct.pack('<BBBBHHII',
                            w,             # width (0 means 256)
                            h,             # height (0 means 256)
                            0,             # color palette
                            0,             # reserved
                            1,             # color planes
                            32,            # bits per pixel
                            data_size,     # image data size
                            current_offset # offset to image data
                            )
        directory += entry
        all_data += png_data
        current_offset += data_size

    with open(output_path, 'wb') as f:
        f.write(header + directory + all_data)


def main():
    print("Generating MarkText Plus minimalist icon...")

    # Generate base icon at 1024x1024
    icon_1024 = generate_icon(1024)

    # --- macOS ---
    macos_dir = os.path.join(PROJECT_DIR, 'macos', 'Runner', 'Assets.xcassets',
                              'AppIcon.appiconset')
    os.makedirs(macos_dir, exist_ok=True)

    macos_sizes = [16, 32, 64, 128, 256, 512, 1024]
    for s in macos_sizes:
        resized = icon_1024.resize((s, s), Image.LANCZOS)
        resized.save(os.path.join(macos_dir, f'app_icon_{s}.png'))
        print(f"  macOS: app_icon_{s}.png")

    # --- Windows ---
    win_dir = os.path.join(PROJECT_DIR, 'windows', 'runner', 'resources')
    os.makedirs(win_dir, exist_ok=True)

    ico_sizes = [16, 32, 48, 64, 128, 256]
    ico_images = [icon_1024.resize((s, s), Image.LANCZOS) for s in ico_sizes]
    ico_path = os.path.join(win_dir, 'app_icon.ico')
    create_ico(ico_images, ico_path)
    print(f"  Windows: app_icon.ico ({ico_sizes})")

    # --- Linux ---
    linux_dir = os.path.join(PROJECT_DIR, 'linux', 'resources')
    os.makedirs(linux_dir, exist_ok=True)

    linux_sizes = [48, 64, 128, 256, 512]
    for s in linux_sizes:
        resized = icon_1024.resize((s, s), Image.LANCZOS)
        resized.save(os.path.join(linux_dir, f'app_icon_{s}.png'))
        print(f"  Linux: app_icon_{s}.png")

    # Also save a reference 512x512 PNG
    icon_512 = icon_1024.resize((512, 512), Image.LANCZOS)
    icon_512.save(os.path.join(linux_dir, 'app_icon.png'))
    print(f"  Linux: app_icon.png (512x512)")

    # Web / Flutter assets
    assets_dir = os.path.join(PROJECT_DIR, 'assets')
    os.makedirs(assets_dir, exist_ok=True)
    icon_1024.save(os.path.join(assets_dir, 'app_icon.png'))
    print(f"  Assets: app_icon.png (1024x1024)")

    print("\nDone! Icon generated for all platforms.")


if __name__ == '__main__':
    main()

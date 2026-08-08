#!/usr/bin/env python3
"""
image_to_epd4c.py

Convert an image into three separate 1-bit-per-pixel C byte arrays
(black, red, yellow) suitable for GxEPD2 4-color e-paper displays
(e.g. GDEM0154F51H 1.54" BWRY panel).

Usage:
    pip install pillow
    python image_to_epd4c.py input.jpg -o imagemap.h -w 200 -H 200

Output:
    A .h file defining:
        const unsigned char epd_bitmap_black[]  PROGMEM = {...};
        const unsigned char epd_bitmap_red[]    PROGMEM = {...};
        const unsigned char epd_bitmap_yellow[] PROGMEM = {...};

    Each array is packed MSB-first, one bit per pixel, rows padded to
    a byte boundary — the format Adafruit_GFX / GxEPD2 drawBitmap()
    expects. A set bit means "draw this ink color" at that pixel.
"""

import argparse
from PIL import Image

# Target 4-color palette (order doesn't matter for quantize, we map by RGB after)
PALETTE = {
    "white":  (255, 255, 255),
    "black":  (10, 10, 10),
    "red":    (255, 30, 0),
    "yellow": (255, 255, 20),
}


def quantize_to_palette(img: Image.Image) -> Image.Image:
    """Quantize an RGB image to the fixed 4-color palette with dithering."""
    # Build a palette image Pillow can quantize against
    pal_img = Image.new("P", (1, 1))
    flat_palette = []
    for color in PALETTE.values():
        flat_palette.extend(color)
    # Pillow palettes need 256 entries (768 values); pad with the last color
    while len(flat_palette) < 768:
        flat_palette.extend(PALETTE["white"])
    pal_img.putpalette(flat_palette)

    rgb = img.convert("RGB")
    quantized = rgb.quantize(palette=pal_img, dither=Image.FLOYDSTEINBERG)
    return quantized.convert("RGB")


def pack_mask_to_bytes(mask: Image.Image) -> bytes:
    """Pack a 1-bit-per-pixel mask (mode '1') into MSB-first bytes, row-padded."""
    w, h = mask.size
    bytes_per_row = (w + 7) // 8
    out = bytearray(bytes_per_row * h)
    px = mask.load()

    for y in range(h):
        for x in range(w):
            if px[x, y]:  # non-zero == set
                byte_index = y * bytes_per_row + (x // 8)
                bit_index = 7 - (x % 8)
                out[byte_index] |= (1 << bit_index)
    return bytes(out)


def make_color_mask(quantized_rgb: Image.Image, target_rgb: tuple) -> Image.Image:
    """Return a mode '1' image: pixel set where quantized image == target_rgb."""
    w, h = quantized_rgb.size
    mask = Image.new("1", (w, h), 0)
    src = quantized_rgb.load()
    dst = mask.load()
    for y in range(h):
        for x in range(w):
            if src[x, y] == target_rgb:
                dst[x, y] = 1
    return mask


def format_c_array(name: str, data: bytes, width: int, height: int) -> str:
    lines = [f"// {name}: {width}x{height}px, {len(data)} bytes"]
    lines.append(f"const unsigned char {name}[] PROGMEM = {{")
    for i in range(0, len(data), 16):
        chunk = data[i:i + 16]
        row = ", ".join(f"0x{b:02X}" for b in chunk)
        lines.append(f"  {row},")
    lines.append("};")
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("input", help="Path to source image")
    ap.add_argument("-o", "--output", default="imagemap.h", help="Output header file")
    ap.add_argument("-w", "--width", type=int, default=200, help="Target width in px")
    ap.add_argument("-H", "--height", type=int, default=200, help="Target height in px")
    ap.add_argument("--fit", choices=["stretch", "cover"], default="cover",
                     help="How to resize source image to target dims")
    args = ap.parse_args()

    img = Image.open(args.input).convert("RGB")

    if args.fit == "stretch":
        img = img.resize((args.width, args.height), Image.LANCZOS)
    else:  # cover: resize+crop to fill target, preserving aspect ratio
        src_ratio = img.width / img.height
        dst_ratio = args.width / args.height
        if src_ratio > dst_ratio:
            new_h = args.height
            new_w = int(new_h * src_ratio)
        else:
            new_w = args.width
            new_h = int(new_w / src_ratio)
        img = img.resize((new_w, new_h), Image.LANCZOS)
        left = (new_w - args.width) // 2
        top = (new_h - args.height) // 2
        img = img.crop((left, top, left + args.width, top + args.height))

    quantized = quantize_to_palette(img)

    black_mask = make_color_mask(quantized, PALETTE["black"])
    red_mask = make_color_mask(quantized, PALETTE["red"])
    yellow_mask = make_color_mask(quantized, PALETTE["yellow"])

    black_bytes = pack_mask_to_bytes(black_mask)
    red_bytes = pack_mask_to_bytes(red_mask)
    yellow_bytes = pack_mask_to_bytes(yellow_mask)

    header = []
    header.append("#pragma once")
    header.append("#include <Arduino.h>")
    header.append("")
    header.append(format_c_array("epd_bitmap_black", black_bytes, args.width, args.height))
    header.append("")
    header.append(format_c_array("epd_bitmap_red", red_bytes, args.width, args.height))
    header.append("")
    header.append(format_c_array("epd_bitmap_yellow", yellow_bytes, args.width, args.height))
    header.append("")

    with open(args.output, "w") as f:
        f.write("\n".join(header))

    print(f"Wrote {args.output}")
    print(f"  black:  {len(black_bytes)} bytes")
    print(f"  red:    {len(red_bytes)} bytes")
    print(f"  yellow: {len(yellow_bytes)} bytes")

    # Optional: save a preview PNG of what will actually be printed
    preview_path = args.output.rsplit(".", 1)[0] + "_preview.png"
    quantized.save(preview_path)
    print(f"  preview: {preview_path}")


if __name__ == "__main__":
    main()

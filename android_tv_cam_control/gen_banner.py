import zlib
import struct
import os

def create_png(width, height, path):
    # RGBA image
    raw_data = bytearray()
    for y in range(height):
        raw_data.append(0)  # Filter type 0 (None)
        # Gradient background from dark slate (15, 23, 42) to dark blue/cyan (14, 116, 144)
        t = (y / height)
        r = int(15 + (14 - 15) * t)
        g = int(23 + (116 - 23) * t)
        b = int(42 + (144 - 42) * t)
        
        for x in range(width):
            tx = x / width
            # Border
            if x < 4 or x >= width - 4 or y < 4 or y >= height - 4:
                raw_data.extend([56, 189, 248, 255]) # Cyan border
            elif 40 <= y <= 75 and 40 <= x <= 140:
                # Icon box (cyan/blue accent)
                raw_data.extend([14, 165, 233, 255])
            else:
                # Smooth background gradient with slight horizontal accent
                cr = min(255, int(r + tx * 30))
                cg = min(255, int(g + tx * 40))
                cb = min(255, int(b + tx * 60))
                raw_data.extend([cr, cg, cb, 255])

    compressed = zlib.compress(bytes(raw_data))

    def make_chunk(chunk_type, data):
        length = len(data)
        crc = zlib.crc32(chunk_type + data) & 0xffffffff
        return struct.pack('>I', length) + chunk_type + data + struct.pack('>I', crc)

    png = bytearray(b'\x89PNG\r\n\x1a\n')
    # IHDR: width, height, 8 bit depth, color type 6 (RGBA), compression 0, filter 0, interlace 0
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    png.extend(make_chunk(b'IHDR', ihdr_data))
    png.extend(make_chunk(b'IDAT', compressed))
    png.extend(make_chunk(b'IEND', b''))

    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as f:
        f.write(png)
    print(f"Wrote banner: {path} ({len(png)} bytes)")

create_png(320, 180, 'android/app/src/main/res/drawable/tv_banner.png')
create_png(320, 180, 'android/app/src/main/res/drawable-xhdpi/tv_banner.png')

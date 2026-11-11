from PIL import Image, ImageDraw, ImageFont
import math
W, H = 720, 840
cx, cy = 360, 410
R = 340
verts = [(cx + R*math.cos(math.radians(d)), cy - R*math.sin(math.radians(d))) for d in [90,150,210,270,330,30]]
mask = Image.new("L", (W, H), 0)
ImageDraw.Draw(mask).polygon(verts, fill=255)
interior = Image.new("RGB", (W, H), (15,76,107))
mp = Image.open("/home/hatch/workspace/windsoropendata-build/ward_map.png").convert("RGB")
mp = mp.resize((520, 520), Image.LANCZOS)
interior.paste(mp, (100, 20))
d = ImageDraw.Draw(interior)
d.rectangle([100, 540, 620, 700], fill=(15,76,107))
font_big = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 56)
font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 46)
for txt, font, y in [("windsor", font_big, 545), ("opendata", font_small, 605)]:
    bbox = d.textbbox((0,0), txt, font=font)
    tw = bbox[2]-bbox[0]
    d.text(((W-tw)/2, y), txt, font=font, fill=(255,255,255))
canvas = Image.new("RGBA", (W, H), (0,0,0,0))
canvas.paste(interior, (0,0), mask)
draw = ImageDraw.Draw(canvas)
draw.polygon(verts, outline=(255,255,255,255), width=12)
verts2 = [(cx + (R-18)*math.cos(math.radians(dg)), cy - (R-18)*math.sin(math.radians(dg))) for dg in [90,150,210,270,330,30]]
draw.polygon(verts2, outline=(242,183,5,255), width=3)
canvas.save("/home/hatch/workspace/windsoropendata/man/figures/logo.png")
print("saved")

from pathlib import Path
p = Path(r"d:\ECHAPP\frontend\lib\presentation\screens\auth\auth_selection_screen.dart")
s = p.read_text().splitlines()
for ln in range(330, 352):
    print(f"{ln+1:4}: {s[ln]}")
print('\n---\n')
for ln in range(432, 440):
    print(f"{ln+1:4}: {s[ln]}")

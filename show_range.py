from pathlib import Path
p = Path(r"d:\ECHAPP\frontend\lib\presentation\screens\auth\auth_selection_screen.dart")
s = p.read_text().splitlines()
for ln in range(316,348):
    print(f"{ln+1:4}: {s[ln]}")

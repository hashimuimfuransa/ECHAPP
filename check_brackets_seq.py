from pathlib import Path
p = Path(r"d:\ECHAPP\frontend\lib\presentation\screens\auth\auth_selection_screen.dart")
s = p.read_text()
start = 10465-1
end = 16591
seg = s[start:end]
br = ''.join(ch for ch in seg if ch in '()[]{}')
print(br)
print('\nlen', len(br))

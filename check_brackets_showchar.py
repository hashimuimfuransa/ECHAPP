from pathlib import Path
p = Path(r"d:\ECHAPP\frontend\lib\presentation\screens\auth\auth_selection_screen.dart")
s = p.read_text()
pos_close = 16591
idx = pos_close-1
print('char at pos', pos_close, 'is', repr(s[idx]))
start = max(0, idx-20)
end = min(len(s), idx+20)
segment = s[start:end]
print(segment)
print('\n' + ' '*(idx-start) + '^')

from pathlib import Path
p = Path(r"d:\ECHAPP\frontend\lib\presentation\screens\auth\auth_selection_screen.dart")
s = p.read_text()
# index positions found earlier
pos_open = 10465
pos_close = 16591
# convert 1-based positions returned by previous script to 0-based index
open_idx = pos_open-1
close_idx = pos_close-1
# compute line/col
line_open = s.count('\n',0,open_idx) + 1
col_open = open_idx - (s.rfind('\n',0,open_idx))
line_close = s.count('\n',0,close_idx) + 1
col_close = close_idx - (s.rfind('\n',0,close_idx))
print('open at pos', pos_open, 'line', line_open, 'col', col_open)
print('close at pos', pos_close, 'line', line_close, 'col', col_close)
print('\n---context around open---')
start = max(0, open_idx-80)
end = min(len(s), open_idx+80)
print(s[start:end])
print('\n---context around close---')
start = max(0, close_idx-80)
end = min(len(s), close_idx+80)
print(s[start:end])

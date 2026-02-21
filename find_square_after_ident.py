import re
from pathlib import Path
p=Path(r'd:\ECHAPP\frontend\lib\presentation\screens\auth\auth_selection_screen.dart')
s=p.read_text()
for m in re.finditer(r"\b([A-Za-z_][A-Za-z0-9_]*)\[", s):
    idx=m.start()
    line = s.count('\n',0,idx)+1
    print(f"{line}: {m.group(1)}[")

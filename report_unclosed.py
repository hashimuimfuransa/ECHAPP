from pathlib import Path
p=Path(r'd:\ECHAPP\frontend\lib\presentation\screens\auth\auth_selection_screen.dart')
s=p.read_text()
unclosed=[(6284,'{'),(8752,'{'),(9649,'{'),(9739,'('),(9763,'('),(9795,'('),(9828,'{'),(9915,'('),(9941,'['),(10465,'(')]
for pos,ch in unclosed:
    idx=pos-1
    line = s.count('\n',0,idx)+1
    col = idx - s.rfind('\n',0,idx)
    start=max(0,idx-40)
    end=min(len(s),idx+40)
    print(f"pos {pos} char {ch} -> line {line} col {col}\n{s[start:end]}\n---\n")

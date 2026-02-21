import sys
from pathlib import Path
p = Path(r"d:\ECHAPP\frontend\lib\presentation\screens\auth\auth_selection_screen.dart")
s = p.read_text()
pairs = {'(':')','[':']','{':'}'}
openers = set(pairs.keys())
closers = set(pairs.values())
stack = []
for i,ch in enumerate(s, start=1):
    if ch in openers:
        stack.append((ch,i))
    elif ch in closers:
        if not stack:
            print(f"Unmatched closer {ch} at pos {i}")
            sys.exit(1)
        last, pos = stack.pop()
        if pairs[last]!=ch:
            print(f"Mismatched {last} at {pos} with {ch} at {i}")
            sys.exit(1)
if stack:
    for ch,pos in stack:
        print(f"Unclosed {ch} at pos {pos}")
    sys.exit(1)
print('All brackets matched')

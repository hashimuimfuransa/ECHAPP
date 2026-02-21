from pathlib import Path
p = Path(r"d:\ECHAPP\frontend\lib\presentation\screens\auth\auth_selection_screen.dart")
s = p.read_text()
pairs = {'(':')','[':']','{':'}'}
openers = set(pairs.keys())
closers = set(pairs.values())
stack = []
start = 10465-5
end = 16591+5
for i,ch in enumerate(s[start:end], start=start+1):
    if ch in openers:
        stack.append((ch,i))
    elif ch in closers:
        if not stack:
            print(f"Unmatched closer {ch} at pos {i}")
            break
        last,pos = stack[-1]
        if pairs[last]==ch:
            stack.pop()
        else:
            print(f"At pos {i} char {ch} found but top is {last} at pos {pos}")
            print('Stack top 10:', stack[-10:])
            # print context
            context_start = max(0, i-60)
            context_end = min(len(s), i+60)
            print('\nContext around mismatch:\n', s[context_start:context_end])
            break
else:
    print('No mismatch in range')
print('\nFinal top of stack (last 10):', stack[-10:])

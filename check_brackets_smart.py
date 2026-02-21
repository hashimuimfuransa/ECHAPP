from pathlib import Path
p = Path(r"d:\ECHAPP\frontend\lib\presentation\screens\auth\auth_selection_screen.dart")
s = p.read_text()
pairs = {'(':')','[':']','{':'}'}
openers = set(pairs.keys())
closers = set(pairs.values())
stack = []

i = 0
L = len(s)
state = 'code'
str_quote = None
while i < L:
    ch = s[i]
    # handle line comments
    if state == 'code' and s.startswith('//', i):
        # skip to end of line
        j = s.find('\n', i)
        if j == -1:
            break
        i = j + 1
        continue
    # block comments
    if state == 'code' and s.startswith('/*', i):
        j = s.find('*/', i+2)
        if j == -1:
            print('Unclosed block comment at', i+1)
            break
        i = j+2
        continue
    # string start
    if state == 'code' and s[i] in ('"', "'"):
        # check for triple quotes
        if s.startswith(s[i]*3, i):
            str_quote = s[i]*3
            i += 3
            state = 'string'
            continue
        else:
            str_quote = s[i]
            state = 'string'
            i += 1
            continue
    if state == 'string':
        if s.startswith(str_quote, i):
            i += len(str_quote)
            state = 'code'
            continue
        # escape sequences
        if s[i] == '\\':
            i += 2
            continue
        i += 1
        continue
    # raw strings r'...' or r"..." not handled specially but treat as starting with r then quote
    # now in code
    if ch in openers:
        stack.append((ch, i+1))
    elif ch in closers:
        if not stack:
            print(f"Unmatched closer {ch} at pos {i+1}")
            break
        last,pos = stack[-1]
        if pairs[last]==ch:
            stack.pop()
        else:
            print(f"Mismatch at pos {i+1}: found {ch} but top is {last} at {pos}")
            # print context
            start = max(0, i-60)
            end = min(L, i+60)
            print('\nContext:\n' + s[start:end])
            break
    i += 1
else:
    print('No mismatches')

if stack:
    print('Unclosed opens (last 10):', stack[-10:])
else:
    print('All good')

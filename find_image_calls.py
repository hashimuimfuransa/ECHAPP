import os, re

root = 'frontend/lib'
patterns = [r'Image\.network\(', r'NetworkImage\(', r'CachedNetworkImage\(']
for dirpath, dirs, files in os.walk(root):
    # Skip build dirs
    dirs[:] = [d for d in dirs if d not in ('build', '.dart_tool')]
    for f in files:
        if not f.endswith('.dart'):
            continue
        p = os.path.join(dirpath, f)
        s = open(p, encoding='utf-8', errors='ignore').read()
        for pat in patterns:
            for m in re.finditer(pat, s):
                start = max(0, m.start() - 60)
                end = min(len(s), m.end() + 100)
                ctx = s[start:end].replace('\n', ' ')
                print(f'{p}: {pat} :: ...{ctx}...')

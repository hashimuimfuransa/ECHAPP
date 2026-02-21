from pathlib import Path
p=Path(r'd:\ECHAPP\frontend\lib\presentation\screens\auth\auth_selection_screen.dart')
s=p.read_text()
start=10465
end=16591
for i in range(start, end+1):
    if s[i-1]==')':
        line=s.count('\n',0,i-1)+1
        col=i- s.rfind('\n',0,i-1)
        print(') at pos',i,'line',line,'col',col)
print('done')

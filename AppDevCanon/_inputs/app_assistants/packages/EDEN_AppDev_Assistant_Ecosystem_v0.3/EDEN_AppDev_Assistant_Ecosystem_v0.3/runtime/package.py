from pathlib import Path
import zipfile
R=Path(__file__).resolve().parents[1]; out=R.parent/(R.name+'.zip')
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
 for p in R.rglob('*'):
  if p.is_file() and 'data' not in p.relative_to(R).parts: z.write(p,p.relative_to(R.parent))
print(out)

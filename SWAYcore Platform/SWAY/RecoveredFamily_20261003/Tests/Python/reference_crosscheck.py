"""Independent Python re-implementation of key Core numerics, run against the SAME scenarios the Swift tests assert.
This is corroborating evidence about the algorithm design only. It does NOT prove the Swift code compiles or passes."""
import math, unittest

def V(x,y,z=0): return (x,y,z)
def sub(a,b): return tuple(i-j for i,j in zip(a,b))
def add(a,b): return tuple(i+j for i,j in zip(a,b))
def mul(a,s): return tuple(i*s for i in a)
def ln(a): return math.sqrt(sum(i*i for i in a))
def nrm(a):
    l=ln(a); return mul(a,1/l) if l>1e-12 else (0,0,0)
def dot(a,b): return sum(i*j for i,j in zip(a,b))

def direction(abd,fwd,side):
    a,f=math.radians(abd),math.radians(fwd); v=(side*math.sin(a),-math.cos(a),0)
    return nrm((v[0],v[1]*math.cos(f),-v[1]*math.sin(f)))
ARM=dict(down=((8,0),(6,0)),side=((90,0),(90,0)),high=((160,0),(170,0)))
LEG=dict(stand=((2,0),(1,0)),wide=((22,0),(18,0)))
def build(armL,armR,legL,legR):
    p={}; p['hips']=V(0,0); p['neck']=V(0,1); 
    for side,s,arm,leg in ((1,'L',armL,legL),(-1,'R',armR,legR)):
        sh=V(side*0.38,0.92); (u,l)=ARM[arm]
        el=add(sh,mul(direction(*u,side),0.55)); wr=add(el,mul(direction(*l,side),0.5))
        hp=V(side*0.15,0); (u2,l2)=LEG[leg]
        kn=add(hp,mul(direction(*u2,side),0.9)); an=add(kn,mul(direction(*l2,side),0.85))
        p['shoulder'+s]=sh;p['elbow'+s]=el;p['wrist'+s]=wr;p['hip'+s]=hp;p['knee'+s]=kn;p['ankle'+s]=an
    return p
SEGS=[('hips','neck'),('shoulderL','elbowL'),('elbowL','wristL'),('shoulderR','elbowR'),('elbowR','wristR'),
      ('hipL','kneeL'),('kneeL','ankleL'),('hipR','kneeR'),('kneeR','ankleR')]
def to_raw(p,scale=0.18,origin=(0.5,0.55)): return {k:(origin[0]+v[0]*scale,origin[1]+v[1]*scale) for k,v in p.items()}
def match(exp,raw):
    c=raw['hips']; t=ln(sub(raw['neck'],c)+(0,))[0] if False else math.hypot(raw['neck'][0]-c[0],raw['neck'][1]-c[1])
    obs={k:((v[0]-c[0])/t,(v[1]-c[1])/t) for k,v in raw.items()}; errs=[]
    for a,b in SEGS:
        e=(exp[b][0]-exp[a][0],exp[b][1]-exp[a][1]); full=ln(sub(exp[b],exp[a]))
        o=(obs[b][0]-obs[a][0],obs[b][1]-obs[a][1])
        if math.hypot(*e)/full<0.25: continue
        cs=max(-1,min(1,(e[0]*o[0]+e[1]*o[1])/(math.hypot(*e)*math.hypot(*o)))); errs.append(math.degrees(math.acos(cs)))
    return sum(errs)/len(errs), len(errs)

def analyze(onsets,lo=70,hi=180):
    o=sorted(onsets); best=(0,0,-1); bpm=lo
    while bpm<=hi:
        per=60/bpm; sx=sy=0
        for t in o: a=2*math.pi*(t%per)/per; sx+=math.cos(a); sy+=math.sin(a)
        r=math.hypot(sx,sy)/len(o)
        if r>best[2]:
            ma=math.atan2(sy,sx); ma+=2*math.pi if ma<0 else 0; best=(bpm,ma/(2*math.pi)*per,r)
        bpm+=0.5
    return best

class T(unittest.TestCase):
    def test_wave_match_and_wrong(self):
        wave=build('side','high','wide','wide'); self.assertLess(match(wave,to_raw(wave))[0],1e-6)
        wrong=build('down','down','stand','stand'); m,n=match(wave,to_raw(wrong)); self.assertGreater(m,35); print("wrong-pose mean error %.1f over %d segs"%(m,n))
    def test_frame_bounds_for_calibration_layout(self):
        p=build('high','high','wide','wide'); raw=to_raw(p)
        for k,(x,y) in raw.items(): self.assertTrue(0.02<x<0.98 and 0.02<y<0.98,(k,x,y))
    def test_neutral_torso_unit(self): self.assertAlmostEqual(ln(sub(build('down','down','stand','stand')['neck'],(0,0,0))),1.0)
    def test_beat_analyzer_clean(self):
        b=analyze([0.13+i*0.5 for i in range(64)]); self.assertAlmostEqual(b[0],120,delta=1); self.assertAlmostEqual(b[1]%0.5,0.13,delta=0.02); self.assertGreater(b[2],0.9)
    def test_beat_analyzer_random_rejected_by_threshold(self):
        s=42; t=0.0; o=[]
        for _ in range(40):
            s=(s*6364136223846793005+1442695040888963407)%(1<<64); t+=0.2+(s>>40)/(1<<24)*0.7; o.append(t)
        b=analyze(o); print("random onsets best r=%.3f (threshold 0.6)"%b[2]); self.assertLessEqual(b[2],0.6)
    def test_wave_oscillation_reversal_logic(self):
        offs=[-0.08,-0.04,0,0.04,0.08,0.04,0,-0.04]; xs=[offs[i%8] for i in range(40)]
        cnt=0;d=0;a=xs[0]
        for x in xs[1:]:
            dd=x-a
            if abs(dd)<0.04-1e-9: continue
            nd=1 if dd>0 else -1
            if d and nd!=d: cnt+=1
            d=nd;a=x
        self.assertGreaterEqual(cnt,2); self.assertGreater(max(xs)-min(xs),0.12)
if __name__=="__main__": unittest.main(verbosity=1)

"""Line-faithful Python MIRROR of Packages/SWAYcoreEngine (calibration machine, match truth, timeline math, pose mapper).
Purpose: execute the same scenarios as the Swift XCTest suite in an environment WITHOUT a Swift toolchain, as corroborating
evidence of the algorithms. It does NOT prove the Swift compiles or passes. Keep in lockstep with the Swift sources."""
from dataclasses import dataclass, field
from typing import Optional, List, Dict

TITLES = ["STEP INTO VIEW", "WAVE LEFT", "WAVE RIGHT", "LIFT LEFT FOOT", "LIFT RIGHT FOOT", "JUMP", "READY TO SWAY"]
FRAME, WAVE_L, WAVE_R, LIFT_L, LIFT_R, JUMP, READY = range(7)

@dataclass
class Pt: x: float; y: float
@dataclass
class Frame:
    t: float; body: bool; ready: bool; root: Optional[Pt]=None
    lw: Optional[Pt]=None; rw: Optional[Pt]=None; la: Optional[Pt]=None; ra: Optional[Pt]=None

class Cfg:
    framed_stable=6; wave_total=0.32; foot_lift=0.055; foot_stable=4; jump_rise=0.045; jump_stable=2
    deadband=0.004; decay=0.995; timeout=60; base_min=5; base_step=0.0007

class Machine:
    def __init__(s, cfg=Cfg): s.cfg=cfg; s.reset()
    def reset(s):
        s.stage=FRAME; s.completed=[]; s.status="STEP INTO VIEW"; s.lost=False; s.timed_out=False; s.cancelled=False; s.low_impact=False
        s.stable=0; s.motion=0.0; s.prev=None; s.hist=[]; s.base=None; s.started=None
    @property
    def is_ready(s): return s.stage==READY
    @property
    def active(s): return not s.is_ready and not s.cancelled
    def cancel(s):
        if not s.active: return []
        s.cancelled=True; s.status="TRACKING OFF"; return ["cancelled"]
    def geometry_changed(s): s._evid(); s.hist=[]; s.base=None
    def continue_after_timeout(s): s.timed_out=False; s.started=None
    def skip_jump(s):
        if s.stage!=JUMP or not s.active: return []
        s.low_impact=True; return s._complete()
    def _evid(s): s.stable=0; s.motion=0.0; s.prev=None
    def ingest(s, f):
        if not s.active: return []
        ev=[]
        if s.started is None: s.started=f.t
        if not s.timed_out and f.t - s.started > s.cfg.timeout: s.timed_out=True; ev.append(("timedOut",s.stage))
        if not f.body:
            if not s.lost: s.lost=True; ev.append("trackingLost")
            s._evid(); s.status="STEP INTO VIEW"; return ev
        if s.lost: s.lost=False; ev.append("trackingRecovered")
        if f.root is not None and f.ready: s._track(f.root.y)
        c=s.cfg
        if s.stage==FRAME:
            if f.ready: s.stable+=1; s.status="HOLD THERE"
            else: s.stable=max(0,s.stable-1); s.status="STEP BACK — SHOW YOUR FEET"
            if s.stable>=c.framed_stable: ev+=s._complete()
        elif s.stage==WAVE_L: ev+=s._wave(f.lw,"LEFT HAND")
        elif s.stage==WAVE_R: ev+=s._wave(f.rw,"RIGHT HAND")
        elif s.stage==LIFT_L: ev+=s._lift(f.la,f.ra,"LEFT FOOT")
        elif s.stage==LIFT_R: ev+=s._lift(f.ra,f.la,"RIGHT FOOT")
        elif s.stage==JUMP:
            if f.root is None or s.base is None: s.status="STEP INTO VIEW"; return ev
            if s.base - f.root.y > c.jump_rise: s.stable+=1; s.status="JUMP DETECTED"
            else: s.stable=max(0,s.stable-1); s.status="JUMP WHEN READY"
            if s.stable>=c.jump_stable: ev+=s._complete()
        return ev
    def _wave(s,w,label):
        if w is None: s.status="SHOW YOUR "+label; s.prev=None; return []
        s.motion*=s.cfg.decay
        if s.prev is not None:
            d=abs(w.x-s.prev.x)+abs(w.y-s.prev.y)
            if d>=s.cfg.deadband: s.motion+=d
        s.prev=w; s.status="WAVE SIDE TO SIDE"
        return s._complete() if s.motion>s.cfg.wave_total else []
    def _lift(s,mv,ot,label):
        if mv is None or ot is None: s.status="SHOW BOTH FEET"; s.stable=0; return []
        if ot.y-mv.y>s.cfg.foot_lift: s.stable+=1; s.status="HOLD IT"
        else: s.stable=max(0,s.stable-1); s.status="LIFT YOUR "+label
        return s._complete() if s.stable>=s.cfg.foot_stable else []
    def _track(s,y):
        if s.base is not None:
            s.base=s.base+max(-s.cfg.base_step,min(s.cfg.base_step,y-s.base)); return
        s.hist.append(y)
        if len(s.hist)>=s.cfg.base_min: srt=sorted(s.hist); s.base=srt[len(srt)//2]
    def _complete(s):
        fin=s.stage; s.completed.append(fin); s._evid(); s.timed_out=False; s.started=None
        ev=[("stageCompleted",fin)]
        if fin+1<=READY:
            s.stage=fin+1
            if s.stage==READY: s.status="READY TO SWAY"; ev.append("ready")
            else: s.status="FOLLOW COACH"
        return ev

# ---- match truth ----
def match_score(ref, obs, timing_err, conf, prev_total, age=None, min_conf=0.30, good=0.72, partial=0.42, max_age=0.35, min_joints=3, min_cov=0.5):
    if not ref: return ("unknown","noReference",0.0)
    if not obs: return ("unknown","noObservation",0.0)
    if age is not None and (age>max_age or age<0): return ("unknown","staleObservation",0.0)
    if not (conf==conf) or conf<min_conf: return ("unknown","lowDetectorConfidence",0.0)
    diffs=[abs(obs[k]-v) for k,v in ref.items() if k in obs]
    cov=len(diffs)/len(ref)
    if len(diffs)<min_joints or cov<min_cov: return ("unknown","insufficientJointCoverage",0.0)
    mean=sum(diffs)/len(diffs); shape=max(0,1-mean/90); timing=max(0,1-abs(timing_err)/0.35)
    cont=1 if prev_total is None else max(0,1-abs(prev_total-shape))
    total=(timing*0.35+shape*0.35+cont*0.30)*conf
    return ("good" if total>=good else ("partial" if total>=partial else "notMatched"), None, total)

# ---- timeline math ----
def first_index_gt(a,t):
    lo,hi=0,len(a)
    while lo<hi:
        mid=(lo+hi)//2
        if a[mid]>t: hi=mid
        else: lo=mid+1
    return lo
def position(t,bpm,beats=None,grid_bpm=None):
    import math
    if beats:
        i=max(0,min(len(beats)-1,first_index_gt(beats,t)-1)); start=beats[i]
        end=beats[i+1] if i+1<len(beats) else start+60.0/max(20.0,grid_bpm or bpm)
        ph=min(max((t-start)/max(0.001,end-start),0),0.999999)
        return dict(beat=i,count=i%8+1,bar=i//4,phrase=i//32,phase=ph)
    spb=60.0/max(20.0,bpm); pos=max(0,t/spb); b=int(math.floor(pos))
    return dict(beat=b,count=b%8+1,bar=b//4,phrase=b//32,phase=pos-math.floor(pos))

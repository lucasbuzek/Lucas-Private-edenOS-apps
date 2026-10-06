"""Deterministic visual evidence sampling; no renderer or approval side effects."""
import math

def direction_error(a,b):
    """Projected direction agreement, independent of native segment lengths."""
    def unit(v):
        length=math.sqrt(sum(x*x for x in v))
        if not math.isfinite(length) or length<1e-8:raise ValueError('degenerate projected direction')
        return tuple(x/length for x in v)
    a,b=unit(a),unit(b)
    return math.degrees(math.acos(max(-1,min(1,sum(x*y for x,y in zip(a,b))))))

def representative_frames(first,last,severity):
    if first>last:raise ValueError('invalid frame range')
    if any(not math.isfinite(v) for v in severity.values()):raise ValueError('nonfinite pose measurement')
    frames={first,last,first+(last-first)//4,first+(last-first)//2,first+3*(last-first)//4}
    eligible={f:v for f,v in severity.items() if first<=f<=last}
    if eligible:frames.add(max(eligible,key=lambda f:(eligible[f],-f)))
    return sorted(frames)

def rotation_distance(a,b):
    def normalized(q):
        n=math.sqrt(sum(x*x for x in q))
        if not math.isfinite(n) or n<1e-12:raise ValueError('invalid rotation')
        return tuple(x/n for x in q)
    a,b=normalized(a),normalized(b)
    return math.degrees(2*math.acos(min(1.0,abs(sum(x*y for x,y in zip(a,b))))))

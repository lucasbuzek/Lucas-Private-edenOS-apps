"""Faithful Python port of the AS-RECEIVED candidate SwayPoseMatcher.score (NativeCapabilities.swift ~1408-1426).
Used ONLY to reproduce a suspected defect before repair. Not a substitute for running the Swift code."""
def score(reference_angles, observed, timing_error, detector_conf, previous_total):
    if detector_conf < 0.30:
        return ("unknown", 0.0)
    pairs = [abs(observed[k] - v) for k, v in reference_angles.items() if k in observed]
    mean = 90 if not pairs else sum(pairs) / len(pairs)
    shape = max(0, 1 - mean / 90)
    timing = max(0, 1 - abs(timing_error) / 0.35)
    continuity = 1 if previous_total is None else max(0, 1 - abs(previous_total - shape))
    total = (timing * 0.35 + shape * 0.35 + continuity * 0.30) * detector_conf
    state = "good" if total >= 0.72 else ("partial" if total >= 0.42 else "unknown")
    return (state, total)

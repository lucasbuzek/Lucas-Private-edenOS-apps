"""Operator-free weight budgets. Preserve native bone names; never fabricate influence coverage."""
import math
EPSILON=1e-4
MAX_INFLUENCES=4

def limit_weights(weights):
    if any(not math.isfinite(w) or w<0 for w in weights.values()):raise ValueError('invalid source skin weight')
    chosen=sorted(((n,w) for n,w in weights.items() if w>0),key=lambda x:(-x[1],x[0]))[:MAX_INFLUENCES]
    total=sum(w for _,w in chosen)
    if not total:raise ValueError('vertex has no source skin weights')
    chosen=[(n,w) for n,w in chosen if w/total>EPSILON]
    total=sum(w for _,w in chosen)
    return {n:w/total for n,w in chosen}

def weight_issues(vertices,allowed,minimum_used=0):
    issues=[];used=set()
    for i,weights in enumerate(vertices):
        if any(not math.isfinite(w) or w<0 for w in weights.values()):
            issues.append(f'vertex {i}: invalid weight');continue
        ws={n:w for n,w in weights.items() if w>EPSILON};used.update(ws)
        if not ws:issues.append(f'vertex {i}: unweighted')
        if len(ws)>MAX_INFLUENCES:issues.append(f'vertex {i}: >4 influences')
        if abs(sum(ws.values())-1)>.02:issues.append(f'vertex {i}: non-normalized')
        if set(ws)-allowed:issues.append(f'vertex {i}: foreign bone groups')
    if len(used & allowed)<minimum_used:issues.append(f'body coverage {len(used & allowed)} < {minimum_used} bones')
    return issues

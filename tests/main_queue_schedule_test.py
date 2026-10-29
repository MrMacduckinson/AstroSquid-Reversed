#!/usr/bin/env python3
"""Compare a gate model to the complete actual PPC Main event trace, not just final text."""
import gzip,itertools,sys
actual=gzip.open(sys.argv[1],"rb").read().decode("ascii").splitlines()
expected=[]
for profile,(seed,focus,interval,step) in enumerate(itertools.product((1000,940,0),range(3),(1,2,3,1000),range(3))):
    state={"reads":0,"frames":0,"queued":0,"stop":False}
    text=[];last_frame=1000;last_service=seed;counter=0
    def record(kind,value):
        expected.append(",".join(str(x) for x in (profile,kind,value,state["reads"],state["frames"],state["queued"])))
    def tick():
        value=1000+state["reads"]*step;state["reads"]+=1
        state["stop"]=state["reads"]>=80
        record("T",value);return value
    def event(kind):
        value=ord("A")+state["queued"]%26;state["queued"]+=1
        record(kind,value)
        if kind=="F":text.append("%02x"%value)
    while True:
        if tick()-last_frame>=interval:
            last_frame=tick();state["frames"]+=1;record("W",0);counter+=1
            if focus:event("F")
        if tick()-last_service>59:
            tick();event("P");last_service=tick();counter=0
        if state["stop"]:break
    expected.append(",".join(str(x) for x in (profile,"Z",state["reads"],state["frames"],state["queued"],last_frame,last_service,counter,"".join(text))))
assert len(actual)==len(expected),(len(actual),len(expected))
for i,(a,b) in enumerate(zip(actual,expected)):
    assert a==b,"record%d: native %s / model %s"%(i,a,b)
print("PASS108 actual PPC Main schedules, %d complete clock/frame/field/periodic/final records"%len(actual))

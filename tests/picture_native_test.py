"""Pure codec replay; no GUI, image rendering or capture on the primary Mac."""
import gzip
import os
import subprocess
import sys
cases=[('one-color',1,3,1),('prefix-byte',62,2,1),('prefix-word',63,2,1),('tiny-black',2,2,0),('tiny-color',2,2,1),('odd-color',9,3,1),('red128',128,2,2),('red129',129,2,2),('full-black',640,480,0),('full-color',640,480,1)]
for name,w,h,pattern in cases:
    path=os.path.join(os.path.dirname(__file__),'picture_native',name+'.pict.gz')
    with gzip.open(path,'rb') as source:
        native=bytearray(source.read())
    # Observed to be the source PixMap's two process-local handles.
    native[98:106]=b'\0'*8
    output=bytearray(subprocess.check_output([sys.argv[1],str(w),str(h),str(pattern)]))
    assert output==native,(name,len(output),len(native),next((i for i in range(min(len(output),len(native))) if output[i]!=native[i]),None))
print('PASS10 original PICT payloads including640x480: all bytes match except canonicalized pmTable/pmExt addresses')

set pagination off
set confirm off
set args /tmp/astrosquid-fullscreen-port-20261028/AstroSquid
set breakpoint pending on
break PBHGetVolSync
run
finish
set $base=$pc-0x6ac
delete 1
break *($base+0x65484)
continue
set $g=(char*)$r14
break *($base+0x65f2c)
continue
set *(short*)($g+0xab6)=1
break *($base+0x66cf0)
continue
disable 3
break *($base+0x4cb28)
continue
set $g=(char*)$r14
set $toc=(void*)$r2
set $lib=(void*)dlopen("/tmp/astrosquid-fullscreen-port-20261028/reference.dylib",2)
set $result=(int)astro_fullscreen_port_reference((void*)$base,$g,$toc)
printf "reference_result=%d\n",$result
quit

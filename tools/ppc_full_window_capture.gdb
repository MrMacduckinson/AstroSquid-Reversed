set pagination off
set confirm off
set args /tmp/astrosquid-full-port-20261028/AstroSquid
set breakpoint pending on
break PBHGetVolSync
run
finish
set $base=$pc-0x6ac
delete 1
break *($base+0x65484)
continue
set $g=(char*)$r14
set *(short*)($g+0xee0)=0
break *($base+0x65f2c)
continue
set *(short*)($g+0xab6)=1
break *($base+0x66cf0)
continue
disable 3
break *($base+0x4cb28)
continue
bt 3
set $g=(char*)$r14
set $toc=(void*)$r2
set $scratch=(char*)malloc(16)
call (void)GetPort($scratch)
set $port=*(char**)$scratch
set $window=*(void**)(*(char**)($g+0x19c)+16)
set $windowport=(void*)GetWindowPort($window)
printf "first_keymap current_port=%p window_port=%p rect=%d,%d,%d,%d debug=%d fullscreen=%d\n",$port,$windowport,*(short*)($port+16),*(short*)($port+18),*(short*)($port+20),*(short*)($port+22),*(short*)($g+0xede),*(short*)($g+0xee0)
call (void)GetForeColor($scratch)
printf "foreground=%u,%u,%u\n",*(unsigned short*)$scratch,*(unsigned short*)($scratch+2),*(unsigned short*)($scratch+4)
call (void)GetBackColor($scratch)
printf "background=%u,%u,%u\n",*(unsigned short*)$scratch,*(unsigned short*)($scratch+2),*(unsigned short*)($scratch+4)
call (void)free($scratch)
set $lib=(void*)dlopen("/tmp/astrosquid-full-port-20261028/capture.dylib",2)
set $result=(int)astro_capture_reference((void*)$base,$g,$toc,$window,"/tmp/astrosquid-full-port-20261028/window.pict")
printf "capture_result=%d\n",$result
quit

set pagination off
set confirm off
set args /tmp/astrosquid-callbacks-20261029/AstroSquid
set breakpoint pending on
break PBHGetVolSync
run
finish
set $base=$pc-0x6ac
delete 1
call (unsigned int)alarm(45)
break *($base+0x65484)
continue
set $g=(char*)$r14
printf "before_game_init menu=%08x end=%08x quit=%08x\n",*(unsigned int*)($g+0x2d4),*(unsigned int*)($g+0x2e0),*(unsigned int*)($g+0x128)
set *(short*)($g+0xee0)=0
break *($base+0x65f2c)
continue
printf "after_assets menu=%08x end=%08x quit=%08x\n",*(unsigned int*)($g+0x2d4),*(unsigned int*)($g+0x2e0),*(unsigned int*)($g+0x128)
set *(short*)($g+0xab6)=1
break *($base+0x66cf0)
continue
disable 3
break *($base+0x4cb28)
continue
printf "main_keymap menu=%08x end=%08x quit=%08x\n",*(unsigned int*)($g+0x2d4),*(unsigned int*)($g+0x2e0),*(unsigned int*)($g+0x128)
quit

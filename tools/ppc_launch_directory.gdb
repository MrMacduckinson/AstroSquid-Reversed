set pagination off
set confirm off
set args /tmp/astrosquid-launch-dir-20261028/AstroSquid
set breakpoint pending on
break PBHGetVolSync
run
set $pb=$r3
bt 4
finish
printf "CarbonWD volume=%d directory=%d\n",*(short*)($pb+22),*(int*)($pb+48)
continue
set $pb=$r3
bt 4
finish
printf "CarbonWD second volume=%d directory=%d\n",*(short*)($pb+22),*(int*)($pb+48)
quit

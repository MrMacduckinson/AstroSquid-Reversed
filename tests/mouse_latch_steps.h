/* H: eligible hover/Button poll; D: DOMOUSE while held; U: release between polls. */
static const struct {char op;short x,y;int down;} mouse_latch_steps[]={
    {'H',400,320,0},{'H',0,100,0},{'D',-1,100,1},
    {'H',400,320,1},{'D',400,320,1},{'U',400,320,0},
    {'D',400,320,1},{'H',400,320,0},{'D',0,100,1},
    {'D',0,100,1},{'D',225,260,1},{'H',0,100,0},
    {'D',225,260,1},{'H',400,320,1},{'D',400,320,1},
    {'H',400,320,0},{'D',400,320,1}
};

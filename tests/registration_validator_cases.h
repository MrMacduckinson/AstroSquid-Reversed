/* Candidate inputs; original oracle independently captures its computed comparison operand. */
static void candidate_registration_code(const unsigned char *name,unsigned length,unsigned char out[8]){
    unsigned first=length?name[0]:0,second=length>1?name[1]:0,third=length>2?name[2]:0,penultimate=length?name[length>1?length-2:0]:0;
    unsigned p=penultimate*42%26,q=second*35%26,r=third*24%26,t=third*11%26;
    unsigned a=(length*128%26+p)%26,b=(q+a)%26,c=(q+b)%26;
    unsigned digits[]={a,(first*13%26+q)%26,(p+r)%26,b,(first*72%26+r)%26,c,(r+t)%26,(t+c)%26};
    for(unsigned i=0;i<8;i++)out[i]='A'+digits[i];
}
static void run_registration_validator_cases(void){
    unsigned char name[256],code[256],expected[8];
    for(unsigned length=0;length<256;length++)for(unsigned pattern=0;pattern<3;pattern++){
        for(unsigned i=0;i<length;i++)name[i]=pattern==0?0:pattern==1?255:(unsigned char)(i*17+length);
        candidate_registration_code(name,length,expected);
        for(unsigned variant=0;variant<8;variant++)for(unsigned prior=0;prior<2;prior++){
            memset(code,0,sizeof(code));memcpy(code,expected,8);unsigned size=8;
            if(variant==0)size=0;
            if(variant==2)for(unsigned i=0;i<8;i++)code[i]+='a'-'A';
            if(variant==3)code[length%8]=code[length%8]=='Z'?'A':code[length%8]+1;
            if(variant==4)size=7;
            if(variant==5){size=9;code[8]='A';}
            if(variant==6)code[length%8]=0;
            if(variant==7)for(unsigned i=0;i<8;i++)code[i]=(unsigned char)(length+i*37);
            registration_validator_case(length,pattern,variant,prior,name,length,code,size,expected);
        }
    }
}

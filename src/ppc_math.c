/*
 * Copyright (c) 2002 Apple Computer, Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * The contents of this file constitute Original Code as defined in and
 * are subject to the Apple Public Source License Version 1.1 (the
 * "License").  You may not use this file except in compliance with the
 * License.  Please obtain a copy of the License at
 * http://www.apple.com/publicsource and read it before using this file.
 * 
 * This Original Code and all software distributed under the License are
 * distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE OR NON-INFRINGEMENT.  Please see the
 * License for the specific language governing rights and limitations
 * under the License.
 * 
 * @APPLE_LICENSE_HEADER_END@
 */
/* Portable adaptation of Apple Libm-47.1 ppc.subproj/FastSinCos.c,
 * asinacos.c and sqrt.c. Explicit fma preserves original PowerPC instructions;
 * surrounding game arithmetic must compile with -ffp-contract=off.
 * Source: https://github.com/apple-oss-distributions/Libm/tree/Libm-47.1/ppc.subproj
 * Default nearest rounding is the game's execution environment. */
#include "ppc_math.h"
#include <math.h>
#include <stdint.h>
#include <string.h>
static const double s13 = 1.5868926979889205164e-10;       // 1.0/13!
static const double s11 = -2.5050225177523807003e-8;       // -1.0/11!
static const double s9 =  2.7557309793219876880e-6;        // 1.0/9!
static const double s7 = -1.9841269816180999116e-4;        // -1.0/7!
static const double s5 =  8.3333333332992771264e-3;        // 1.0/5!
static const double s3 = -0.16666666666666463126;          // 1.0/3!
static const double c14 = -1.138218794258068723867e-11;    // -1.0/14!
static const double c12 = 2.087614008917893178252e-9;      // 1.0/12!
static const double c10 = -2.755731724204127572108e-7;     // -1.0/10!
static const double c8 =  2.480158729870839541888e-5;      // 1.0/8!
static const double c6 = -1.388888888888735934799e-3;      // -1.0/6!
static const double c4 =  4.166666666666666534980e-2;      // 1.0/4!
static const double c2 = -.5;                              // -1.0/2!


static double ppc_nan(unsigned payload){uint64_t u=UINT64_C(0x7ff8000000000000)|payload;double x;memcpy(&x,&u,8);return x;}
static double trig(double x,int cosine){
 const double p4=0.785398163397448390,p2=1.570796326794896619231322,tail=6.1232339957367660e-17,inv=0.636619772367581382,big=6.755399441055744e15;
 if(isnan(x))return x;
 if(isinf(x))return ppc_nan(33);
 if(fabs(x)>1.38168706094305449e13){
  while(fabs(x)>2.829695100811376e16){double n=x*inv;x=fma(-n,p2,x);x=fma(-n,tail,x);}
  double n=fma(x,inv,2.7021597764222976e16)-2.7021597764222976e16;
  x=fma(-n,p2,x);x=fma(-n,tail,x);
 }
 double arg=x,at=0;unsigned q=cosine;int reduced=fabs(x)>=p4;
 if(reduced){double z=fma(x,inv,big),n=z-big,t=fma(-n,p2,x);arg=fma(-n,tail,t);t-=arg;at=fma(-n,tail,t);uint64_t u;memcpy(&u,&z,8);q=((unsigned)u+cosine)&3;}
 double x2=arg*arg,x4=x2*x2,t1,t2;
 if(q&1){t1=fma(c14,x4,c10);t2=fma(c12,x4,c8);t1=fma(t1,x4,c6);t2=fma(t2,x4,c4);t1=fma(t1,x4,c2);t1=fma(x2,t2,t1);if(!reduced)return fma(x2,t1,1);t1=fma(arg,t1,-at);return q<2?fma(arg,t1,1):fma(-arg,t1,-1);}
 t1=fma(s13,x4,s9);t2=fma(s11,x4,s7);t1=fma(t1,x4,s5);t2=fma(t2,x4,s3);t1=fma(t1,x2,t2);double x3=arg*x2;if(!reduced)return fma(t1,x3,x);t1=fma(t1,x3,at);return q<2?arg+t1:-arg-t1;
}
double astro_ppc_sin(double x){return trig(x,0);}double astro_ppc_cos(double x){return trig(x,1);}

const static double a14  = 0.03085091303188211304259;
const static double a13  =-0.02425125216179617744614;
const static double a12  = 0.02273334623573271023373;
const static double a11  = 0.0002983797813053653120360;
const static double a10  = 0.008819738782817955152102;
const static double a9   = 0.008130738583790024803650;
const static double a8   = 0.009793486386035222577675;
const static double a7   = 0.01154901189590083099584;
const static double a6   = 0.01396501522140471126730;
const static double a5   = 0.01735275722383019335276;
const static double a4   = 0.02237215928757573539490;
const static double a3   = 0.03038194444121688698408;
const static double a2   = 0.04464285714288482921087;
const static double a1   = 0.07499999999999990640378;
const static double a0   = 0.1666666666666666667191;

static const unsigned short SqrtTable[256] =
      {
      27497, 27752, 28262, 28517, 28772, 29282, 29537, 29792, 30302, 30557, 31067, 31322,
      31577, 32088, 32343, 32598, 33108, 33363, 33618, 34128, 34384, 34639, 35149, 35404,
      35659, 35914, 36425, 36680, 36935, 37446, 37701, 37956, 38211, 38722, 38977, 39232,
      39487, 39998, 40253, 40508, 40763, 41274, 41529, 41784, 42040, 42550, 42805, 43061,
      43316, 43571, 44082, 44337, 44592, 44848, 45103, 45358, 45869, 46124, 46379, 46635,
      46890, 47401, 47656, 47911, 48167, 48422, 48677, 48933, 49443, 49699, 49954, 50209,
      50465, 50720, 50976, 51231, 51742, 51997, 52252, 52508, 52763, 53019, 53274, 53529,
      53785, 54296, 54551, 54806, 55062, 55317, 55573, 55828, 56083, 56339, 56594, 56850,
      57105, 57616, 57871, 58127, 58382, 58638, 58893, 59149, 59404, 59660, 59915, 60170,
      60426, 60681, 60937, 61192, 61448, 61703, 61959, 62214, 62470, 62725, 62981, 63236,
      63492, 63747, 64003, 64258, 64514, 64769, 65025, 65280, 511,   510,   764,   1018,
      1272,  1526,  1780,  2034,  2288,  2542,  2796,  3050,  3305,  3559,  3813,  4067,
      4321,  4576,  4830,  5084,  5338,  5593,  5847,  6101,  6101,  6356,  6610,  6864,
      7119,  7373,  7627,  7882,  8136,  8391,  8391,  8645,  8899,  9154,  9408,  9663,
      9917,  10172, 10172, 10426, 10681, 10935, 11190, 11444, 11699, 11699, 11954, 12208,
      12463, 12717, 12972, 13226, 13226, 13481, 13736, 13990, 14245, 14245, 14500, 14754,
      15009, 15264, 15518, 15518, 15773, 16028, 16282, 16537, 16537, 16792, 17047, 17301,
      17556, 17556, 17811, 18066, 18320, 18575, 18575, 18830, 19085, 19339, 19339, 19594,
      19849, 20104, 20104, 20359, 20614, 20868, 21123, 21123, 21378, 21633, 21888, 21888,
      22143, 22398, 22653, 22653, 22907, 23162, 23417, 23417, 23672, 23927, 23927, 24182,
      24437, 24692, 24692, 24947, 25202, 25457, 25457, 25712, 25967, 25967, 26222, 26477,
      26732, 26732, 26987, 27242 };

static double from_hi(uint32_t hi){uint64_t u=(uint64_t)hi<<32;double x;memcpy(&x,&u,8);return x;}
double astro_ppc_asin(double x){
 const double halfpi=1.570796326794896619231322,tail=6.1232339957367660e-17;
 double ax=fabs(x),x2=x*x,x4,t1,t2;
 if(isnan(x))return copysign(ppc_nan(34),x);
 if(ax<=.5){if(ax<1.490116119384765625e-8)return x;
  x4=x2*x2;double x3=x*x2;t1=fma(a14,x2,a13);t1=fma(t1,x4,a11);t2=fma(a12,x4,a10);
  t1=fma(t1,x4,a9);t1=fma(t1,x4,a7);t2=fma(t2,x4,a8);t1=fma(t1,x4,a5);t2=fma(t2,x4,a6);
  t1=fma(t1,x4,a3);t2=fma(t2,x4,a4);t1=fma(t1,x4,a1);t2=fma(t2,x4,a2);
  t2=fma(t2,x2,t1);t1=fma(x2,t2,a0);return fma(x3,t1,x);
 }
 if(ax<1){double c=fma(-.5,ax,.5);x2=c;x4=c*c;uint64_t cb;memcpy(&cb,&c,8);uint32_t hi=cb>>32;
  unsigned p=SqrtTable[(hi>>13)&255],gh=((hi+0x3ff00000u)>>1)&0x7ff00000u;
  double g=from_hi(gh+((p&0xff00)<<4)),y=from_hi(0x7fc00000u-gh+((p&255)<<12));
  t1=fma(a13,x4,a11);t2=fma(a14,x4,a12);t1=fma(t1,x4,a9);t2=fma(t2,x4,a10);
  t1=fma(t1,x4,a7);t2=fma(t2,x4,a8);t1=fma(t1,x4,a5);t2=fma(t2,x4,a6);
  t1=fma(t1,x4,a3);t2=fma(t2,x4,a4);t1=fma(t1,x4,a1);t2=fma(t2,x4,a2);
  double d=fma(-g,g,c);g=fma(y,d,g);double y2=y+y,e=fma(-y,g,.5);d=fma(-g,g,c);
  y=fma(e,y2,y);t1=fma(x2,t2,t1);g=fma(y,d,g);y2=y+y;
  e=fma(-y,g,.5);d=fma(-g,g,c);y=fma(e,y2,y);t1=fma(x2,t1,a0);g=fma(y,d,g);
  d=fma(-g,g,c);double u=fma(-2,g,halfpi);d=d*y;double v=fma(-2,g,halfpi-u);g=g*x2;d=fma(-.5,tail,d);
  t2=fma(-.5,v,d);t2=fma(g,t1,t2);return x>0?fma(-2,t2,u):fma(2,t2,-u);
 }
 if(ax==1)return x>0?fma(x,tail,halfpi):fma(x,tail,-halfpi);
 return ppc_nan(34);
}

#include "ppc_atan_table.h"
static double table_double(uint64_t u){double x;memcpy(&x,&u,8);return x;}
static double atan_poly(double x2){
 double x4=x2*x2;
 double t1=fma(x4,7.6018324085327799e-02,1.1111109821671356e-01);
 double t2=fma(x4,-9.0904243427904791e-02,-1.4285714283952728e-01);
 t1=fma(x4,t1,1.9999999999998854e-01);t2=fma(x4,t2,-3.3333333333333330e-01);
 return fma(x2,t1,t2);
}
static double atan_grid(double x,double *zero){
 double z=fma(256,x,6.755399441055744e15);uint64_t u;memcpy(&u,&z,8);
 const uint64_t *p=atan_table[(unsigned)u-16];
 *zero=table_double(p[6]);return table_double(p[0]);
}
static double atan_grid_poly(double x,double z){
 double r=fma(256,x,6.755399441055744e15);uint64_t u;memcpy(&u,&r,8);const uint64_t*p=atan_table[(unsigned)u-16];
 double t=fma(table_double(p[1]),z,table_double(p[2]));
 t=fma(t,z,table_double(p[3]));t=fma(t,z,table_double(p[4]));return fma(t,z,table_double(p[5]));
}
double astro_ppc_atan(double x){
 const double halfpi=1.570796326794896619231322,tail=6.1232339957367660e-17;
 double ax=fabs(x);if(isnan(x)||x==0)return x;
 if(ax>1){double y=1/ax;if(ax<0x1.d0297p53){
  double yt=y*fma(-ax,y,1);
  if(ax>16){double x2=y*y,x3=x2*y,h=halfpi-y,rt=(h-halfpi)+y;
   double t=fma(-x3,atan_poly(x2),tail);
   return x>0?((t-yt)-rt)+h:((yt-t)+rt)-h;
  }
  double zero,p=atan_grid(y,&zero),z=(y-p)+yt,t=atan_grid_poly(y,z),h=halfpi-zero;
  return x>0?fma(-z,t,tail)+h:fma(z,t,-tail)-h;
 }
 return x>0?fma(3.14159265358979323846,.5,tail):fma(-3.14159265358979323846,.5,-tail);
 }
 if(ax>.0625){double zero,p=atan_grid(ax,&zero),z=ax-p,t=atan_grid_poly(ax,z);return x>0?fma(z,t,zero):fma(-z,t,-zero);}
 double x2=x*x,x3=x2*x;return fma(x3,atan_poly(x2),x);
}

int32_t astro_ppc_i32(double x){
 /* Original fctiwz: truncate, saturate signed bounds; NaN maps to INT_MIN. */
 if(isnan(x)||x<=-2147483648.0)return INT32_MIN;
 if(x>=2147483647.0)return INT32_MAX;
 return (int32_t)x;
}

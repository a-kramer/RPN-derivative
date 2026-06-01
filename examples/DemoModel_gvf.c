#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <gsl/gsl_errno.h>
#include <gsl/gsl_odeiv2.h>
#include <gsl/gsl_math.h>

/* string.h for memset() */
enum reaction { _R0,_R1,_R2,_R3,_R4,_R5, numReactions }; /* reaction indexes  */
enum stateVariable { _A,_B,_C,_AB,_AC,_ABC, numStateVar }; /* state variable indexes  */
enum param { _kf_R0,_kr_R0,_kf_R1,_kr_R1,_kf_R2,_kr_R2,_kf_R3,_kr_R3,_kf_R4,_kr_R4,_kf_R5 ,_kr_R5,_u,_t_on, numParam }; /* parameter indexes  */
enum func { _sumA,_sumB,_sumC, numFunc }; /* parameter indexes  */

/* The error code indicates how to pre-allocate memory
 * for output values such as `f_`. The _vf function returns
 * the number of state variables, if any of the args are `NULL`.
 * evaluation errors can be indicated by negative return values.
 * GSL_SUCCESS (0) is returned when no error occurred.
 */

/* ode vector field: y'=f(t,y;p) */
int DemoModel_vf(double t, const double y_[], double f_[], void *par)
{
	double *p_=par;
	if (!y_ || !f_) return 6;
	double inv_tau=1000;
	double kf_R0=p_[0];
	double kr_R0=p_[1];
	double kf_R1=p_[2];
	double kr_R1=p_[3];
	double kf_R2=p_[4];
	double kr_R2=p_[5];
	double kf_R3=p_[6];
	double kr_R3=p_[7];
	double kf_R4=p_[8];
	double kr_R4=p_[9];
	double kf_R5 =p_[10];
	double kr_R5=p_[11];
	double u=p_[12];
	double t_on=p_[13];
	double A=y_[0];
	double B=y_[1];
	double C=y_[2];
	double AB=y_[3];
	double AC=y_[4];
	double ABC=y_[5];
	double Activation=1/(1-exp(-(t-t_on)*inv_tau));
	double ReactionFlux0=u * kf_R0 * A * B - kr_R0 * AB;
	double ReactionFlux1=kf_R1 * A * C - kr_R1 * AC;
	double ReactionFlux2=kf_R2 * AB * C - kr_R2 * ABC;
	double ReactionFlux3=kf_R3 * AC * B - kr_R3 * ABC;
	f_[_R0] = -ReactionFlux0-ReactionFlux1; /* R0 */
	f_[_R1] = -ReactionFlux0-ReactionFlux3; /* R1 */
	f_[_R2] = -ReactionFlux1-ReactionFlux2; /* R2 */
	f_[_R3] = +ReactionFlux0-ReactionFlux2; /* R3 */
	f_[_R4] = +ReactionFlux1-ReactionFlux3; /* R4 */
	f_[_R5] = +ReactionFlux2+ReactionFlux3; /* R5 */
	return GSL_SUCCESS;
}
/* ode Jacobian df(t,y;p)/dy */
int DemoModel_jac(double t, const double y_[], double *jac_, double *dfdt_, void *par)
{
	double *p_=par;
	if (!y_ || !jac_) return 6*6;
	double inv_tau=1000;
	double kf_R0=p_[0];
	double kr_R0=p_[1];
	double kf_R1=p_[2];
	double kr_R1=p_[3];
	double kf_R2=p_[4];
	double kr_R2=p_[5];
	double kf_R3=p_[6];
	double kr_R3=p_[7];
	double kf_R4=p_[8];
	double kr_R4=p_[9];
	double kf_R5 =p_[10];
	double kr_R5=p_[11];
	double u=p_[12];
	double t_on=p_[13];
	double A=y_[0];
	double B=y_[1];
	double C=y_[2];
	double AB=y_[3];
	double AC=y_[4];
	double ABC=y_[5];
	double Activation=1/(1-exp(-(t-t_on)*inv_tau));
	double ReactionFlux0=u * kf_R0 * A * B - kr_R0 * AB;
	double ReactionFlux1=kf_R1 * A * C - kr_R1 * AC;
	double ReactionFlux2=kf_R2 * AB * C - kr_R2 * ABC;
	double ReactionFlux3=kf_R3 * AC * B - kr_R3 * ABC;
	memset(jac_,0,sizeof(double)*numStateVar*numStateVar); /* 36 */
/* column 1 (df/dy_0) */
	jac_[0] = ((-1*((u*kf_R0)*B))-(kf_R1*C)); /* [0, 0] */
	jac_[6] = (-1*((u*kf_R0)*B)); /* [1, 0] */
	jac_[12] = (-1*(kf_R1*C)); /* [2, 0] */
	jac_[18] = ((u*kf_R0)*B); /* [3, 0] */
	jac_[24] = (kf_R1*C); /* [4, 0] */
/* column 2 (df/dy_1) */
	jac_[1] = (-1*(A*(u*kf_R0))); /* [0, 1] */
	jac_[7] = ((-1*(A*(u*kf_R0)))-(kf_R3*AC)); /* [1, 1] */
	jac_[19] = (A*(u*kf_R0)); /* [3, 1] */
	jac_[25] = (0-(kf_R3*AC)); /* [4, 1] */
	jac_[31] = (kf_R3*AC); /* [5, 1] */
/* column 3 (df/dy_2) */
	jac_[2] = (0-(kf_R1*A)); /* [0, 2] */
	jac_[14] = ((-1*(kf_R1*A))-(kf_R2*AB)); /* [2, 2] */
	jac_[20] = (0-(kf_R2*AB)); /* [3, 2] */
	jac_[26] = (kf_R1*A); /* [4, 2] */
	jac_[32] = (kf_R2*AB); /* [5, 2] */
/* column 4 (df/dy_3) */
	jac_[3] = (-1*(0-kr_R0)); /* [0, 3] */
	jac_[9] = (-1*(0-kr_R0)); /* [1, 3] */
	jac_[15] = (0-(kf_R2*C)); /* [2, 3] */
	jac_[21] = ((0-kr_R0)-(kf_R2*C)); /* [3, 3] */
	jac_[33] = (kf_R2*C); /* [5, 3] */
/* column 5 (df/dy_4) */
	jac_[4] = (0-(0-kr_R1)); /* [0, 4] */
	jac_[10] = (B*(0-kf_R3)); /* [1, 4] */
	jac_[16] = (-1*(0-kr_R1)); /* [2, 4] */
	jac_[28] = ((0-kr_R1)-(kf_R3*B)); /* [4, 4] */
	jac_[34] = (kf_R3*B); /* [5, 4] */
/* column 6 (df/dy_5) */
	jac_[11] = (0-(0-kr_R3)); /* [1, 5] */
	jac_[17] = (0-(0-kr_R2)); /* [2, 5] */
	jac_[23] = (0-(0-kr_R2)); /* [3, 5] */
	jac_[29] = (0-(0-kr_R3)); /* [4, 5] */
	jac_[35] = ((0-kr_R2)+(0-kr_R3)); /* [5, 5] */
	return GSL_SUCCESS;
}
/* ode parameter Jacobian df(t,y;p)/dp */
int DemoModel_jacp(double t, const double y_[], double *jacp_, double *dfdt_, void *par)
{
	double *p_=par;
	if (!y_ || !jacp_) return 6*14;
	double inv_tau=1000;
	double kf_R0=p_[0];
	double kr_R0=p_[1];
	double kf_R1=p_[2];
	double kr_R1=p_[3];
	double kf_R2=p_[4];
	double kr_R2=p_[5];
	double kf_R3=p_[6];
	double kr_R3=p_[7];
	double kf_R4=p_[8];
	double kr_R4=p_[9];
	double kf_R5 =p_[10];
	double kr_R5=p_[11];
	double u=p_[12];
	double t_on=p_[13];
	double A=y_[0];
	double B=y_[1];
	double C=y_[2];
	double AB=y_[3];
	double AC=y_[4];
	double ABC=y_[5];
	double Activation=1/(1-exp(-(t-t_on)*inv_tau));
	double ReactionFlux0=u * kf_R0 * A * B - kr_R0 * AB;
	double ReactionFlux1=kf_R1 * A * C - kr_R1 * AC;
	double ReactionFlux2=kf_R2 * AB * C - kr_R2 * ABC;
	double ReactionFlux3=kf_R3 * AC * B - kr_R3 * ABC;
	memset(jacp_,0,sizeof(double)*numStateVar*numParam); /* 84 */
/* column 1 (df/dp_0) */
	jacp_[0] = (-1*((u*A)*B)); /* [0, 0] */
	jacp_[14] = (-1*((u*A)*B)); /* [1, 0] */
	jacp_[42] = ((u*A)*B); /* [3, 0] */
/* column 2 (df/dp_1) */
	jacp_[1] = (-1*(0-AB)); /* [0, 1] */
	jacp_[15] = (-1*(0-AB)); /* [1, 1] */
	jacp_[43] = (0-AB); /* [3, 1] */
/* column 3 (df/dp_2) */
	jacp_[2] = (0-(A*C)); /* [0, 2] */
	jacp_[30] = (-1*(A*C)); /* [2, 2] */
	jacp_[58] = (A*C); /* [4, 2] */
/* column 4 (df/dp_3) */
	jacp_[3] = (0-(0-AC)); /* [0, 3] */
	jacp_[31] = (-1*(0-AC)); /* [2, 3] */
	jacp_[59] = (0-AC); /* [4, 3] */
/* column 5 (df/dp_4) */
	jacp_[32] = (0-(AB*C)); /* [2, 4] */
	jacp_[46] = (0-(AB*C)); /* [3, 4] */
	jacp_[74] = (AB*C); /* [5, 4] */
/* column 6 (df/dp_5) */
	jacp_[33] = (0-(0-ABC)); /* [2, 5] */
	jacp_[47] = (0-(0-ABC)); /* [3, 5] */
	jacp_[75] = (0-ABC); /* [5, 5] */
/* column 7 (df/dp_6) */
	jacp_[20] = (B*(0-AC)); /* [1, 6] */
	jacp_[62] = (0-(AC*B)); /* [4, 6] */
	jacp_[76] = (AC*B); /* [5, 6] */
/* column 8 (df/dp_7) */
	jacp_[21] = (0-(0-ABC)); /* [1, 7] */
	jacp_[63] = (0-(0-ABC)); /* [4, 7] */
	jacp_[77] = (0-ABC); /* [5, 7] */
/* column 9 (df/dp_8) */
/* column 10 (df/dp_9) */
/* column 11 (df/dp_10) */
/* column 12 (df/dp_11) */
/* column 13 (df/dp_12) */
	jacp_[12] = (-1*((kf_R0*A)*B)); /* [0, 12] */
	jacp_[26] = (-1*((kf_R0*A)*B)); /* [1, 12] */
	jacp_[54] = ((kf_R0*A)*B); /* [3, 12] */
/* column 14 (df/dp_13) */
	return GSL_SUCCESS;
}
/* ode Functions F(t,y;p) */
int DemoModel_func(double t, const double y_[], double *func_, void *par)
{
	double *p_=par;
	if (!y_ || !func_) return 3;
	double inv_tau=1000;
	double kf_R0=p_[0];
	double kr_R0=p_[1];
	double kf_R1=p_[2];
	double kr_R1=p_[3];
	double kf_R2=p_[4];
	double kr_R2=p_[5];
	double kf_R3=p_[6];
	double kr_R3=p_[7];
	double kf_R4=p_[8];
	double kr_R4=p_[9];
	double kf_R5 =p_[10];
	double kr_R5=p_[11];
	double u=p_[12];
	double t_on=p_[13];
	double A=y_[0];
	double B=y_[1];
	double C=y_[2];
	double AB=y_[3];
	double AC=y_[4];
	double ABC=y_[5];
	double Activation=1/(1-exp(-(t-t_on)*inv_tau));
	double ReactionFlux0=u * kf_R0 * A * B - kr_R0 * AB;
	double ReactionFlux1=kf_R1 * A * C - kr_R1 * AC;
	double ReactionFlux2=kf_R2 * AB * C - kr_R2 * ABC;
	double ReactionFlux3=kf_R3 * AC * B - kr_R3 * ABC;
	func_[_sumA] = A+AB+AC+ABC; /* sumA */
	func_[_sumB] = B+AB+ABC; /* sumB */
	func_[_sumC] = C+AC+ABC; /* sumC */
	return GSL_SUCCESS;
}
/* Function Jacobian dF(t,y;p)/dy */
int DemoModel_funcJac(double t, const double y_[], double *funcJac_, void *par)
{
	double *p_=par;
	if (!y_ || !funcJac_) return 18;
	double inv_tau=1000;
	double kf_R0=p_[0];
	double kr_R0=p_[1];
	double kf_R1=p_[2];
	double kr_R1=p_[3];
	double kf_R2=p_[4];
	double kr_R2=p_[5];
	double kf_R3=p_[6];
	double kr_R3=p_[7];
	double kf_R4=p_[8];
	double kr_R4=p_[9];
	double kf_R5 =p_[10];
	double kr_R5=p_[11];
	double u=p_[12];
	double t_on=p_[13];
	double A=y_[0];
	double B=y_[1];
	double C=y_[2];
	double AB=y_[3];
	double AC=y_[4];
	double ABC=y_[5];
	double Activation=1/(1-exp(-(t-t_on)*inv_tau));
	double ReactionFlux0=u * kf_R0 * A * B - kr_R0 * AB;
	double ReactionFlux1=kf_R1 * A * C - kr_R1 * AC;
	double ReactionFlux2=kf_R2 * AB * C - kr_R2 * ABC;
	double ReactionFlux3=kf_R3 * AC * B - kr_R3 * ABC;
	memset(funcJac_,0,sizeof(double)*numFunc*numStateVar); /* 18 */
/* column 1 (dF/dy_0) */
	funcJac_[0] = 1; /* [0, 0] */
/* column 2 (dF/dy_1) */
	funcJac_[7] = 1; /* [1, 1] */
/* column 3 (dF/dy_2) */
	funcJac_[14] = 1; /* [2, 2] */
/* column 4 (dF/dy_3) */
	funcJac_[3] = 1; /* [0, 3] */
	funcJac_[9] = 1; /* [1, 3] */
/* column 5 (dF/dy_4) */
	funcJac_[4] = 1; /* [0, 4] */
	funcJac_[16] = 1; /* [2, 4] */
/* column 6 (dF/dy_5) */
	funcJac_[5] = 1; /* [0, 5] */
	funcJac_[11] = 1; /* [1, 5] */
	funcJac_[17] = 1; /* [2, 5] */
	return GSL_SUCCESS;
}
/* Function parameter Jacobian dF(t,y;p)/dp */
int DemoModel_funcJacp(double t, const double y_[], double *funcJacp_, void *par)
{
	double *p_=par;
	if (!y_ || !funcJacp_) return 42;
	double inv_tau=1000;
	double kf_R0=p_[0];
	double kr_R0=p_[1];
	double kf_R1=p_[2];
	double kr_R1=p_[3];
	double kf_R2=p_[4];
	double kr_R2=p_[5];
	double kf_R3=p_[6];
	double kr_R3=p_[7];
	double kf_R4=p_[8];
	double kr_R4=p_[9];
	double kf_R5 =p_[10];
	double kr_R5=p_[11];
	double u=p_[12];
	double t_on=p_[13];
	double A=y_[0];
	double B=y_[1];
	double C=y_[2];
	double AB=y_[3];
	double AC=y_[4];
	double ABC=y_[5];
	double Activation=1/(1-exp(-(t-t_on)*inv_tau));
	double ReactionFlux0=u * kf_R0 * A * B - kr_R0 * AB;
	double ReactionFlux1=kf_R1 * A * C - kr_R1 * AC;
	double ReactionFlux2=kf_R2 * AB * C - kr_R2 * ABC;
	double ReactionFlux3=kf_R3 * AC * B - kr_R3 * ABC;
	memset(funcJacp_,0,sizeof(double)*numFunc*numParam); /* 42 */
/* column 1 (dF/dp_0) */
/* column 2 (dF/dp_1) */
/* column 3 (dF/dp_2) */
/* column 4 (dF/dp_3) */
/* column 5 (dF/dp_4) */
/* column 6 (dF/dp_5) */
/* column 7 (dF/dp_6) */
/* column 8 (dF/dp_7) */
/* column 9 (dF/dp_8) */
/* column 10 (dF/dp_9) */
/* column 11 (dF/dp_10) */
/* column 12 (dF/dp_11) */
/* column 13 (dF/dp_12) */
/* column 14 (dF/dp_13) */
	return GSL_SUCCESS;
}
/* ode default parameters */
int DemoModel_default(double t, void *par)
{
	double *p_=par;
	if (!p_) return 14;
	double inv_tau=1000;
	memset(p_,0,sizeof(double)*numParam);
	p_[_kf_R0] = 1.0;
	p_[_kr_R0] = 1.0;
	p_[_kf_R1] = 1.0;
	p_[_kr_R1] = 1.0;
	p_[_kf_R2] = 1.0;
	p_[_kr_R2] = 1.0;
	p_[_kf_R3] = 1.0;
	p_[_kr_R3] = 1.0;
	p_[_kf_R4] = 1.0;
	p_[_kr_R4] = 1.0;
	p_[_kf_R5 ] = 1.0;
	p_[_kr_R5] = 1.0;
	p_[_u] = 1;
	return GSL_SUCCESS;
}
/* ode initial values */
int DemoModel_init(double t, double *y_, void *par)
{
	double *p_=par;
	if (!y_) return 6;
	double inv_tau=1000;
	double kf_R0=p_[0];
	double kr_R0=p_[1];
	double kf_R1=p_[2];
	double kr_R1=p_[3];
	double kf_R2=p_[4];
	double kr_R2=p_[5];
	double kf_R3=p_[6];
	double kr_R3=p_[7];
	double kf_R4=p_[8];
	double kr_R4=p_[9];
	double kf_R5 =p_[10];
	double kr_R5=p_[11];
	double u=p_[12];
	double t_on=p_[13];
	/* the initial value of y may depend on the parameters. */
	memset(y_,0,sizeof(double)*numStateVar);
	y_[_A] = 1000;
	y_[_B] = 10;
	y_[_C] = 10;
	return GSL_SUCCESS;
}

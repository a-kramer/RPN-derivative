#include <stdlib.h>
#include <math.h>
#include <gsl/gsl_errno.h>
#include <gsl/gsl_odeiv2.h>

/* The error code indicates how to pre-allocate memory
 * for output values such as `f_`. The _vf function returns
 * the number of state variables, if any of the args are `NULL`.
 * evaluation errors can be indicated by negative return values.
 * GSL_SUCCESS (0) is returned when no error occurred.
 */

/* ode vector field: y'=f(t,y;p), the Activation expression is currently unused */
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
	double kf_R5=p_[10];
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
	f_[0] = -ReactionFlux0-ReactionFlux1;
	f_[1] = -ReactionFlux0-ReactionFlux3;
	f_[2] = -ReactionFlux1-ReactionFlux2;
	f_[3] = +ReactionFlux0-ReactionFlux2;
	f_[4] = +ReactionFlux1-ReactionFlux3;
	f_[5] = +ReactionFlux2+ReactionFlux3;
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
	double kf_R5=p_[10];
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
/* column 1 (df/dy_0) */
	jac_[0] = ((-1*((u*kf_R0)*B))-(kf_R1*C)); /* [0, 0] */
	jac_[6] = (-1*((u*kf_R0)*B)); /* [1, 0] */
	jac_[12] = (-1*(kf_R1*C)); /* [2, 0] */
	jac_[18] = ((u*kf_R0)*B); /* [3, 0] */
	jac_[24] = (kf_R1*C); /* [4, 0] */
	jac_[30] = 0; /* [5, 0] */
/* column 2 (df/dy_1) */
	jac_[1] = (-1*(A*(u*kf_R0))); /* [0, 1] */
	jac_[7] = ((-1*(A*(u*kf_R0)))-(kf_R3*AC)); /* [1, 1] */
	jac_[13] = 0; /* [2, 1] */
	jac_[19] = (A*(u*kf_R0)); /* [3, 1] */
	jac_[25] = (0-(kf_R3*AC)); /* [4, 1] */
	jac_[31] = (kf_R3*AC); /* [5, 1] */
/* column 3 (df/dy_2) */
	jac_[2] = (0-(kf_R1*A)); /* [0, 2] */
	jac_[8] = 0; /* [1, 2] */
	jac_[14] = ((-1*(kf_R1*A))-(kf_R2*AB)); /* [2, 2] */
	jac_[20] = (0-(kf_R2*AB)); /* [3, 2] */
	jac_[26] = (kf_R1*A); /* [4, 2] */
	jac_[32] = (kf_R2*AB); /* [5, 2] */
/* column 4 (df/dy_3) */
	jac_[3] = (-1*(0-kr_R0)); /* [0, 3] */
	jac_[9] = (-1*(0-kr_R0)); /* [1, 3] */
	jac_[15] = (0-(kf_R2*C)); /* [2, 3] */
	jac_[21] = ((0-kr_R0)-(kf_R2*C)); /* [3, 3] */
	jac_[27] = 0; /* [4, 3] */
	jac_[33] = (kf_R2*C); /* [5, 3] */
/* column 5 (df/dy_4) */
	jac_[4] = (0-(0-kr_R1)); /* [0, 4] */
	jac_[10] = (B*(0-kf_R3)); /* [1, 4] */
	jac_[16] = (-1*(0-kr_R1)); /* [2, 4] */
	jac_[22] = 0; /* [3, 4] */
	jac_[28] = ((0-kr_R1)-(kf_R3*B)); /* [4, 4] */
	jac_[34] = (kf_R3*B); /* [5, 4] */
/* column 6 (df/dy_5) */
	jac_[5] = 0; /* [0, 5] */
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
	double kf_R5=p_[10];
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
/* column 1 (df/dp_0) */
	jacp_[0] = (-1*((u*A)*B)); /* [0, 0] */
	jacp_[14] = (-1*((u*A)*B)); /* [1, 0] */
	jacp_[28] = 0; /* [2, 0] */
	jacp_[42] = ((u*A)*B); /* [3, 0] */
	jacp_[56] = 0; /* [4, 0] */
	jacp_[70] = 0; /* [5, 0] */
/* column 2 (df/dp_1) */
	jacp_[1] = (-1*(0-AB)); /* [0, 1] */
	jacp_[15] = (-1*(0-AB)); /* [1, 1] */
	jacp_[29] = 0; /* [2, 1] */
	jacp_[43] = (0-AB); /* [3, 1] */
	jacp_[57] = 0; /* [4, 1] */
	jacp_[71] = 0; /* [5, 1] */
/* column 3 (df/dp_2) */
	jacp_[2] = (0-(A*C)); /* [0, 2] */
	jacp_[16] = 0; /* [1, 2] */
	jacp_[30] = (-1*(A*C)); /* [2, 2] */
	jacp_[44] = 0; /* [3, 2] */
	jacp_[58] = (A*C); /* [4, 2] */
	jacp_[72] = 0; /* [5, 2] */
/* column 4 (df/dp_3) */
	jacp_[3] = (0-(0-AC)); /* [0, 3] */
	jacp_[17] = 0; /* [1, 3] */
	jacp_[31] = (-1*(0-AC)); /* [2, 3] */
	jacp_[45] = 0; /* [3, 3] */
	jacp_[59] = (0-AC); /* [4, 3] */
	jacp_[73] = 0; /* [5, 3] */
/* column 5 (df/dp_4) */
	jacp_[4] = 0; /* [0, 4] */
	jacp_[18] = 0; /* [1, 4] */
	jacp_[32] = (0-(AB*C)); /* [2, 4] */
	jacp_[46] = (0-(AB*C)); /* [3, 4] */
	jacp_[60] = 0; /* [4, 4] */
	jacp_[74] = (AB*C); /* [5, 4] */
/* column 6 (df/dp_5) */
	jacp_[5] = 0; /* [0, 5] */
	jacp_[19] = 0; /* [1, 5] */
	jacp_[33] = (0-(0-ABC)); /* [2, 5] */
	jacp_[47] = (0-(0-ABC)); /* [3, 5] */
	jacp_[61] = 0; /* [4, 5] */
	jacp_[75] = (0-ABC); /* [5, 5] */
/* column 7 (df/dp_6) */
	jacp_[6] = 0; /* [0, 6] */
	jacp_[20] = (B*(0-AC)); /* [1, 6] */
	jacp_[34] = 0; /* [2, 6] */
	jacp_[48] = 0; /* [3, 6] */
	jacp_[62] = (0-(AC*B)); /* [4, 6] */
	jacp_[76] = (AC*B); /* [5, 6] */
/* column 8 (df/dp_7) */
	jacp_[7] = 0; /* [0, 7] */
	jacp_[21] = (0-(0-ABC)); /* [1, 7] */
	jacp_[35] = 0; /* [2, 7] */
	jacp_[49] = 0; /* [3, 7] */
	jacp_[63] = (0-(0-ABC)); /* [4, 7] */
	jacp_[77] = (0-ABC); /* [5, 7] */
/* column 9 (df/dp_8) */
	jacp_[8] = 0; /* [0, 8] */
	jacp_[22] = 0; /* [1, 8] */
	jacp_[36] = 0; /* [2, 8] */
	jacp_[50] = 0; /* [3, 8] */
	jacp_[64] = 0; /* [4, 8] */
	jacp_[78] = 0; /* [5, 8] */
/* column 10 (df/dp_9) */
	jacp_[9] = 0; /* [0, 9] */
	jacp_[23] = 0; /* [1, 9] */
	jacp_[37] = 0; /* [2, 9] */
	jacp_[51] = 0; /* [3, 9] */
	jacp_[65] = 0; /* [4, 9] */
	jacp_[79] = 0; /* [5, 9] */
/* column 11 (df/dp_10) */
	jacp_[10] = 0; /* [0, 10] */
	jacp_[24] = 0; /* [1, 10] */
	jacp_[38] = 0; /* [2, 10] */
	jacp_[52] = 0; /* [3, 10] */
	jacp_[66] = 0; /* [4, 10] */
	jacp_[80] = 0; /* [5, 10] */
/* column 12 (df/dp_11) */
	jacp_[11] = 0; /* [0, 11] */
	jacp_[25] = 0; /* [1, 11] */
	jacp_[39] = 0; /* [2, 11] */
	jacp_[53] = 0; /* [3, 11] */
	jacp_[67] = 0; /* [4, 11] */
	jacp_[81] = 0; /* [5, 11] */
/* column 13 (df/dp_12) */
	jacp_[12] = (-1*((kf_R0*A)*B)); /* [0, 12] */
	jacp_[26] = (-1*((kf_R0*A)*B)); /* [1, 12] */
	jacp_[40] = 0; /* [2, 12] */
	jacp_[54] = ((kf_R0*A)*B); /* [3, 12] */
	jacp_[68] = 0; /* [4, 12] */
	jacp_[82] = 0; /* [5, 12] */
/* column 14 (df/dp_13) */
	jacp_[13] = 0; /* [0, 13] */
	jacp_[27] = 0; /* [1, 13] */
	jacp_[41] = 0; /* [2, 13] */
	jacp_[55] = 0; /* [3, 13] */
	jacp_[69] = 0; /* [4, 13] */
	jacp_[83] = 0; /* [5, 13] */
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
	double kf_R5=p_[10];
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
	func_[0] = A+AB+AC+ABC;
	func_[1] = B+AB+ABC;
	func_[2] = C+AC+ABC;
	return GSL_SUCCESS;
}
/* ode default parameters */
int DemoModel_default(double t, void *par)
{
	double *p_=par;
	if (!p_) return 14;
	double inv_tau=1000;
	p_[0] = 1.0;
	p_[1] = 1.0;
	p_[2] = 1.0;
	p_[3] = 1.0;
	p_[4] = 1.0;
	p_[5] = 1.0;
	p_[6] = 1.0;
	p_[7] = 1.0;
	p_[8] = 1.0;
	p_[9] = 1.0;
	p_[10] = 1.0;
	p_[11] = 1.0;
	p_[12] = 1;
	p_[13] = 0;
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
	double kf_R5=p_[10];
	double kr_R5=p_[11];
	double u=p_[12];
	double t_on=p_[13];
	/* the initial value of y may depend on the parameters. */
	y_[0] = 1000;
	y_[1] = 10;
	y_[2] = 10;
	y_[3] = 0;
	y_[4] = 0;
	y_[5] = 0;
	return GSL_SUCCESS;
}

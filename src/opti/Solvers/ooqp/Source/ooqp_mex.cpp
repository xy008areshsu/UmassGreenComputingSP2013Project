/* OOQP                                                               *
 * Authors: E. Michael Gertz, Stephen J. Wright                       *
 * (C) 2001 University of Chicago. See Copyright Notification in OOQP */

/* Modified J.Currie July-Sep 2011, March 2012, September 2012
 */

#include "mkl.h"
#include "string.h"
#include "mexUtility.h"
#include "QpGenData.h"
#include "QpGenVars.h"
#include "QpGenResiduals.h"
#include "GondzioSolver.h"
#include "QpGenSparsePardiso.h"
#include "QpGenSparseMa27.h"
#include "OoqpMonitor.h"
#include "OoqpVersion.h"
#include "Status.h"
#include <exception>

#define OOQP_VERSION "0.99.22"

using namespace std;

//Function Prototypes
void printSolverInfo();
void checkInputs(const mxArray *prhs[], int nrhs);

//Message Class
class mexPrinter : public OoqpMonitor {
    public:
        virtual void doIt( Solver * solver, Data * data, Variables * vars,
					 Residuals * resids,
					 double alpha, double sigma,
					 int i, double mu, 
                     int status_code,
					 int level );
};
//Print Handler
void mexPrinter::doIt( Solver * solver, Data * data, Variables * vars,
					 Residuals * resids,
					 double alpha, double sigma,
					 int i, double mu, 
                     int status_code,
					 int level )
{
    try
    {
        if(level < 2)
        {
            if(i == 1 || !(i%10))
                mexPrintf(" iter   duality gap           mu     resid norm\n");

            mexPrintf("%5d     %9.3g    %9.3g      %9.3g\n",i,resids->dualityGap(),mu,resids->residualNorm());
            mexEvalString("drawnow;"); //flush draw buffer
        }
    }
    catch (std::exception& error) 
    {
        mexErrMsgTxt(error.what());
    }
}

//Main Function
void mexFunction( int nlhs, mxArray * plhs[], int nrhs, const mxArray * prhs[] ) 
{
    //Input Args
    double *H, *f, *A, *rl, *ru, *C, *beq, *lb, *ub;
    
    //Return Args
    double *x, *fval, *exitflag, *iter;
    
    //Options
    int printLevel = 0;    
    int debug = 0;
    
    //Sparse Indicing
    mwIndex *H_ir, *H_jc, *A_ir, *A_jc, *C_ir, *C_jc;
    int *iH_ir = NULL, *iH_jc = NULL, *iA_ir = NULL, *iA_jc = NULL, *iC_ir = NULL, *iC_jc = NULL;
    size_t Hcol, Hrow, Acol, Arow, Ccol, Crow;
    mwIndex startrow, stoprow, currow;     
    int col, ind = 0;
    
    //Problem Size
    size_t ndec, neq, nin;
    mwSize nnzH, nnzA, nnzC;
    
    //Infinite Check Indexing
    char *ilb = NULL, *iub = NULL, *irl = NULL, *iru = NULL;
    
    //Local Copies
    double *qp_rl = NULL, *qp_ru = NULL, *qp_lb  = NULL , *qp_ub = NULL;
    
    //Internal Vars
    int i, err;
    const char *fnames[4] = {"pi","y","phi","gamma"};
    mxArray *d_pi, *d_y, *d_phi, *d_gam;
    
    //Check # Inputs
    if(nrhs < 1) {
        if(nlhs < 1)
            printSolverInfo();
        else
            plhs[0] = mxCreateString(OOQP_VERSION);
        return;
    }
    //Thorough Check
    checkInputs(prhs,nrhs); 
    
    //Get pointers to Input variables	
	H = mxGetPr(prhs[0]); //QP H
    H_ir = mxGetIr(prhs[0]);
    H_jc = mxGetJc(prhs[0]);
    f = mxGetPr(prhs[1]);
    A = mxGetPr(prhs[2]); //Lin In A
    A_ir = mxGetIr(prhs[2]);
    A_jc = mxGetJc(prhs[2]);
    rl = mxGetPr(prhs[3]);
    ru = mxGetPr(prhs[4]);
    C = mxGetPr(prhs[5]); //Lin Eq C
    C_ir = mxGetIr(prhs[5]);
    C_jc = mxGetJc(prhs[5]);
    beq = mxGetPr(prhs[6]);
    lb = mxGetPr(prhs[7]);
    ub = mxGetPr(prhs[8]);
    
    //Get options if specified
    if(nrhs > 9) {
        if(mxGetField(prhs[9],0,"display"))
            printLevel = (int)*mxGetPr(mxGetField(prhs[9],0,"display"));
        if(mxGetField(prhs[9],0,"debug"))
            debug = (int)*mxGetPr(mxGetField(prhs[9],0,"debug"));
    }

    //Get sizes
    ndec = mxGetM(prhs[1]); //f    
    nin = mxGetN(prhs[2]);  //A
    neq = mxGetN(prhs[5]);  //C
    if(mxIsEmpty(prhs[0]))
        nnzH = 0;
    else
        nnzH = *(H_jc + mxGetN(prhs[0])); //H
    if(mxIsEmpty(prhs[2]))
        nnzA = 0;
    else
        nnzA = *(A_jc + mxGetN(prhs[2])); //A
    if(mxIsEmpty(prhs[5]))
        nnzC = 0;
    else
        nnzC = *(C_jc + mxGetN(prhs[5])); //C
    
    //Create Outputs
    plhs[0] = mxCreateDoubleMatrix(ndec,1, mxREAL);
    plhs[1] = mxCreateDoubleMatrix(1,1, mxREAL);
    plhs[2] = mxCreateDoubleMatrix(1,1, mxREAL);
    plhs[3] = mxCreateDoubleMatrix(1,1, mxREAL);
    plhs[4] = mxCreateDoubleMatrix(nin+neq,1,mxREAL);
    x = mxGetPr(plhs[0]); 
    fval = mxGetPr(plhs[1]); 
    exitflag = mxGetPr(plhs[2]);    
    iter = mxGetPr(plhs[3]);
    //Optional Outputs
    if(nlhs > 4) {    
        plhs[4] = mxCreateStructMatrix(1,1,4,fnames);
        d_pi = mxCreateDoubleMatrix(nin,1, mxREAL);
        d_y = mxCreateDoubleMatrix(neq,1, mxREAL);        
        d_phi = mxCreateDoubleMatrix(ndec,1, mxREAL);
        d_gam = mxCreateDoubleMatrix(ndec,1, mxREAL);
    }

    try
    {
        //QP Variables
        #ifdef USE_MA27
            QpGenSparseMa27 *qp = NULL;
        #else
            QpGenSparsePardiso *qp = NULL;
        #endif
        QpGenData *prob = NULL;
        QpGenVars *vars = NULL;
        QpGenResiduals *resid = NULL;
        GondzioSolver *s = NULL;
        mexPrinter *printer; //deleted automatically (I think)
        
        //Bounds Local Vectors
        ilb = (char*) mxCalloc(ndec, sizeof(char));
        iub = (char*) mxCalloc(ndec, sizeof(char));
        qp_lb = (double*)mxCalloc(ndec, sizeof(double));        
        qp_ub = (double*)mxCalloc(ndec, sizeof(double));
        //Copy lb if exists
        if(!mxIsEmpty(prhs[7])) {
            for(i=0;i<ndec;i++) {
                //Create Finite lb Index Vectors + Copy Finite Values
                if(mxIsFinite(lb[i])) {
                    ilb[i] = 1;
                    qp_lb[i] = lb[i];
                }
                else {
                    ilb[i] = 0;
                    qp_lb[i] = 0.0;
                }
            }
        }
        //Else fill lb with 0s
        else {
            for(i=0;i<ndec;i++) {
                ilb[i] = 0;
                qp_lb[i] = 0.0;
            }            
        }
        //Copy ub if exists
        if(!mxIsEmpty(prhs[8])) {    
            for(i=0;i<ndec;i++) {
                //Create Finite ub Index Vectors + Copy Finite Values
                if(mxIsFinite(ub[i])) {
                    iub[i] = 1;
                    qp_ub[i] = ub[i];
                }
                else {
                    iub[i] = 0;
                    qp_ub[i] = 0.0;
                }
            }
        }
        //Else fill ub with 0s
        else {
            for(i=0;i<ndec;i++) {
                iub[i] = 0;
                qp_ub[i] = 0.0;
            }            
        }
        
        //Copy Linear Inequalities if exist
        if(nin > 0) {
            irl = (char*) mxCalloc(nin, sizeof(char));
            iru = (char*) mxCalloc(nin, sizeof(char));
            qp_rl = (double*)mxCalloc(nin, sizeof(double));
            qp_ru = (double*)mxCalloc(nin, sizeof(double));
            for( i = 0; i < nin; i++ ) {
                //Create Finite rl Index Vectors + Copy Finite Values
                if(mxIsFinite(rl[i])) {
                    irl[i] = 1;
                    qp_rl[i] = rl[i];
                }
                else {
                    irl[i] = 0;
                    qp_rl[i] = 0.0;
                }
                //Create Finite ru Index Vectors + Copy Finite Values
                if(mxIsFinite(ru[i])) {
                    iru[i] = 1;
                    qp_ru[i] = ru[i];
                }
                else {
                    iru[i] = 0;
                    qp_ru[i] = 0.0;
                }
            }
        }
        
        //Build Sparse Triples + Convert Indices to int32 
        //QP H Matrix
        iH_ir = (int*)mxCalloc(nnzH,sizeof(int)); Hrow = mxGetM(prhs[0]);
        iH_jc = (int*)mxCalloc(nnzH,sizeof(int)); Hcol = mxGetN(prhs[0]);
        ind = 0;
        for(col = 0; col < Hcol; col++) {
            startrow = H_jc[col];
            stoprow = H_jc[col+1];
            if(startrow != stoprow) {
                for(currow = startrow; currow < stoprow; currow++) {
                    iH_ir[ind] = (int)H_ir[currow];
                    iH_jc[ind] = col;
                    ind++;
                }
            }
        }
        //Linear Inequality Constraint A Matrix
        if(!nnzA) {
            iA_ir = NULL;
            iA_jc = NULL;
        }
        else {
            iA_ir = (int*)mxCalloc(nnzA,sizeof(int)); Arow = mxGetM(prhs[2]);
            iA_jc = (int*)mxCalloc(nnzA,sizeof(int)); Acol = mxGetN(prhs[2]);
            ind = 0;
            for(col = 0; col < Acol; col++) {
                startrow = A_jc[col];
                stoprow = A_jc[col+1];
                if(startrow != stoprow) {
                    for(currow = startrow; currow < stoprow; currow++) {
                        iA_ir[ind] = (int)A_ir[currow];
                        iA_jc[ind] = col;
                        ind++;
                    }
                }
            }
        }
        //Linear Equality Constraint C Matrix
        if(!nnzC) {
            iC_ir = NULL;
            iC_jc = NULL;
        }
        else {
            iC_ir = (int*)mxCalloc(nnzC,sizeof(int)); Crow = mxGetM(prhs[5]);
            iC_jc = (int*)mxCalloc(nnzC,sizeof(int)); Ccol = mxGetN(prhs[5]);
            ind = 0;
            for(col = 0; col < Ccol; col++) {
                startrow = C_jc[col];
                stoprow = C_jc[col+1];
                if(startrow != stoprow) {
                    for(currow = startrow; currow < stoprow; currow++) {
                        iC_ir[ind] = (int)C_ir[currow];
                        iC_jc[ind] = col;
                        ind++;
                    }
                }
            }
        }
        
        if(debug) {
            mexPrintf("---------------------------------------------\n");
            mexPrintf("ndec: %d, rowA: %d, rowC: %d\n",ndec,nin,neq);
            mexPrintf("nnzH: %d, nnzA: %d, nnzC: %d\n",nnzH,nnzA,nnzC);
            mexPrintf("---------------------------------------------\n");
            if(debug > 1) {
                for( i = 0; i < ndec; i++ )
                    mexPrintf("lb[%d] = %2.2f, %d, ub[%d] = %2.2f, %d\n",i,qp_lb[i],ilb[i],i,qp_ub[i],iub[i]);

                mexPrintf("---------------------------------------------\n");
                for( i = 0; i < ndec; i++ )
                    mexPrintf("f[%d] = %2.2f\n",i,f[i]);

                mexPrintf("---------------------------------------------\n");
                for(i=0;i<nnzH;i++)
                    mexPrintf("H[%d,%d] = %2.2f\n",iH_ir[i],iH_jc[i],H[i]);

                if(nin) {        
                    mexPrintf("---------------------------------------------\n");
                    for(i=0;i<nnzA;i++)
                        mexPrintf("A[%d,%d] = %2.2f\n",iA_ir[i],iA_jc[i],A[i]);               
                    mexPrintf("---------------------------------------------\n");
                    for( i = 0; i < nin; i++ )
                        mexPrintf("rl[%d] = %2.2f, %d, ru[%d] = %2.2f, %d\n",i,qp_rl[i],irl[i],i,qp_ru[i],iru[i]);
                }

                if(neq) {
                    mexPrintf("---------------------------------------------\n");
                    for(i=0;i<nnzC;i++)
                        mexPrintf("Aeq[%d,%d] = %2.2f\n",iC_ir[i],iC_jc[i],C[i]);
                    for(i=0;i<neq;i++)
                        mexPrintf("beq[%d] = %2.2f\n",i,beq[i]);
                }
            }
            
            mexPrintf("---------------------------------------------\n");
        }
        
        //Create Problem
        #ifdef USE_MA27
            qp = new QpGenSparseMa27(ndec,neq,nin,nnzH,nnzC,nnzA);
        #else
            qp = new QpGenSparsePardiso((int)ndec,(int)neq,(int)nin,(int)nnzH,(int)nnzC,(int)nnzA);
        #endif
        //Fill In Data (note flipped i & j)
        prob = (QpGenData*) qp->copyDataFromSparseTriple(       
                                                            f,      iH_jc,  (int)nnzH,   iH_ir,   H,
                                                            qp_lb,  ilb,    qp_ub,  iub,
                                                            iC_jc,  (int)nnzC,   iC_ir,  C,       beq,
                                                            iA_jc,  (int)nnzA,   iA_ir,  A,
                                                            qp_rl,  irl,    qp_ru,  iru);
        //Make Vars
        vars  = (QpGenVars*)qp->makeVariables(prob);
        resid = (QpGenResiduals*)qp->makeResiduals(prob);
        //Make Solver
        s = new GondzioSolver(qp,prob);
        //Assign Status Handler (need more info from solver class really..)
//         DerivedStatus *ctrlCStatus = new DerivedStatus();
//         s->useStatus(ctrlCStatus);
        
        //Setup Options
        if(printLevel > 0) {
            if(printLevel == 1) { //iter print
                printer = new mexPrinter();
                //s->monitorSelf(); //weird crash with this
                s->addMonitor( printer );
            }
            
            //Print Header
            char verStr[1024]; int slen = 1024;
            getOoqpVersionString( verStr, 1024);
            mexPrintf("\n------------------------------------------------------------------\n");
            mexPrintf(" This is %s\n Authors: E. Michael Gertz, Stephen J. Wright\n Modified MEX Interface J. Currie 2011\n\n",verStr);
            mexPrintf(" Problem Properties:\n");
            mexPrintf(" # Decision Variables:     %6d\n # Equality Constraints:   %6d\n # Inequality Constraints: %6d\n",ndec,neq,nin);
            mexPrintf(" # Non-Zeros in H:         %6d\n # Non-Zeros in A:         %6d\n # Non-Zeros in Aeq:       %6d\n",nnzH,nnzA,nnzC);
            
            if(printLevel == 1)
                mexPrintf("------------------------------------------------------------------\n");
        }
        
        //Solve QP
        try
        {
            err = s->solve(prob,vars,resid);
        }
        catch(...)
        {
            mexWarnMsgTxt("Error solving Problem with OOQP");
            return;
        }
        //Assign variables
        *exitflag = err;       
        vars->x->copyIntoArray(x);
        *fval = prob->objectiveValue(vars);
        *iter = (double)s->iter;
        //Assign Dual Solution
        if(nlhs > 4) {            
            vars->pi->copyIntoArray(mxGetPr(d_pi));     //dual row in
            mxSetField(plhs[4],0,fnames[0],d_pi);         
            vars->y->copyIntoArray(mxGetPr(d_y));       //dual row eq
            mxSetField(plhs[4],0,fnames[1],d_y); 
            vars->phi->copyIntoArray(mxGetPr(d_phi));   //dual col upper
            mxSetField(plhs[4],0,fnames[2],d_phi);
            vars->gamma->copyIntoArray(mxGetPr(d_gam)); //dual col lower
            mxSetField(plhs[4],0,fnames[3],d_gam);
        }

        if(printLevel > 0){
            
            //Termination Detected
            if(err == SUCCESSFUL_TERMINATION)
                mexPrintf("\n *** SUCCESSFUL TERMINATION ***\n");
            else if(err == MAX_ITS_EXCEEDED)
                mexPrintf("\n *** MAXIMUM ITERATIONS REACHED ***\n");
            else if(err == INFEASIBLE)
                mexPrintf("\n *** TERMINATION: PROBABLY INFEASIBLE ***\n");
            else if(err == UNKNOWN)
                mexPrintf("\n *** TERMINATION: STATUS UNKNOWN ***\n");                        
            
            if(!err)
                mexPrintf(" Final Objective Value: %9.3g\n In %3.0f iterations\n",*fval,*iter);
            
            mexPrintf("------------------------------------------------------------------\n\n");
        }
        
         /* Free any scratch arrays */
        if( iru != NULL ) mxFree( iru ); iru = NULL;
        if( irl != NULL ) mxFree( irl ); irl = NULL;
        if( iub != NULL ) mxFree( iub ); iub = NULL;
        if( ilb != NULL ) mxFree( ilb ); ilb = NULL;   
        
        //Free int vectors
        if(iH_ir != NULL) mxFree(iH_ir); iH_ir = NULL; 
        if(iH_jc != NULL) mxFree(iH_jc); iH_jc = NULL; 
        if(iA_ir != NULL) mxFree(iA_ir); iA_ir = NULL; 
        if(iA_jc != NULL) mxFree(iA_jc); iA_jc = NULL; 
        if(iC_ir != NULL) mxFree(iC_ir); iC_ir = NULL; 
        if(iC_jc != NULL) mxFree(iC_jc); iC_jc = NULL; 
        
        //Free Local Copies
        if( qp_ru != NULL ) mxFree( qp_ru ); qp_ru = NULL;
        if( qp_rl != NULL ) mxFree( qp_rl ); qp_rl = NULL;
        if( qp_ub != NULL ) mxFree( qp_ub ); qp_ub = NULL;
        if( qp_lb != NULL ) mxFree( qp_lb ); qp_lb = NULL;
        
        //Free up classes
        if( qp != NULL) delete qp; qp = NULL;
        if( prob != NULL) delete prob; prob = NULL;
        if( vars != NULL) delete vars; vars = NULL;
        if( resid != NULL) delete resid; resid = NULL;
        if( s != NULL) delete s; s = NULL;
    }
    catch(exception& e) //Unfortunately still crashes matlab...
    {
        mexPrintf("Caught OOQP Error: %s",e.what());           
    }
    catch(...)
    {
        mexErrMsgTxt("Fatal OOQP Error");
    }
}


//Check all inputs for size and type errors
void checkInputs(const mxArray *prhs[], int nrhs)
{
    int i;
    double *beq;
    size_t ndec, nin, neq;
    
    //Correct number of inputs
    if(nrhs < 9)
        mexErrMsgTxt("You must supply at least 9 arguments to OOQP (H, f, A', rl, ru, Aeq', beq, lb, ub)");  

    //Check we have an objective
    if(mxIsEmpty(prhs[1]))
        mexErrMsgTxt("You must supply an objective function!");
    
    //Check we have some constraints
    if(mxIsEmpty(prhs[2]) && mxIsEmpty(prhs[5]) && mxIsEmpty(prhs[7]) && mxIsEmpty(prhs[8]))
        mexErrMsgTxt("You have not supplied any constraints!");
   
    //Check options is a structure
    if(nrhs > 9 && !mxIsStruct(prhs[9]))
        mexErrMsgTxt("The options argument must be a structure!");
    
    //Get Sizes
    ndec = mxGetM(prhs[1]);
    nin = mxGetN(prhs[2]); //remember transposed
    neq = mxGetN(prhs[5]); //remember transposed
    
    //Check Constraint Pairs
    if(nin && mxIsEmpty(prhs[3]))
        mexErrMsgTxt("rl is empty!");
    if(nin && mxIsEmpty(prhs[4]))
        mexErrMsgTxt("ru is empty!");
    
    //Check Sparsity (only supported in A, C and H)
    if(mxIsSparse(prhs[1]) || mxIsSparse(prhs[3]) || mxIsSparse(prhs[4]) || mxIsSparse(prhs[6]))
        mexErrMsgTxt("All vectors must be dense");
    if(!mxIsEmpty(prhs[0]) && !mxIsSparse(prhs[0]))
        mexErrMsgTxt("H must be a sparse matrix");
    if(!mxIsEmpty(prhs[2]) && !mxIsSparse(prhs[2]))
        mexErrMsgTxt("A must be a sparse matrix");
    if(!mxIsEmpty(prhs[5]) && !mxIsSparse(prhs[5]))
        mexErrMsgTxt("Aeq must be a sparse matrix");
    
    //Check Orientation
    if(mxGetM(prhs[1]) < mxGetN(prhs[1]))
        mexErrMsgTxt("f must be a column vector");
    if(mxGetM(prhs[3]) < mxGetN(prhs[3]))
        mexErrMsgTxt("rl must be a column vector");
    if(mxGetM(prhs[4]) < mxGetN(prhs[4]))
        mexErrMsgTxt("ru must be a column vector");
    if(mxGetM(prhs[7]) < mxGetN(prhs[7]))
        mexErrMsgTxt("lb must be a column vector");
    if(mxGetM(prhs[8]) < mxGetN(prhs[8]))
        mexErrMsgTxt("ub must be a column vector");
    
    //Check Sizes
    if(!mxIsEmpty(prhs[0]) && ((mxGetM(prhs[0]) != ndec) || (mxGetN(prhs[0]) != ndec)))
        mexErrMsgTxt("H has incompatible dimensions");
    if(nin) {
        if(mxGetM(prhs[2]) != ndec)
            mexErrMsgTxt("A has incompatible dimensions");
        if(mxGetM(prhs[3]) != nin)
            mexErrMsgTxt("rl has incompatible dimensions");
        if(mxGetM(prhs[4]) != nin)
            mexErrMsgTxt("ru has incompatible dimensions");
    }
    if(neq) {
        if(mxGetM(prhs[5]) != ndec)
            mexErrMsgTxt("Aeq has incompatible dimensions");
        if(mxGetM(prhs[6]) != neq)
            mexErrMsgTxt("beq has incompatible dimensions");
        //Check for infinite equalities
        beq = mxGetPr(prhs[6]);
        for(i=0;i<neq;i++) {
            if(mxIsInf(beq[i]) || mxIsNaN(beq[i]))
                mexErrMsgTxt("beq cannot contain Inf or NaN!");
        }
    }
    if(!mxIsEmpty(prhs[7]) && (mxGetM(prhs[7]) != ndec))
        mexErrMsgTxt("lb has incompatible dimensions");
    if(!mxIsEmpty(prhs[8]) && (mxGetM(prhs[8]) != ndec))
        mexErrMsgTxt("ub has incompatible dimensions");    
}

//Print Solver Information
void printSolverInfo()
{    
    mexPrintf("\n-----------------------------------------------------------\n");
    mexPrintf(" OOQP: Object Orientated Quadratic Programming [v%s]\n",OOQP_VERSION);              
    mexPrintf("  - Source available from: http://pages.cs.wisc.edu/~swright/ooqp/\n\n");
    
    mexPrintf(" This binary is statically linked to the following software:\n");
    mexPrintf("  - Intel Math Kernel Library [v%d.%d R%d]\n",__INTEL_MKL__,__INTEL_MKL_MINOR__,__INTEL_MKL_UPDATE__);

    mexPrintf("\n MEX Interface S.Wright [Modified by J.Currie 2013]\n");
    mexPrintf("-----------------------------------------------------------\n");
}
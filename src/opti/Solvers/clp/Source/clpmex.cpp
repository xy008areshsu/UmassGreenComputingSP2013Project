/* CLPMEX - A simple MEX Interface to CLP LP Solver
 * Copyright (C) Jonathan Currie 2012 (I2C2)
 */

#include "mex.h"
#include "Coin_C_defines.h"
#include "config_clp_default.h"
#include "config_coinutils_default.h"
#include "ClpSimplex.hpp"
#include "ClpPresolve.hpp"
#include "CoinModel.hpp"
#include "CoinMessageHandler.hpp"
#include "ClpEventHandler.hpp"
#include <exception>

using namespace std;

//Function Prototypes
void printSolverInfo();
void checkInputs(const mxArray *prhs[], int nrhs);
double getStatus(int stat);

//Ctrl-C Detection (Undocumented - Found in gurobi_mex.c!)
#ifdef __cplusplus
    extern "C" bool utIsInterruptPending();
    extern "C" void utSetInterruptPending(bool);
#else
    extern bool utIsInterruptPending();
    extern void utSetInterruptPending(bool);
#endif

//Message Handler
class DerivedHandler : public CoinMessageHandler {
public:
	virtual int print() ;
};
int DerivedHandler::print()
{
	mexPrintf(messageBuffer());
	mexPrintf("\n");
    mexEvalString("drawnow;"); //flush draw buffer
	return 0;
}

//Ctrl-C Event Handler
class DerivedEvent : public ClpEventHandler {
public:
     virtual int event(Event whichEvent);
     virtual ClpEventHandler * clone() const ;
};
int DerivedEvent::event(Event whichEvent)
{
    if (utIsInterruptPending()) {
        utSetInterruptPending(false); /* clear Ctrl-C status */
        mexPrintf("\nCtrl-C Detected. Exiting CLP...\n\n");
        return 5; //terminate asap
    }
    else
        return -1; //return ok
}
ClpEventHandler * DerivedEvent::clone() const
{
     return new DerivedEvent(*this);
}

//Main Function
void mexFunction(int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[])
{
    //Input Args
    double *f, *A, *rl, *ru, *lb = NULL, *ub = NULL, *H = NULL;
    
    //Return Args
    double *x, *fval, *exitflag, *iter;
    
    //Options
    int maxiter = 1500;
    int maxtime = 1000;
    int printLevel = 0;
    double primeTol = 1e-6;
    int debug = 0;
    
    //Internal Vars
    size_t ncon, ndec;
    size_t i, j, k;
    double *sol;
    int ii, no = 0, alb = 0, aub = 0;
    const char *fnames[2] = {"dual_row","dual_col"};
    mxArray *dRow, *dCol;
        
    //Sparse Indicing
    mwIndex *A_ir, *A_jc;
    mwIndex *H_ir, *H_jc;
    mwIndex startRow, stopRow;
    int *rowInd = NULL, *rows = NULL;
    CoinBigIndex *cols = NULL;
    
    if(nrhs < 1) {
        if(nlhs < 1)
            printSolverInfo();
        else
            plhs[0] = mxCreateString(CLP_VERSION);
        return;
    }        
    
    //Check Inputs
    checkInputs(prhs,nrhs); 
    
    //Get pointers to Input variables
	f = mxGetPr(prhs[0]);
	A = mxGetPr(prhs[1]); 
    A_ir = mxGetIr(prhs[1]);
    A_jc = mxGetJc(prhs[1]);
    rl = mxGetPr(prhs[2]);
    ru = mxGetPr(prhs[3]);
    lb = mxGetPr(prhs[4]); 
    ub = mxGetPr(prhs[5]);
    if(nrhs > 7) //optional quadratic part
        H = mxGetPr(prhs[7]);
    
    //Get Options if Specified
    if(nrhs > 6) {
    	if(mxGetField(prhs[6],0,"tolfun"))
            primeTol = *mxGetPr(mxGetField(prhs[6],0,"tolfun"));
        if(mxGetField(prhs[6],0,"maxiter"))
            maxiter = (int)*mxGetPr(mxGetField(prhs[6],0,"maxiter"));
        if(mxGetField(prhs[6],0,"maxtime"))
            maxtime = (int)*mxGetPr(mxGetField(prhs[6],0,"maxtime"));
        if(mxGetField(prhs[6],0,"display"))
            printLevel = (int)*mxGetPr(mxGetField(prhs[6],0,"display"));
        if(mxGetField(prhs[6],0,"debug"))
            debug = (int)*mxGetPr(mxGetField(prhs[6],0,"debug"));
    }
                
    //Get sizes
    ndec = mxGetM(prhs[0]);
    ncon = mxGetM(prhs[1]); 
    
    //Debug Print
    if(debug)
        mexPrintf("CLP Debug\nndec: %d, ncon: %d\n",ndec,ncon);
    
    //Create Outputs
    plhs[0] = mxCreateDoubleMatrix(ndec,1, mxREAL);
    plhs[1] = mxCreateDoubleMatrix(1,1, mxREAL);
    plhs[2] = mxCreateDoubleMatrix(1,1, mxREAL);
    plhs[3] = mxCreateDoubleMatrix(1,1, mxREAL);    
    x = mxGetPr(plhs[0]); 
    fval = mxGetPr(plhs[1]); 
    exitflag = mxGetPr(plhs[2]);    
    iter = mxGetPr(plhs[3]);
    //Optional Outputs
    if(nlhs > 4) {    
        plhs[4] = mxCreateStructMatrix(1,1,2,fnames);
        dRow = mxCreateDoubleMatrix(ncon,1, mxREAL);
        dCol = mxCreateDoubleMatrix(ndec,1, mxREAL);
    }
    
    try
    {
        //CLP Objects
        ClpSimplex simplex;
        ClpPresolve presolveInfo;
        CoinModel model;        
        DerivedHandler *mexprinter;   
        DerivedEvent *ctrlCEvent;
        
        //Create bounds if empty
        if(mxIsEmpty(prhs[4])) {
            lb = (double*)mxCalloc(ndec,sizeof(double)); alb=1;
            for(i=0;i<ndec;i++)
                lb[i] = -COIN_DBL_MAX;
        }
        if(mxIsEmpty(prhs[5])) {
            ub = (double*)mxCalloc(ndec,sizeof(double)); aub=1;
            for(i=0;i<ndec;i++)
                ub[i] = COIN_DBL_MAX;
        }
        
        //Add Linear Constraints
        if(ncon) {                    
            //Allocate Index Vector
            rowInd = (int*)mxCalloc(ncon,sizeof(int)); //set as max no of rows
            
            for(i = 0; i < ndec; i++) {
                startRow = A_jc[i];
                stopRow = A_jc[i+1];
                no = (int)(stopRow - startRow);
                if(no > 0) {
                    for(j = 0, k = startRow; k < stopRow; j++, k++) //build int32 row indicies
                        rowInd[j] = (int)A_ir[k];                
                }
                model.addColumn(no,rowInd,&A[startRow],lb[i],ub[i],f[i]);
            }
        }
        else {//just bounds
            for(ii=0;ii<ndec;ii++) {
                model.setObjective(ii,f[ii]);
                model.setColumnBounds(ii,lb[ii],ub[ii]);
            }
        }

        //Add Row Bounds
        for (ii = 0; ii < ncon; ii++)
        	model.setRowBounds(ii, rl[ii], ru[ii]);
        
        //Load Problem into solver
        simplex.loadProblem(model);
        
        //Add Quadratic Objective
        if(H && !mxIsEmpty(prhs[7])) {           
           H_ir = mxGetIr(prhs[7]);
           H_jc = mxGetJc(prhs[7]);
           //Convert Indicies
           mwIndex nzH = H_jc[ndec];
           rows = (int*)mxCalloc(nzH,sizeof(int));
           cols = (CoinBigIndex*)mxCalloc(ndec+1,sizeof(CoinBigIndex));
           //Assign Convert Data Type Vectors
           for(i = 0; i <= ndec; i++)
               cols[i] = (CoinBigIndex)H_jc[i];
           for(i = 0; i < nzH; i++)
               rows[i] = (int)H_ir[i];
           //Load QuadObj
           simplex.loadQuadraticObjective((int)ndec,cols,rows,H);             
        }

        //Set Options   
        simplex.setPrimalTolerance(primeTol);
        simplex.setDualTolerance(primeTol);
        simplex.setMaximumIterations(maxiter);
		simplex.setMaximumSeconds(maxtime);
        if(printLevel) {
            mexprinter = new DerivedHandler();
            mexprinter->setLogLevel(printLevel);
            simplex.passInMessageHandler(mexprinter);
        }
        //Add Event Handler for Ctrl+C
        ctrlCEvent = new DerivedEvent();      
        simplex.passInEventHandler(ctrlCEvent);    
                        
        //Perform Presolve (seems to crash?)
        //ClpSimplex *presolvedModel = presolveInfo.presolvedModel(simplex);
        
        //Solve using Primal Simplex
        if(H)
            simplex.primal();
        //Solve using Dual Simplex
        else
            simplex.dual();
            
        //Assign Return Arguments
        sol = simplex.primalColumnSolution();
        if(sol != NULL) {
            memcpy(x,sol,ndec*sizeof(double));
            *fval = simplex.objectiveValue();
            *exitflag = getStatus(simplex.status());
            *iter = simplex.numberIterations();
            //Assign Dual Solution
            if(nlhs > 4) {
                memcpy(mxGetPr(dRow),simplex.dualRowSolution(),ncon*sizeof(double));
                mxSetField(plhs[4],0,fnames[0],dRow);
                memcpy(mxGetPr(dCol),simplex.dualColumnSolution(),ndec*sizeof(double));
                mxSetField(plhs[4],0,fnames[1],dCol);
            }
        }
        
        //Clean up memory
        mxFree(rowInd);
        if(alb) mxFree(lb);
        if(aub) mxFree(ub);
        if(printLevel)
            delete mexprinter;
        //delete ctrlCEvent;
        if(rows) mxFree(rows);
        if(cols) mxFree(cols);
        
    }
    //Error Handling (still crashes Matlab though...)
    catch(CoinError e)
    {
        mexPrintf("Caught Coin Error: %s",e.message());
    }
    catch(exception& e)
    {
        mexPrintf("Caught CLP Error: %s",e.what());           
    }  
}               


//Check all inputs for size and type errors
void checkInputs(const mxArray *prhs[], int nrhs)
{
    size_t ndec, ncon;
    
    //Correct number of inputs
    if(nrhs < 6)
        mexErrMsgTxt("You must supply at least 6 arguments to clp (f, A, rl, ru, lb, ub)"); 
    
    //Check we have an objective
    if(mxIsEmpty(prhs[0]))
        mexErrMsgTxt("You must supply an objective function!");
    
    //Check we have some constraints
    if(mxIsEmpty(prhs[1]) && mxIsEmpty(prhs[4]) && mxIsEmpty(prhs[5]))
        mexErrMsgTxt("You have not supplied any constraints!");
   
    //Check options is a structure
    if(nrhs > 6 && !mxIsStruct(prhs[6]))
        mexErrMsgTxt("The options argument must be a structure!");
    
    //Get Sizes
    ndec = mxGetM(prhs[0]);
    ncon = mxGetM(prhs[1]);
    
    //Check Constraint Pairs
    if(ncon && mxIsEmpty(prhs[2]))
        mexErrMsgTxt("rl is empty!");
    if(ncon && mxIsEmpty(prhs[3]))
        mexErrMsgTxt("ru is empty!");
    
    //Check Sparsity (only supported in A and H)
    if(mxIsSparse(prhs[0]))
        mexErrMsgTxt("Only A is a sparse matrix");
    if(!mxIsSparse(prhs[1]))
        mexErrMsgTxt("A must be a sparse matrix");
    if(nrhs > 7 && !mxIsSparse(prhs[7]))
        mexErrMsgTxt("H must be a sparse matrix");
    
    //Check Orientation
    if(mxGetM(prhs[0]) < mxGetN(prhs[0]))
        mexErrMsgTxt("f must be a column vector");
    if(mxGetM(prhs[2]) < mxGetN(prhs[2]))
        mexErrMsgTxt("rl must be a column vector");
    if(mxGetM(prhs[3]) < mxGetN(prhs[3]))
        mexErrMsgTxt("ru must be a column vector");
    if(mxGetM(prhs[4]) < mxGetN(prhs[4]))
        mexErrMsgTxt("lb must be a column vector");
    if(mxGetM(prhs[5]) < mxGetN(prhs[5]))
        mexErrMsgTxt("ub must be a column vector");
    
    //Check Sizes
    if(ncon) {
        if(mxGetN(prhs[1]) != ndec)
            mexErrMsgTxt("A has incompatible dimensions");
        if(mxGetM(prhs[2]) != ncon)
            mexErrMsgTxt("rl has incompatible dimensions");
        if(mxGetM(prhs[3]) != ncon)
            mexErrMsgTxt("ru has incompatible dimensions");
    }
    if(!mxIsEmpty(prhs[4]) && (mxGetM(prhs[4]) != ndec))
        mexErrMsgTxt("lb has incompatible dimensions");
    if(!mxIsEmpty(prhs[5]) && (mxGetM(prhs[5]) != ndec))
        mexErrMsgTxt("ub has incompatible dimensions");    
    if(nrhs > 7 && !mxIsEmpty(prhs[7]) && ((mxGetM(prhs[7]) != ndec) || (mxGetN(prhs[7]) != ndec)))
        mexErrMsgTxt("H has incompatible dimensions");
}


//Convert exiflag to OPTI status
double getStatus(int stat)
{
    double ret = -1;

    switch(stat)
    {
        case 0: //looks optimal
            ret = 1;
            break;
        case 1: //looks infeasible
            ret = -1;
            break;
        case 3: //max iterations
            ret = 0;
            break;
        case 5: //user exit
            ret = -5;
            break;
        default: //inaccuracy / unbounded
            ret = -2;
            break;
    }
    return ret;
}  

//Print Solver Information
void printSolverInfo()
{    
    mexPrintf("\n-----------------------------------------------------------\n");
    mexPrintf(" CLP: COIN-OR Linear Programming [v%s]\n",CLP_VERSION);
    mexPrintf("  - Released under the Eclipse Public License: http://opensource.org/licenses/eclipse-1.0\n");
    mexPrintf("  - Source available from: https://projects.coin-or.org/Clp\n\n");
    
    mexPrintf(" This binary is statically linked to the following software:\n");
    mexPrintf("  - CoinUtils [v%s] (Eclipse Public License)\n",COINUTILS_VERSION);
    
    mexPrintf("\n MEX Interface J.Currie 2013 (www.i2c2.aut.ac.nz)\n");
    mexPrintf("-----------------------------------------------------------\n");
}
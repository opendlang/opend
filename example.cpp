// Posix instruction:
// 1. Remove local .dub folder
// rm -rf .dub
// 2. Compile the mir-optim with following flags
// dub build --build-mode=singleFile --build=better-c-release --compiler=ldmd2 --force
// 3. Compile and run example:
// g++ -std=c++14 example.cpp -L./ -lopenblas -lmir-optim && ./a.out
// Windows instruction: TODO

#include "mir_least_squares.h"

#include <stdio.h>
#include <vector>
#include <thread>
#include <iostream>
#include <functional>
#include <atomic>
#include <algorithm>

// Function context (optional)
struct F
{
    double scale;
};

// Jacobian context (optional)
struct G
{
    double scale;
};

// Function
void f(void* context, size_t m, size_t n, const double* x, double* y)
{
    F* ctx = (F*) context;
    y[0] = (x[0]) * ctx->scale;
    y[1] = (2 - x[1]) * ctx->scale;
}

///  Jacobian (optional)
void g(void* context, size_t m, size_t n, const double* x, double* J)
{
    F* ctx = (F*) context;
    J[0 * n + 0] = 1 * ctx->scale;
    J[0 * n + 1] = 0 * ctx->scale;
    J[1 * n + 0] = 0 * ctx->scale;
    J[1 * n + 1] = -1 * ctx->scale;
}

void printVector(const char* name, size_t n, const double* v)
{
    printf("%s =", name);
    for (size_t i = 0; i < n; ++i)
        printf(" %.2f", v[i]);
    printf("\n");
}

void threadManager(void*, size_t count, void* taskContext,
    void (*task)(void* context, size_t totalThreads, size_t threadId, size_t i))
{
    const size_t nthreads = std::min((size_t) std::thread::hardware_concurrency(), count);
    std::cout<<"parallel ("<<nthreads<<" threads)"<<std::endl;
    std::vector<std::thread> threads(nthreads);
    std::atomic_uint_least32_t index;
    index = 0;
    for(size_t t = 0; t < nthreads; t++)
    {
        threads[t] = std::thread(std::bind(
        [&](const size_t threadId)
            {
                for(uint i = index++; i < count; i = index++)
                    task(taskContext, nthreads, threadId, i);
            }, t));
    }
    std::for_each(threads.begin(),threads.end(),[](std::thread& x){x.join();});
}

void printReport(const LeastSquaresLMD& lm)
{
    printf("----- LM REPORT ------\n");
    printf("status: %s\n", mir_least_squares_lm_status_string((LeastSquaresLMStatus) lm.status));
    printf("lm.xConverged = %d\n", lm.xConverged);
    printf("lm.gConverged = %d\n", lm.gConverged);
    printf("lm.iterCt = %lu\n", lm.iterCt);
    printf("lm.fCalls = %lu\n", lm.fCalls);
    printf("lm.gCalls = %lu\n", lm.gCalls);
    if (lm.lower)
        printVector("lower bounds", lm.n, lm.lower);
    if (lm.upper)
        printVector("upper bounds", lm.n, lm.upper);
    printVector("x", lm.n, lm.x);
    printVector("y", lm.m, lm.y);
    printf("----------------------\n\n");
}

int main()
{
    LeastSquaresLMD lm;

    size_t m = 2;
    size_t n = 2;
    bool lowerBounds = true;
    bool upperBounds = true;
    // allocate memory using C's malloc
    // lm.x and lm.y are filled with NaN value,
    // lower is filled with -INF, and upper with +INF
    mir_least_squares_lm_stdc_alloc_d(&lm, m, n, lowerBounds, upperBounds);

    // init default params ...
    mir_least_squares_lm_init_params_d(&lm);
    // --  See D source code for actual defaults. --
    // for fields:
    // lm.tolX = 1e-8;
    // lm.tolG = 1e-12;
    // lm.lambda = 10;
    // lm.lambdaIncrease = 10;
    // lm.lambdaDecrease = 0.1;
    // lm.minStepQuality = 1e-3;
    // lm.goodStepQuality = 0.75;
    // lm.maxLambda = 1e16;
    // lm.minLambda = 1e-16;
    // lm.minDiagonal = 1e-6;
    // lm.jacobianEpsilon = T.epsilon.sqrt;

    lm.x[0] = 100;
    lm.x[1] = 100;
    
    F fCtx = {1.0};
    G gCtx = {1.0};
    mir_least_squares_lm_optimize_d(&lm, &fCtx, &f, &gCtx, &g, NULL, NULL);
    printReport(lm);

    mir_least_squares_lm_reset_d(&lm);
    lm.x[0] = 100;
    lm.x[1] = 100;
    lm.lower[0] = 4;
    mir_least_squares_lm_optimize_d(&lm, &fCtx, &f, NULL, NULL, NULL, NULL);
    printReport(lm);

    mir_least_squares_lm_reset_d(&lm);
    lm.x[0] = 100;
    lm.x[1] = -100;
    lm.lower[0] = 5;
    lm.upper[1] = 1.9;
    mir_least_squares_lm_optimize_d(&lm, &fCtx, &f, NULL, NULL, NULL, &threadManager);
    printReport(lm);

    mir_least_squares_lm_stdc_free_d(&lm);
    return 0;
}

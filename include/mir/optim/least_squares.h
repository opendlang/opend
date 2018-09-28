#ifdef __cplusplus
extern "C"
{
#endif

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

struct LeastSquaresLMD_S;
typedef struct LeastSquaresLMD_S LeastSquaresLMD;
typedef struct LeastSquaresLMS_S LeastSquaresLMS;
typedef int lapackint;

typedef enum LeastSquaresLMStatus_E
{
    success = 0,
    badBounds = -32,
    badGuess,
    badMinStepQuality,
    badGoodStepQuality,
    badStepQuality,
    badLambdaParams
} LeastSquaresLMStatus;

typedef void (*LeastSquaresLMFunctionS)(void* context, size_t m, size_t n, const float* x, float* y);
typedef void (*LeastSquaresLMFunctionD)(void* context, size_t m, size_t n, const double* x, double* y);

typedef void (*LeastSquaresLMJacobianS)(void* context, size_t m, size_t n, const float* x, float* J);
typedef void (*LeastSquaresLMJacobianD)(void* context, size_t m, size_t n, const double* x, double* J);

typedef void (*LeastSquaresThreadManagerFunction)(
    void* context,
    size_t count,
    void* taskContext,
    void (*task)(
        void* context,
        size_t totalThreads,
        size_t treadId,
        size_t i));

const char* mir_least_squares_lm_status_string(LeastSquaresLMStatus st);

void mir_least_squares_lm_reset_s(LeastSquaresLMS* lm);
void mir_least_squares_lm_reset_d(LeastSquaresLMD* lm);

void mir_least_squares_lm_init_params_s(LeastSquaresLMS* lm);
void mir_least_squares_lm_init_params_d(LeastSquaresLMD* lm);

void mir_least_squares_lm_stdc_alloc_s(LeastSquaresLMS* lm, size_t m, size_t n, bool lowerBounds, bool upperBounds);
void mir_least_squares_lm_stdc_alloc_d(LeastSquaresLMD* lm, size_t m, size_t n, bool lowerBounds, bool upperBounds);

void mir_least_squares_lm_stdc_free_s(LeastSquaresLMS* lm);
void mir_least_squares_lm_stdc_free_d(LeastSquaresLMD* lm);

LeastSquaresLMStatus mir_least_squares_lm_optimize_s
    (
        LeastSquaresLMS* lm,
        void* fContext,
        LeastSquaresLMFunctionS f,
        void* gContext,
        LeastSquaresLMJacobianS g,
        void* tmContext,
        LeastSquaresThreadManagerFunction tm
    );
LeastSquaresLMStatus mir_least_squares_lm_optimize_d
    (
        LeastSquaresLMD* lm,
        void* fContext,
        LeastSquaresLMFunctionD f,
        void* gContext,
        LeastSquaresLMJacobianD g,
        void* tmContext,
        LeastSquaresThreadManagerFunction tm
    );

struct LeastSquaresLMS_S
{
    float* lower;
    float* upper;
    float* x;
    float* deltaX;
    float* deltaXBase;
    float* mJy;
    lapackint* ipiv;
    float* y;
    float* mBuffer;
    float* nBuffer;
    float* JJ;
    float* J;
    size_t work_length;
    float* work;

    size_t m;
    size_t n;

    size_t maxIter;
    float tolX;
    float tolG;
    float maxGoodResidual;
    float lambda;
    float lambdaIncrease;
    float lambdaDecrease;
    float minStepQuality;
    float goodStepQuality;
    float maxLambda;
    float minLambda;
    float jacobianEpsilon;

    size_t iterCt;
    size_t fCalls;
    size_t gCalls;
    float residual;
    uint32_t maxAge;
    LeastSquaresLMStatus_E status;
    bool xConverged;
    bool gConverged;
};

struct LeastSquaresLMD_S
{
    double* lower;
    double* upper;
    double* x;
    double* deltaX;
    double* deltaXBase;
    double* mJy;
    lapackint* ipiv;
    double* y;
    double* mBuffer;
    double* nBuffer;
    double* JJ;
    double* J;
    size_t work_length;
    double* work;

    size_t m;
    size_t n;

    size_t maxIter;
    double tolX;
    double tolG;
    double maxGoodResidual;
    double lambda;
    double lambdaIncrease;
    double lambdaDecrease;
    double minStepQuality;
    double goodStepQuality;
    double maxLambda;
    double minLambda;
    double jacobianEpsilon;

    size_t iterCt;
    size_t fCalls;
    size_t gCalls;
    double residual;
    uint32_t maxAge;
    LeastSquaresLMStatus_E status;
    bool xConverged;
    bool gConverged;
};

#ifdef __cplusplus
}
#endif

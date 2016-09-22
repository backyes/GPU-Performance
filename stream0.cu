#include <stdio.h>
#include <pthread.h>

const int N = 1 << 27;

__global__ void kernel(float *x, int n)
{
    int tid = threadIdx.x + blockIdx.x * blockDim.x;
    for (int i = tid; i < n; i += blockDim.x * gridDim.x) {
        x[i] = sqrt(pow(3.14159,i));
    }
}

void *thread(void *args)
{
    int * thread_data = (int*) args;
    const int num_streams = 8;

    cudaStream_t streams[num_streams];
    float *data[num_streams];

    int deviceNum; 
    cudaError_t ret = cudaGetDeviceCount(&deviceNum);
    ret = cudaSetDevice(*thread_data);
    printf("device num: %d\n", *thread_data);

    for (int i = 0; i < num_streams; i++) {
        cudaStreamCreate(&streams[i]);
 
        cudaError_t  ret0 = cudaMalloc(&data[i], N * sizeof(float));

        if (ret0 != cudaSuccess) {
           printf("allocate failed\n");
           return 0;
        } else {
           printf("%d MB\n", N*sizeof(float)/1024/1024);
        }

        // launch one worker kernel per stream
        kernel<<<1, 64, 0, streams[i]>>>(data[i], N);

        // launch a dummy kernel on the default stream
        kernel<<<1, 1>>>(0, 0);

        printf("finished stream syn %d\n", i);
    }

    printf("finished all stream %d\n");
    cudaDeviceReset();
    printf("finished device reset %d\n");

    return 0;
}

int main() {
  pthread_t threads[4];

  int thread_data[4];
  for(int t=0;t<4;t++){

    printf("In main: creating thread %ld\n", t);
    thread_data[t] = t;
    int rc = pthread_create(&threads[t], NULL, thread, &thread_data[t]);
    if (rc){

      printf("ERROR; return code from pthread_create() is %d\n", rc);
      exit(-1);
    }
  }

  for(int i = 0; i < 4; i++) 
    pthread_join(threads[i], NULL);

  /* Last thing that main() should do */
  pthread_exit(NULL);
}

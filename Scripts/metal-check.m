#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <CoreGraphics/CoreGraphics.h>
#include <unistd.h>
int main(void) {
    @autoreleasepool {
        CGDisplayModeRef mode = CGDisplayCopyDisplayMode(CGMainDisplayID());
        if (mode) {
            printf("Main display: %zux%zu; reported refresh %.3f Hz\n", CGDisplayModeGetPixelWidth(mode), CGDisplayModeGetPixelHeight(mode), CGDisplayModeGetRefreshRate(mode));
            CGDisplayModeRelease(mode);
        }
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) { fprintf(stderr,"FAIL: no Metal device\n"); return 2; }
        printf("Metal device: %s\n", device.name.UTF8String);
        NSString *src = @"#include <metal_stdlib>\nusing namespace metal;\nkernel void verify_gpu(device const uint *a [[buffer(0)]], device uint *b [[buffer(1)]], uint i [[thread_position_in_grid]]) { if(i<256) b[i]=a[i]*3u+7u; }";
        NSError *error = nil;
        id<MTLLibrary> lib = [device newLibraryWithSource:src options:nil error:&error];
        if (!lib) { fprintf(stderr,"FAIL: MSL compilation: %s\n",error.description.UTF8String); return 3; }
        id<MTLFunction> function = [lib newFunctionWithName:@"verify_gpu"];
        id<MTLComputePipelineState> pipeline = [device newComputePipelineStateWithFunction:function error:&error];
        if (!pipeline) { fprintf(stderr,"FAIL: pipeline: %s\n",error.description.UTF8String); return 3; }
        id<MTLCommandQueue> queue = [device newCommandQueue];
        id<MTLBuffer> a = [device newBufferWithLength:256*sizeof(uint32_t) options:MTLResourceStorageModeShared];
        id<MTLBuffer> b = [device newBufferWithLength:256*sizeof(uint32_t) options:MTLResourceStorageModeShared];
        if (!queue || !a || !b) { fprintf(stderr,"FAIL: allocation\n"); return 4; }
        for (unsigned i=0; i<256; ++i) { ((uint32_t *)a.contents)[i]=i; ((uint32_t *)b.contents)[i]=0xdeadbeef; }
        id<MTLCommandBuffer> cmd = [queue commandBuffer];
        id<MTLComputeCommandEncoder> enc = [cmd computeCommandEncoder];
        if (!cmd || !enc) { fprintf(stderr,"FAIL: command creation\n"); return 4; }
        [enc setComputePipelineState:pipeline]; [enc setBuffer:a offset:0 atIndex:0]; [enc setBuffer:b offset:0 atIndex:1];
        [enc dispatchThreads:MTLSizeMake(256,1,1) threadsPerThreadgroup:MTLSizeMake(MIN((NSUInteger)64,pipeline.maxTotalThreadsPerThreadgroup),1,1)];
        [enc endEncoding]; [cmd commit];
        unsigned ticks=0;
        while (cmd.status!=MTLCommandBufferStatusCompleted && cmd.status!=MTLCommandBufferStatusError && ticks++<500) usleep(10000);
        if (cmd.status!=MTLCommandBufferStatusCompleted) { fprintf(stderr,"FAIL: GPU command status %lu: %s\n",(unsigned long)cmd.status,cmd.error.description.UTF8String); return 5; }
        for (unsigned i=0; i<256; ++i) if (((uint32_t *)b.contents)[i]!=i*3+7) { fprintf(stderr,"FAIL: result %u\n",i); return 6; }
        puts("PASS: MSL compiled, GPU command completed, all 256 results correct.");
        return 0;
    }
}

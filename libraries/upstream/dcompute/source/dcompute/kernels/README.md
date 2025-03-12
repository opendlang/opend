Algorithms
==========

Adjacent

Example use
===========

Ideally we want to be able to do something like
```D
with(kernelLaunchConfig(...)) //includes the Queue to launch on and any any other info
    T val = hostrange.array
            .transfer // transfer to device. parameters in config
            .exclusice_scan!add
            .inner_product(someOtherDeviceArray)
            .mapReduce(map_func,reduce_op)
            .retrieve;
```
and

```D
with(kernelLaunchConfig(...)) //includes the Queue device allocator to launch on and any any other info
    Event e = hostrange.array
                .transfer // transfer to device. parameters in config
                .exclusice_scan!add
                .inner_product(someOtherDeviceArray);
ErrorCode ec = e.waitAndYeild(); //play nice with fibres/threads.
```
and have the pipeline be async and return an event/error.

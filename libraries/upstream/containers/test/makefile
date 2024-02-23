.PHONY: test graphs clean

DC?=dmd
SRC:=$(shell find ../src/ -name "*.d")

ifeq ($(DC), ldc2)
  FLAGS:=-unittest -main -g -cov -I../src/ -d-debug -wi
  hashmap_gc_test_FLAGS:=-g -O3 -d-debug -wi
  looptest_FLAGS:=-O3
else
  FLAGS:=-unittest -main -g -cov -I../src/ -debug -wi
  hashmap_gc_test_FLAGS:=-g -inline -O -release -debug -wi
  looptest_FLAGS:=-inline -O -release
endif
FLAGS32:=$(FLAGS) -m32

all_arch:=
ifeq ($(OS), Windows_NT)
	all_arch += all_32 all_64
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S), Linux)
		all_arch += all_32 all_64
	else
		all_arch += all_64
	endif
endif

all: $(all_arch)

all_64: test compile_test external_allocator_test hashmap_gc_test
	./tests
	./compile_test
	./external_allocator_test
	./hashmap_gc_test

all_32: test_32 compile_test_32 external_allocator_test_32
	./tests_32
	./compile_test_32
	./external_allocator_test_32

test: $(SRC)
	$(DC) $(FLAGS) $(SRC) -oftests
test_32: $(SRC)
	$(DC) $(FLAGS32) $(SRC) -oftests_32

compile_test: compile_test.d $(SRC)
	$(DC) $(FLAGS) compile_test.d $(SRC) -ofcompile_test
compile_test_32: compile_test.d $(SRC)
	$(DC) $(FLAGS32) compile_test.d $(SRC) -ofcompile_test_32

external_allocator_test: external_allocator_test.d $(SRC)
	$(DC) $(FLAGS) external_allocator_test.d $(SRC) -ofexternal_allocator_test
external_allocator_test_32: external_allocator_test.d $(SRC)
	$(DC) $(FLAGS32) external_allocator_test.d $(SRC) -ofexternal_allocator_test_32

looptest: looptest.d
	$(DC) looptest.d $(looptest_FLAGS) \
		../src/memory/allocators.d \
		../src/containers/ttree.d \
		../src/containers/internal/node.d \
		-I../src/ \

hashmap_gc_test: hashmap_gc_test.d $(SRC)
	$(DC) $(hashmap_gc_test_FLAGS) \
		-I../src/ \
		$(SRC) \
		hashmap_gc_test.d \
		-ofhashmap_gc_test

clean:
	rm -f tests
	rm -f *.o
	rm -f *.dot
	rm -f *.png
	rm -f ..*.lst
	rm -f looptest

graphs: clean
	$(DC) $(FLAGS) $(SRC) -oftests -version=graphviz_debugging
	-./tests
	parallel "dot -Tpng {} > {.}.png" ::: graph*.dot

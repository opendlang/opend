include ../common.mak

TESTS=stderr_msg unittest_assert invalid_memory_operation unknown_gc static_dtor \
      future_message refcounted rt_trap_exceptions_drt catch_in_finally \
      message_with_null

ifeq ($(OS)-$(BUILD),linux-debug)
    TESTS+=line_trace line_trace_21656 long_backtrace_trunc rt_trap_exceptions cpp_demangle
    LINE_TRACE_DFLAGS:=-L--export-dynamic
endif
ifeq ($(OS),linux)
    TESTS+=rt_trap_exceptions_drt_gdb
endif
ifeq ($(OS)-$(BUILD),freebsd-debug)
    TESTS+=line_trace line_trace_21656 long_backtrace_trunc cpp_demangle
    LINE_TRACE_DFLAGS:=-L--export-dynamic
endif
ifeq ($(OS)-$(BUILD),dragonflybsd-debug)
    TESTS+=line_trace line_trace_21656 long_backtrace_trunc cpp_demangle
    LINE_TRACE_DFLAGS:=-L--export-dynamic
endif
ifeq ($(OS)-$(BUILD),osx-debug)
    TESTS+=line_trace line_trace_21656 cpp_demangle
    LINE_TRACE_DFLAGS:=
endif
ifeq ($(OS)-$(BUILD),windows-debug)
    TESTS+=winstack
endif

ifeq ($(BUILD),debug)
    TESTS+=assert_fail
endif

DIFF:=diff
SED:=sed
GDB:=gdb

.PHONY: all clean
all: $(addprefix $(ROOT)/,$(addsuffix .done,$(TESTS)))
ifeq ($(OS),linux)
    TESTS+=line_trace line_trace_21656 long_backtrace_trunc rt_trap_exceptions cpp_demangle \
		   memoryerror_null_read memoryerror_null_write memoryerror_null_call memoryerror_stackoverflow
    line_trace_dflags:=-L--export-dynamic
endif

ifeq ($(OS),linux)
# Only add this test if gdb is available.
    ifneq (,$(shell which $(GDB) > /dev/null 2>&1 && echo 1))
	TESTS+=rt_trap_exceptions_drt_gdb
    endif
endif

ifeq ($(OS),freebsd)
    TESTS+=line_trace line_trace_21656 long_backtrace_trunc cpp_demangle
    line_trace_dflags:=-L--export-dynamic
endif
ifeq ($(OS),dragonflybsd)
    TESTS+=line_trace line_trace_21656 long_backtrace_trunc cpp_demangle
    line_trace_dflags:=-L--export-dynamic
endif
ifeq ($(OS),osx)
    TESTS+=line_trace line_trace_21656 cpp_demangle
    line_trace_dflags:=
endif
ifeq ($(OS)-$(BUILD),windows-debug)
    TESTS+=winstack
endif
include ../common.mak

$(ROOT)/line_trace.done: $(ROOT)/line_trace$(DOTEXE)
	@echo Testing line_trace
	$(QUIET)$(TIMELIMIT)$(ROOT)/line_trace $(RUN_ARGS) > $(ROOT)/line_trace.output
	# Use sed to canonicalize line_trace.output and compare against expected output in line_trace.exp
	$(QUIET)$(SED) "s|^.*/src/|src/|g; s/\[0x[0-9a-f]*\]/\[ADDR\]/g; s/scope //g; s/Nl//g" $(ROOT)/line_trace.output | $(DIFF) line_trace.exp -
	@rm -f $(ROOT)/line_trace.output
	@touch $@

# https://issues.dlang.org/show_bug.cgi?id=21656
$(ROOT)/line_trace_21656.done: $(ROOT)/line_trace$(DOTEXE)
	@echo Testing line_trace_21656
	@mkdir -p $(ROOT)/line_trace_21656
	@touch $(ROOT)/line_trace_21656/line_trace
	$(QUIET)cd $(ROOT)/line_trace_21656 && PATH="..:$$PATH" $(TIMELIMIT)line_trace $(RUN_ARGS) > line_trace.output
	$(QUIET)$(SED) "s|^.*/src/|src/|g; s/\[0x[0-9a-f]*\]/\[ADDR\]/g; s/scope //g; s/Nl//g" $(ROOT)/line_trace_21656/line_trace.output | $(DIFF) line_trace.exp -
	@rm -rf $(ROOT)/line_trace_21656
	@touch $@

$(ROOT)/long_backtrace_trunc.done: $(ROOT)/long_backtrace_trunc$(DOTEXE)
	@echo Testing long_backtrace_trunc
	$(QUIET)$(TIMELIMIT)$(ROOT)/long_backtrace_trunc $(RUN_ARGS) > $(ROOT)/long_backtrace_trunc.output
	# Use sed to canonicalize long_backtrace_trunc.output and compare against expected output in long_backtrace_trunc.exp
	$(QUIET)$(SED) "s|^.*/src/|src/|g; s/\[0x[0-9a-f]*\]/\[ADDR\]/g; s/scope //g; s/Nl//g" $(ROOT)/long_backtrace_trunc.output | $(DIFF) long_backtrace_trunc.exp -
	@rm -f $(ROOT)/long_backtrace_trunc.output
	@touch $@

$(ROOT)/chain.done: $(ROOT)/chain$(DOTEXE)
	@echo Testing chain
	$(QUIET)$(TIMELIMIT)$(ROOT)/chain $(RUN_ARGS) > $(ROOT)/chain.output
	@rm -f $(ROOT)/chain.output
	@touch $@

$(ROOT)/winstack.done: $(ROOT)/winstack$(DOTEXE)
	@echo Testing winstack
	$(QUIET)$(TIMELIMIT)$(ROOT)/winstack $(RUN_ARGS)
	@touch $@

$(ROOT)/stderr_msg.done: stderr_exp="stderr_msg msg"
$(ROOT)/unittest_assert.done: stderr_exp="unittest_assert msg"
$(ROOT)/invalid_memory_operation.done: stderr_exp="InvalidMemoryOperationError"
$(ROOT)/unknown_gc.done: stderr_exp="'unknowngc'"
$(ROOT)/static_dtor.done: stderr_exp="dtor_called_more_than_once"
$(ROOT)/static_dtor.done: private negate=!
$(ROOT)/future_message.done: stderr_exp="exception I have a custom message. exception exception "
$(ROOT)/catch_in_finally.done: stderr_exp="success."
$(ROOT)/rt_trap_exceptions.done: stderr_exp="object.Exception@src/rt_trap_exceptions.d(12): this will abort"
$(ROOT)/rt_trap_exceptions.done: stderr_exp2="src/rt_trap_exceptions.d:8 main"
$(ROOT)/assert_fail.done: stderr_exp="success."
$(ROOT)/cpp_demangle.done: stderr_exp="thrower(int)"
$(ROOT)/message_with_null.done: stderr_exp=" world"
$(ROOT)/memoryerror_null_read.done: stderr_exp="segmentation fault: null pointer read/write operation"
$(ROOT)/memoryerror_null_write.done: stderr_exp="segmentation fault: null pointer read/write operation"
$(ROOT)/memoryerror_null_call.done: stderr_exp="segmentation fault: null pointer read/write operation"
$(ROOT)/memoryerror_null_call.done: stderr_exp2="uncaught exception reached top of stack"
$(ROOT)/memoryerror_stackoverflow.done: stderr_exp="segmentation fault: call stack overflow"

$(ROOT)/%.done: $(ROOT)/%$(DOTEXE)
	@echo Testing $*
	$(QUIET)$(TIMELIMIT)$(ROOT)/$* $(RUN_ARGS) 2>$(ROOT)/$*.stderr || true

	@if $(NEGATE) grep -qF $(STDERR_EXP) < $(ROOT)/$*.stderr ; then true ; else  \
		echo 'Searched for pattern $(STDERR_EXP), NEGATE = $(NEGATE)' ;\
		tail --bytes=5000 $(ROOT)/$*.stderr ;\
		exit 1 ;\
	fi
	@if [ ! -z $(STDERR_EXP2) ] ; then \
		if $(NEGATE) grep -qF $(STDERR_EXP2) < $(ROOT)/$*.stderr ; then true ; else \
			echo 'Searched for '$(STDERR_EXP2)' NEGATE = $(NEGATE)' ;\
			tail --bytes=5000 $(ROOT)/$*.stderr ;\
			exit 1 ;\
		fi \
	fi
	@touch $@

$(ROOT)/rt_trap_exceptions_drt.done: STDERR_EXP="uncaught exception\nobject.Exception@rt_trap_exceptions_drt.d(4): exception"
$(ROOT)/rt_trap_exceptions_drt.done: RUN_ARGS="--DRT-trapExceptions=0"
$(ROOT)/rt_trap_exceptions_drt.done: NEGATE=!


$(ROOT)/rt_trap_exceptions_drt_gdb.done: $(ROOT)/rt_trap_exceptions_drt$(DOTEXE)
	@echo Testing rt_trap_exceptions_drt_gdb
	$(QUIET)$(TIMELIMIT) $(GDB) -n -ex 'set confirm off' -ex run -ex 'bt full' -ex q --args $< --DRT-trapExceptions=0 \
		> $(ROOT)/rt_trap_exceptions_drt_gdb.output 2>&1 || true
	cat $(ROOT)/rt_trap_exceptions_drt_gdb.output
	grep "\(D main\|_Dmain\) (args=...) at .*rt_trap_exceptions_drt.d:9" > /dev/null < $(ROOT)/rt_trap_exceptions_drt_gdb.output
	grep 'myLocal' > /dev/null < $(ROOT)/rt_trap_exceptions_drt_gdb.output
	! grep "No stack." > /dev/null < $(ROOT)/rt_trap_exceptions_drt_gdb.output
	@touch $@

$(ROOT)/refcounted.done: $(ROOT)/refcounted$(DOTEXE)
	$(QUIET) $<
	@touch $@

ifneq (,$(findstring ldmd,$(DMD)))
# LDC: Make sure allocation intended to provoke exception is not elided.
$(ROOT)/invalid_memory_operation$(DOTEXE): DFLAGS+=-disable-gc2stack
endif
$(ROOT)/unittest_assert$(DOTEXE): DFLAGS+=-unittest -version=CoreUnittest
$(ROOT)/line_trace$(DOTEXE): DFLAGS+=$(LINE_TRACE_DFLAGS)
$(ROOT)/long_backtrace_trunc$(DOTEXE): DFLAGS+=$(LINE_TRACE_DFLAGS)
$(ROOT)/rt_trap_exceptions$(DOTEXE): DFLAGS+=$(LINE_TRACE_DFLAGS)
$(ROOT)/rt_trap_exceptions_drt$(DOTEXE): DFLAGS+=-g
$(ROOT)/refcounted$(DOTEXE): DFLAGS+=-dip1008
$(ROOT)/cpp_demangle$(DOTEXE): DFLAGS+=-L-lstdc++ $(LINE_TRACE_DFLAGS)

$(ROOT)/%$(DOTEXE): $(SRC)/%.d $(DMD) $(DRUNTIME)
	$(QUIET)$(DMD) $(DFLAGS) -of$@ $<

clean:
	rm -rf $(GENERATED)

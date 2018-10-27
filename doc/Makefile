###########################################################
# This file builds the cpuid documentation.
###########################################################

# tags
LATEST:=$(git describe --abbrev=0 --tags | tr -d v)

# binaries
DMD=dmd
RDMD=rdmd
DDOC=$(DMD) -w -c -o- -version=StdDdoc

# folders
DOC_OUTPUT_DIR=web
DOC_SOURCE_DIR=doc
GENERATED=.generated
CPUID_DIR=source
CORE_DIR=mir-core/source
DLANGORG_DIR=$(DOC_SOURCE_DIR)/dlang.org

###########################################################
# setup packages
##########################################################

# Packages in cpuid. Just mention the package name here. The contents of package
# xy/zz is in variable PACKAGE_xy_zz. This allows automation in iterating
# packages and their modules.
CPUID_PACKAGES = cpuid
#$(addprefix cpuid/,\ amd intel x86_any)

PACKAGE_cpuid = unified common x86_any intel amd
#PACKAGE_cpuid_blas = package dot gemm gemv

#MOD_EXCLUDES=$(addprefix --ex=, cpuid.internal)

###########################################################
# Setup macros + generate dynamic info needed
###########################################################

all: html

DLANGORG_MACROS=$(addprefix $(DLANGORG_DIR)/, macros html dlang.org)
STDDOC=$(addsuffix .ddoc, ${DLANGORG_MACROS} ${GENERATED}/${LATEST} $(DLANGORG_DIR)/std $(DOC_SOURCE_DIR)/custom ${GENERATED}/cpuid) $(NODATETIME)

${GENERATED}/${LATEST}.ddoc :
	mkdir -p $(dir $@)
	echo "LATEST=${LATEST}" >$@

${GENERATED}/cpuid.ddoc : $(DOC_SOURCE_DIR)/gen_modlist.d $(CPUID_DIR)
	mkdir -p $(dir $@)
	$(RDMD) $< $(CPUID_DIR) $(MOD_EXCLUDES) >$@

###########################################################
# Makefile bootstrapping
# It's mostly about the conversion from cpuid.foo -> cpuid_foo
###########################################################

# Given one or more packages, returns the modules they contain
P2MODULES=$(foreach P,$1,$(addprefix $P/,$(PACKAGE_$(subst /,_,$P))))
CPUID_MODULES=$(call P2MODULES,$(CPUID_PACKAGES))
SRC_DOCUMENTABLES = index.d $(addsuffix .d,$(CPUID_MODULES))

# D file to html, e.g. cpuid/combinatorics -> cpuid_combinatorics.html
# But "package.d" is special cased: std/range/package.d -> std_range.html
D2HTML=$(foreach p,$1,$(if $(subst package.d,,$(notdir $p)),$(subst /,_,$(subst .d,.html,$p)),$(subst /,_,$(subst /package.d,.html,$p))))

HTMLS=$(addprefix $(DOC_OUTPUT_DIR)/, \
	$(call D2HTML, $(SRC_DOCUMENTABLES)))

$(DOC_OUTPUT_DIR)/. :
	mkdir -p $@

# everything except index.d needs a source path
ADDSOURCE=$(if $(subst index.d,,$1),$(CPUID_DIR)/$1,$1)

# For each module, define a rule e.g.:
# ../web/phobos/std_conv.html : std/conv.d $(STDDOC) ; ...
$(foreach p,$(SRC_DOCUMENTABLES),$(eval \
$(DOC_OUTPUT_DIR)/$(call D2HTML,$p) : $(call ADDSOURCE,$p) $(STDDOC) ;\
  $(DDOC) $(STDDOC) -I$(CPUID_DIR) -I$(CORE_DIR) -Df$$@ $$<))

###########################################################
# Setup all other resources needed by dlang.org
###########################################################

#%IMAGES=images/cpuid.svg favicon.ico
IMAGES=

JAVASCRIPT=$(addsuffix .js, $(addprefix js/, \
	dlang ddox listanchors run run-main-website jquery-1.7.2.min))

STYLES=$(addsuffix .css, $(addprefix css/, \
	style print custom ))

ALL_FILES = $(addprefix $(DOC_OUTPUT_DIR)/, \
	$(STYLES) $(IMAGES) $(JAVASCRIPT))

$(DOC_OUTPUT_DIR)/css/custom.css: $(DOC_SOURCE_DIR)/custom.css
	@mkdir -p $(dir $@)
	cp $< $@

$(DOC_OUTPUT_DIR)/% : $(DLANGORG_DIR)/%
	@mkdir -p $(dir $@)
	cp $< $@

html : $(DOC_OUTPUT_DIR)/. $(HTMLS) $(ALL_FILES)

clean:
	rm -rf $(DOC_OUTPUT_DIR)
	rm -rf $(GENERATED)

# prints the listed modules and sources
debug:
	@echo $(SRC_DOCUMENTABLES)
	@echo $(STDDOC)

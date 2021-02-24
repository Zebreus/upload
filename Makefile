BUILD_DIR := build
LIB_DIR := libs
SRC_DIR := src

# Upload will load plugins from here
INSTALL_PLUGIN_DIR := $(abspath $(BUILD_DIR))

WARNING_FLAGS := -pedantic -Wall -Wextra -Wcast-align -Wcast-qual -Wctor-dtor-privacy -Wdisabled-optimization -Wformat=2 -Winit-self -Wlogical-op -Wmissing-declarations -Wmissing-include-dirs -Wnoexcept -Wold-style-cast -Woverloaded-virtual -Wredundant-decls -Wshadow -Wsign-conversion -Wsign-promo -Wstrict-null-sentinel -Wstrict-overflow=5 -Wswitch-default -Wundef -Werror -Wno-unused

CXX=g++
MKDIR := mkdir -p
MAKEOVERRIDES += CXX:=$(CXX)
MAKEOVERRIDES += MKDIR:=$(MKDIR)

export COMMON_CXX_FLAGS :=  -std=c++2a -O3 $(WARNING_FLAGS)
export COMMON_LD_FLAGS :=  -std=c++2a -O3 $(WARNING_FLAGS)

TARGETS_DIR = targets
TARGETS_BUILD_DIR = ../../$(BUILD_DIR)
TARGETS += nullpointer transfersh oshi
STATIC_TARGET_LIBS = $(TARGETS:%=$(BUILD_DIR)/lib%.a)
SHARED_TARGET_LIBS = $(TARGETS:%=$(BUILD_DIR)/lib%.so)

# TODO improve this
# If set to yeah, the targets are build as shared libraries
DYNAMIC := yeah

UPLOAD := upload
INCLUDE_DIRS += include
INCLUDE_DIRS += $(LIB_DIR)/cxxopts/include
INCLUDE_DIRS += $(LIB_DIR)/miniz-cpp
INCLUDE_DIRS += $(SRC_DIR)
INCLUDE_FLAGS := $(INCLUDE_DIRS:%=-I%)
CXX_FLAGS := $(COMMON_CXX_FLAGS) $(INCLUDE_FLAGS) -MMD -MP -pthread -DUPLOAD_PLUGIN_DIR=$(INSTALL_PLUGIN_DIR)
LD_FLAGS := $(COMMON_LD_FLAGS) -pthread -lcrypto -lssl 
SRCS := $(wildcard $(SRC_DIR)/*.cpp)
OBJS := $(SRCS:%=$(BUILD_DIR)/%.o)

DEPS := $(OBJS:.o=.d)

all: $(BUILD_DIR)/$(UPLOAD)

ifeq ($(DYNAMIC),yeah)

# dynamic loading
LD_FLAGS += -ldl -rdynamic

$(BUILD_DIR)/$(UPLOAD): $(OBJS) $(SHARED_TARGET_LIBS)
	$(CXX) $(OBJS) -o $@ $(LD_FLAGS)

else

# static linking
LD_FLAGS += $(STATIC_TARGET_LIBS)
CXX_FLAGS += $(TARGETS:%=-I$(TARGETS_DIR)/%)
CXX_FLAGS += -DSTATIC_LOADER

$(BUILD_DIR)/$(UPLOAD): $(OBJS) $(STATIC_TARGET_LIBS)
	$(CXX) $(OBJS) -o $@ $(LD_FLAGS)

endif

# c++ source
$(OBJS): $(BUILD_DIR)/%.cpp.o: %.cpp
	$(MKDIR) $(dir $@)
	$(CXX) $(CXX_FLAGS) -c $< -o $@

$(STATIC_TARGET_LIBS): $(BUILD_DIR)/lib%.a :
	$(MAKE) -C $(TARGETS_DIR)/$* $(TARGETS_BUILD_DIR)/lib$*.a

$(SHARED_TARGET_LIBS): $(BUILD_DIR)/lib%.so :
	$(MAKE) -C $(TARGETS_DIR)/$* $(TARGETS_BUILD_DIR)/lib$*.so

.PHONY: clean $(SHARED_TARGET_LIBS) $(STATIC_TARGET_LIBS)

-include $(DEPS)

clean:
	$(RM) -r $(BUILD_DIR)

## Section for formatting

ALL_SOURCE_FOLDERS := $(SRC_DIR) include $(wildcard $(TARGETS_DIR)/*)
ALL_CXX_FILES := $(wildcard $(ALL_SOURCE_FOLDERS:%=%/*.cpp)) $(wildcard $(ALL_SOURCE_FOLDERS:%=%/*.hpp))

format: 
	clang-format -style=file -i $(ALL_CXX_FILES)

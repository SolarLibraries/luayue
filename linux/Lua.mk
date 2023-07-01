SRCDIR=./

#Do not include any files that have _unittests in their name
SRCS = $(shell find $(SRCDIR) -name "*.cc" -not -name "*unittest*" -not -name "*_test.cc" -not -name "main.cc")
OBJS = $(patsubst %.cc,%.o,$(SRCS))

lua.a: $(OBJS)
	@/usr/bin/printf "[\033[1;35mLua\033[0m] \033[32mLinking \033[33m$@\n\033[0m"
	$(AR) rcs $@ $^

%.o: %.cc
	@/usr/bin/printf "[\033[1;35mLua\033[0m] \033[32mCompiling \033[33m$<\n\033[0m"
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

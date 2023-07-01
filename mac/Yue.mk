SRCDIR=src/mac

SRCS = 	$(shell find $(SRCDIR) -name "*.c")\
		$(shell find $(SRCDIR) -name "*.cc") $(shell find $(SRCDIR) -name "*.mm")\
		$(shell find $(SRCDIR) -name "*.S")
OBJS = $(patsubst %.c,%.o,$(patsubst %.cc,%.o,$(patsubst %.mm,%.o,$(patsubst %.S,%.o,$(SRCS)))))


# merge the objects into a single object (NOT LIBRARY)
yue.a: $(OBJS)
	@/usr/bin/printf "[\033[1;35mYue\033[0m] \033[32mLinking \033[33m$@\n\033[0m"
	$(AR) rcs $@ $^

%.o: %.c
	@/usr/bin/printf "[\033[1;35mYue\033[0m] \033[32mCompiling \033[33m$<\n\033[0m"
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

%.o: %.cc
	@/usr/bin/printf "[\033[1;35mYue\033[0m] \033[32mCompiling \033[33m$<\n\033[0m"
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

%.o: %.mm
	@/usr/bin/printf "[\033[1;35mYue\033[0m] \033[32mCompiling \033[33m$<\n\033[0m"
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

%.o: %.S
	@/usr/bin/printf "[\033[1;35mYue\033[0m] \033[32mAssembling \033[33m$<\n\033[0m"
	$(CC) $(CFLAGS) -c $< -o $@

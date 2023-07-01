SRCDIR=src/linux

SRCS = 	$(shell find $(SRCDIR) -name "*.c")\
		$(shell find $(SRCDIR) -name "*.cc") $(shell find $(SRCDIR) -name "*.mm")\
		$(shell find $(SRCDIR) -name "*.S")
OBJS = $(patsubst %.c,%.o,$(patsubst %.cc,%.o,$(patsubst %.mm,%.o,$(patsubst %.S,%.o,$(SRCS)))))


# merge the objects into a single object (NOT LIBRARY)
yue.a: $(OBJS)
	$(AR) rcs $@ $^

%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

%.o: %.cc
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

%.o: %.mm
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

%.o: %.S
	$(CC) $(CFLAGS) -c $< -o $@

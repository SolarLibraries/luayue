INCLUDES += -I../../yue/include/\
			-I../\
			$(INCDIRS)

ifeq ($(OS),darwin)
	include ../../mac/Lua.mk
else ifeq ($(OS),windows)
	include ../../win/Lua.mk
else
	include ../../linux/Lua.mk
endif

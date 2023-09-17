INCLUDES =	-I../../yue/include/\
			-I../\
			-I../lua/\
			$(INCDIRS)

ifeq ($(OS),darwin)
	include ../../mac/LuaYue.mk
else ifeq ($(OS),windows)
	include ../../win/LuaYue.mk
else
	include ../../linux/LuaYue.mk
endif

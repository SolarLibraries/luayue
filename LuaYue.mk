INCLUDES =	$(INCDIRS)\
			-I../../yue/include/\
			-I../\
			-I../lua/

ifeq ($(OS),darwin)
	include ../../mac/LuaYue.mk
else ifeq ($(OS),windows)
	include ../../win/LuaYue.mk
else
	include ../../linux/LuaYue.mk
endif

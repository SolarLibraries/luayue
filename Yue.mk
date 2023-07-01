INCLUDES = 	-I$(INCDIRS)\
			-Iinclude/

ifeq ($(OS),darwin)
	include ../mac/Yue.mk
else ifeq ($(OS),windows)
	include ../win/Yue.mk
else
	include ../linux/Yue.mk
endif

.PHONY: clean test bootstrap
.SUFFIXES:

# --- Paths / files
SOURCE.d  := source
OBJECT.d  := object

SOURCE    := main.cpp
OBJECT    := $(addprefix ${OBJECT.d}/,${SOURCE})
OBJECT    := $(subst .cpp,.o,${OBJECT})

GENSOURCE := include_lexer.yy.cpp
GENSOURCE := $(addprefix ${OBJECT.d}/,${GENSOURCE})
GENOBJECT := $(subst .cpp,.o,${GENSOURCE})

# --- Tools/Flags
LDLIBS   := -lgvc -lcgraph
CPPFLAGS := -Iobject/

ifeq (${DEBUG}, 1)
  LFLAGS     += --debug --trace
  CFLAGS     += -O0 -ggdb -fno-inline
  CPPFLAGS   += -DDEBUG
  FLEXFLAGS  += --trace --debug
else
  CFLAGS += -O3 -flto=auto -fno-stack-protector
endif

OUT := depgra

# --- Rule Section ---

${OUT}: ${GENSOURCE} ${GENOBJECT} ${OBJECT}
	${LINK.cpp} -o $@ ${OBJECT} ${GENOBJECT} ${LDLIBS}

${OBJECT.d}/%.yy.cpp: ${SOURCE.d}/%.l
	flex ${FLEXFLAGS} --header-file=object/$(basename $(notdir $<)).yy.h -o $@ $<

${OBJECT.d}/%.o: ${SOURCE.d}/%.cpp
	${COMPILE.cpp} -o $@ $<

clean:
	-rm ${GENSOURCE}
	-rm ${OBJECT}
	-rm ${OUT}

test:
	./bepgra debug/dummy_c_project/*.c
	nomacs output.png

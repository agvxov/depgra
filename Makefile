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
CPPFLAGS := -Iobject/ -Isource/

ifeq (${DEBUG}, 1)
  LFLAGS     += --debug --trace
  CFLAGS     += -O0 -ggdb -fno-inline
  CPPFLAGS   += -DDEBUG
  FLEXFLAGS  += --trace --debug
else
  CFLAGS += -O3 -flto=auto -fno-stack-protector
endif

# TODO: clean-up the flexgra target
OUTS := depgra flexgra

# --- Rule Section ---

all: ${OUTS}

depgra: ${GENSOURCE} ${GENOBJECT} ${OBJECT}
	${LINK.cpp} -o $@ ${OBJECT} ${GENOBJECT} ${LDLIBS}

${OBJECT.d}/%.yy.cpp: ${SOURCE.d}/%.l
	flex ${FLEXFLAGS} --header-file=object/$(basename $(notdir $<)).yy.h -o $@ $<

${OBJECT.d}/%.yy.o: ${OBJECT.d}/%.yy.cpp
	${COMPILE.cpp} -o $@ $<

${OBJECT.d}/%.o: ${SOURCE.d}/%.cpp
	${COMPILE.cpp} -o $@ $<

flexgra:
	flex ${FLEXFLAGS} -o object/flexgra.yy.c source/flexgra.l
	g++ ${CFLAGS} -o flexgra object/flexgra.yy.c ${LDLIBS}

clean:
	-rm ${GENSOURCE}
	-rm ${OBJECT}
	-rm ${OUTS}

test:
	./allegra depgra -s debug/dummy_c_project/*.c
	nomacs dependency_graph.png

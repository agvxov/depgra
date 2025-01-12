#include <stdio.h>
#include <graphviz/cgraph.h>
#include "node_t.h"
#include "include_lexer.yy.h"

#define OUTPUT_FILE_NAME "c.dot"

#define dagnode(o, s) { \
    auto ds = strdup(s); \
    o = agnode(g, ds, true); \
    free(ds); \
} while (0)

Agraph_t * g;

extern void add_new_file(const char * const name);

using namespace std;

bool is_no_system = false;

static inline
void init_graph(void) {
    g = agopen("G", Agdirected, NULL);

    agattr(g, AGNODE, "shape", "oval");
    agattr(g, AGRAPH, "rankdir", "BT");
}

static inline
void finish_graph() {
    FILE * output = fopen(OUTPUT_FILE_NAME, "w");
    (void)agwrite(g, output);
    fclose(output);

    agclose(g);
}

void append_node(const char * const name, const char * const parent, const node_t type) {
    if (type == SYSTEM
    &&  is_no_system) {
        return;
    }

    Agnode_t * new_node;
    dagnode(new_node, name);

    if (parent) {
        Agnode_t * parent_node;
        dagnode(parent_node, parent);
        agedge(g, parent_node, new_node, NULL, true);
    }

    switch (type) {
        case SYSTEM: {
            agset(new_node, "shape", "hexagon");
        } break;
        case INTERFACE: {
            agset(new_node, "shape", "box");
        } break;
    }
}

signed main(const int argc, const char * const argv[]) {
    if (argc < 2) {
        printf("%s [options] <files>\n", argv[0]);
        return 1;
    }


    int file_index = 1;

    for (; file_index < argc; file_index++) {
        if (argv[file_index][0] != '-') { break; }

        if (!strcmp(argv[file_index], "-k")) {
            is_no_system = true;
        }
    }

    init_graph();

    for (; file_index < argc; file_index++) {
        add_new_file(argv[file_index]);
    }

    yylex();

    finish_graph();

    return 0;
}

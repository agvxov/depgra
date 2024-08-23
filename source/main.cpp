#include <stdio.h>
#include <graphviz/cgraph.h>
#include "node_t.h"
#include "include_lexer.h"

#define OUTPUT_FILE_NAME "c.dot"

#define dagnode(o, s) { \
    auto ds = strdup(s); \
    o = agnode(g, ds, true); \
    free(ds); \
} while (0)

Agraph_t * g;

extern void add_new_file(const char * const name);

using namespace std;

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
        return 1;
    }

    init_graph();

    for (int i = 1; i < argc; i++) {
        add_new_file(argv[i]);
    }

    yylex();

    finish_graph();

    return 0;
}

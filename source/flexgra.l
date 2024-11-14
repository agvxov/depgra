/* @BAKE
    flex -o $*.yy.c $@
    g++ -o $* $*.yy.c -lgvc -lcgraph -ggdb
    ./$* $@
    cat out.dot
    dot -Tpng out.dot -o output.png
   @STOP
*/
%{
    /* XXX:
     *  We dont handle edge cases where a "goto"/"BEGIN"/label
     *   appears inside a comment or string literal within the
     *   rule section.
     *  This could be easily resolved by adding IN_STRING and
     *   IN_COMMENT states.
     */
    #include <stdio.h>
    #include <graphviz/cgraph.h>
    #include <vector>
    #include <map>
    #include <string>

    using namespace std;

    Agraph_t * g;

    char * current_state;
    char * current_rule;

    typedef enum {
        BEGIN_TRANSITION,
        GOTO_TRANSITION,
    } transition_t;

    typedef struct {
        string state;
        string rule;
        string label;
    } goto_t;

    vector<goto_t> gotos;
    map<string, string> labels;

    char * escape(const char * s) {
        std::string r;

        for (; *s != '\0'; s++) {
            if (*s == '\\') {
                r += "\\\\";
            } else {
                r += *s;
            }
        }

        return strdup(r.c_str());
    }

    void add_edge(const char * from, const char * to, const char * label, transition_t transition) {
        Agnode_t * from_state = agnode(g, (char*)from, false);
        Agnode_t * to_state   = agnode(g, (char*)to, false);

        if (not from_state
        ||  not to_state) {
            printf("Transition involves non-existent states (%s -> %s)",
                from,
                to
            );
            exit(1);
        }

        auto edge = agedge(g, from_state, to_state, NULL, true);
        agsafeset(edge, (char*)"label", label, "");

        const char * style;
        switch (transition) {
            case BEGIN_TRANSITION: {
                style = "solid";
            } break;
            case GOTO_TRANSITION: {
                style = "dashed";
            } break;
        }
        
        agsafeset(edge, (char*)"style", style, "");
    }
%}
%x IN_RULE_SECTION IN_STATE_DECLARATION IN_BEGIN IN_GOTO

ws          [ \t\v]
identifier  [A-Za-z0-9_]+
begin       BEGIN{ws}+\(?{ws}*
goto        goto{ws}+\(?{ws}*
label       {identifier}{ws}*:

/* NOTE:
 *  This horrid thing will match "%%". We handle that as a special case.
 */
rule        ^[^ \t\v\n<][^ \t\v\n]*

%option noyywrap
%option nodefault
%%
    (void)agnode(g, (char*)"INITIAL", true);
    current_state = strdup("INITIAL");
    current_rule  = strdup("");

^\%(x|s)            {
                        BEGIN IN_STATE_DECLARATION;
                    }
^\%\%               {
                    /* NOTE:
                     *  This pattern technically creates a bug.
                     *  One could open a multiline comment within the
                     *  definition section and insert the %% there.
                     *  This would throw off the scanner, but Flex would accept it.
                     *  However, at that point the user is begging for a good beating.
                     */
                        BEGIN IN_RULE_SECTION;
                    }
.|\n                { ; }

<IN_STATE_DECLARATION>{
{identifier}    {
                    (void)agnode(g, yytext, true);
                }
{ws}*           { ; }
.               {
                    puts("Could not parse a state declaration.");
                    exit(1);
                }
\n              { BEGIN INITIAL; }
}

<IN_RULE_SECTION>{
^\<{identifier}\>   {
                        char identifier[(yyleng-2)+1];
                        memcpy(identifier, yytext + 1, yyleng-2);
                        identifier[yyleng-2] = '\0';

                        free(current_state);
                        current_state = strdup(identifier);
                    }
^\}                 {
                        free(current_state);
                        current_state = strdup("INITIAL");
                    }
{rule}              {
                        if (!strcmp(yytext, "%%")) {
                            return 0;
                        }

                        free(current_rule);
                        current_rule = escape(yytext);
                    }
{label}             {
                        yytext[yyleng-1] = '\0'; // amputate the ':'
                        labels[yytext] = current_state;
                    }
{begin}             { BEGIN IN_BEGIN; }
{goto}              { BEGIN IN_GOTO;  }
.|\n                { ; }
}

<IN_BEGIN>{
{identifier}    {
                    add_edge(current_state, yytext, current_rule, BEGIN_TRANSITION);
                }
.|\n            { BEGIN IN_RULE_SECTION; }
}

<IN_GOTO>{
{identifier}    {
                    gotos.push_back((goto_t) {
                        .state = current_state,
                        .rule  = current_rule,
                        .label = yytext,
                    });
                }
.|\n            { BEGIN IN_RULE_SECTION; }
}

%%

signed main(const int argc, const char * * argv) {
    // Init
    g = agopen((char*)"G", Agdirected, NULL);

    agattr(g, AGNODE, (char*)"shape", "oval");
    agattr(g, AGRAPH, (char*)"rankdir", "BT");

    if (argc < 2) {
        printf("Usage: %s <file>\n", argv[0]);
        return 1;
    }

    FILE * input_file = fopen(argv[1], "r");
    if (not input_file) {
        puts("Could not open the input file.");
        return 2;
    }

    // Lex
    yyin = input_file;
    yylex();

    // Process gotos
    for (auto &i : gotos) {
        auto to = labels.find(i.label);
        const char * to_str;
        if (to != labels.end()) {
            to_str = to->second.c_str();
        } else {
            to_str = NULL;
        }

        add_edge(i.state.c_str(), to_str, i.rule.c_str(), GOTO_TRANSITION);
    }

    // Save our graph
    FILE * output = fopen("out.dot", "w");
    agwrite(g, output);
    fclose(output);

    // Deinit
    free(current_state);
    free(current_rule);
    agclose(g);

    return 0;
}

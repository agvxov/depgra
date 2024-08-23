%{
    #include <vector>
    #include <string>
    #include <algorithm>
    #include <stdio.h>

    #include "CSourceFile.hpp"
    #include "node_t.h"

    extern void append_node(const char * const name, const char * const parent, const node_t type);

    char buffer[113];
    char buffer_empty_top = 0;

    std::vector<CSourceFile*> input_file_queue;
    std::vector<std::string> done_list;

    void add_new_file(const char * const name);
    int next_file(void);
%}

ib  \"|\<
ie  \"|\>

%x IN_NEW_INCLUDE

%option nodefault
%%
    yyin = NULL;
    if(next_file()) {
        return 1;
    }

^[[:space:]]*\#[[:space:]]*include[[:space:]]*{ib} {
        BEGIN IN_NEW_INCLUDE;
        buffer[buffer_empty_top++] = yytext[yyleng-1];
    }

<IN_NEW_INCLUDE>{
{ie} {
         BEGIN INITIAL;

         buffer[buffer_empty_top++] = yytext[0];
         buffer[buffer_empty_top]   = '\0';

         add_new_file(buffer);

         buffer_empty_top = 0;
     }
.    {
         buffer[buffer_empty_top++] = yytext[0];
     }
\n   { BEGIN INITIAL; }
}

.|\n { ; }
%%

void add_new_file(const char * const name) {
    CSourceFile * this_file = source_factory(name);

    if (std::find(done_list.begin(),
                  done_list.end(),
                  name
                ) != done_list.end()
    ||  std::find_if(input_file_queue.begin(),
                     input_file_queue.end(),
                     [&](const auto& e) {
                       return e->get_name() == name;
                  }) != input_file_queue.end()) {
        fprintf(stderr, "\033[33mSkipped file: '%s'\033[0m\n", name);
    } else {
        fprintf(stderr, "\033[32mNew file: '%s'\033[0m\n", name);
        input_file_queue.push_back(this_file);
    }

    const char * parent = NULL;
    if (this_file->get_type() != DEFAULT) { // XXX
        parent = strdup(input_file_queue.front()->get_name().c_str());
    }
    append_node(this_file->get_name().c_str(), parent, this_file->get_type());
}

int next_file(void) {
    while (!yyin) {
        if (input_file_queue.empty()) { return 1; }

        yyin = fopen(input_file_queue.front()->get_path().c_str(), "r");
        if (!yyin) {
            perror(input_file_queue.front()->get_path().c_str());
            input_file_queue.erase(input_file_queue.begin());
        }
    }
    
    fprintf(stderr, "\033[34mOpening file: '%s'\033[0m\n", input_file_queue.front()->get_path().c_str());

    done_list.push_back(input_file_queue.front()->get_name());

    return 0;
}

int yywrap(void) {
    input_file_queue.erase(input_file_queue.begin());

    yyin = NULL;
    if(next_file()) {
        return 1;
    }

    return 0;
}

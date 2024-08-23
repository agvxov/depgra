#include <string>
#include <libgen.h>

#include "node_t.h"

#define DEFAULT_SYSTEM_INCLUDE_PATH "/usr/include"

class CSourceFile {
  public:
    virtual std::string get_name() = 0;
    virtual std::string get_path() = 0;
    virtual node_t      get_type() = 0;
};

class CSource : public CSourceFile {
    std::string base_name;
    std::string path;
  public:
    CSource(const char * const full_path) {
        base_name = basename(strdup(full_path));
        path = full_path;
    }

    std::string get_name() { return base_name; }
    std::string get_path() { return path; }
    node_t      get_type() { return DEFAULT; };
};

class CHeader : public CSourceFile {
    static std::vector<std::string> * libpath;
    std::string name;
  public:
    CHeader(const char * const name_) : name(name_) {
        ;
    }

    std::string get_name() { return name; }

    std::string get_path() { // XXX
        return name.substr(1, name.size()-2);
    }

    node_t      get_type() { return INTERFACE; };
};

class CSystemHeader : public CSourceFile {
    static std::vector<std::string> * syslibpath;
    std::string name;
  public:
    CSystemHeader(const char * const name_) : name(name_) {
        ;
    }

    std::string get_name() { return name; }

    std::string get_path() {
        return std::string()
             + DEFAULT_SYSTEM_INCLUDE_PATH
               "/"
             + name.substr(1, name.size()-2);
    }

    node_t      get_type() { return SYSTEM; };
};

CSourceFile * source_factory(const char * const name) {
    switch (name[0]) {
        case '"': return new CHeader(name);
        case '<': return new CSystemHeader(name);
        default:  return new CSource(name);
    }
}

#ifndef NODE_TYPE_H
#define NODE_TYPE_H

/* Yes, we do have a class hierarchy too, however thats opaque to 'main.cpp'.
 * 'main.cpp' only uses these to apply styling, it does not care about anything else
 *   and thats how its should be.
 */

typedef enum {
    DEFAULT,
    INTERFACE,
    SYSTEM,
} node_t;

#endif

### graphs such as:
```
   +-------+
   |  i.h  | 
   |  ___  |
   | | i | |
   |  '''  |
   +-------+

   +--------------------+     +---------------------+
   |       main.c       |     |          i.c        | 
   |  ________________  |     |  _________________  |
   | | used by main.c | |     | | declared by i.c | |
   |  ''''''''''''''''  |     |  '''''''''''''''''' |
   +--------------------+     +---------------------+

```

(arrows omitted for simplicity)

these rectangles can be achieved with cluster subgraphs,
however you cant have edges between subgraphs and nodes
so for better or worse `* by $@` will have to be used

the same logic is achievable inside files for static globals.
not sure how combining them to one graph would work

this really only works well with header files,
but i dont mind being less generic if the visualization is better

ctags cant do this (--extras=+referece only indexes the preprocessor),
i will have to use treesitter.

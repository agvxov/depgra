### graphs such as:
```
   +-------+
   |  i.h  | 
   |  ___  |
   | | i | |
   |  '''  |
   +-------+

   +--------------------+     +------------------------+
   |       main.c       |     |          i.c           | 
   |  ________________  |     |  ____________________  |
   | | used by main.h | |     | | declared by main.h | |
   |  ''''''''''''''''  |     |  ''''''''''''''''''''  |
   +--------------------+     +------------------------+

```

(arrows omited for simplicity)

ctags cant do this (--extras=+referece only indexes the preprocessor),
i will have to use treesitter

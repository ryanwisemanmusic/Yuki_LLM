One of the problems that you may run into when dealing with Docker Compose is the issue of WebUI's API being extremely picky with .json files. These are very difficult to generate, since Modfile instructions are often broken up onto multiple lines.

This is a giant mess, since if a Modfile contains any special characters, you break the JSON payload unless you explicitly set up for this. Because of this issue, the best way to satisfy WebUI's API is to avoid packaging things in a .json file altogether.

The only time you ever should deal with .json is when you are working on actively serving models. This is because you are giving it a static request that it can parse, compared to the dynamic nature of the Modfile, which is extremely difficult to account for well.


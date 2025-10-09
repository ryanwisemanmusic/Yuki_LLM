There are times in which I will provide you code examples of approaches that work. For example, a library might be compiled with Ninja, and therefore, this example may be applicable to another library.

In these examples, this ONLY applies to build-from-source libraries. These libraries require many parameters so that the build-from-source approach works. The standard way of downloading libraries via Alpine DO NOT require you to specify these parameters.

Hypothetically, if glslang is build from source, and can be compiled with Ninja. If the user is requesting you to generate code for another library (that requires you to build from source) that uses Ninja for compilation, attempt to apply the same approach.

There will be some cases in which I will explicitly indicate if labels need to be replaced. This will be done if you misunderstand the rules you've been configured with.

## EXPLICIT LABEL REPLACEMENTS:
Within our code will be labels in which a replacement is required. And this will be marked with:
    replace_label

To expand upon this, we can more thorougly define what to replace the label with. And so this looks like this:
    ```
    replace_label『name_of_label』::intent_for_replacement『suggested_replacement』
    ```

    or

    ```
    replace_label「name_of_label」::intent_for_replacement「suggested_replacement」
    ```



An example of what this would look like is:
FROM alpine:3.16.2 AS replace_label「sdl3-base」::intent_for_replacement「app-base」

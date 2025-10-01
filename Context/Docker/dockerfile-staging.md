This is an example of the minimal Dockerfile required to make a Dockerfile work:

```
FROM alpine:3.21 AS base-deps

# Additional stages go here as needed

FROM debug AS runtime

# Set the user to root
USER root

# if you have a seperate app build and debug stage, you MUST copy the app build stage into the runtime stage
COPY --from=app-build /name_of_root_folder/app/build/simplehttpserver /name_of_root_folder/usr/bin/

# Make the binary executable
RUN chmod +x /name_of_root_folder/usr/bin/simplehttpserver
RUN mkdir -p /name_of_root_folder/etc/profile.d && \
    cat > /name_of_root_folder/etc/profile.d/runtime.sh <<'RUNTIME_PROFILE'

# Set user permissions
RUN chown -R shs:shs /name_of_root_folder/app /name_of_root_folder/usr/local

# Essential runtime dependencies
RUN apk add --no-cache libstdc++ libgcc

# Set environment variables - EXCLUDE the problematic sysroot lib paths from runtime
ENV LD_LIBRARY_PATH="/name_of_root_folder/usr/lib/runtime:/name_of_root_folder/usr/lib:/name_of_root_folder/usr/local/lib:$LD_LIBRARY_PATH" \
    PATH="/name_of_root_folder/compiler/bin:/name_of_root_folder/usr/local/bin:/name_of_root_folder/usr/bin:$PATH"

# Run the application
CMD ["/name_of_root_folder/usr/bin/simplehttpserver"]
```
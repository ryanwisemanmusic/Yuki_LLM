Here are examples of libraries that are built from source. You will need to modify path labels all depending on the filesystem being used. For example, my OS, uses the root folder of /lilyspark/

You may need to specify what folders need to be created at the beginning, in this format (other libraries will have different folders):
```
RUN mkdir -p \
    /lilyspark/opt/lib/audio/jack2 \
    /lilyspark/opt/lib/audio/jack2/bin \
    /lilyspark/opt/lib/audio/jack2/lib \
    /lilyspark/opt/lib/audio/jack2/include \
    /lilyspark/opt/lib/audio/jack2/share \
    /lilyspark/opt/lib/audio/jack2/metadata
```

So if a user has a root folder of /name_of_root_folder/, you will need to replace all instances of /lilyspark/ with /name_of_root_folder/. Same applies to folders within the root folder, and all other folders within the Dockerfile.

## JACK2 EXAMPLE:
RUN echo "=== BUILDING JACK2 FROM SOURCE ===" && \
    /usr/local/bin/check_llvm15.sh "pre-jack2-source-build" || true && \
    \
    mkdir -p /tmp/jack2 && cd /tmp/jack2 && \
    \
    if git clone --depth=1 https://github.com/jackaudio/jack2.git /tmp/jack2-source; then \
        echo "JACK2 source cloned successfully"; \
        # Capture git commit hash, tag, and version info
        cd /tmp/jack2-source && \
        JACK2_COMMIT=$(git rev-parse HEAD) && \
        JACK2_TAG=$(git describe --tags --exact-match HEAD 2>/dev/null || echo "1.9.23") && \
        JACK2_VERSION=$(git describe --tags --always 2>/dev/null | sed 's/^v//' || echo "1.9.23") && \
        echo "JACK2 commit: $JACK2_COMMIT" && \
        echo "JACK2 tag: $JACK2_TAG" && \
        echo "JACK2 version: $JACK2_VERSION" && \
        # Store comprehensive version info for dependencies tracking
        echo "{" > /lilyspark/opt/lib/audio/jack2/metadata/version.json && \
        echo "  \"git\": \"https://github.com/jackaudio/jack2.git\"," >> /lilyspark/opt/lib/audio/jack2/metadata/version.json && \
        echo "  \"commit\": \"$JACK2_COMMIT\"," >> /lilyspark/opt/lib/audio/jack2/metadata/version.json && \
        echo "  \"tag\": \"$JACK2_TAG\"," >> /lilyspark/opt/lib/audio/jack2/metadata/version.json && \
        echo "  \"version\": \"$JACK2_VERSION\"" >> /lilyspark/opt/lib/audio/jack2/metadata/version.json && \
        echo "}" >> /lilyspark/opt/lib/audio/jack2/metadata/version.json; \
    else \
        echo "ERROR: Could not clone JACK2 repository" >&2 && false; \
    fi && \
    \
    cd /tmp/jack2-source && \
    \
    # Install libexecinfo for execinfo.h support (quietly)
    apk add --no-cache libexecinfo-dev >/dev/null 2>&1 || echo "Note: libexecinfo-dev not available, continuing without it" >&2 && \
    \
    if [ -x ./waf ]; then \
        echo ">>> Using waf build system <<<"; \
        # Enhanced filtering: keep only "yes", important settings, and remove all "no" and ucontext checks
        ./waf configure --prefix=/usr --libdir=/usr/lib 2>&1 | grep -v "not found" | grep -v "ERROR" | grep -v "no" | grep -E "(Checking for|yes|Setting|JACK|Maximum|Build|Enable|Use|C\+\+|Linker)" | grep -v "ucontext" || true && \
        ./waf build && \
        DESTDIR="/lilyspark/opt/lib/audio/jack2" ./waf install; \
    else \
        echo ">>> Waf not found, trying autotools <<<"; \
        if [ -x ./configure ]; then \
            # Redirect configure output with enhanced filtering
            ./configure --prefix=/usr --libdir=/usr/lib --with-sysroot=/lilyspark/opt/lib/audio/jack2 2>&1 | grep -v "not found" | grep -v "checking for" | grep -v "no" | grep -E "(yes|YES|configure:)" || true && \
            make -j$(nproc) && \
            make DESTDIR="/lilyspark/opt/lib/audio/jack2" install; \
        else \
            echo "ERROR: No recognized build system found (waf or autotools)" >&2 && false; \
        fi; \
    fi && \
    \
    echo "=== RELOCATING JACK2 BINARIES ===" && \
    # Move executables to jack-specific bin directory
    if [ -d /lilyspark/opt/lib/audio/jack2/usr/bin ]; then \
        find /lilyspark/opt/lib/audio/jack2/usr/bin -maxdepth 1 -type f -name "jack*" -exec mv -v {} /lilyspark/opt/lib/audio/jack2/bin/ \; || true; \
    fi && \
    \
    echo "=== VERIFYING JACK2 INSTALLATION ===" && \
    find /lilyspark/opt/lib/audio/jack2/bin -type f -name "jack*" -ls && \
    find /lilyspark/opt/lib/audio/jack2/usr/lib -type f -name "libjack*" -ls && \
    \
    # Display the captured version info
    echo "=== JACK2 BUILD COMPLETE ===" && \
    echo "Version info stored at: /lilyspark/opt/lib/audio/jack2/metadata/version.json" && \
    cat /lilyspark/opt/lib/audio/jack2/metadata/version.json && \
    \
    /usr/local/bin/check_llvm15.sh "post-jack2-install" || true && \
    \
    cd / && rm -rf /tmp/jack2 /tmp/jack2-source
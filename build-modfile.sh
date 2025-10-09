#!/bin/bash
cat > Modfile << 'EOF'
FROM deepseek-coder:33b

SYSTEM """
EOF


# Add all General folder files
cat Context/General/core-identity.md >> Modfile
#cat Context/General/introduction.md >> Modfile
#cat Context/General/substitutions.md >> Modfile

# Add all Docker folder files
#cat Context/Docker/mkdir_rules.md >> Modfile
#cat Context/Docker/dockerfile-staging.md >> Modfile

# Add all Makefile folder files
#cat Context/Makefile/Docker-Gen-Rules.md >> Modfile
#cat Context/Makefile/Building-Docker-Containers-Via-Makefile.md >> Modfile
#cat Context/Makefile/platform-detect.md >> Modfile

cat >> Modfile << 'EOF'
"""

PARAMETER temperature 0.7
PARAMETER num_ctx 16384
EOF

echo "Modfile built successfully with all context files!"
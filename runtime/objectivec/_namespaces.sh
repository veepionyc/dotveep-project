#/bin/bash

# run this ONCE to change filenames and namespaces
for f in VPKGPB*; do mv -- "$f" "VPK${f%}"; done
find . -type f -exec sed -i '' -e 's/VPKGPB/VPKVPKGPB/g' {} +

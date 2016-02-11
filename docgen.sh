command -v doxygen >/dev/null 2>&1 || { echo >&2 "Utility doxygen is not installed.  Aborting."; exit 1; }
rm -r -f /tmp/doxydoc
mkdir /tmp/doxydoc
doxygen .Doxyfile 2>&1 || { echo >&2 "Error while running doxygen.  Aborting."; exit 1; }
make --quiet -C /tmp/doxydoc/latex/ 2>&1 || { echo >&2 "Error while generating the PDF.  Aborting."; exit 1; }
mv /tmp/doxydoc/latex/refman.pdf ./refman.pdf

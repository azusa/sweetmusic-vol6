set -eu

rm -rf target
mkdir -p target

cat src/newpage.txt >> target/tmp.md
cat "src/010-TDDは死んだのか.md" >> target/tmp.md
cat src/newpage.txt >> target/tmp.md
cat src/*.yaml >> target/tmp.md

cat -n target/tmp.md


pandoc -V fontsize:14pt -V papersize:b5 -f markdown+raw_tex+tex_math_dollars+citations+yaml_metadata_block --filter pandoc-citeproc -o target/techbookfest2.pdf --latex-engine=lualatex -H h-luatexja.tex --toc --toc-depth=1 target/tmp.md

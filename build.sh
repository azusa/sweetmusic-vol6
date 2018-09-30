set -eux

export LANG="ja_JP.UTF-8"

#cat /usr/local/texlive/2016/texmf-dist/tex/latex/listings/listings.sty

rm -rf target
mkdir -p target

OUTPUT="sweetmusic-vol5"

for file in `ls src/*.md`
do
  cat $file >> src/tmp.md
  cat src/newpage.txt >> src/tmp.md
done
cat src/990*.yaml >> src/tmp.md

cat -n src/tmp.md

cd src

pandoc  \
  -s -f markdown+raw_tex+citations+yaml_metadata_block+fenced_code_blocks \
  -c book.css --filter pandoc-crossref \
  -M "crossrefYaml=${PWD}/../crossref_config.yaml" \
  --filter pandoc-citeproc -o ../target/${OUTPUT}.html \
  --toc --toc-depth=2 --reference-location=block \
  -B cover.html -A imprint.html \
  -S tmp.md  --verbose

# cat epub.yaml >> tmp.md
# pandoc -V fontsize:12pt -V papersize:b5 -s -f markdown+raw_tex+citations+yaml_metadata_block+fenced_code_blocks+ignore_line_breaks --filter pandoc-crossref -M "crossrefYaml=${PWD}/../crossref_config.yaml" --filter pandoc-citeproc -t epub3 -o ../target/${OUTPUT}.epub --latex-engine=lualatex   --toc --toc-depth=2 -S  tmp.md  --verbose

cd ../

RET=$?

mkdir -p target/img
cp -f src/*.css src/*.otf src/*.ttf target/
cp -f src/img/* target/img

set +e
/opt/redpen-distribution-1.9.0/bin/redpen -c redpen-config.xml -f markdown src/*.md |tee target/${OUTPUT}.txt

exit $RET

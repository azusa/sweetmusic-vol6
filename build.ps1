Remove-Item target\*.pdf

docker build -t tf6 .
docker run tf6

$out = docker ps -a |Select-String "tf6"
foreach ($line in $out){
  $ids = $line.line -split " "
  $id = ${ids}[0]
  & docker cp ${id}:/tmp/code/target .
  docker rm $id
}


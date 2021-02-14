#! /bin/zsh
# beginNumber=$1
# endNumber=`expr $beginNumber + 10`
# if $2
# then
#   endNumber=$2
# fi

# while (($beginNumber < $endNumber))
# do
#   wget -O cover$beginNumber.jpg http://api.btstu.cn/sjbz/\?lx\=dongman 
#   let "beginNumber++"
# done

for i in {1..60}
do
  echo "  - /img/cover$i.jpg"
done
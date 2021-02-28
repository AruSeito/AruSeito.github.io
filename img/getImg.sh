#! /bin/zsh
beginNumber=$1
endNumber=`expr $beginNumber + 10`
if [ $2 ];then
  endNumber=$2
fi

while (($beginNumber < $endNumber))
do
  wget -O bg$beginNumber.jpg http://api.btstu.cn/sjbz/\?lx\=dongman 
  let "beginNumber++"
done
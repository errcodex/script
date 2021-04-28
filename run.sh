#!/bin/sh
# author errcodex https://github.com/errcodex
echo P盘程序启动中

# 环境变量
. ~/chia-blockchain/activate

# begin
if [ $# != 2 ]; then
	echo 参数错误
	echo usage: $0 FROM TO
	echo
	echo FROM  缓存盘符
	echo TO    最终盘符
	exit
fi

if [ ! -d "/mnt/$1" ] || [ ! -d "/mnt/$2" ]; then
	echo 盘符$1或$2不存在
	exit
fi

_temp=/mnt/$1/chia_cache
_dest=/mnt/$2/chia
_temp2=$_temp
# 日志目录
_log=/mnt/d/chia_log
_i=1
_fail=0
echo temp=$_temp
echo dest=$_dest
echo temp2=$_temp2
touch /mnt/$1/.delete_to_stop
mkdir $_log 2>/dev/null

#trap "trap - 15 && kill -- -$$" 2 15 EXIT
trap abort 2 15

# clean dir
clean()
{
	if [ $# != 1 ]; then
		echo 参数错误 - clean 
		return 0
        fi

	_cache=$(ls $1 | wc -l)
	rm $1 -rf
	if [ $_cache != 0 ]; then
		echo 从$1中删除$_cache个缓存文件
	fi
}
#先定义好time防止误删父目录
_time=0
abort()
{
	echo
        kill $!
        if [ $? != 0 ]; then
                echo 任务结束失败，可能是没有任务在执行，PID: $!
        else
                echo 已中止任务，PID: $!
        fi

	clean $_temp/$_time
        
	trap - 15 && kill $$
        return 0
}

while true
do
	echo 休眠10S,Ctrl+C立即结束
	sleep 10
	_time=$(date "+%Y%m%d_%H%M%S")
	
	echo 正在执行第${_i}次绘图程序,编号 ${_time}

	 ( \
	 chia plots create -k 32 -b 7000 -u 128 -r 2 -e \
	-f 99c1fc3fa6916b129439820a1483b0cd730ff29f83c01dae481a47e29efce0790d3c4fd6a0dfaf26661a51447a9e2943 \
	-p ae7971e84a5542416d970d82ee50080c7dbb05af6ba4bdb65acf1be2066013c1a3a67035e8c00a1aefcdafa33551c4d9 \
	-t $_temp/$_time \
	-2 $_temp2/$_time \
	-d $_dest \
	> $_log/${1}_${2}_${_time}.txt 2>&1 \
	)&
	
	wait

	clean $_temp/$_time

	if [ $? != 0 ]; then
		echo 第${_i}次绘图失败,编号 ${_time}
		_fail=`expr $_fail + 1`
	fi

	if [ ! -f "/mnt/$1/.delete_to_stop" ]; then
		echo 标记文件被删除，程序停止
		echo 总计运行$_i次，失败$_fail次
		exit
	fi
	echo 完成	
	_i=`expr $_i + 1`
done

#!/bin/sh
# author errcodex https://github.com/errcodex
echo P盘程序启动中

# 环境变量
. ~/chia-blockchain/activate

# 参数长度校验
if [ $# -lt "2" ] || [ $# -gt "3" ]; then
	echo 参数错误
	echo usage: $0 \<FROM\> \[\<TEMP\>\] \<TO\>
	echo
	echo FROM  缓存盘符
	echo TEMP  缓存2盘符\(temp2\)
	echo TO    最终盘符
	exit
fi

# 盘符有效性校验
if [ ! -d "/mnt/$1" ] || [ ! -d "/mnt/$2" ] || [ ! -d "/mnt/$3" ]; then
	echo 盘符$1或$2或$3不存在
	exit
fi

# 变量设置
_temp=/mnt/$1/chia_cache
_dest=/mnt/$2/chia
if [ $# -eq 2 ];then
	_temp2=$_dest
else
	_temp2=/mnt/$3/chia_cache2
fi

# 日志目录
_log=/mnt/d/chia_log
mkdir $_log 2>/dev/null

# 变量-循环次数和失败次数
_i=1
_fail=0

# 打印参数
echo temp=$_temp
echo dest=$_dest
echo temp2=$_temp2

# 设置停止文件，删除对应盘符中的delete_to_stop文件，将在任务完成后自动停止
touch /mnt/$1/.delete_to_stop

#trap "trap - 15 && kill -- -$$" 2 15 EXIT
trap abort 2 15

# clean dir
clean()
{
	if [ $# -ne 1 ]; then
		echo 参数错误 - clean 
		return 0
	fi

	_cache=`ls $1 | wc -l`
	rm $1 -rf
	if [ $_cache -ne 0 ]; then
		echo 从$1中删除$_cache个缓存文件
	fi
}

#先定义好time防止误删父目录
_temp_sub=$_temp/00000000_000000
abort()
{
	echo
	kill $!
	
	if [ $? -ne 0 ]; then
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
	echo
	echo 休眠10S,Ctrl+C立即结束
	sleep 10
	_time=$(date "+%Y%m%d_%H%M%S")
	
	echo 正在执行第${_i}次绘图程序,编号 ${_time}

	# 设置任务子目录
	_temp_sub=$_temp/$_time
	
	# 执行P盘任务
	( \
	 chia plots create -k 32 -b 6000 -u 128 -r 4 \
	-f 99c1fc3fa6916b129439820a1483b0cd730ff29f83c01dae481a47e29efce0790d3c4fd6a0dfaf26661a51447a9e2943 \
	-p ae7971e84a5542416d970d82ee50080c7dbb05af6ba4bdb65acf1be2066013c1a3a67035e8c00a1aefcdafa33551c4d9 \
	-t $_temp_sub \
	-2 $_temp2 \
	-d $_dest \
	> $_log/${1}_${2}_${_time}.txt 2>&1 \
	)&
	
	wait

	if [ $? -ne 0 ]; then
		echo 第${_i}次绘图失败,编号 ${_time}
		_fail=`expr $_fail + 1`
	fi

	clean $_temp_sub

	if [ ! -f "/mnt/$1/.delete_to_stop" ]; then
		echo 标记文件被删除，程序停止
		echo 总计运行$_i次，失败$_fail次
		exit
	fi
	echo 完成	
	_i=`expr $_i + 1`
done

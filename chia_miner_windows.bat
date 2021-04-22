rem ==================================================================
rem 
rem  chia循环挖矿脚本，删除本目录下.delete_to_stop文件，本次P盘完成自动停止
rem
rem  默认最终目录      X:\chia
rem  默认TEMP目录      当前目录\chia_cache
rem  默认TEMP2目录同   最终目录(可减少移动文件花费的时间)
rem  默认日志目录      C:\chia_log (不建议在当前盘符，碎文件读写会影响P盘效率)
rem  默认内存          5120M
rem
rem ==================================================================
@echo off
chcp 65001 > nul
title CHIA循环挖矿脚本 - by errcodex
rem ==================================================================

rem 修改项
set DEST_PATH=X:\chia

rem 可选修改项
set BUKKIT_COUNT=128
set MEM_USE=5120
set TEMP_PATH=%~dp0chia_cache
set TEMP2_PATH=%DEST_PATH%
set LOG_PATH=C:\chia_log

rem ==================================================================
cd /d %UserProfile%\AppData\Local\chia-blockchain\app-*\resources\app.asar.unpacked\daemon\ 2> nul
if not exist chia.exe (
	echo 未找到chia主程序
	pause
	exit
)

set PATH=%PATH%;%cd%
cd /d %~dp0

echo 正在启动CHIA循环挖矿脚本 - by errcodex
echo. > .delete_to_stop

rem 变量延迟扩展，用于实时生效set变量
setlocal enabledelayedexpansion

rem 执行次数
set /A "CHIA_COUNT=0"

rem 创建日志目录
md %LOG_PATH% 2> nul

echo.
echo 缓存目录：%TEMP_PATH%
echo 缓存2目录：%TEMP2_PATH%
echo 目标目录：%DEST_PATH%
echo.

rem 中止文件".delete_to_stop"不存在则停止
:while
rem 睡眠5秒钟
ping ::1 -n 5 > nul
if exist .delete_to_stop (
	set /A "CHIA_COUNT=!CHIA_COUNT!+1"
	
	call :get_date %date%
	call :get_time %time%
	call :get_log_file_fullpath
	
	title CHIA循环挖矿脚本 - by errcodex - !LOG_FILE:~10,6!
	echo 正在执行第!CHIA_COUNT!次,LOG:%LOG_PATH%\!LOG_FILE!

	chia plots create -k 32 -u %BUKKIT_COUNT% -b %MEM_USE% -t %TEMP_PATH% -2 %TEMP2_PATH% -d %DEST_PATH% > %LOG_PATH%\!LOG_FILE! 2>&1
	
	goto :while
)

pause
exit

rem ================函数调用==================

rem 获取日期(解决日期前有星期数)
rem _DATE get_date(date)
:get_date
if "%2"=="" ( set _DATE=%1 ) else ( set _DATE=%2 )
goto :eof

rem 获取时间(解决小时有可能第一位为空格)
rem _TIME get_time(time)
:get_time
set _TIME=%1
if "%_TIME:~1,1%"==":" ( set _TIME=0%_TIME% )
goto :eof

rem 获取日志路径
rem LOG_FILE get_log_file_fullpath():_DATE, _TIME
:get_log_file_fullpath
for /f %%i in ( 'echo %_DATE:~0,4%%_DATE:~5,2%%_DATE:~8,2%_%_TIME:~0,2%%_TIME:~3,2%%_TIME:~6,2%.txt' ) do ( set "LOG_FILE=%%i" )
goto :eof


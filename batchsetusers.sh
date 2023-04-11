#!/bin/bash

# 检查是否有sudo权限
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# 验证用户输入的用户名列表是否合法
echo "请输入需要创建的用户，每个用户名后请用\分隔，无需空格，以回车键结束："
read USER_LIST

if [ -z "$USER_LIST" ]; then
   echo "请输入至少一个用户名"
   exit 1
fi

for USER in $USER_LIST; do
   if [[ ! "$USER" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
      echo "用户名 $USER 不符合命名规范，请使用小写字母、数字、下划线和连字符"
      exit 1
   fi
done

# 设置存储用户名和密码信息的文件
USER_FILE=./user.info

# 遍历用户名列表，对每个用户名进行处理
for USER in $USER_LIST; do
   if id "$USER" &>/dev/null; then
      echo "用户 $USER 已经存在"
      continue
   fi

   # 生成随机密码
   PASS=$(openssl rand -base64 8 | tr -d "=+/" | cut -c 1-8)

   # 创建用户并设置密码
   if ! useradd -m "$USER"; then
      echo "创建用户 $USER 失败"
      exit 1
   fi

   if ! echo "$USER:$PASS" | chpasswd; then
      echo "设置用户 $USER 密码失败"
      exit 1
   fi

   # 将用户名和密码信息写入文件
   echo "$USER:$PASS" >> "$USER_FILE"
   echo "用户 $USER 创建成功"
done

# 记录日志
LOG_FILE=./user.log
echo "$(date '+%Y-%m-%d %H:%M:%S') 用户创建脚本执行成功" >> "$LOG_FILE"
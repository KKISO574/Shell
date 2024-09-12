#!/bin/bash

# 定义输出文件
output_file="scan_server.txt"

# 获取机器名称
hostname=$(hostname)

# 获取CPU核心总数
cpu_cores=$(nproc)

# 获取总内存 (以GB为单位)
total_mem=$(awk '/MemTotal/ {printf "%.0f\n", $2/1024/1024}' /proc/meminfo)
mem="${total_mem}G"

# 获取硬盘大小和类型 (SSD 和 HDD)
disk_info=$(lsblk -d -o name,rota,size | grep -v "NAME")
total_ssd_size=0
total_hdd_size=0

while read -r line; do
    disk_name=$(echo $line | awk '{print $1}')
    disk_type=$(echo $line | awk '{print $2}')
    disk_size=$(echo $line | awk '{print $3}')

    # 检查磁盘大小的单位并进行转换
    if [[ $disk_size == *T ]]; then
        disk_size_in_gb=$(echo "${disk_size%T} * 1024" | bc)
    elif [[ $disk_size == *G ]]; then
        disk_size_in_gb=${disk_size%G}
    else
        echo "Skipping invalid disk size: $disk_size"
        continue
    fi

    if [ "$disk_type" -eq 0 ]; then
        # SSD
        total_ssd_size=$(echo "$total_ssd_size + $disk_size_in_gb" | bc)
    else
        # HDD
        total_hdd_size=$(echo "$total_hdd_size + $disk_size_in_gb" | bc)
    fi
done <<< "$disk_info"

# 输出格式：CPU总核心数 内存大小 SSD总容量 HDD总容量
echo "$hostname ${cpu_cores}核 $mem ${total_ssd_size}GSSD ${total_hdd_size}GHDD"
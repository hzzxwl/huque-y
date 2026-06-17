#!/bin/bash
# Intel Arc A770 Ubuntu 22.04 自动压测脚本
# 日志保存路径
LOG_FILE="a770_stress_log_$(date +%Y%m%d_%H%M%S).log"

# 压测时长（分钟）
STRESS_TIME=30

echo "========================================"
echo " Intel Arc A770 显卡压测脚本启动 "
echo " 压测时长：${STRESS_TIME} 分钟"
echo " 日志文件：$LOG_FILE"
echo "========================================"
echo | tee -a $LOG_FILE

# 检查依赖
if ! command -v clpeak &> /dev/null; then
    echo "错误：未安装 clpeak，请先执行：apt install -y clpeak"
    exit 1
fi

if ! command -v intel_gpu_top &> /dev/null; then
    echo "错误：未安装 intel-gpu-tools，请先执行：apt install -y intel-gpu-tools"
    exit 1
fi

# 后台启动 GPU 监控（每秒记录一次）
echo "【启动】GPU 实时监控..."
timeout ${STRESS_TIME}m watch -n 1 "intel_gpu_top -l | tail -20 | head -15" >> $LOG_FILE &
MONITOR_PID=$!

# 启动循环满载压测
echo "【启动】显卡 100% 满载压测（OpenCL 算力）..."
start_time=$(date +%s)
end_time=$((start_time + STRESS_TIME * 60))

while [ $(date +%s) -lt $end_time ]; do
    clpeak >> $LOG_FILE 2>&1
    sleep 1
done

# 结束监控
kill $MONITOR_PID > /dev/null 2>&1

echo | tee -a $LOG_FILE
echo "========================================" | tee -a $LOG_FILE
echo " 压测完成！日志已保存到：$LOG_FILE" | tee -a $LOG_FILE
echo "========================================" | tee -a $LOG_FILE
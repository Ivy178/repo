#!/bin/bash
# 文件路径：/opt/ansible-patching/run_patching.sh
# 功能：无人值守补丁更新调度脚本

set -e

WORK_DIR="/opt/ansible-patching"
LOG_DIR="${WORK_DIR}/logs"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/patching_${DATE}.log"

cd${WORK_DIR}

# 函数：发送通知
send_notification() {
local message=$1
local webhook_url="https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=xxx"

    curl -s -X POST ${webhook_url} \
        -H 'Content-Type: application/json' \
        -d "{\"msgtype\": \"text\", \"text\": {\"content\": \"${message}\"}}" \
        > /dev/null 2>&1 || true
}

# 函数：执行单个批次
run_batch() {
local batch_name=$1
local batch_size=$2

echo"[$(date)] 开始执行批次: ${batch_name}" | tee -a ${LOG_FILE}
    send_notification "[补丁更新] 开始执行批次: ${batch_name}"

if ansible-playbook playbooks/patching.yml \
        -e "target_hosts=${batch_name}" \
        -e "batch_size=${batch_size}" \
        >> ${LOG_FILE} 2>&1; then
echo"[$(date)] 批次 ${batch_name} 执行成功" | tee -a ${LOG_FILE}
        send_notification "[补丁更新] 批次 ${batch_name} 执行成功"
return 0
else
echo"[$(date)] 批次 ${batch_name} 执行失败" | tee -a ${LOG_FILE}
        send_notification "[补丁更新] 批次 ${batch_name} 执行失败，请检查"
return 1
fi
}

# 主流程
main() {
    send_notification "[补丁更新] 开始执行，预计耗时 6-8 小时"

# 金丝雀批次
if ! run_batch "canary" 1; then
        send_notification "[补丁更新] 金丝雀批次失败，终止后续更新"
exit 1
fi

# 等待 10 分钟观察金丝雀
echo"[$(date)] 等待 10 分钟观察金丝雀环境..." | tee -a ${LOG_FILE}
sleep 600

# 后续批次
local batches=("batch1:10""batch2:20""batch3:30""batch4:50""batch5:50")

for batch_config in"${batches[@]}"; do
        batch_name="${batch_config%%:*}"
        batch_size="${batch_config##*:}"

if ! run_batch "${batch_name}""${batch_size}"; then
            send_notification "[补丁更新] 批次 ${batch_name} 失败，终止后续更新"
exit 1
fi

# 批次间间隔 5 分钟
echo"[$(date)] 批次间隔等待 5 分钟..." | tee -a ${LOG_FILE}
sleep 300
done

    send_notification "[补丁更新] 全部完成！请检查各服务状态"
}

main "$@"






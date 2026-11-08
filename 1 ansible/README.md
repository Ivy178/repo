1.1 背景介绍
每个季度的安全补丁更新是运维团队的噩梦。上个季度我们还在用 SSH 跳板机 + xshell 批量执行脚本的方式给服务器打补丁，500 台机器分 10 批次，整整熬了三个通宵。中间还出了两次事故：
一次是补丁依赖冲突导致某台数据库服务器重启失败，另一次是并发太高把内网带宽打满了。痛定思痛，我们决定用 Ansible 重构整个补丁管理流程。
这套方案跑了两个季度，现在 500 台服务器的补丁更新，从晚上 10 点开始，第二天早上 6 点收工，全程无人值守。这篇文章把踩过的坑和最终方案都记录下来。

1.2 技术特点
幂等性保障：Ansible 的 yum/apt 模块天然支持幂等操作，重复执行不会造成问题，中断后可以安全重试
滚动更新：通过 serial 参数控制并发数，避免同时重启太多机器影响业务
自动回滚：结合健康检查，发现异常自动停止后续批次，保留现场等待人工介入• 详细日志：每台机器的执行结果都有记录，事后审计和故障定位都很方便

1.3 适用场景
场景一：季度/月度安全补丁批量更新，需要在维护窗口内完成大量服务器的系统升级
场景二：紧急漏洞修复，比如 log4j 这种 0day，需要快速在全网推送修复补丁
场景三：内核升级，需要有序重启服务器并验证业务恢复状态

1.4 环境要求组件版本要求说明
Ansible 控制节点     CentOS 7+/Ubuntu 18.04+      建议使用专用的运维跳板机
Ansible2.9+        （推荐 2.12+）2.12             版本的性能优化明显
Python              3.6+                         目标机器需要安装 Python
目标服务器           CentOS 7/8、Ubuntu 18/20/22  混合环境需要区分 playbook
网络                控制节点到目标机器 SSH 可达     建议配置 SSH 密钥认证




2.1 准备工作
2.1.1 系统检查
# 检查 Ansible 版本
ansible --version

# 输出示例：
# ansible [core 2.14.3]
# python version = 3.9.16

# 检查控制节点到目标机器的连通性（抽样测试几台）
ansible -i inventory/prod.ini webservers -m ping --limit'web-001,web-002,web-003'

# 检查目标机器的磁盘空间（补丁包需要空间）
ansible -i inventory/prod.ini all -m shell -a "df -h / | tail -1 | awk '{print \$5}'" --limit'web-001'



2.1.2 安装依赖
# CentOS/RHEL 安装 Ansible
sudo yum install -y epel-release
sudo yum install -y ansible

# Ubuntu/Debian 安装 Ansible
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible

# 安装额外的 collection（用于更丰富的模块支持）
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install community.general



2.1.3 配置 Ansible# 创建项目目录结构
mkdir -p ~/ansible-patching/{inventory,group_vars,roles,logs}
cd ~/ansible-patching

# 生成 ansible.cfg
cat > ansible.cfg << 'EOF'
[defaults]
inventory = ./inventory/hosts.ini
remote_user = ops             //使用远程用户 ops，通过 ~/.ssh/ops_key 私钥登录目标服务器。
private_key_file = ~/.ssh/ops_key
host_key_checking = False
timeout = 30
forks = 20                       //最多同时并发处理 20 台主机
log_path = ./logs/ansible.log    // 将 Ansible 日志写入指定文件
callback_whitelist = profile_tasks

[privilege_escalation]
become = True
become_method = sudo
become_user = root

[ssh_connection]
pipelining = True
control_path = /tmp/ansible-%%h-%%p-%%r
EOF


2.2 核心配置
2.2.1 主机清单配置
见目录

2.2.3 核心 Playbook
见目录


2.3 启动和验证
2.3.1 执行补丁更新
# 先在金丝雀环境测试
ansible-playbook playbooks/patching.yml -e "target_hosts=canary" -e "batch_size=1" --check

# 确认无误后正式执行金丝雀批次
ansible-playbook playbooks/patching.yml -e "target_hosts=canary" -e "batch_size=1"

# 金丝雀通过后，分批次执行
ansible-playbook playbooks/patching.yml -e "target_hosts=batch1" -e "batch_size=10"
ansible-playbook playbooks/patching.yml -e "target_hosts=batch2" -e "batch_size=20"

# 或者一次性执行全部，由 serial 控制并发
ansible-playbook playbooks/patching.yml -e "target_hosts=all" -e "batch_size=30"


2.3.2 功能验证
# 查看执行日志
tail -f logs/ansible.log

# 检查更新结果汇总
ansible -i inventory/hosts.ini all -m shell -a "cat /tmp/packages_diff_*.txt 2>/dev/null | head -20" --limit'web-001'

# 检查服务状态
ansible -i inventory/hosts.ini webservers -m shell -a "systemctl is-active nginx"

# 预期输出：每台机器都返回 active



3.1 完整配置示例
3.1.1 无人值守调度脚本
见目录

3.1.2 定时任务配置
# /etc/cron.d/ansible-patching
# 每月第一个周六晚上 22:00 执行补丁更新
0 22 1-7 * 6 root /opt/ansible-patching/run_patching.sh



3.2 实际应用案例
案例一：紧急漏洞修复场景描述：2024 年某天早上收到安全团队通知，某个 glibc 漏洞需要紧急修复，要求当天完成全网更新。
见目录

案例二：内核升级与滚动重启场景描述：需要升级内核修复某个性能问题，但必须保证业务不中断，采用滚动重启方式。
实现步骤：1. 首先修改配置，允许内核更新和自动重启2. 将主机按照业务分组，确保每组重启时有其他组提供服务3. 使用 serial: 1 逐台执行，配合负载均衡摘除


4.1 最佳实践
4.1.1 性能优化
• 开启 SSH Pipelining：减少 SSH 连接次数，大幅提升执行速度
# ansible.cfg
[ssh_connection]
pipelining = True

• 调整 forks 数量：根据控制节点性能和网络情况调整并发数
• 4 核 8G 的机器，forks 设置 50-100 比较合适• 网络带宽充足时可以适当调高
• 更新包比较大时要降低，避免打满带宽
• 使用 Mitogen 加速：Mitogen 是一个 Ansible 加速插件，实测能提升 2-5 倍速度pip install mitogen
# ansible.cfg 添加
[defaults]
strategy_plugins = /path/to/mitogen/ansible_mitogen/plugins/strategy
strategy = mitogen_linear


4.1.2 安全加固
• 使用 Vault 加密敏感信息：
# 创建加密的变量文件
ansible-vault create group_vars/all/vault.yml
# 内容示例
vault_webhook_key: "your-secret-key"
vault_ssh_password: "your-password"

• 限制 sudo 权限：运维账号的 sudoers 配置只开放必要权限
# /etc/sudoers.d/ops
ops ALL=(root) NOPASSWD: /usr/bin/yum, /usr/bin/apt, /usr/sbin/reboot, /usr/bin/systemctl

• 审计日志：所有操作都要有日志记录，方便事后追溯



4.1.3 高可用配置
• 多控制节点：部署多个 Ansible 控制节点，避免单点故障
• AWX/Tower：生产环境建议使用 AWX 或 Ansible Tower，提供 Web 界面、权限控制、执行历史等功能
• 备份 Playbook：将 Playbook 代码托管到 Git，做好版本管理


4.2 注意事项
4.2.1 配置注意事项警告：补丁更新可能导致服务中断，务必在维护窗口执行，并提前做好回滚准备！
• 注意事项一：数据库、消息队列等有状态服务，建议单独处理，不要混在批量更新里
• 注意事项二：更新前一定要检查磁盘空间，空间不足会导致更新失败甚至系统损坏
• 注意事项三：生产环境务必先在金丝雀/预发布环境验证，确认无问题再推全量


4.2.2 常见错误
SSH 连接超时目标机器   SSHD 服务异常或网络不通   检查网络连通性和 SSHD 服务状态
sudo 密码错误         密码过期或权限配置问题     检查 sudoers 配置，考虑使用 NOPASSWD
yum lock 错误        其他进程占用 yum 锁        kill 掉占用进程或等待其完成
重启后连接失败        启动时间过长或启动失败     增加 reboot_timeout，检查启动日志
包依赖冲突           第三方源与官方源冲突使用    exclude 排除问题包，手动处理



5.1 故障排查
5.1.1 日志查看
# 查看 Ansible 执行日志
tail -f /opt/ansible-patching/logs/ansible.log

# 查看详细输出（调试用）
ansible-playbook playbooks/patching.yml -vvv

# 查看目标机器的 yum 日志
ssh web-001 "tail -100 /var/log/yum.log"

# 查看系统日志（排查重启问题）
ssh web-001 "journalctl -b -1 --no-pager | tail -100"


5.1.2 常见问题排查
问题一：部分主机执行失败但没有详细错误信息# 单独对失败主机执行，增加详细输出
ansible-playbook playbooks/patching.yml -e "target_hosts=web-001" -vvv

解决方案：1. 查看 -vvv 输出找到具体错误2. SSH 到目标机器手动执行命令验证3. 检查目标机器的系统日志


问题二：重启后服务没有自动恢复
# 检查服务状态
ansible -i inventory/hosts.ini webservers -m shell -a "systemctl status nginx"

# 检查服务是否设置了开机自启
ansible -i inventory/hosts.ini webservers -m shell -a "systemctl is-enabled nginx"

解决方案：确保关键服务都设置了 enable，在 playbook 中增加服务状态检查


5.3 备份与恢复
5.3.1 备份策略

#!/bin/bash
# 补丁更新前的快照备份脚本

HOSTS_FILE=$1
DATE=$(date +%Y%m%d)

# 对虚拟机创建快照（需要 vCenter API 或 cloud provider API）
whileread host; do
echo"Creating snapshot for ${host}..."
# VMware 示例
# govc vm.snapshot.create -vm="${host}" "pre-patching-${DATE}"

# AWS 示例
# aws ec2 create-snapshot --volume-id $(get_volume_id ${host}) --description "pre-patching-${DATE}"
done < ${HOSTS_FILE}


5.3.2 恢复流程
1. 停止服务：ansible -i inventory/hosts.ini target_host -m service -a "name=nginx state=stopped"
2. 恢复快照：通过虚拟化平台或云平台恢复到补丁前的快照
3. 验证完整性：启动服务器，检查服务状态和数据完整性
4. 重启服务：ansible -i inventory/hosts.ini target_host -m service -a "name=nginx state=started"
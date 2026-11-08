# run_playbook.py
import ansible_runner

# 核心调用
r = ansible_runner.run(
    private_data_dir='/path/to/your/project',  # 项目根目录
    playbook='deploy.yml'                       # Playbook 文件名
)

# 1. 检查整体状态 (最可靠的判断依据)
print(f"Status: {r.status}")   # 期望输出: 'successful'
print(f"Return Code: {r.rc}")  # 期望输出: 0

# 2. 查看汇总统计 (ok/changed/failures 数量)
print(f"Stats: {r.stats}")     # 输出: {'ok': {...}, 'failures': {...}}

# 3. 遍历每个事件，获取具体主机的执行结果
for event in r.events:
    if event['event'] == 'runner_on_failed':
        host = event['event_data']['host']
        msg = event['event_data']['res'].get('msg', 'Unknown error')
        print(f"FAILED: {host} -> {msg}")



# private_data_dir 目录结构
# /path/to/your/project/
# ├── project/
# │   └── deploy.yml          # 你的 Playbook
# ├── inventory/
# │   └── hosts               # Inventory 文件
# └── env/
#     ├── extravars           # 额外变量（JSON/YAML格式）
#     └── passwords           # Vault 密码或敏感密码
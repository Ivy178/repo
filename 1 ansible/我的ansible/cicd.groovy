// Jenkinsfile
pipeline {
    agent any

    environment {
        INVENTORY = 'hosts.ini'
        PLAYBOOK  = 'site.yml'
        ANSIBLE_HOST_KEY_CHECKING = 'False'
    }

    stages {
        // 1. 预检：语法 + dry-run
        stage('Check') {
            steps {
                sh "ansible-playbook -i ${INVENTORY} ${PLAYBOOK} --syntax-check"
                sh "ansible-playbook -i ${INVENTORY} ${PLAYBOOK} --check --diff | tee check.log"
            }
            post {
                always {
                    archiveArtifacts artifacts: 'check.log', allowEmptyArchive: true
                }
            }
        }

        // 2. 人工门禁
        stage('Approve') {
            steps {
                input message: 'check 已通过，确认 apply?', ok: 'Apply'
            }
        }

        // 3. 正式执行
        stage('Apply') {
            steps {
                retry(1) {
                    sh "ansible-playbook -i ${INVENTORY} ${PLAYBOOK}"
                }
            }
        }

        // 4. 失败定位：只对失败机器加 -vv 看详细报错
        stage('Diagnose') {
            when { expression { currentBuild.result == 'FAILURE' } }
            steps {
                sh "ansible-playbook -i ${INVENTORY} ${PLAYBOOK} --limit @site.retry -vv | tee diag.log"
            }
            post {
                always {
                    archiveArtifacts artifacts: 'diag.log', allowEmptyArchive: true
                }
            }
        }
    }

    post {
        failure {
            echo "补跑失败机器: ansible-playbook -i ${INVENTORY} ${PLAYBOOK} --limit @site.retry"
            echo "断点续跑(第三个任务): ansible-playbook -i ${INVENTORY} ${PLAYBOOK} --start-at-task \"启动并开机自启\""
            echo "yaml 不能动时逐步确认: ansible-playbook -i ${INVENTORY} ${PLAYBOOK} --start-at-task \"启动并开机自启\" --step"
            // ansible:跑临时命令（Ad-Hoc）
            echo "对 web 组所有机器执行 ping 模块: ansible web -i hosts.ini -m ping"
            echo "批量查看磁盘使用率: ansible web -i hosts.ini -m shell -a "df -h""
        }
        success {
            // 可选：成功后跑点 ad-hoc 确认
            sh "ansible web -i ${INVENTORY} -m shell -a \"df -h\""
        }
    }
}






# 加密
ansible-vault create secrets.yml
1️⃣ 创建加密的变量文件
ansible-vault create secrets.yml
会提示你设置一个 Vault 密码，然后打开编辑器，写入敏感变量:

# secrets.yml（加密后存盘）
db_password: "MyS3cretP@ss"
api_token: "abc123xyz"
保存退出后,secrets.yml 在磁盘上已经是加密的乱码，可以直接提交到 Git。

2️⃣ Playbook 里引用加密变量
yaml
# deploy.yml
- hosts: web
  become: yes
  vars_files:
    - secrets.yml            # ← 引用加密文件，运行时会自动解密

  tasks:
    - name: 用密码连接数据库
      mysql_user:
        name: app
        password: "{{ db_password }}"
        state: present
3️⃣ 运行时解密
bash
# 方式一:交互式输入 Vault 密码
ansible-playbook -i hosts.ini deploy.yml --ask-vault-pass

# 方式二:从密码文件读（适合 CI/CD）
ansible-playbook -i hosts.ini deploy.yml --vault-password-file ~/.vault_pass





# 分环境加密管理
> 不同环境用不同密码
ansible-vault encrypt --vault-id dev@prompt secrets-dev.yml   //对secrets-dev.yml加密，打上dev标签，执行时输入交互密码，定向到.vault_pass_prod
ansible-vault encrypt --vault-id prod@prompt secrets-prod.yml   // secrets-dev.yml是锁，.vault_pass_prod是钥匙

> 运行时指定对应 vault-id
ansible-playbook deploy.yml --vault-id prod@~/.vault_pass_prod



# roles 目录结构
# roles/nginx/
# ├── tasks/main.yml        # 主任务
# ├── handlers/main.yml     # 触发器
# ├── templates/            # Jinja2 模板
# ├── files/                # 静态文件
# ├── vars/main.yml         # 高优先级变量
# ├── defaults/main.yml     # 默认变量（可覆盖）
# ├── meta/main.yml         # 依赖声明
# └── tests/                # 测试


# 例子:Playbook 调用 Role
# > 目录结构
# text
# project/
# ├── site.yml                  # Playbook（顶层剧本）
# └── roles/
#     └── nginx/                # Role（可复用任务包）
#         ├── tasks/main.yml
#         └── handlers/main.yml

# > Role:roles/nginx/tasks/main.yml
# - name: 安装 nginx
#   yum:
#     name: nginx
#     state: present

# - name: 启动 nginx
#   service:
#     name: nginx
#     state: started
  
# > Playbook:site.yml
# yaml
# - hosts: web
#   become: yes
#   roles:
#     - nginx

# > 执行
# ansible-playbook -i hosts.ini site.yml
# Playbook 说“对 web 组执行”，然后调用 nginx role,role 里的任务就跑了。
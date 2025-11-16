# Go SAE 部署模板

基于 Copier 的 Go 应用部署模板，支持阿里云 SAE + GitHub Actions + Terraform。

## ✨ 设计特点

### 非侵入性设计
所有部署文件隔离在 `.deploy/` 目录，不污染项目根目录：
- ✅ 配置文件：`.deploy.yml` （根目录）
- ✅ 部署文件：`.deploy/` 目录
- ✅ 简单命令：便捷脚本调用

### 模块化组合
- Docker 构建
- GitHub Actions CI/CD
- Terraform 基础设施（可选）
- Makefile 工具（可选）
- 便捷脚本

## 🚀 快速开始

### 1. 安装 Copier

```bash
pip install copier
```

### 2. 应用模板

```bash
cd /path/to/your/go/project
copier copy gh:blksails/go_template .
```

回答交互式问题（应用名、Go 版本、SAE 配置等）

### 3. 生成的结构

```
your-project/
├── .deploy.yml                    # 配置文件
├── .github/                       # GitHub Actions（可选，通过脚本启用）
│   └── workflows/
│       └── build-and-deploy.yml
└── .deploy/                       # 部署目录
    ├── Dockerfile
    ├── .dockerignore
    ├── Makefile              # 可选
    ├── README.md             # 部署说明
    ├── .github/workflows/    # GitHub Actions 源文件
    │   └── build-and-deploy.yml
    ├── terraform/            # 可选
    │   ├── terraform.tf
    │   └── main.tf
    └── scripts/              # 便捷脚本
        ├── build.sh          # 构建
        ├── run.sh            # 运行
        ├── docker-build.sh   # Docker 构建
        ├── docker-push.sh    # Docker 推送
        ├── deploy.sh         # Terraform 部署
        ├── enable-github-actions.sh   # 启用 CI/CD
        └── disable-github-actions.sh  # 禁用 CI/CD
```

## 📝 使用方式

### 方式一：使用脚本（推荐）

```bash
# 构建应用
.deploy/scripts/build.sh

# 本地运行
.deploy/scripts/run.sh

# Docker 构建
.deploy/scripts/docker-build.sh

# Docker 推送（指定版本）
TAG=v1.0.0 .deploy/scripts/docker-push.sh

# Terraform 部署
.deploy/scripts/deploy.sh init
.deploy/scripts/deploy.sh plan
.deploy/scripts/deploy.sh apply
```

### 方式二：使用 Makefile

```bash
cd .deploy

# 开发
make build
make run
make test
make clean

# Docker
make docker-build
make docker-push

# Terraform
make terraform-init
make terraform-plan
make terraform-apply
```

## ⚙️ 配置说明

### .deploy.yml

项目根目录的配置文件，包含所有部署参数：

```yaml
app:
  name: myapp
  version: 1.23.3
  port: 8080
  health_check: /healthz

registry:
  endpoint: registry.cn-hangzhou.aliyuncs.com
  namespace: blksails
  image_name: myapp

sae:
  region: cn-hangzhou
  replicas: 2
  cpu: 1000
  memory: 2048

features:
  terraform: true
  makefile: true
  tests: true
  private_repos: false

services:
  database: true
  redis: true
```

修改配置后，更新模板：
```bash
copier update
```

## 🔧 GitHub Actions CI/CD

### 启用方式

**方式一：应用模板时启用**

在交互式配置中选择 `enable_github_actions: yes`，工作流会自动生成到项目根目录。

**方式二：使用脚本启用**

```bash
.deploy/scripts/enable-github-actions.sh
```

脚本会提示选择：
1. 创建符号链接（推荐，自动同步更新）
2. 复制文件（独立管理）

**禁用 GitHub Actions：**

```bash
.deploy/scripts/disable-github-actions.sh
```

### 配置 GitHub Secrets

在 GitHub 仓库的 **Settings → Secrets and variables → Actions** 中添加：

**必需：**
- `ALIYUN_REGISTRY_USERNAME` - 阿里云容器镜像服务用户名
- `ALIYUN_REGISTRY_PASSWORD` - 阿里云容器镜像服务密码

**可选（私有仓库）：**
- `GH_TOKEN` - GitHub Personal Access Token
- `NETRC_LOGIN` - 私有包仓库登录
- `NETRC_PASSWORD` - 私有包仓库密码
- `NETRC_FILE` - .netrc 文件内容（base64 编码）

### 触发部署

```bash
git add .
git commit -m "Add SAE deployment"
git push origin main
```

CI/CD 流程会自动：
- 运行测试（如果启用）
- 构建 Go 二进制
- 构建并推送 Docker 镜像
- 按分支/标签自动标记

## 🏗️ Terraform 部署

### 初始化和部署

```bash
cd .deploy/terraform

# 初始化
terraform init

# 查看计划
terraform plan \
  -var="database_url=$DATABASE_URL" \
  -var="redis_url=$REDIS_URL"

# 应用部署
terraform apply \
  -var="database_url=$DATABASE_URL" \
  -var="redis_url=$REDIS_URL"
```

或使用脚本：
```bash
.deploy/scripts/deploy.sh init
.deploy/scripts/deploy.sh plan
.deploy/scripts/deploy.sh apply
```

## 🐳 Docker 说明

### 本地构建

```bash
# 使用脚本
.deploy/scripts/docker-build.sh

# 或直接使用 Docker
docker build -f .deploy/Dockerfile -t myapp:latest .
```

### 推送镜像

```bash
# 指定版本
TAG=v1.0.0 .deploy/scripts/docker-push.sh

# 或使用 Makefile
cd .deploy && IMAGE_TAG=v1.0.0 make docker-push
```

## 📊 健康检查

应用必须实现健康检查端点（默认 `/healthz`）：

```go
package main

import (
    "fmt"
    "net/http"
)

func main() {
    http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
        w.Write([]byte("OK"))
    })
    
    // 其他路由...
    
    fmt.Println("Server starting on :8080")
    http.ListenAndServe(":8080", nil)
}
```

## 🔍 故障排查

### 脚本权限问题

```bash
chmod +x .deploy/scripts/*.sh
```

### Docker 构建失败

- 确保在项目根目录有 `go.mod` 和 `go.sum`
- 检查 `.deploy/.dockerignore` 配置
- 验证 Docker 构建上下文

### CI/CD 失败

- 验证 GitHub Secrets 配置
- 检查 `.github/workflows/` 文件是否存在
- 查看 GitHub Actions 日志

### Terraform 错误

- 确认阿里云凭证配置
- 检查 SAE 服务是否已开通
- 验证变量值是否正确

## 🎯 最佳实践

1. **配置管理**
   - 所有配置集中在 `.deploy.yml`
   - 敏感信息使用环境变量或 Secrets

2. **版本控制**
   - 提交 `.deploy/` 目录到 Git
   - `.deploy.yml` 根据需要决定是否提交

3. **CI/CD**
   - 使用符号链接保持 workflow 同步
   - 定期检查 Actions 日志

4. **部署流程**
   - 开发环境：使用脚本本地测试
   - 测试环境：使用 `develop` 分支触发
   - 生产环境：使用 tag 或 `main` 分支

## 📦 模板更新

更新模板配置：

```bash
copier update
```

Copier 会记住你的配置，只提示新的或修改的问题。

## 🌐 GitHub 仓库

模板托管在：https://github.com/blksails/go_template

使用 GitHub 引用：
```bash
copier copy gh:blksails/go_template /path/to/project
```

## 📚 技术栈

- **模板工具**: Copier + Jinja2
- **容器化**: Docker (Multi-stage build)
- **CI/CD**: GitHub Actions
- **IaC**: Terraform (Aliyun Provider)
- **云平台**: Aliyun SAE + ACR
- **数据库**: Supabase (PostgreSQL)
- **缓存**: Redis

## 📖 更多文档

- [.deploy/README.md](.deploy/README.md) - 详细的部署说明
- [Copier 文档](https://copier.readthedocs.io/)
- [阿里云 SAE](https://www.aliyun.com/product/sae)
- [Docker 文档](https://docs.docker.com/)
- [Terraform 阿里云 Provider](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs)

## 🎉 示例项目

参考完整示例：`/Users/hysios/Projects/BlackSail/services/kf`

## 📄 许可证

此模板供 BlackSail 项目内部使用。

# Lambda Code Interpreter

一个基于AWS Lambda的Python代码执行器，专为AI Agent的代码解释功能设计。配合[lambda-tool-mcp-server](https://awslabs.github.io/mcp/servers/lambda-tool-mcp-server/)使用，为Agent提供安全的代码执行沙盒环境。

## 主要用途

本项目主要用于配合[lambda-tool-mcp-server](https://awslabs.github.io/mcp/servers/lambda-tool-mcp-server/)实现AI Agent的代码解释器功能：

1. **Agent生成代码** - AI Agent根据用户需求生成Python代码
2. **MCP服务器调用** - lambda-tool-mcp-server接收代码并调用此Lambda函数
3. **安全执行** - 在Lambda沙盒环境中安全执行代码
4. **结果返回** - 返回执行结果和生成的图像给Agent

## 功能特性

- 执行任意Python代码
- 动态安装Python模块
- 自动处理图像输出（PNG、JPEG、JPG、GIF、WebP）
- 临时文件管理
- Base64编码的图像返回
- 与MCP服务器无缝集成

## 架构

该项目使用AWS SAM（Serverless Application Model）构建，包含：

- **Lambda函数**: 执行Python代码的无服务器函数
- **运行时**: Python 3.13
- **架构**: ARM64
- **内存**: 1024MB
- **超时**: 600秒

## 部署

### 前提条件

- AWS CLI已配置
- SAM CLI已安装
- 适当的AWS权限

### 部署步骤

1. 构建应用程序：
```bash
sam build
```

2. 部署应用程序：
```bash
sam deploy --guided
```

## 集成配置

### 与lambda-tool-mcp-server集成

1. 部署此Lambda函数后，获取函数名称（如：lambda-code-interpreter-RunPythonCode-xxx）
2. 配置MCP服务器，在Claude Desktop或其他支持MCP的客户端配置文件中添加：

```json
{
  "mcpServers": {
    "awslabs.lambda-tool-mcp-server": {
      "command": "uvx",
      "args": ["awslabs.lambda-tool-mcp-server@latest"],
      "env": {
        "AWS_REGION": "us-west-2",
        "FUNCTION_PREFIX": "lambda-code-interpreter"
      }
    }
  }
}
```

3. Agent即可通过MCP服务器调用代码执行功能

### 工作流程

```
AI Agent → 生成代码 → lambda-tool-mcp-server → Lambda函数 → 执行结果 → Agent
```

### 使用示例

使用Amazon Q CLI与Agent交互：

```bash
# 基本计算示例
q chat --no-interactive "生成python代码调用lambda-tool-mcp-server计算24*23434/2574"

# 复杂计算示例
q chat --no-interactive "生成python代码调用lambda-tool-mcp-server计算斐波那契数列前20项"
```

## 技术细节

### 临时文件管理

- 函数执行前后自动清理`/tmp`目录
- 支持的图像格式：PNG、JPEG、JPG、GIF、WebP
- 图像自动转换为Base64编码返回

### 模块安装

- 使用pip动态安装所需模块
- 模块安装到`/tmp`目录
- 自动设置`PYTHONPATH`环境变量

### 错误处理

- 捕获并返回代码执行错误
- 模块安装失败时继续执行
- 文件操作异常处理

## 限制

- 执行时间限制：600秒
- 内存限制：1024MB
- 临时存储：512MB（Lambda限制）
- 仅支持Python 3.13运行时

## 开发

### 本地测试

```bash
# 本地调用函数
sam local invoke RunPythonCode -e events/event.json

# 启动本地API
sam local start-api
```

### 项目结构

```
lambda-code-iterperter/
├── app.py              # Lambda函数代码
├── template.yml        # SAM模板
└── README.md          # 项目文档
```

## 许可证

本项目采用MIT许可证。
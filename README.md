# E-Commerce Data Platform
## 项目进度
- [x] Day 1: 环境搭建和第一个Pipeline ✅
## 技术栈
- Azure Data Factory
- Azure Data Lake Storage Gen2
- Python, SQL
- Azure DevOps
## 项目结构
```
ecommerce-data-platform/
├── data/                  # 数据文件
├── scripts/              # 脚本
│   ├── python/          # Python脚本
│   └── sql/             # SQL脚本
├── pipelines/           # Pipeline配置
└── docs/                # 文档
```

## 已完成功能
- [x] Azure环境搭建
- [x] Storage Account和容器创建
- [x] Data Factory创建
- [x] 数据生成和上传
- [x] 第一个Copy Pipeline

## 技术亮点
- 使用Managed Identity进行安全认证
- Bronze-Silver-Gold数据湖分层架构
- 参数化Pipeline设计

## 下一步
- [ ] 实现批量处理（ForEach）
- [ ] 添加数据转换（Mapping Data Flow）
- [ ] 实现增量加载

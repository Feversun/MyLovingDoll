# MyLovingDoll - ObjectCamp MVP

一款基于 iOS Vision 框架的智能照片主体提取与聚类应用。

## 📱 当前状态

✅ **阶段 2: VisionKit 增强版已完成** - 交互式主体调整 + 手动编辑功能

## 🎯 核心功能

### 1. 智能主体提取 (ObjectCase)
- 自动从照片中提取主体对象(娃娃、玩具等)
- 生成透明背景贴纸
- 提取特征向量用于智能分类

### 2. 自动聚类 (EntityCluster)
- 基于深度学习特征向量识别同一对象
- 余弦相似度算法自动分组
- 可调节识别敏感度

### 3. 可视化管理
- 网格展示所有识别出的对象
- 每个对象显示封面图和照片数量
- 点击查看对象的所有照片

### 4. 手动校正
- 重命名对象
- 拆分错误分组
- 合并相同对象
- 标记非目标照片

## 📂 项目结构

```
MyLovingDoll/
├── Models/                          # 数据层
│   ├── TargetSpec.swift            # 目标配置(如:doll, car)
│   ├── Subject.swift               # 提取的主体
│   ├── Entity.swift                # 聚类后的实体
│   └── ProcessingTask.swift       # 处理任务管理
│
├── Services/                        # 业务逻辑层
│   ├── FileManager+ObjectCamp.swift     # 文件存储管理
│   ├── ObjectCaseService.swift          # 主体提取服务
│   └── EntityClusterService.swift       # 聚类服务
│
├── Views/                           # 界面层
│   ├── ObjectCampHomeView.swift         # 首页(选择+进度)
│   ├── PhotoPickerView.swift            # 照片选择器
│   ├── EntityLibraryView.swift          # 对象库网格
│   └── EntityDetailView.swift           # 对象详情
│
└── MyLovingDollApp.swift           # 应用入口
```

## 🚀 快速开始

### 1. 配置权限

在 Xcode 的 Info 设置中添加:

```
Privacy - Photo Library Usage Description: 需要访问相册以识别和整理您的娃娃照片
Privacy - Photo Library Additions Usage Description: 需要保存处理后的照片
```

详细配置说明见 [SETUP.md](SETUP.md)

### 2. 运行要求

- iOS 17.0+
- Xcode 15.0+
- 建议真机测试(Vision 功能)

### 3. 使用流程

1. 启动应用
2. 点击"选择照片" → 选择包含对象的照片
3. 点击"开始整理" → 自动提取与聚类
4. 查看"对象库" → 浏览识别结果
5. 点击对象 → 查看详情并校正

## 🛠 技术栈

| 技术 | 用途 |
|------|------|
| **SwiftUI** | 声明式界面开发 |
| **SwiftData** | 本地数据持久化 |
| **Vision** | AI 主体识别与特征提取 |
| **PhotoKit** | 相册访问与管理 |
| **Combine** | 响应式编程 |

## 📊 关键算法

### 主体提取
使用 Vision 的 `VNGenerateForegroundInstanceMaskRequest`:
- 自动分离前景/背景
- 生成实例掩码
- 提取边界框信息

### 特征提取
使用 `VNGenerateImageFeaturePrintRequest`:
- 生成 256 维特征向量
- 用于相似度计算

### 聚类算法
基于余弦相似度的贪心聚类:
```
相似度 = dot(v1, v2) / (||v1|| * ||v2||)
阈值 = 0.75 (可调整)
```

## 📝 数据存储

### SwiftData 存储
- TargetSpec (目标配置)
- Subject (主体记录)
- Entity (实体分组)
- ProcessingTask (任务状态)

### 文件系统存储
```
Documents/ObjectCamp/
└── {specId}/              # 例如: doll
    ├── subjects/          # 贴纸 PNG
    ├── thumbnails/        # 缩略图 JPEG
    └── temp/              # 临时文件
```

## 🔮 下一步开发计划

基于 ObjectCamp MVP,将开发完整的 MyLovingDoll 功能:

### Phase 2: 娃娃档案系统
- [ ] 为每个娃娃建立详细档案
- [ ] 添加性格标签与描述
- [ ] 图片集管理

### Phase 3: AI 幻想生成
- [ ] 接入 nano banana API
- [ ] 生成幻想画面
- [ ] 生成幻想故事

### Phase 4: 陪伴记录
- [ ] 每日娃娃选择
- [ ] 拍照打卡
- [ ] 情绪日记
- [ ] 睡眠记录

## 🐛 已知问题

1. Vision 主体识别需要清晰的前景/背景对比
2. 复杂背景可能导致识别不准确
3. 聚类阈值需要根据实际使用调整

## 📄 许可证

私有项目

## 👤 作者

How Sun

---

**当前版本**: ObjectCamp MVP v1.0  
**最后更新**: 2025-10-29

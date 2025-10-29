# ObjectCamp MVP - 配置说明

## 必须配置的权限

### 1. 相册访问权限

在 Xcode 中打开项目后,需要添加以下权限描述:

1. 选择项目根目录中的 `MyLovingDoll` target
2. 选择 `Info` 标签页
3. 添加以下 Key-Value 对:

| Key | Value |
|-----|-------|
| `Privacy - Photo Library Usage Description` | 需要访问相册以识别和整理您的娃娃照片 |
| `Privacy - Photo Library Additions Usage Description` | 需要保存处理后的照片 |

或者直接在 `Info.plist` 中添加:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册以识别和整理您的娃娃照片</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>需要保存处理后的照片</string>
```

## 项目结构说明

```
MyLovingDoll/
├── Models/                      # 数据模型
│   ├── TargetSpec.swift        # 目标规格配置
│   ├── Subject.swift           # 主体提取结果
│   ├── Entity.swift            # 聚类实体
│   └── ProcessingTask.swift   # 处理任务
├── Services/                    # 核心服务
│   ├── FileManager+ObjectCamp.swift    # 文件管理
│   ├── ObjectCaseService.swift         # 主体提取服务
│   └── EntityClusterService.swift      # 聚类服务
├── Views/                       # 界面
│   ├── ObjectCampHomeView.swift        # 主界面
│   ├── PhotoPickerView.swift           # 照片选择器
│   ├── EntityLibraryView.swift         # 实体库网格
│   └── EntityDetailView.swift          # 实体详情
└── MyLovingDollApp.swift       # 应用入口
```

## 功能说明

### 已实现功能

1. ✅ **主体提取 (ObjectCase)**
   - 使用 Vision framework 的 `VNGenerateForegroundInstanceMaskRequest` 提取照片主体
   - 自动生成贴纸和缩略图
   - 提取特征向量用于聚类

2. ✅ **智能聚类 (EntityCluster)**
   - 基于余弦相似度的特征向量聚类
   - 自动识别同一对象
   - 可调节相似度阈值 (默认 0.75)

3. ✅ **照片选择**
   - PHPicker 多选照片
   - 支持未来扩展相册选择

4. ✅ **实体管理**
   - 网格展示所有实体
   - 查看实体详情和所有照片
   - 重命名、拆分、合并、标记非目标

5. ✅ **文件管理**
   - 按 specId 分目录存储
   - 贴纸 PNG + 缩略图 JPEG
   - 支持清理数据

6. ✅ **进度显示**
   - 实时显示处理进度
   - 可在处理中途查看已完成结果

### 使用流程

1. 启动应用
2. 点击"选择照片"选取包含娃娃的照片
3. 点击"开始整理"开始处理
4. 等待处理完成(可看到进度)
5. 点击"已整理 X 个对象"进入实体库
6. 点击任意实体查看详情
7. 在详情页可以:
   - 重命名对象
   - 选择照片后拆分为新对象
   - 标记照片为非目标

### 默认配置

- **目标类型**: doll (娃娃)
- **相似度阈值**: 0.75
- **存储位置**: Documents/ObjectCamp/doll/

## 运行要求

- iOS 17.0+
- Xcode 15.0+
- 真机测试 (Vision 功能在模拟器上可能不稳定)

## 下一步扩展方向

1. **相册选择器** - 支持选择整个相册
2. **多目标支持** - 支持切换不同的 TargetSpec (car, person 等)
3. **手动调整** - 集成 VisionKit 的交互式主体选择
4. **批量操作** - 在实体库支持批量合并/删除
5. **导出分享** - 导出整理好的贴纸
6. **撤销/重做** - 完整的操作历史管理

## 常见问题

### Q: 为什么没有识别出主体?
A: Vision 的主体识别需要清晰的前景/背景对比。建议使用背景简单的照片。

### Q: 聚类不准确怎么办?
A: 可以在 `EntityClusterService.swift` 中调整 `similarityThreshold` 值。值越大越严格,值越小越宽松。

### Q: 如何清空所有数据?
A: 进入设置页面,点击"清空所有数据"。

## 技术栈

- SwiftUI - 界面框架
- SwiftData - 数据持久化
- Vision - 主体识别与特征提取
- PhotoKit - 相册访问
- FileManager - 文件存储

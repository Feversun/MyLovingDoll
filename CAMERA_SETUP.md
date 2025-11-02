# 相机功能配置说明

## 权限配置

需要在项目中配置相机权限，请按以下步骤操作：

### 方式1：通过Xcode配置

1. 打开Xcode项目
2. 选择项目的Target
3. 进入 **Info** 标签页
4. 在 **Custom iOS Target Properties** 中添加：
   - Key: `Privacy - Camera Usage Description`
   - Value: `需要使用相机拍摄对象进行识别`

### 方式2：通过Info.plist配置

如果项目有Info.plist文件，添加以下内容：

```xml
<key>NSCameraUsageDescription</key>
<string>需要使用相机拍摄对象进行识别</string>
```

## 功能说明

### 相机拍照Tab

- **位置**：第3个Tab，图标为相机
- **功能**：
  1. 打开相机实时预览
  2. 屏幕中央显示引导框，提示用户将对象放在框内
  3. 点击底部拍照按钮拍摄照片
  4. 自动调用现有的对象识别流程
  5. 识别成功后对象会出现在对象库中

### UI元素

- **引导框**：280x280的圆角矩形，渐变蓝色边框
- **拍照按钮**：底部中央的白色圆形按钮
- **状态提示**：
  - 顶部：显示"拍摄对象"
  - 引导框内：显示"将对象放在框内"
  - 识别时：显示"识别中..."进度条

### 识别流程

1. 用户拍照
2. 保存照片到临时目录
3. 调用EntityClusterService.processImage()
4. 提取主体并创建Entity
5. 保存到SwiftData数据库
6. 用户可在对象库中查看

## 技术细节

- 使用AVFoundation框架
- 支持后置摄像头
- 自动请求相机权限
- 进入Tab时自动启动相机
- 离开Tab时自动停止相机

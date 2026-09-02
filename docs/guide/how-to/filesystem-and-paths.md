# 管理文件系统与应用路径

## 目标

基于[平台诊断工具](../tutorials/platform-toolbox.md)，把设置写入稳定的首选项目录，查询路径信息，列出匹配文件，并区分可执行目录、当前目录、用户文档目录和应用配置目录。完成后，程序从不同工作目录启动仍能找到自己的配置。

## 适用场景

适用于配置、存档、缓存、导出目录和随程序分发的只读资源。`basePath` 适合定位可执行文件旁资源，`preferencePath` 适合配置和存档，`userFolder` 适合用户主动管理的文档、图片等；`currentDirectory` 只代表启动时工作目录，不应默认当配置根。

## 准备工作

确认平台探针能取得非空首选项目录。文件操作会真实修改磁盘，只在明确的测试子目录中练习，并保留清理边界。`FileSystem.remove` 可删除文件或空目录，测试前后都核对准确路径；不要拼接不受信任的 `..` 片段越出目标目录。

## 操作步骤

先用 `ApplicationPaths.preferencePath("GuideLab", "SdlNotes")` 获取并准备应用目录，再在其中建立专用 `drafts` 子目录。创建前查询 `FileSystem.exists`；创建后匹配 `FileSystem.pathInfo` 的 `Some` 与 `None`。需要列出配置时，调用 `globDirectory` 并明确传入 `"*.json"` 和大小写策略。实际文件内容使用仓颉标准库读写，SDL `FileSystem` 负责跨平台的目录和文件操作。

若应用资源随可执行文件分发，先匹配 `ApplicationPaths.basePath()`；None 时给出明确错误或使用已配置替代目录。用户主动选择的文件路径来自对话框，不应被强行搬到首选项目录。

## 确认结果

从两个不同终端目录启动程序，打印出的 preference 根应相同，currentDirectory 可不同。`drafts` 第一次创建，第二次运行不报“已存在”；`pathInfo` 返回目录类型。放入两个 JSON 与一个 TXT 后，glob 只列 JSON。所有路径都记录为平台实际分隔符；测试清理后确认只删除了专用子目录，没有触及用户已有文件。

## 常见错误

手工写 `C:\Users\name` 或 `/home/name` 会失去可移植性；把 currentDirectory 当资源目录会随启动方式改变。`basePath` 和 userFolder 可能返回 None，不能直接解包。glob 模式和大小写规则要按业务明确设置。复制或重命名前先检查目标是否已有重要文件；本页 API 不替你决定覆盖策略。

## 可以继续修改

为配置更新增加可恢复备份：先检查原文件是否存在，存在时用 `copyFile` 复制为 `.bak`；写入新文件并确认存在后，再按产品策略保留或删除备份。这个练习会真实修改磁盘，只能在明确的测试目录中执行，并且不得覆盖已有用户文件。

## 相关 API

- [`ApplicationPaths`](../../api/sdl/system/ApplicationPaths.md)：可执行、当前、首选项和用户目录。
- [`UserFolder`](../../api/sdl/system/UserFolder.md)：标准用户目录类别。
- [`FileSystem`](../../api/sdl/system/FileSystem.md)：创建、删除、复制、重命名、信息与 glob。
- [`PathInfo`](../../api/sdl/system/PathInfo.md)：类型、大小和时间信息。

## 下一步

继续[显示器、窗口状态与全屏](displays-fullscreen-window.md)，处理另一个必须运行时查询的平台边界。

# CangjieSDL 开发工具

`.dev` 保存仓库维护者使用的检查脚本。所有临时文件写入 `target/dev`，不会混入源码或文档目录。

在仓库根目录运行：

```text
python .dev/cli.py check docs
python .dev/cli.py check snippets
python .dev/cli.py test examples
python .dev/cli.py test tools
```

- `check docs`：检查 README、示例和指南中的本地链接与标题锚点，并确认每个公开类型、函数、成员、重载及可调用签名都有 API 参考。
- `check snippets`：把 README、示例、API 和指南中标记为 `verify` 的完整程序汇总到临时 cjpm 工程并编译。指南和 README 不允许保留未验证的仓颉片段。
- `test examples`：逐个构建 `examples` 下的公开示例。
- `test tools`：运行开发工具自身的契约测试。

这些检查只验证结构、编译和 API 覆盖。窗口显示、字体回退、DPI 和 GPU 输出仍需在目标平台做视觉验证。

# Umineko When They Cry - Question Arcs Chinese

Steam《海猫鸣泣之时》**EP1–4 提问篇中文正文补丁**，适用于 Windows 原版（App ID **406550**）。使用日不落汉化组公开译文作文本适配，继续从 Steam 正常启动游戏。

**这是非官方正文适配版 v0.1.0，并非全界面汉化。** 需要自行购买并安装 Steam 游戏。此仓库只提供补丁差异数据、中文字体和安装工具，不包含游戏程序、完整原版脚本、图片、音乐、语音或个人存档。

## 汉化范围

| 内容 | 状态 |
| --- | --- |
| EP1、EP2、EP3、EP4 正文 | 已适配 |
| 各章茶会、隐藏茶会 | 已适配 |
| 红字、蓝字及原文强调格式 | 已适配并作检查 |
| 菜单、人物资料、图片内文字 | 仍有原文，未作完整汉化 |
| PS3 立绘、背景、语音 | 本补丁不提供 |

共适配 **40,167 行对白、67,506 个显示片段**。译文来自日不落相关公开脚本仓库；另有 **2 个 Steam 特有片段**作兼容补译。译文与 Steam 的分句有自动对齐和少量人工调整，仍可能存在版本差异或断句问题，未进行完整人工通关校对。详情见 [来源与署名](CREDITS.md) 和 [验证记录](docs/VALIDATION.md)。

## 在另一台电脑安装

1. 在 Steam 安装 **Umineko When They Cry - Question Arcs**（EP1–4 提问篇），并关闭游戏。
2. 下载本仓库的完整 ZIP：仓库页面绿色 **Code → Download ZIP**。将 ZIP **全部解压**到普通文件夹，例如 `D:\UminekoChinesePatch`。不要在压缩包内部运行。
3. 在 Steam 游戏库右键游戏，选择 **管理 → 浏览本地文件**，记住打开的游戏目录。它应包含 `Umineko1to4.exe` 和 `0.utf`。
4. 双击补丁目录中的 **`Install.bat`**，在弹出的窗口中选择上述游戏目录。
5. 等待显示“安装完成”，从 Steam 正常启动游戏。如果出现语言选择，选择 **English**，正文就会显示为中文。

安装包包含全部所需字体；解压后安装不需要联网。使用 Windows 自带的 PowerShell 5.1，通常不需要管理员权限。若游戏目录不可写，可将游戏通过 Steam 移动到有写入权限的游戏库后再安装。

**不要叠加安装到 07th-Mod、其他汉化或已经修改过的脚本上。** 安装工具只接受下文记录的 Steam 原版文件，版本不符会停止，不会强行覆盖。遇到此提示，先保存自己的模组和备份，再通过 Steam“属性 → 已安装文件 → 验证游戏文件的完整性”恢复原版。游戏更新导致版本变化时，也需要重新核对适配。

## 校验与恢复

- **`Verify.bat`**：选择游戏目录，检查中文脚本和四个字体文件是否完整。
- **`Restore.bat`**：选择游戏目录，恢复本工具安装前的脚本及字体。
- 自动备份保存在游戏目录的 `umineko-cn-backup-…` 文件夹，安装记录为 `.umineko-cn-install.json`。**需要恢复时必须保留它们。** 恢复后备份文件夹继续保留，供自行留存。
- 若安装后的文件已被其他模组更改，或备份损坏，工具会停止恢复，以免覆盖后来的修改。
- 安装、校验、恢复均不读写 `saves`。老存档加载、Steam 云同步和成就没有逐项验证；建议更换补丁前自行保留存档副本。
- Steam 验证完整性或更新可能覆盖中文脚本。确认回到支持的原版后可重新安装。

如果正文已是本补丁版本但字体不完整，可先用 `Restore.bat` 恢复，再安装。如果是手动复制脚本、没有本工具的备份记录，可手动将 `payload/NotoSansCJKjp-Regular.otf` 复制到游戏的 `fonts/face0.otf`，将 `payload/NotoSansCJKjp-Bold.otf` 分别复制成 `fonts/face1.otf`、`face2.otf`、`face3.otf`；先保留原字体，随后运行 `Verify.bat`。仅复制 `0.utf` 不足以保证另一台电脑正确显示中文。

## 文件说明

| 文件或目录 | 用途 |
| --- | --- |
| `Install.bat` / `Restore.bat` / `Verify.bat` | 双击安装、恢复、校验 |
| `Patch.ps1` | 可查看源码的安装工具 |
| `payload/dialogue.delta.gz` | 正文差异补丁，在本机原版脚本上生成中文脚本 |
| `payload/NotoSansCJKjp-*.otf` | Noto Sans CJK JP 中文兼容字体 |
| `manifest.json` | 版本、来源和 SHA-256 校验值 |
| `docs/` | 检查范围与结果 |
| `licenses/` / `CREDITS.md` | 字体许可、上游声明及署名 |

安装只更改游戏的 `0.utf` 和 `fonts/face0.otf` 至 `fonts/face3.otf`，并新建备份和安装记录。它不替换游戏程序。字体中的 Bold 用于原脚本的多种强调样式，显示效果与原英文的斜体/字形可能不同。

## 版本信息

| 文件 | SHA-256 |
| --- | --- |
| 支持的原版 `0.utf` | `9ef6a9f08b03eac8ef24ceb839f0083c2739dbb403d2fde33f838b994298f937` |
| 生成的中文 `0.utf` | `ef110ab517db9f05392189774fa50e7e032197957529057d6f954a34e0350b02` |
| 已验证的 `Umineko1to4.exe` | `b9223161d5d2b564da45b614d7b6442d2bd468af5ed0aaf9131c81a9bfe4d0c3` |

工具按文件内容核对版本，不按某台电脑的盘符或安装路径匹配。字体与差异数据的校验值见 [manifest.json](manifest.json)。

高级用法（游戏目录按实际位置填写）：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Patch.ps1 -Mode Install -GameDirectory "D:\SteamLibrary\steamapps\common\Umineko"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Patch.ps1 -Mode Verify -GameDirectory "D:\SteamLibrary\steamapps\common\Umineko"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Patch.ps1 -Mode Restore -GameDirectory "D:\SteamLibrary\steamapps\common\Umineko"
```

参数只对这次运行生效，不修改系统的长期执行策略。

反馈问题时，请描述章节、上下文、现象和补丁版本；无需提交自己的存档、完整游戏文件或个人路径。本项目与 07th Expansion、MangaGamer、日不落汉化组及 Umineko Project 没有官方隶属关系。



如本项目涉及侵权，请联系告知，我们将及时删除相关内容。

## **感谢日不落汉化组的辛勤翻译与付出**

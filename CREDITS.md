# 来源与署名

## 游戏与中文译文

- 原作：07th Expansion《うみねこのなく頃に》。Steam 版本：MangaGamer 发行的 **Umineko When They Cry - Question Arcs**，App ID 406550。
- 中文译文：日不落汉化组（SNS Team）及相关贡献者。相关项目入口：[日不落移植版页面](https://snsteam.club/port/)。
- 此次适配使用的公开文本仓库：[Umineko-Project-CN/umineko-scripting](https://github.com/Umineko-Project-CN/umineko-scripting)。分支 `cn_staging`，固定提交 [`162a77eb764f181236b8044d1f75a93458ea4937`](https://github.com/Umineko-Project-CN/umineko-scripting/tree/162a77eb764f181236b8044d1f75a93458ea4937)。中文来源为 `story/ep1/cn` 至 `story/ep4/cn`；对齐参照同仓库的旧版、新版英文文本。
- 感谢 Umineko Project、Knox Translations、SNS Team 及上游列出的第三方贡献者。保留上游软件的 [BSD 声明](licenses/UminekoProject-BSD.txt)。

此仓库只做 Steam Windows 原版显示文本的适配和部署，不应将已有汉化稿表述为仓库作者原创译文。原游戏、译文和其他第三方内容的权利归各自权利人；所附软件许可不等于对游戏内容或译文作新的授权。此适配不代表原作、发行商或汉化组的官方发布或背书。

原版 Steam 与中文源版本存在章节边界、分句和措辞差异。适配使用自动对齐、重新分段、少量人工分组；95 个仅含停顿/标点的显示片段在保留脚本控制符的同时留空。另有两处 Steam 特有句子作兼容补译：民明书房一句（原版脚本行 184405）及呼喊缘寿的一句（原版脚本行 214658）。一处红字范围在最终脚本中补回。自动匹配并不等于完整人工校对。

## 字体

使用未经修改的 **Noto Sans CJK JP Regular / Bold 1.004** 字体文件，字体内部版本为 `Version 1.004;PS 1.004;hotconv 1.0.82;makeotf.lib2.5.63406`。

- [官方字体仓库 v1.004 对应提交](https://github.com/notofonts/noto-cjk/tree/f36eda03dfa5582a6d49abbfb5c83d0209584158)
- Copyright © 2014, 2015 Adobe Systems Incorporated.
- [SIL Open Font License 1.1](licenses/NotoSansCJK-OFL.txt)，[字体内嵌版权声明](licenses/NotoSansCJK-COPYRIGHT.txt)。

所附字体与上述官方提交中的文件内容一致；安装时仅复制为游戏要求的文件名，不修改字体内部名称或字体数据。

## 本仓库的工具代码

`Patch.ps1`、三个 `.bat` 启动文件及 `tools/make_delta.py` 的新增工具代码采用 [MIT 许可](licenses/Installer-MIT.txt)。该许可只覆盖这些工具代码，不覆盖第三方译文、游戏内容或字体。字体继续遵循其原有 OFL 许可。

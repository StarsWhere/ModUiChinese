# ModUiChinese

为模组菜单、设置和计数器提供简体中文翻译。

## 安装

关闭游戏，从 [Releases](https://github.com/StarsWhere/ModUiChinese/releases) 下载模组包，将包内目录合并到游戏根目录。另需安装兼容版本的 BSIPA、BeatSaberMarkupLanguage、SiraUtil，以及单独下载的 [LocalModUI](https://github.com/StarsWhere/LocalModUI/releases)；依赖版本见 [manifest.json](scripts/mod_ui_chinese/ModUiChinese.manifest.json)。

## 构建

准备 Windows x64、PowerShell 7、.NET 8 SDK 或更新版本、Python 3，以及包含上述依赖的 Beat Saber 1.45.2_28848：

~~~powershell
git clone --recurse-submodules https://github.com/StarsWhere/ModUiChinese
Set-Location ModUiChinese
pwsh -File scripts/build_release.ps1 -GameRoot 'C:\Games\Beat Saber'
~~~

发布包和校验文件生成在 `releases/`。目标依赖包含本地移植版本；本次拆分未追加游戏内运行或 VR 验证。

原创代码采用 [MIT 许可](LICENSE)，第三方说明见 [THIRD-PARTY-NOTICES.txt](THIRD-PARTY-NOTICES.txt)。

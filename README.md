# ST-Preread
目的是做成一个可用的TTS+文生图存储的小说阅读器，可能采用新的格式。

## 如何运行测试

需要 Flutter 3.47（stable）或更新版本。

```sh
flutter pub get
flutter analyze   # 静态检查
flutter test      # 单元测试与 widget test
```

当前阶段界面使用内存中的示例数据，不读取真实文件、不播放真实音频，数据也不会持久化。

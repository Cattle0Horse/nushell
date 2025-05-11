文档：https://platform.moonshot.cn/docs/api/chat
处理流式输出：https://platform.moonshot.cn/docs/guide/utilize-the-streaming-output-feature-of-kimi-api#%E5%9C%A8%E4%B8%8D%E4%BD%BF%E7%94%A8-sdk-%E7%9A%84%E5%9C%BA%E5%90%88%E4%B8%8B%E5%A6%82%E4%BD%95%E5%A4%84%E7%90%86%E6%B5%81%E5%BC%8F%E8%BE%93%E5%87%BA

## 预设提示词

预设提示词应放在 data/kimi/pre_solutions 目录下，一个文件对应一组提示词（文件名不限）

- 第一行表示选择时的显示
- 从第二行开始，表示发送给 ai 的提示词

下面是一个示例文件，将会提供向用户提示'Moonshot AI 提供的人工智能助手'的选项，而其他字符将会发送给 ai

```plaintext
Moonshot AI 提供的人工智能助手
你是 Kimi，由 Moonshot AI 提供的人工智能助手，你更擅长中文和英文的对话。你会为用户提供安全，有帮助，准确的回答。同时，你会拒绝一切涉及恐怖主义，种族歧视，黄色暴力等问题的回答。Moonshot AI 为专有名词，不可翻译成其他语言。
```

注意：将会按第一行过滤重复提示词

文档：https://platform.moonshot.cn/docs/api/chat

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

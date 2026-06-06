# 同事版测试表 HTML 规范

独立运行的数据收集工具，不需要 AI 配合。禁止使用 emoji。

## 数据结构

测试用例定义为 JS 数组，每条用例：

```js
{
  id: "C-001",
  group: "分组名",
  account: "谁来操作",
  title: "测试点名称",
  steps: "操作步骤（大白话）",
  expected: "通过标准（看到什么）",
  placeholder: "反馈提示（textarea 的 placeholder）"
}
```

## HTML 骨架

```
<header>  标题 + 副标题 + 元信息标签
<main>
  <section> 进度统计面板（总数/通过/失败/完成率）
  <section> 测试路线建议（分组策略，推荐顺序）
  <section> 已知问题提醒（非技术语言）
  <section> 筛选控件（搜索框 + 分组下拉 + 导出按钮 + 清空按钮）
  <section> 用例卡片列表（不用 table，用卡片更好读）
</main>
```

## 测试路线建议区

表格前面用步骤卡片展示推荐测试顺序：

```html
<section class="panel">
  <h2>推荐测试路线</h2>
  <div class="route-map">
    <div class="route-step">
      <div class="step-number">1</div>
      <div class="step-content">
        <strong>准备环境</strong>
        <p>用例 C-001 ~ C-003</p>
        <p class="hint">登录管理员后台 + 注册新测试号，大约 5 分钟</p>
      </div>
    </div>
    <div class="arrow">--></div>
    <!-- more steps -->
  </div>
</section>
```

每步标注涉及的用例 ID 范围和预估时间。

## 交互功能

### 状态下拉
选项：未测 / 通过 / 失败 / 阻塞 / 不适用
颜色：绿/红/橙/灰

### 反馈文本框
- `<textarea>` 带具体 placeholder
- input 事件实时存 localStorage

### 截图粘贴
每条用例下方一个粘贴区域：

```js
// 监听 paste 事件
pasteBox.addEventListener("paste", async (e) => {
  const files = Array.from(e.clipboardData?.items || [])
    .filter(i => i.type.startsWith("image/"))
    .map(i => i.getAsFile())
    .filter(Boolean);
  if (!files.length) return;
  e.preventDefault();
  for (const file of files) {
    // 压缩：FileReader -> Image -> canvas 缩放 -> toDataURL
    const raw = await readAsDataURL(file);
    const img = await loadImage(raw);
    const maxW = 1600;
    const scale = img.width > maxW ? maxW / img.width : 1;
    const canvas = document.createElement("canvas");
    canvas.width = Math.round(img.width * scale);
    canvas.height = Math.round(img.height * scale);
    canvas.getContext("2d").drawImage(img, 0, 0, canvas.width, canvas.height);
    const dataUrl = canvas.toDataURL("image/webp", 0.9);
    // 存入 localStorage
  }
});
```

- 最多 4 张/条
- 显示为缩略图网格，每张有删除按钮

### 导出分享版 HTML
点击"导出分享版"按钮，用 Blob + URL.createObjectURL 生成独立 HTML：
- 只包含有反馈或非"未测"状态的用例
- 截图内联为 base64 `<img>`
- 不含交互控件，纯展示
- 包含导出时间戳

### 导出 TSV
TSV 格式：ID / 分组 / 标题 / 状态 / 反馈 / 时间

### 清空
confirm 后清除 localStorage 和所有表单状态

## 样式

```css
:root {
  --bg: #f7f8fb;
  --panel: #ffffff;
  --panel-2: #eef6f5;
  --text: #111827;
  --muted: #64748b;
  --line: #d9e2ec;
  --brand: #0f766e;
  --danger: #b91c1c;
  --warn: #a16207;
  --ok: #15803d;
}
```

- 圆角 8px，阴影柔和
- 表格 sticky header
- 响应式：<=980px 单列
- 打印样式隐藏控件

## 语言规范

禁止出现：API、DB、gateway、token、credit、schema、webhook、endpoint

替换规则：
- 额度同步 -> 付完款后能不能正常使用
- 订阅配额 -> 你买的套餐包含的额度
- gateway balance -> 账户余额
- trial credit -> 试用额度
- subscription canceled -> 订阅被取消了

操作步骤用"点这里""打开那个页面""看看显示什么"
通过标准用"应该看到""不应该出现""数字应该变化"

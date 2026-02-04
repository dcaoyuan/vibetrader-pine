export function preprocess(code: string): string {
    const lines = code.split('\n');
    let currentIndent = 0;
    let result = "";

    lines.forEach(line => {
        // 1. 彻底忽略纯空白行，避免干扰缩进计算
        if (!line.trim()) return;

        // 2. 计算缩进：Pine 支持 Tab(算4格) 或 空格
        const whitespaceMatch = line.match(/^([ \t]*)/);
        const ws = whitespaceMatch ? whitespaceMatch[1] : "";

        // 将 Tab 转换为 4 个空格计算，确保统一
        const spaceCount = ws.replace(/\t/g, "    ").length;
        const indentLevel = Math.floor(spaceCount / 4);

        // 3. 插入虚拟令牌
        if (indentLevel > currentIndent) {
            result += " { ".repeat(indentLevel - currentIndent);
        } else if (indentLevel < currentIndent) {
            result += " } ".repeat(currentIndent - indentLevel);
        }

        // 4. 保持内容并换行
        result += line.trim() + "\n";
        currentIndent = indentLevel;
    });

    result += " } ".repeat(currentIndent);
    return result;
}

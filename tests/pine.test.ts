import * as fs from 'node:fs';
import * as path from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, it, expect } from 'vitest';
import { parse } from '../src/parser';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

describe('ESM File Reading Test - Multiple Files', () => {
    const testCases = [
        { fileName: 'test_only.pine', expected: 'expected content ...' },
        { fileName: 'code1.pine', expected: 'expected content ...' },
        { fileName: 'code2.pine', expected: 'expected content ...' },
        { fileName: 'code3.pine', expected: 'expected content ...' }
    ];


    it.each(testCases)('reads $fileName correctly', ({ fileName, expected }) => {
        const filePath = path.join(__dirname, fileName);
        const content = fs.readFileSync(filePath, 'utf-8');

        expect(() => {
            const ast = parse(content);
            const json = JSON.stringify(ast, null, 2);

            console.log(json);

        }).not.toThrow();
    });
});
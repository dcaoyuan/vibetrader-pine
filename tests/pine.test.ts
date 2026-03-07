import * as fs from 'node:fs';
import * as path from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, it, expect } from 'vitest';
import { parse } from '../src/parser';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

describe('File Reading Test - Multiple Files', () => {
    const testCases = [
        { fileName: 'test_only.pine', expected: 'expected content ...' },
    ];

    it.each(testCases)(`parses $fileName`, ({ fileName, expected }) => {
        const filePath = path.join(__dirname, 'pines', fileName);
        const content = fs.readFileSync(filePath, 'utf-8');

        const ast = parse(content);
        expect(ast).toMatchSnapshot();
    });
});


describe('Dynamic Folder Reading Test', () => {
    const pinesDirPath = path.join(__dirname, 'pines');
    const allFiles = fs.readdirSync(pinesDirPath);

    const pineFiles = allFiles.filter(file => file.endsWith('.pine'));

    pineFiles.forEach((fileName) => {
        it(`parses ${fileName}`, () => {
            const filePath = path.join(pinesDirPath, fileName);

            const content = fs.readFileSync(filePath, 'utf-8');

            const ast = parse(content);
            expect(ast).toMatchSnapshot();
        });

    });
});

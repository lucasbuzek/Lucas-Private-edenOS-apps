#!/usr/bin/env python3
"""Run unchanged synchronous core XCTest methods using the installed Swift compiler.

An alternative environment check when SwiftPM's nested sandbox cannot start.
Does not prove SwiftPM packaging, the app build, or native device behaviour.
"""
import os
import pathlib
import re
import subprocess
import tempfile

root = pathlib.Path(__file__).resolve().parents[2]
package = root / 'Packages/SWAYcoreEngine'
developer = pathlib.Path(subprocess.check_output(['xcode-select', '-p'], text=True).strip())
frameworks = developer / 'Platforms/MacOSX.platform/Developer/Library/Frameworks'
support = developer / 'Platforms/MacOSX.platform/Developer/usr/lib'
cases = []
with tempfile.TemporaryDirectory(prefix='sway-core-xctest-') as directory:
    temporary = pathlib.Path(directory)
    tests = []
    for path in sorted((package / 'Tests/SWAYcoreEngineTests').glob('*.swift')):
        source = path.read_text()
        declarations = list(re.finditer(r'final class (\w+): XCTestCase\s*\{', source))
        for i, declaration in enumerate(declarations):
            end = declarations[i + 1].start() if i + 1 < len(declarations) else len(source)
            block = source[declaration.end():end]
            methods = re.findall(r'func (test\w+)\(\)\s*\{', block)
            assert methods, 'No synchronous XCTest methods found in ' + declaration.group(1)
            assert len(methods) == len(re.findall(r'func test\w+', block)), 'Unsupported test signature'
            cases.append((declaration.group(1), methods))
        copy = temporary / path.name
        # Apple's XCTest discovers Objective-C selectors; annotate copies only.
        # Assertion bodies and production source remain unchanged.
        copy.write_text(re.sub(r'func (test\w+)\(', r'@objc func \1(',
                               source.replace('@testable import SWAYcoreEngine', '')))
        tests.append(str(copy))
    count = sum(len(methods) for _, methods in cases)
    assert count > 0, 'Zero tests is never verification'
    main = temporary / 'main.swift'
    additions = '\n'.join('suite.addTest(' + name + '.defaultTestSuite)' for name, _ in cases)
    main.write_text('import XCTest\nimport Foundation\n'
                    'let suite = XCTestSuite(name: "R2 actual core")\n' + additions + '\n'
                    'suite.run()\nlet result = suite.testRun!\n'
                    'guard result.executionCount == ' + str(count) + ' else { fatalError("Test discovery mismatch") }\n'
                    'exit(result.totalFailureCount == 0 ? 0 : 1)\n')
    binary = temporary / 'core-tests'
    environment = dict(os.environ)
    environment['CLANG_MODULE_CACHE_PATH'] = str(temporary / 'module-cache')
    sources = [str(p) for p in sorted((package / 'Sources/SWAYcoreEngine').glob('*.swift'))]
    subprocess.run(['swiftc', *sources, *tests, str(main), '-F', str(frameworks),
                    '-I', str(support), '-L', str(support), '-lXCTestSwiftSupport',
                    '-framework', 'XCTest', '-Xlinker', '-rpath', '-Xlinker', str(frameworks),
                    '-Xlinker', '-rpath', '-Xlinker', str(support),
                    '-o', str(binary)], env=environment, check=True)
    subprocess.run([str(binary)], env=environment, check=True)
    print('ACTUAL_CORE_XCTEST ' + str(count) + ' synchronous methods executed; SwiftPM/app/device gates separate')

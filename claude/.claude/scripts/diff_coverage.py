"""
Diff Coverage Analysis Script

Cross-references git diff changed lines with Cobertura coverage data to calculate
code coverage specifically for lines changed on the current branch vs a base branch.

Prerequisites:
  - dotnet-coverage (global tool): `dotnet tool install -g dotnet-coverage`
  - reportgenerator (global tool): `dotnet tool install -g dotnet-reportgenerator-globaltool`

Usage:
  1. Run tests with coverage:
       dotnet test <test-project> --collect:"Code Coverage" --results-directory "TestResults" -s <runsettings>
  2. Merge coverage files:
       dotnet-coverage merge -o "TestResults/output.xml" -f xml "TestResults/**/*.coverage" --remove-input-files
  3. Generate Cobertura XML (filtered to changed source files):
       reportgenerator "-reports:TestResults/output.xml" -reporttypes:Cobertura "-targetdir:TestResults/cobertura" "-filefilters:+*File1*;+*File2*"
  4. Run this script:
       python ~/.claude/scripts/diff_coverage.py --base-branch <branch> --cobertura TestResults/cobertura/Cobertura.xml --sources src/File1.cs src/File2.cs

  Or with defaults (base=develop, cobertura=TestResults/cobertura/Cobertura.xml, sources auto-detected from diff):
       python ~/.claude/scripts/diff_coverage.py
"""

import xml.etree.ElementTree as ET
import subprocess
import re
import argparse
import sys


def get_changed_source_files(base_branch):
    """Get list of non-test source files changed on the current branch vs base."""
    output = subprocess.check_output(
        ['git', 'diff', f'{base_branch}...HEAD', '--name-only'], text=True
    )
    files = []
    for f in output.strip().split('\n'):
        f = f.strip()
        if f and f.endswith('.cs') and '/Tests/' not in f and '/test/' not in f.lower():
            files.append(f)
    return files


def get_changed_lines(base_branch, source_files):
    """Parse git diff to find changed line numbers (new side) per file."""
    if not source_files:
        return {}

    cmd = ['git', 'diff', f'{base_branch}...HEAD', '-U0', '--'] + source_files
    diff = subprocess.check_output(cmd, text=True)

    changed_lines = {}
    current_file = None
    for line in diff.split('\n'):
        if line.startswith('+++ b/'):
            current_file = line[6:]
        elif line.startswith('@@ ') and current_file:
            m = re.search(r'\+(\d+)(?:,(\d+))?', line)
            if m:
                start = int(m.group(1))
                count = int(m.group(2)) if m.group(2) else 1
                if current_file not in changed_lines:
                    changed_lines[current_file] = set()
                for i in range(start, start + count):
                    changed_lines[current_file].add(i)
    return changed_lines


def parse_cobertura(cobertura_path):
    """Parse Cobertura XML into {normalized_path: {line_num: hits}}."""
    tree = ET.parse(cobertura_path)
    root = tree.getroot()

    coverage_data = {}
    for cls in root.findall('.//class'):
        fname = cls.get('filename', '')
        # Normalize to forward-slash relative path
        fname_norm = fname.replace('\\', '/')
        # Strip common absolute prefixes (drive letters, etc.)
        # Try to find the repo-relative path by looking for src/
        for prefix_marker in ['src/', 'lib/', 'app/']:
            idx = fname_norm.find(prefix_marker)
            if idx >= 0:
                fname_norm = fname_norm[idx:]
                break

        coverage_data[fname_norm] = {}
        for line_el in cls.findall('lines/line'):
            ln = int(line_el.get('number'))
            hits = int(line_el.get('hits'))
            coverage_data[fname_norm][ln] = hits

    return coverage_data


def match_coverage(filepath, coverage_data):
    """Find the coverage data for a given file path."""
    fp_norm = filepath.replace('\\', '/')
    short = fp_norm.split('/')[-1]

    # Try exact match first
    if fp_norm in coverage_data:
        return coverage_data[fp_norm]

    # Try suffix match
    for cov_path, cov_data in coverage_data.items():
        if cov_path.endswith(fp_norm) or fp_norm.endswith(cov_path):
            return cov_data

    # Try filename match
    for cov_path, cov_data in coverage_data.items():
        if cov_path.split('/')[-1] == short:
            return cov_data

    return None


def analyze(base_branch, cobertura_path, source_files=None, target_pct=90.0):
    """Main analysis: cross-reference diff lines with coverage data."""
    if source_files is None:
        source_files = get_changed_source_files(base_branch)

    if not source_files:
        print('No changed source files found.')
        return True

    changed_lines = get_changed_lines(base_branch, source_files)
    coverage_data = parse_cobertura(cobertura_path)

    print('=' * 80)
    print('DIFF LINE COVERAGE ANALYSIS')
    print('=' * 80)

    total_covered = 0
    total_uncovered = 0
    total_not_instrumented = 0

    for filepath, lines in sorted(changed_lines.items()):
        short = filepath.split('/')[-1]
        cov = match_coverage(filepath, coverage_data)

        covered = 0
        uncovered = 0
        not_inst = 0
        uncovered_list = []

        for ln in sorted(lines):
            if cov and ln in cov:
                if cov[ln] > 0:
                    covered += 1
                else:
                    uncovered += 1
                    uncovered_list.append(ln)
            else:
                not_inst += 1

        inst = covered + uncovered
        pct = (covered / inst * 100) if inst > 0 else 100.0

        print(f'\n  {short}:')
        print(f'    Changed lines: {len(lines)}, Instrumented: {inst} (covered={covered}, uncovered={uncovered})')
        print(f'    Not instrumented (declarations/braces): {not_inst}')
        print(f'    Coverage: {pct:.1f}%')
        if uncovered_list:
            print(f'    Uncovered lines: {uncovered_list}')

        total_covered += covered
        total_uncovered += uncovered
        total_not_instrumented += not_inst

    total_inst = total_covered + total_uncovered
    overall = (total_covered / total_inst * 100) if total_inst > 0 else 100.0

    print()
    print('=' * 80)
    print('OVERALL DIFF COVERAGE')
    print('=' * 80)
    print(f'  Total changed lines:        {total_covered + total_uncovered + total_not_instrumented}')
    print(f'  Instrumented lines:         {total_inst}')
    print(f'    Covered:                  {total_covered}')
    print(f'    Uncovered:                {total_uncovered}')
    print(f'  Not instrumented:           {total_not_instrumented}')
    print(f'  DIFF LINE COVERAGE:         {overall:.1f}%')
    print(f'  Target:                     {target_pct:.1f}%')
    passed = overall >= target_pct
    result = "PASS" if passed else "FAIL"
    print(f'  Result:                     {result}')

    return passed


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Analyze code coverage for changed lines only.')
    parser.add_argument('--base-branch', default='develop', help='Base branch to diff against (default: develop)')
    parser.add_argument('--cobertura', default='TestResults/cobertura/Cobertura.xml', help='Path to Cobertura XML')
    parser.add_argument('--target', type=float, default=90.0, help='Target coverage percentage (default: 90)')
    parser.add_argument('--sources', nargs='*', help='Source files to check (default: auto-detect from diff)')
    args = parser.parse_args()

    passed = analyze(args.base_branch, args.cobertura, args.sources, args.target)
    sys.exit(0 if passed else 1)

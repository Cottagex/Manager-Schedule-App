#!/usr/bin/env python3
"""Truncate schedule_view.dart to remove duplicate code after ShiftPlaceholder"""

with open('lib/widgets/schedule/schedule_view.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Truncate to 1125 lines (up to and including the ShiftPlaceholder closing brace)
with open('lib/widgets/schedule/schedule_view.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines[:1125])

print(f'File truncated from {len(lines)} to 1125 lines')

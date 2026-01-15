#!/usr/bin/env python3
import re

# Read the file
with open('lib/widgets/schedule/schedule_view.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix the literal \n strings
content = content.replace("`n", "\n")

# Write back
with open('lib/widgets/schedule/schedule_view.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed literal \\n strings")

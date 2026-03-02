import os
import re

def gather_swift_strings(directory):
    pattern1 = re.compile(r'String\(localized:\s*"([^"]+)"')
    pattern2 = re.compile(r'Text\(\s*"([^"]+)"')
    strings = set()
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.swift'):
                with open(os.path.join(root, file), 'r', encoding='utf-8') as f:
                    content = f.read()
                    strings.update(pattern1.findall(content))
                    strings.update(pattern2.findall(content))
    return strings

def gather_localizable_keys(filepath):
    keys = set()
    pattern = re.compile(r'^"([^"]+)"\s*=')
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            for line in f:
                match = pattern.search(line.strip())
                if match:
                    keys.add(match.group(1))
    return keys

swift_strings = gather_swift_strings('horoscope')
en_keys = gather_localizable_keys('horoscope/en.lproj/Localizable.strings')

missing = swift_strings - en_keys

# filter out empty strings and obvious non-keys like single spaces, or symbols we don't localize
filtered_missing = []
for m in missing:
    if m.strip() and not m.startswith("%") and not m in ["Bottom", "top", "bottom"]:
        filtered_missing.append(m)

print(f"Found {len(swift_strings)} strings in Swift files.")
print(f"Found {len(en_keys)} keys in en.lproj/Localizable.strings")
print(f"Missing {len(filtered_missing)} keys.")
if filtered_missing:
    print("Some missing keys:")
    for k in list(filtered_missing)[:20]:
        print(f" - {k}")


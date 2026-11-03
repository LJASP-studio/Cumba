#!/usr/bin/env python3
"""Checks the string catalogs.

1. User-facing strings used in code that are missing from Localizable.xcstrings. Xcode adds
   new strings to the catalog only when building in the IDE; command line and CI builds
   don't, so this compares the keys the compiler extracted (*.stringsdata) with the catalog.
2. Every string in Localizable.xcstrings and InfoPlist.xcstrings has a translation in every
   language the app ships, with the same format specifiers as the English.

Run it after a build:

    python3 scripts/check-strings.py build

Exits with 1 when something is missing.
"""
import json
import pathlib
import re
import sys

LANGUAGES = ["es", "es-419", "fr", "tr"]
SPECIFIER = re.compile(r"%(?:\d+\$)?(lld|ld|d|@|f|\.\d+f)")

build_dir = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "build")
catalog_path = pathlib.Path("Cumba/Resources/Localizable.xcstrings")
catalog = json.loads(catalog_path.read_text(encoding="utf-8"))["strings"]
info_path = pathlib.Path("Cumba/Resources/InfoPlist.xcstrings")
info = json.loads(info_path.read_text(encoding="utf-8"))["strings"]
problems = []

used = {}
for path in build_dir.rglob("*.stringsdata"):
    if "CumbaTests" in str(path):
        continue
    data = json.loads(path.read_text(encoding="utf-8"))
    source = pathlib.Path(data.get("source", "")).name
    for entry in data.get("tables", {}).get("Localizable", []):
        used.setdefault(entry["key"], source)

for key in sorted(key for key in used if key not in catalog):
    problems.append(f"{used[key]}: {key!r} is not in the catalog")


def values(localization):
    """The text of a localization, or of each of its plural forms."""
    if "stringUnit" in localization:
        return [localization["stringUnit"].get("value", "")]
    forms = localization.get("variations", {}).get("plural", {})
    return [form.get("stringUnit", {}).get("value", "") for form in forms.values()]


def check(name, key, entry, source):
    if entry.get("shouldTranslate") is False:
        return
    expected = sorted(SPECIFIER.findall(source))
    for language in LANGUAGES:
        localization = entry.get("localizations", {}).get(language)
        if localization is None:
            problems.append(f"{name}: {key!r} has no {language} translation")
            continue
        for value in values(localization):
            if not value.strip():
                problems.append(f"{name}: {key!r} has an empty {language} translation")
            elif sorted(SPECIFIER.findall(value)) != expected:
                problems.append(f"{name}: {key!r} in {language} has other placeholders: {value!r}")


for key, entry in catalog.items():
    check("Localizable", key, entry, key)
for key, entry in info.items():
    source = entry.get("localizations", {}).get("en", {}).get("stringUnit", {}).get("value", key)
    check("InfoPlist", key, entry, source)

print("\n".join(problems))
sys.exit(1 if problems else 0)

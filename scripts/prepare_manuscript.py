#!/usr/bin/env python3
"""Prepare the reader-facing manuscript without modifying the source file."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


INTRO_HEADING = "# Introduction: I Thought I Was Bad at Languages"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    source = args.source.read_text(encoding="utf-8-sig").replace("\r\n", "\n")
    start = source.find(INTRO_HEADING)
    if start < 0:
        raise SystemExit(f"Expected heading not found: {INTRO_HEADING}")

    # The source keeps a convenient title block and clickable Markdown contents.
    # Pandoc generates the EPUB title page and navigation, so those source-only
    # elements are intentionally omitted from the build.
    manuscript = source[start:]

    # A level-one heading already starts a new EPUB document. Remove only the
    # horizontal rules immediately preceding those headings; keep separators
    # used inside chapters.
    manuscript = re.sub(r"(?m)^---[ \t]*\n\n(?=# )", "", manuscript)

    chapters = [int(value) for value in re.findall(r"(?m)^# Chapter (\d+): ", manuscript)]
    if not chapters:
        raise SystemExit("No numbered chapter headings were found.")

    expected = list(range(1, len(chapters) + 1))
    if chapters != expected:
        raise SystemExit(
            f"Chapter numbering is not sequential. Found {chapters}; expected {expected}."
        )

    required_endings = ("# Conclusion: Get to the Fun Part", "# Research Notes and References")
    for heading in required_endings:
        if heading not in manuscript:
            raise SystemExit(f"Expected heading not found: {heading}")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(manuscript.rstrip() + "\n", encoding="utf-8")
    print(f"Prepared {len(chapters)} chapters: {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())


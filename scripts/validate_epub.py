#!/usr/bin/env python3
"""Perform deterministic structural checks on the generated EPUB."""

from __future__ import annotations

import argparse
import posixpath
import zipfile
from pathlib import PurePosixPath
from xml.etree import ElementTree as ET


CONTAINER_NS = {"c": "urn:oasis:names:tc:opendocument:xmlns:container"}
OPF_NS = {
    "opf": "http://www.idpf.org/2007/opf",
    "dc": "http://purl.org/dc/elements/1.1/",
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("epub")
    args = parser.parse_args()

    with zipfile.ZipFile(args.epub) as archive:
        bad_file = archive.testzip()
        if bad_file:
            raise SystemExit(f"Corrupt ZIP member: {bad_file}")

        names = archive.namelist()
        if not names or names[0] != "mimetype":
            raise SystemExit("EPUB mimetype must be the first archive member.")
        if archive.getinfo("mimetype").compress_type != zipfile.ZIP_STORED:
            raise SystemExit("EPUB mimetype must be stored without compression.")
        if archive.read("mimetype") != b"application/epub+zip":
            raise SystemExit("Invalid EPUB mimetype value.")

        container = ET.fromstring(archive.read("META-INF/container.xml"))
        rootfile = container.find("c:rootfiles/c:rootfile", CONTAINER_NS)
        if rootfile is None:
            raise SystemExit("No package document declared in container.xml.")

        opf_path = rootfile.attrib["full-path"]
        opf_dir = posixpath.dirname(opf_path)
        package = ET.fromstring(archive.read(opf_path))

        title = package.findtext("opf:metadata/dc:title", namespaces=OPF_NS)
        creator = package.findtext("opf:metadata/dc:creator", namespaces=OPF_NS)
        language = package.findtext("opf:metadata/dc:language", namespaces=OPF_NS)
        if not title or not creator or language != "en":
            raise SystemExit(
                f"Incomplete metadata: title={title!r}, creator={creator!r}, language={language!r}"
            )

        manifest = {}
        nav_items = []
        cover_items = []
        for item in package.findall("opf:manifest/opf:item", OPF_NS):
            item_id = item.attrib["id"]
            href = item.attrib["href"]
            properties = set(item.attrib.get("properties", "").split())
            manifest[item_id] = href
            full_path = str(PurePosixPath(opf_dir, href))
            if full_path not in names:
                raise SystemExit(f"Manifest resource is missing: {full_path}")
            if "nav" in properties:
                nav_items.append(full_path)
            if "cover-image" in properties:
                cover_items.append(full_path)

        if len(nav_items) != 1:
            raise SystemExit(f"Expected one navigation document; found {len(nav_items)}.")
        if len(cover_items) != 1:
            raise SystemExit(f"Expected one cover image; found {len(cover_items)}.")

        spine = package.findall("opf:spine/opf:itemref", OPF_NS)
        if not spine:
            raise SystemExit("EPUB spine is empty.")
        for itemref in spine:
            if itemref.attrib.get("idref") not in manifest:
                raise SystemExit(f"Spine references an unknown item: {itemref.attrib!r}")

        xhtml_files = [name for name in names if name.lower().endswith(('.xhtml', '.html'))]
        for name in xhtml_files:
            try:
                ET.fromstring(archive.read(name))
            except ET.ParseError as exc:
                raise SystemExit(f"Invalid XHTML/XML in {name}: {exc}") from exc

        print(f"Validated EPUB: {args.epub}")
        print(f"  Title: {title}")
        print(f"  Author: {creator}")
        print(f"  Spine documents: {len(spine)}")
        print(f"  XHTML documents: {len(xhtml_files)}")
        print(f"  Cover: {cover_items[0]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())


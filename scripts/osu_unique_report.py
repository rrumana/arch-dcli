#!/usr/bin/env python3
"""Report unique/shared osu files between an old and a new installation.

This script is read-only: it only scans files and prints a report.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List


DEFAULT_OLD_OSU_DIR = "/mnt/old/home/rcrumana/.local/share/osu"
DEFAULT_NEW_OSU_DIR = "~/.local/share/osu"
DEFAULT_DATA_SUBDIR = "files"


@dataclass
class ScanResult:
    label: str
    root: Path
    hashes_to_paths: Dict[str, List[Path]] = field(default_factory=dict)
    total_files: int = 0
    total_bytes: int = 0
    errors: List[str] = field(default_factory=list)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Compare two osu data trees by file content hash and report unique/shared file counts."
        )
    )
    parser.add_argument(
        "--old-osu-dir",
        default=DEFAULT_OLD_OSU_DIR,
        help=f"Old osu root directory (default: {DEFAULT_OLD_OSU_DIR})",
    )
    parser.add_argument(
        "--new-osu-dir",
        default=DEFAULT_NEW_OSU_DIR,
        help=f"New osu root directory (default: {DEFAULT_NEW_OSU_DIR})",
    )
    parser.add_argument(
        "--data-subdir",
        default=DEFAULT_DATA_SUBDIR,
        help=(
            "Subdirectory under each osu root to compare recursively "
            f"(default: {DEFAULT_DATA_SUBDIR})"
        ),
    )
    parser.add_argument(
        "--algorithm",
        default="sha256",
        help="Hash algorithm from hashlib (default: sha256)",
    )
    parser.add_argument(
        "--chunk-size",
        type=int,
        default=1024 * 1024,
        help="Read size per chunk in bytes while hashing (default: 1048576)",
    )
    parser.add_argument(
        "--progress-every",
        type=int,
        default=0,
        help="Print progress to stderr every N files (default: 0 = disabled)",
    )
    return parser.parse_args()


def hash_file(path: Path, algorithm: str, chunk_size: int) -> str:
    hasher = hashlib.new(algorithm)
    with path.open("rb") as handle:
        while True:
            chunk = handle.read(chunk_size)
            if not chunk:
                break
            hasher.update(chunk)
    return hasher.hexdigest()


def scan_tree(
    label: str,
    root: Path,
    algorithm: str,
    chunk_size: int,
    progress_every: int,
) -> ScanResult:
    result = ScanResult(label=label, root=root)
    if not root.exists():
        raise FileNotFoundError(f"{label} path does not exist: {root}")
    if not root.is_dir():
        raise NotADirectoryError(f"{label} path is not a directory: {root}")

    for dirpath, dirnames, filenames in os.walk(root, followlinks=False):
        kept_dirs: List[str] = []
        for dirname in dirnames:
            candidate = Path(dirpath, dirname)
            if not candidate.is_symlink():
                kept_dirs.append(dirname)
        dirnames[:] = kept_dirs

        for filename in filenames:
            file_path = Path(dirpath, filename)
            if file_path.is_symlink():
                continue
            if not file_path.is_file():
                continue

            try:
                digest = hash_file(file_path, algorithm=algorithm, chunk_size=chunk_size)
                file_size = file_path.stat().st_size
            except OSError as exc:
                result.errors.append(f"{file_path}: {exc}")
                continue

            result.hashes_to_paths.setdefault(digest, []).append(file_path)
            result.total_files += 1
            result.total_bytes += file_size

            if progress_every > 0 and result.total_files % progress_every == 0:
                print(
                    f"[{label}] hashed {result.total_files} files...",
                    file=sys.stderr,
                    flush=True,
                )

    return result


def print_report(old_scan: ScanResult, new_scan: ScanResult) -> None:
    old_hashes = set(old_scan.hashes_to_paths)
    new_hashes = set(new_scan.hashes_to_paths)

    shared_hashes = old_hashes & new_hashes
    old_only_hashes = old_hashes - new_hashes
    new_only_hashes = new_hashes - old_hashes

    old_unique_files = sum(len(old_scan.hashes_to_paths[d]) for d in old_only_hashes)
    new_unique_files = sum(len(new_scan.hashes_to_paths[d]) for d in new_only_hashes)

    old_shared_files = sum(len(old_scan.hashes_to_paths[d]) for d in shared_hashes)
    new_shared_files = sum(len(new_scan.hashes_to_paths[d]) for d in shared_hashes)

    old_internal_duplicates = old_scan.total_files - len(old_hashes)
    new_internal_duplicates = new_scan.total_files - len(new_hashes)

    print("osu file uniqueness report (content-based)")
    print("=" * 44)
    print(f"old data root: {old_scan.root}")
    print(f"new data root: {new_scan.root}")
    print()
    print(f"old total files scanned: {old_scan.total_files}")
    print(f"new total files scanned: {new_scan.total_files}")
    print()
    print(f"old unique files vs new: {old_unique_files}")
    print(f"new unique files vs old: {new_unique_files}")
    print()
    print(f"shared file instances in old tree: {old_shared_files}")
    print(f"shared file instances in new tree: {new_shared_files}")
    print(f"shared unique content hashes: {len(shared_hashes)}")
    print()
    print(f"old internal duplicate files (same-content repeats): {old_internal_duplicates}")
    print(f"new internal duplicate files (same-content repeats): {new_internal_duplicates}")

    if old_scan.errors or new_scan.errors:
        print()
        print("warnings")
        print("-" * 8)
        print(f"old read errors: {len(old_scan.errors)}")
        print(f"new read errors: {len(new_scan.errors)}")
        max_examples = 5
        for err in old_scan.errors[:max_examples]:
            print(f"  old: {err}")
        for err in new_scan.errors[:max_examples]:
            print(f"  new: {err}")


def main() -> int:
    args = parse_args()

    try:
        hashlib.new(args.algorithm)
    except ValueError as exc:
        print(f"invalid hash algorithm '{args.algorithm}': {exc}", file=sys.stderr)
        return 2

    if args.chunk_size <= 0:
        print("--chunk-size must be > 0", file=sys.stderr)
        return 2
    if args.progress_every < 0:
        print("--progress-every must be >= 0", file=sys.stderr)
        return 2

    old_root = Path(args.old_osu_dir).expanduser()
    new_root = Path(args.new_osu_dir).expanduser()
    old_data = old_root / args.data_subdir
    new_data = new_root / args.data_subdir

    try:
        old_scan = scan_tree(
            label="old",
            root=old_data,
            algorithm=args.algorithm,
            chunk_size=args.chunk_size,
            progress_every=args.progress_every,
        )
        new_scan = scan_tree(
            label="new",
            root=new_data,
            algorithm=args.algorithm,
            chunk_size=args.chunk_size,
            progress_every=args.progress_every,
        )
    except (FileNotFoundError, NotADirectoryError) as exc:
        print(exc, file=sys.stderr)
        return 1

    print_report(old_scan, new_scan)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

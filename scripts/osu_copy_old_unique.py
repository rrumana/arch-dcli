#!/usr/bin/env python3
"""Copy old-only osu files into a migration directory.

This script compares file content between old/new osu `files` directories.
Any file whose content exists only in old is copied to the migration folder.
Source osu files are never modified.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Set


DEFAULT_OLD_OSU_DIR = "/mnt/old/home/rcrumana/.local/share/osu"
DEFAULT_NEW_OSU_DIR = "~/.local/share/osu"
DEFAULT_DATA_SUBDIR = "files"
DEFAULT_OUTPUT_DIR = "~/migration"


@dataclass
class HashScanStats:
    files_scanned: int = 0
    bytes_scanned: int = 0
    read_errors: int = 0


@dataclass
class CopyStats:
    files_scanned_old: int = 0
    unique_candidates: int = 0
    copied: int = 0
    skipped_existing: int = 0
    bytes_copied: int = 0
    read_errors: int = 0
    copy_errors: int = 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Copy files unique to old osu installation into a migration directory."
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
        help=f"Subdirectory to compare under each osu root (default: {DEFAULT_DATA_SUBDIR})",
    )
    parser.add_argument(
        "--output-dir",
        default=DEFAULT_OUTPUT_DIR,
        help=f"Destination root for copied files (default: {DEFAULT_OUTPUT_DIR})",
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
        help="Hash read chunk size in bytes (default: 1048576)",
    )
    parser.add_argument(
        "--progress-every",
        type=int,
        default=0,
        help="Print progress to stderr every N processed files (default: 0 = off)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Do not copy files; only report what would be copied",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite destination file if it already exists (default: skip existing)",
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


def is_relative_to(path: Path, base: Path) -> bool:
    try:
        path.relative_to(base)
        return True
    except ValueError:
        return False


def validate_inputs(
    old_data: Path,
    new_data: Path,
    output_root: Path,
    algorithm: str,
    chunk_size: int,
    progress_every: int,
) -> None:
    if not old_data.exists():
        raise FileNotFoundError(f"old path does not exist: {old_data}")
    if not old_data.is_dir():
        raise NotADirectoryError(f"old path is not a directory: {old_data}")
    if not new_data.exists():
        raise FileNotFoundError(f"new path does not exist: {new_data}")
    if not new_data.is_dir():
        raise NotADirectoryError(f"new path is not a directory: {new_data}")

    hashlib.new(algorithm)

    if chunk_size <= 0:
        raise ValueError("--chunk-size must be > 0")
    if progress_every < 0:
        raise ValueError("--progress-every must be >= 0")

    old_resolved = old_data.resolve()
    output_resolved = output_root.resolve()
    if is_relative_to(output_resolved, old_resolved):
        raise ValueError(
            "--output-dir must not be inside the old data tree to avoid recursive copying"
        )


def walk_regular_files(root: Path):
    for dirpath, dirnames, filenames in os.walk(root, followlinks=False):
        dirnames[:] = [
            dirname
            for dirname in dirnames
            if not Path(dirpath, dirname).is_symlink()
        ]
        for filename in filenames:
            file_path = Path(dirpath, filename)
            if file_path.is_symlink():
                continue
            if not file_path.is_file():
                continue
            yield file_path


def build_hash_set(
    root: Path,
    algorithm: str,
    chunk_size: int,
    progress_every: int,
    label: str,
) -> tuple[Set[str], HashScanStats]:
    hashes: Set[str] = set()
    stats = HashScanStats()
    for file_path in walk_regular_files(root):
        try:
            digest = hash_file(file_path, algorithm=algorithm, chunk_size=chunk_size)
            file_size = file_path.stat().st_size
        except OSError as exc:
            stats.read_errors += 1
            print(f"[{label}] read error: {file_path}: {exc}", file=sys.stderr)
            continue

        hashes.add(digest)
        stats.files_scanned += 1
        stats.bytes_scanned += file_size

        if progress_every > 0 and stats.files_scanned % progress_every == 0:
            print(
                f"[{label}] scanned {stats.files_scanned} files...",
                file=sys.stderr,
                flush=True,
            )
    return hashes, stats


def copy_old_unique_files(
    old_root: Path,
    new_hashes: Set[str],
    output_root: Path,
    data_subdir: str,
    algorithm: str,
    chunk_size: int,
    progress_every: int,
    overwrite: bool,
    dry_run: bool,
) -> CopyStats:
    stats = CopyStats()
    output_data = output_root / data_subdir

    for old_file in walk_regular_files(old_root):
        stats.files_scanned_old += 1
        try:
            digest = hash_file(old_file, algorithm=algorithm, chunk_size=chunk_size)
            file_size = old_file.stat().st_size
        except OSError as exc:
            stats.read_errors += 1
            print(f"[old] read error: {old_file}: {exc}", file=sys.stderr)
            continue

        if digest in new_hashes:
            continue

        stats.unique_candidates += 1
        rel_path = old_file.relative_to(old_root)
        dest_file = output_data / rel_path

        if not dry_run:
            dest_file.parent.mkdir(parents=True, exist_ok=True)
            if dest_file.exists() and not overwrite:
                stats.skipped_existing += 1
            else:
                try:
                    shutil.copy2(old_file, dest_file)
                    stats.copied += 1
                    stats.bytes_copied += file_size
                except OSError as exc:
                    stats.copy_errors += 1
                    print(f"[copy] error: {old_file} -> {dest_file}: {exc}", file=sys.stderr)
        else:
            stats.copied += 1
            stats.bytes_copied += file_size

        if progress_every > 0 and stats.files_scanned_old % progress_every == 0:
            print(
                f"[old] processed {stats.files_scanned_old} files...",
                file=sys.stderr,
                flush=True,
            )

    return stats


def print_summary(
    old_data: Path,
    new_data: Path,
    output_root: Path,
    new_scan_stats: HashScanStats,
    copy_stats: CopyStats,
    dry_run: bool,
) -> None:
    mode = "DRY RUN (no files copied)" if dry_run else "COPY MODE"
    print(f"osu old-unique copy summary [{mode}]")
    print("=" * 45)
    print(f"old data root: {old_data}")
    print(f"new data root: {new_data}")
    print(f"output root:   {output_root}")
    print()
    print(f"new files scanned: {new_scan_stats.files_scanned}")
    print(f"old files scanned: {copy_stats.files_scanned_old}")
    print(f"old-unique candidate files: {copy_stats.unique_candidates}")
    print(f"files copied: {copy_stats.copied}")
    print(f"files skipped (already existed): {copy_stats.skipped_existing}")
    print(f"bytes copied: {copy_stats.bytes_copied}")
    print()
    print(f"new read errors: {new_scan_stats.read_errors}")
    print(f"old read errors: {copy_stats.read_errors}")
    print(f"copy errors: {copy_stats.copy_errors}")


def main() -> int:
    args = parse_args()

    old_root = Path(args.old_osu_dir).expanduser()
    new_root = Path(args.new_osu_dir).expanduser()
    output_root = Path(args.output_dir).expanduser()
    old_data = old_root / args.data_subdir
    new_data = new_root / args.data_subdir

    try:
        validate_inputs(
            old_data=old_data,
            new_data=new_data,
            output_root=output_root,
            algorithm=args.algorithm,
            chunk_size=args.chunk_size,
            progress_every=args.progress_every,
        )
    except (FileNotFoundError, NotADirectoryError, ValueError) as exc:
        print(exc, file=sys.stderr)
        return 1

    if not args.dry_run:
        output_root.mkdir(parents=True, exist_ok=True)

    new_hashes, new_scan_stats = build_hash_set(
        root=new_data,
        algorithm=args.algorithm,
        chunk_size=args.chunk_size,
        progress_every=args.progress_every,
        label="new",
    )

    copy_stats = copy_old_unique_files(
        old_root=old_data,
        new_hashes=new_hashes,
        output_root=output_root,
        data_subdir=args.data_subdir,
        algorithm=args.algorithm,
        chunk_size=args.chunk_size,
        progress_every=args.progress_every,
        overwrite=args.overwrite,
        dry_run=args.dry_run,
    )

    print_summary(
        old_data=old_data,
        new_data=new_data,
        output_root=output_root,
        new_scan_stats=new_scan_stats,
        copy_stats=copy_stats,
        dry_run=args.dry_run,
    )

    if new_scan_stats.read_errors > 0 or copy_stats.read_errors > 0 or copy_stats.copy_errors > 0:
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

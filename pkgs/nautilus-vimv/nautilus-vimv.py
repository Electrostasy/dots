from gi.repository import Nautilus, GObject

from pathlib import Path
from urllib.parse import urlparse, unquote
import itertools
import os
import subprocess


class BulkRenameMenuProvider(GObject.GObject, Nautilus.MenuProvider):
    def _uri_to_str(self, file: Nautilus.FileInfo) -> str:
        return unquote(urlparse(file.get_uri()).path)

    def _iterate_nautilus_dir(self, dir: Nautilus.FileInfo) -> list[Path]:
        return [entry for entry in Path(self._uri_to_str(dir)).iterdir() if entry.exists()]

    def _open_vimv_for_entries(self, menu, files: list[Path]) -> None:
        cwd = os.path.commonpath(files)
        cmd = [
            "ptyxis", "--new-window", "--",
            "/usr/bin/env",
            "vimv",
        ]
        for file in files:
            cmd.append(file.relative_to(cwd))

        subprocess.Popen(cmd, cwd=cwd)

    def get_file_items(self, files: list[Nautilus.FileInfo]) -> list[Nautilus.MenuItem]:
        items = []
        total_entries = len(files)
        if total_entries == 1:
            # If the only selected item is a directory, add an option to bulk
            # rename its contents as well.
            if files[0].is_directory():
                dir_entries = self._iterate_nautilus_dir(files[0])
                total_entries = len(dir_entries)
                label = f"Bulk Rename Contents ({total_entries} Items)"
                item = Nautilus.MenuItem(name=f"{self.__class__.__name__}::Directory", label=label)
                item.connect("activate", self._open_vimv_for_entries, dir_entries)
                items.append(item)
            label = f"Bulk Rename Selection"
        else:
            label = f"Bulk Rename Selection ({total_entries} Items)"

        item = Nautilus.MenuItem(name=f"{self.__class__.__name__}::Files", label=label)
        selected_entries = [Path(self._uri_to_str(file)) for file in files if not file.is_gone()]
        item.connect("activate", self._open_vimv_for_entries, selected_entries)
        items.append(item)
        return items

    def get_background_items(self, current_folder: Nautilus.FileInfo) -> list[Nautilus.MenuItem]:
        dir_entries = self._iterate_nautilus_dir(current_folder)
        total_entries = len(dir_entries)
        label = f"Bulk Rename Contents ({total_entries} Items)"
        item = Nautilus.MenuItem(name=f"{self.__class__.__name__}::DirectoryBackground", label=label)
        item.connect("activate", self._open_vimv_for_entries, dir_entries)
        return [item]

from gi.repository import Nautilus, GObject
from itertools import count
from pathlib import Path
from subprocess import Popen
from typing import List
from urllib.parse import urlparse, unquote
from os import environ


class BulkRenameMenuProvider(GObject.GObject, Nautilus.MenuProvider):
    def _class_name(self) -> str:
        return self.__class__.__name__

    def _uri_to_str(self, file: Nautilus.FileInfo) -> str:
        return unquote(urlparse(file.get_uri()).path)

    def _find_common_cwd(self, files: List[Path]) -> Path:
        if len(files) > 1:
            depth = 0
            for i in count(1):
                common = set(file.parts[:i] for file in files)
                if len(common) > 1:
                    depth = i - 1
                    break
            return Path(*files[0].parts[:depth])
        # When only one entry is selected, the other branch goes into an
        # infinite loop because of the set, as there is only 1 common root.
        return Path(*files[0].parts[:-1])

    def _iterate_nautilus_dir(self, dir: Nautilus.FileInfo) -> List[Path]:
        return [entry for entry in Path(self._uri_to_str(dir)).iterdir() if entry.exists()]

    def _open_vimv_for_entries(self, menu, files: List[Path]) -> None:
        cwd = self._find_common_cwd(files)
        cmd = [
            "xdg-terminal-exec",
            "/usr/bin/env",
            "vimv",
        ]
        for file in files:
            cmd.append(file.relative_to(cwd))

        Popen(cmd, cwd=cwd)

    def get_file_items(self, files: List[Nautilus.FileInfo]) -> List[Nautilus.MenuItem]:
        items = []
        total_entries = len(files)
        if total_entries == 1:
            # If the only selected item is a directory, add an option to bulk
            # rename its contents as well.
            if files[0].is_directory():
                dir_entries = self._iterate_nautilus_dir(files[0])
                total_entries = len(dir_entries)
                label = f"Bulk Rename Contents ({total_entries} Items)"
                item = Nautilus.MenuItem(name=f"{self._class_name()}::Directory", label=label)
                item.connect("activate", self._open_vimv_for_entries, dir_entries)
                items.append(item)
            label = f"Bulk Rename Selection"
        else:
            label = f"Bulk Rename Selection ({total_entries} Items)"

        item = Nautilus.MenuItem(name=f"{self._class_name()}::Files", label=label)
        selected_entries = [Path(self._uri_to_str(file)) for file in files if not file.is_gone()]
        item.connect("activate", self._open_vimv_for_entries, selected_entries)
        items.append(item)
        return items

    def get_background_items(self, current_folder: Nautilus.FileInfo) -> List[Nautilus.MenuItem]:
        dir_entries = self._iterate_nautilus_dir(current_folder)
        total_entries = len(dir_entries)
        label = f"Bulk Rename Contents ({total_entries} Items)"
        item = Nautilus.MenuItem(name=f"{self._class_name()}::DirectoryBackground", label=label)
        item.connect("activate", self._open_vimv_for_entries, dir_entries)
        return [item]

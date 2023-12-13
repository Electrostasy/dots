from gi.repository import Nautilus, GObject
from itertools import count
from pathlib import Path
from subprocess import Popen
from typing import List
from urllib.parse import urlparse, unquote


def uri_to_str(file: Nautilus.FileInfo) -> str:
    return unquote(urlparse(file.get_uri()).path)


class BulkRenameMenuProvider(GObject.GObject, Nautilus.MenuProvider):
    def _class_name(self) -> str:
        return self.__class__.__name__

    def _open_vimv_for_entries(self, menu, files: List[Path]) -> None:
        depth = 0
        for i in count(1):
            common = set(file.parts[:i] for file in files)
            if len(common) > 1:
                depth = i - 1
                break

        cwd = Path(*files[0].parts[:depth])
        cmd = [
            "/usr/bin/env",
            "kgx",
            f"--working-directory={cwd}",
            f"--title=Bulk Renaming entries in {cwd}",
            "--",
            "/usr/bin/env",
            "vimv",
        ]
        for file in files:
            cmd.append(file.relative_to(cwd))

        Popen(cmd, cwd=cwd)

    def get_file_items(self, files: List[Nautilus.FileInfo]) -> List[Nautilus.MenuItem]:
        items = len(files)
        if items == 1:
            label = f"Bulk Rename Selection"
        else:
            label = f"Bulk Rename Selection ({items} Items)"
        item = Nautilus.MenuItem(name=f"{self._class_name()}::Files", label=label)
        arg = [Path(uri_to_str(file)) for file in files if not file.is_gone()]
        item.connect("activate", self._open_vimv_for_entries, arg)
        return [item]

    def get_background_items(
        self, current_folder: Nautilus.FileInfo
    ) -> List[Nautilus.MenuItem]:
        item = Nautilus.MenuItem(
            name=f"{self._class_name()}::Directory", label="Bulk Rename"
        )
        arg = [
            file for file in Path(uri_to_str(current_folder)).iterdir() if file.exists()
        ]
        item.connect("activate", self._open_vimv_for_entries, arg)
        return [item]

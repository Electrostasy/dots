from gi.repository import Nautilus, GObject
from os import walk
from pathlib import Path
from subprocess import Popen
from typing import List
from urllib.parse import urlparse, unquote
import mimetypes


class AmberolMenuProvider(GObject.GObject, Nautilus.MenuProvider):
    def __init__(self):
        super().__init__()

        # For some reason, mimetypes is not initialized fully when started
        # from Nautilus.
        if not mimetypes.inited:
            mimetypes.init(files=mimetypes.knownfiles)

    def _class_name(self) -> str:
        return self.__class__.__name__

    def _open_amberol_for_files(self, menu, paths: List[Path]) -> None:
        cmd = ["/usr/bin/env", "amberol"]
        for path in paths:
            cmd.append(path)
        Popen(cmd)

    def get_file_items(self, files: List[Nautilus.FileInfo]) -> List[Nautilus.MenuItem]:
        paths = []
        for file in files:
            # We only care about non-hidden directories.
            if not file.is_directory() or file.get_name().startswith("."):
                continue

            # TODO: Is it possible to async it up in order to not block the UI?
            # https://github.com/GNOME/nautilus-python/blob/0eaaad1a44c4fd1d7324dfb97fd8c382d59cd4e3/docs/reference/nautilus-python-operation-result.xml#L41
            start = unquote(urlparse(file.get_uri()).path)
            for root, walk_dirs, walk_files in walk(start):
                # Don't descend down into hidden directories.
                walk_dirs[:] = [dir for dir in walk_dirs if not dir.startswith(".")]
                for walk_file in walk_files:
                    # Don't take hidden files either.
                    if walk_file.startswith("."):
                        continue

                    mime, _ = mimetypes.guess_type(walk_file)
                    if mime is not None and mime.startswith("audio/"):
                        paths.append(f"{root}/{walk_file}")

        paths_len = len(paths)
        if len(files) == 1:
            label = f"Open directory with Amberol ({paths_len} Items)"
        else:
            label = f"Open directories with Amberol ({paths_len} Items)"

        if len(paths) > 0:
            item = Nautilus.MenuItem(name=f"{self._class_name()}::Files", label=label)
            item.connect("activate", self._open_amberol_for_files, paths)
            return [item]

        return []

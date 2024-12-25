from gi.repository import Nautilus, GObject
from os import walk
from pathlib import Path
from subprocess import Popen
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

    def _open_amberol_for_files(self, menu, paths: list[Path]) -> None:
        cmd = ["/usr/bin/env", "amberol"]
        for path in paths:
            cmd.append(path)
        _ = Popen(cmd)

    def get_file_items(self, files: list[Nautilus.FileInfo]) -> list[Nautilus.MenuItem]:
        paths = []
        for file in files:
            # We only care about non-hidden directories.
            if not file.is_directory() or file.get_name().startswith("."):
                continue

            start = unquote(urlparse(file.get_uri()).path)
            for root, walk_dirs, walk_files in walk(start):
                # Don't descend down into hidden directories.
                walk_dirs[:] = [dir for dir in walk_dirs if not dir.startswith(".")]
                for walk_file in walk_files:
                    # Don't take hidden files either.
                    if walk_file.startswith("."):
                        continue

                    # Guess mimetype by filename only in order to not slow down/crash
                    # Nautilus for larger directory trees.
                    mime, _ = mimetypes.guess_type(walk_file.title())
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

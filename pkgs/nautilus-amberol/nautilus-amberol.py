import gi
gi.require_version('Tracker', '3.0')
from gi.repository import GObject, Nautilus, Tracker, GLib

import weakref
import mimetypes
from urllib.parse import urlparse, unquote
import os
import subprocess


TRACKER_REMOTE_NAME = 'org.freedesktop.Tracker3.Miner.Files'


class AmberolMenuProvider(GObject.GObject, Nautilus.MenuProvider):
    def __init__(self):
        super().__init__()

        try:
            self.tracker = Tracker.SparqlConnection.bus_new(TRACKER_REMOTE_NAME, None, None)
        except GLib.GError as e:
            # TODO: This could use better error handling/reporting.
            print(f'Could not connect to {TRACKER_REMOTE_NAME}:\n{e}')

            self.tracker = None
            self.find_files = self._find_files_walk
        else:
            self._finalizer = weakref.finalize(self, self.tracker.close)
            self.find_files = self._find_files_tracker

    def _find_files_tracker(self, directory: Nautilus.FileInfo) -> list[str]:
        assert self.tracker, 'self._find_files_tracker called with self.tracker = None'
        query = self.tracker.query_statement('SELECT ?urn { GRAPH tracker:Audio { ?urn a nfo:FileDataObject; FILTER( strstarts(?urn, ~name) ) } }', None)
        query.bind_string('name', directory.get_uri())

        cursor = query.execute()
        files = []
        while cursor.next():
            files.append(unquote(urlparse(cursor.get_string(0)[0]).path))
        cursor.close()

        return files

    def _find_files_walk(self, directory: Nautilus.FileInfo) -> list[str]:
        files = []
        for root, _, walk_files in os.walk(unquote(urlparse(directory.get_uri()).path)):
            for walk_file in walk_files:
                if walk_file.startswith('.'):
                    continue

                mime, _ = mimetypes.guess_type(walk_file.title())
                # 'audio/x-mpegurl' etc. are playlists and not real audio files.
                if mime is not None and mime.startswith('audio/') and not mime.endswith('mpegurl'):
                    files.append(f'{root}/{walk_file}')

        return files

    def _menu_activate_callback(self, menu: Nautilus.MenuItem, files: list[str]) -> None:
        # `subprocess.Popen` doesn't wait for the command to finish which doesn't
        # hang Nautilus for a few seconds when the callback is called.
        _ = subprocess.Popen(['/usr/bin/env', 'amberol'] + files)

    def get_file_items(self, files: list[Nautilus.FileInfo]) -> list[Nautilus.MenuItem]:
        # Only create a menu item if there is a directory among the selected items.
        if not any([file.is_directory() for file in files]):
            return []

        audio_files = []
        for file in files:
            audio_files += self.find_files(file)

        count = len(audio_files)
        if count == 0:
            return []

        name = f'{self.__class__.__name__}::AmberolMenu'
        label = f'Play with Amberol ({count} Item{'s' if count > 1 else ''})'
        item = Nautilus.MenuItem(name=name, label=label)
        item.connect('activate', self._menu_activate_callback, audio_files)
        return [item]

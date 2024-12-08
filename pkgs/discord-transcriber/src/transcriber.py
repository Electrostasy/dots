#!/usr/bin/env python
# pyright: reportAny=false, reportExplicitAny=false

from argparse import ArgumentParser
from functools import partial
from pathlib import Path
from shutil import which
from subprocess import run
from tempfile import NamedTemporaryFile
from typing import Any, override
import asyncio
import logging
import logging.handlers

import discord

discord.utils.setup_logging()

def transcribe_file_blocking(input_file: Path, model_file: Path) -> str:
    '''
    Forms a blocking pipeline between ffmpeg and whisper-cpp to convert the
    ogg opus voice message files received from Discord into 16KHz wav files
    suitable for whisper-cpp.
    '''
    ffmpeg = run([
        'ffmpeg',
        '-hide_banner',
        '-loglevel', 'error',
        '-y',
        '-i', input_file.as_posix(),
        '-f', 'wav', # has to be in wav format for whisper-cpp.
        '-map_metadata', '0:s:a:0',
        '-ar', '16k', # has to be 16KHz for whisper-cpp.
        '-'
    ], check=True, capture_output=True)

    whisper = run([
        'whisper-cpp',
        '-m', model_file.as_posix(),
        '-np', # suppress all output that isn't the transcribed text.
        '-f', '-',
    ], input=ffmpeg.stdout, capture_output=True)

    return whisper.stdout.decode('utf-8').strip()

async def transcribe_file(input_file: Path, model_file: Path) -> str:
    '''
    Same as above, but wrapped to run asynchronously in order to not block
    the main Discord client loop.
    '''
    loop = asyncio.get_event_loop()
    func = partial(transcribe_file_blocking, input_file, model_file)

    return await loop.run_in_executor(None, func)

def format_transcription(text: str) -> str:
    '''
    Format the transcription created with whisper-cpp by removing leading zero
    pairs and putting the start times in inline code blocks.

    Example input string:
        [00:00:00.880 --> 00:00:03.380]   This is the future we live in now, Bates.
        [00:00:03.380 --> 00:00:05.200]   This is what you've done.
        [00:00:05.200 --> 00:00:06.840]   You've done it to yourself.
        [00:00:06.840 --> 00:00:08.000]   This is your fault.

    Example output string:
        `00.880` This is the future we live in now, Bates.
        `03.380` This is what you've done.
        `05.200` You've done it to yourself.
        `06.840` This is your fault.
    '''
    input_lines = text.splitlines()
    pairs = input_lines[-1][1:12].split(':').count('00')
    output_lines = [f'`{ts[0][1 + 2 * pairs + pairs:]}` {ts[3]}' for ts in (l.split(maxsplit=3) for l in input_lines)]
    return '\n'.join(output_lines)


class TranscriberClient(discord.Client):
    tree: discord.app_commands.CommandTree
    model_path: Path = Path()

    def __init__(self, *, intents: discord.Intents, **options: Any) -> None:
        super().__init__(intents=intents, **options)
        self.tree = discord.app_commands.CommandTree(self)

    @override
    async def setup_hook(self) -> None:
        _ = await self.tree.sync()
        logging.info('Transcriber is ready')

intents = discord.Intents.default()
intents.message_content = True
client = TranscriberClient(intents=intents)


@client.tree.context_menu()
@discord.app_commands.allowed_installs(guilds=False, users=True)
@discord.app_commands.allowed_contexts(guilds=True, dms=True, private_channels=True)
async def transcribe(interaction: discord.Interaction, message: discord.Message) -> None:
    '''
    Context menu command to be run for a single message in Discord. After running,
    it will try to transcribe the voice message, if it exists, into text, and
    post it in the same channel.

    We require the 'message_content' privileged intent for this.
    '''
    # Immediately defer since ffmpeg + whisper usually takes more than 3s.
    await interaction.response.defer(thinking=True)

    attachments: list[discord.Attachment] = []

    # For forwarded voice messages, message.attachments is empty, and we need
    # to traverse the message_snapshots for attachments instead.
    if message.attachments:
        attachments = message.attachments
    elif message.flags.forwarded:
        for snapshot in message.message_snapshots:
            for attachment in snapshot.attachments:
                attachments.append(attachment)

    if len(attachments) == 0:
        await interaction.followup.send(content='This message does not have any attachments!')
        return

    for attachment in attachments:
        # We want to support both voice messages (implemented as audio
        # attachments) and regular audio attachments.
        if attachment.content_type and not attachment.content_type.startswith('audio'):
            continue

        # TODO: Cache transcriptions in files named after their voice
        # message MD5, this way we don't have to re-run the pipeline.
        # We can remove them after some time using systemd tmpfiles.
        with NamedTemporaryFile() as attachment_file:
            attachment_path = Path(attachment_file.name)
            _ = await attachment.save(attachment_path)

            transcription = await transcribe_file(attachment_path, client.model_path)
            result = format_transcription(transcription)

            # Message contents are limited to 2000 characters, so we add it as
            # a file if it goes over the limit.
            if len(result) > 2000:
                logging.info('Processed whisper-cpp output exceeds 2000 characters, sending file')
                # We have to close the file to ensure the text is written to it,
                # otherwise we send an empty file.
                with NamedTemporaryFile(mode='w', delete_on_close=False) as result_file:
                    _ = result_file.write(result)
                    result_file.close()

                    file = discord.File(result_file.name, filename='transcription.txt')
                    await interaction.followup.send(content='transcribed:', file=file)

                    # Remove it after upload.
                    Path(result_file.name).unlink()

                    return

            await interaction.followup.send(content=f'transcribed:\n{result}')
            return

    # TODO: Some error messages here would be nice.
    logging.error('Transcription failed for some reason')
    await interaction.followup.send(content='Could not transcribe message!')


def main():
    parser = ArgumentParser()
    _ = parser.add_argument('-t', '--token', help='The Discord token to use', type=str, required=True)
    _ = parser.add_argument('-m', '--model', help='Path to the whisper-cpp model to use', type=str, required=True)
    args = parser.parse_args()

    client.model_path = Path(args.model)

    if not which('whisper-cpp'):
        logging.error('whisper-cpp binary not found in PATH, exiting')
        exit(1)

    if not which('ffmpeg'):
        logging.error('ffmpeg binary not found in PATH, exiting')
        exit(1)

    logging.info('Starting the Transcriber client')
    client.run(args.token, log_handler=None)


if __name__ == '__main__':
    main()

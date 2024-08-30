function phobos-up -d "Upload files to phobos for public sharing"
  # Avoid uploading directories.
  set -l files
  for arg in $argv
    if test -d "$arg"
      printf 'Skipping directory %s\n' "$arg"
      continue
    end
    set files $files "$arg"
  end

  if test (count $files) -gt 0
    # Nginx needs to be able to read the files.
    if rsync --compress --progress --chmod=D440,F664 $files phobos:/srv/http/static
      printf "\nUpload finished successfully!\n"
    else
      printf '\nUpload failed due to errors!\n'
      return 1
    end
  else
    printf '\nUpload skipped due to not enough arguments!\n'
    return 1
  end

  # If multiple arguments are provided, get escaped URLs for all of them.
  set -l urls
  set -l domain (domainname)
  for file in (path basename $files)
    set urls $urls "https://$domain/static/$(string escape --style=url $file)"
  end

  set urls "$(string collect $urls)"
  printf "\nUploaded files can be downloaded from these URLs:\n%s\n\n" $urls

  # If we are in a graphical Wayland environment, copy the URLs to the clipboard.
  if command -q wl-copy
    wl-copy $urls

    if test $status -eq 0
      printf "Above URLs have been copied to the clipboard.\n"
    end
  end
end

# `age` Key Rotation

The `age` private key is used for decrypting secrets encrypted with the public
key on activation. If the key is unavailable, you will not be able to login and
certain services will not function correctly.

The `age` private key has to be generated and placed in
`/var/lib/sops-nix/keys.txt` before secrets can be decrypted or rotated.
Generate the `age` private key:
```sh
rage-keygen -o ~/keys.txt
```

These commands can rotate the keys in all encrypted files in-place:
```sh
key="$(rg '# public key: (.*)' -or '$1' /var/lib/sops-nix/keys.txt)"
key_new="$(rg '# public key: (.*)' -or '$1' ~/keys.txt)"

fd --full-path "secrets.yaml" -x sops rotate -i --add-age "$key_new" --rm-age "$key"
```

> [!IMPORTANT]
> The public key in the `.sops.yaml` configuration file and the private key in
> `/var/lib/sops-nix/keys.txt` have to be updated manually.

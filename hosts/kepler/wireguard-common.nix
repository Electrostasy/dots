{ lib, ... }:

let
  imapNAttrs = imapFn: f: set:
    lib.listToAttrs
      (imapFn
        (i: attr:
          lib.nameValuePair
            attr
            (f i attr set.${attr}))
        (lib.attrNames set));
  imap1Attrs = imapNAttrs lib.imap1;
  incrementIPs =
    imap1Attrs (i: _: v:
      # Begin incrementing from 2 (i + 1), because we need to exclude `kepler`
      # (10.10.1.1/32) as the Wireguard server. Nix rearranges attribute sets
      # so we specify the `AllowedIPs` field for `kepler` separately to ensure
      # it receives the correct IP.
      v // { AllowedIPs = [ "10.10.1.${toString (i + 1)}/32" ]; });
in
{
  server = "89.40.15.69";
  port = 51820;

  # Add new nodes by generating private-public key-pairs, put public key here
  # and private key in sops. Generate keys using the following command:
  # $ wg genkey | tee wg-private.key | wg pubkey > wg-public.key
  nodes =
    # The Wireguard server needs a hardcoded IP, we ensure that by specifying
    # it separately here, and assigning the rest of the peers incrementally
    # higher IPs, starting with 10.10.1.2/32.
    { kepler = {
        PublicKey = "K9+2GqQVcDHziXuRH0b+0qa/h4hSiHT+Yucvw8nzHiw=";
        AllowedIPs = [ "10.10.1.1/32" ];
      };
    }
    // incrementIPs
    { jupiter.PublicKey = "+6fRdPzEfxga54TAownHZkB1HWwJnx710sYGsQYo+hI=";
      phobos.PublicKey = "1oFQGMa4Bqz4fI7eFzv35McKIqM2uHmx84xYUzIoJy8=";
      terra.PublicKey = "sD/7po+EE6tudfD161kTNljopV1yRKp4QdMMhvgkcBY=";
      venus.PublicKey = "aKbnzn8++N5OoTv4tTFKlcq246m1s02s9SUttxoJICo=";
    };
}

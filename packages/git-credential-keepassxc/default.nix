{
  fetchFromGitHub,
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "git-credential-keepassxc";
  version = "0.10.1";

  src = fetchFromGitHub {
    owner = "Frederick888";
    repo = pname;
    rev = "c8bc2ca201cd9794c641eefca51865547b9203bd";
    sha256 = "sha256-zVE3RQlh0SEV4iavz40YhR+MP31oLCvG54H8gqXwL/k=";
  };

  cargoSha256 = "sha256-H75SGbT//02I+umttnPM5BwtFkDVNxEYLf84oULEuEk=";

  meta = with lib; {
    description = ''
      Helper that allows Git (and shell scripts) to use KeePassXC as credential store
    '';
    homepage = "https://github.com/Frederick888/git-credential-keepassxc";
    license = licenses.gpl3;
  };
}

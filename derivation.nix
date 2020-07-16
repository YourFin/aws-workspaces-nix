{ stdenv, fetchurl, dpkg, gtk3, gtk3-x11, icu, saneBackends, webkitgtk, systemd
, libsoup, libpulseaudio, pcre, krb5, openssl, lttng-ust, curl, autoPatchelfHook
, makeWrapper, lib }:
let
  mirror = "https://d3nt0h4h6pmmc4.cloudfront.net/workspacesclient_amd64.deb";
  src = fetchurl {
    url = mirror;
    sha256 = "1nsgd6z47aaw750f6j3qa7bq40bxcvvb5qmi43sbk5bkjyrbwvq4";
  };
in stdenv.mkDerivation rec {
  pname = "amazon-workspaces";
  version = "3.0.7.470";

  inherit src;

  system = "x86_64-linux";

  nativeBuildInputs = [ autoPatchelfHook dpkg makeWrapper ];
  # Required at runtime
  buildInputs = [
    systemd.lib
    icu
    gtk3
    gtk3-x11
    webkitgtk
    libsoup
    saneBackends
    libpulseaudio
    krb5
    openssl
    pcre
    lttng-ust
    curl
  ];

  unpackPhase = "true";

  installPhase = let
    ld-prefix =
      lib.strings.concatMapStringsSep ":" (itm: itm + "/lib") buildInputs;
  in ''
    mkdir -p $out/bin
    # Extract from deb
    dpkg -x $src $out
    # Fix desktop file
    substituteInPlace \
      $out/usr/share/applications/workspacesclient.desktop \
      --replace /opt/ $out/opt
    # Symlink binary to bin/
    ln -s $out/opt/workspacesclient/workspacesclient \
       $out/bin/workspaceclient-unwrapped
    # Build wrapper so dotnet doesn't yell at runtime
    makeWrapper $out/bin/workspaceclient-unwrapped $out/bin/workspaceclient \
                --prefix LD_LIBRARY_PATH : ${ld-prefix}
  '';

  meta = with stdenv.lib; {
    description = "Client for Amazon workspaces VDI";
    homepage = "https://aws.amazon.com/workspaces/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}

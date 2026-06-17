{
  description = "Nix flake packaging the Zo desktop app from the upstream Debian release";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };

  outputs = { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      systems = [ "x86_64-linux" ];
      forAllSystems = lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          runtimeLibs = with pkgs; [
            alsa-lib
            at-spi2-atk
            atk
            cairo
            cups
            dbus
            expat
            fontconfig
            freetype
            gdk-pixbuf
            glib
            gtk3
            libdrm
            libsecret
            libuuid
            mesa
            nspr
            nss
            pango
            stdenv.cc.cc.lib
            systemd
            vulkan-loader
            xorg.libX11
            xorg.libXcomposite
            xorg.libXcursor
            xorg.libXdamage
            xorg.libXext
            xorg.libXfixes
            xorg.libXi
            xorg.libXinerama
            xorg.libXrandr
            xorg.libxcb
            libxkbcommon
          ];
          runtimeBins = with pkgs; [
            bash
            coreutils
            curl
            findutils
            gnugrep
            gnused
            openssh
            procps
            xdg-utils
          ];
          zo = pkgs.stdenv.mkDerivation (finalAttrs: {
            pname = "zo";
            version = "1.5.6";

            src = pkgs.fetchurl {
              url = "https://github.com/zocomputer/Zo/releases/download/v${finalAttrs.version}/Zo-${finalAttrs.version}-amd64.deb";
              hash = "sha256-jLeWMmQA7PsTuOCIvxz4UAoANBShKlwGCPQQbIqgEfg=";
            };

            nativeBuildInputs = with pkgs; [
              autoPatchelfHook
              dpkg
              makeWrapper
            ];

            buildInputs = runtimeLibs;

            dontWrapGApps = true;

            unpackPhase = ''
              runHook preUnpack
              dpkg-deb -x "$src" .
              runHook postUnpack
            '';

            installPhase = ''
              runHook preInstall

              mkdir -p "$out/opt" "$out/bin"
              cp -r opt/Zo "$out/opt/Zo"

              install -Dm644 usr/share/icons/hicolor/512x512/apps/zo.png \
                "$out/share/icons/hicolor/512x512/apps/zo.png"

              sed \
                -e "s#^Exec=/opt/Zo/zo %U#Exec=$out/bin/zo %U#" \
                -e "s#^Icon=zo#Icon=$out/share/icons/hicolor/512x512/apps/zo.png#" \
                usr/share/applications/zo.desktop > zo.desktop

              install -Dm644 zo.desktop "$out/share/applications/zo.desktop"

              makeWrapper "$out/opt/Zo/zo" "$out/bin/zo" \
                --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}" \
                --prefix PATH : "${lib.makeBinPath runtimeBins}" \
                --set-default ELECTRON_FORCE_IS_PACKAGED 1 \
                --add-flags "\''${NIX_ZO_FLAGS:-}"

              runHook postInstall
            '';

            meta = with lib; {
              description = "Zo desktop client packaged from the upstream Debian release";
              homepage = "https://zo.computer";
              sourceProvenance = [ sourceTypes.binaryNativeCode ];
              platforms = [ "x86_64-linux" ];
              mainProgram = "zo";
            };
          });
        in
        {
          inherit zo;
          default = zo;
        });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.zo}/bin/zo";
        };
      });
    };
}

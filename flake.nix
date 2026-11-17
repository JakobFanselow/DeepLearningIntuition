{
  description = "Quarto slides with live Python (torch) via a local Jupyter kernel";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      python = pkgs.python3.withPackages (ps: with ps; [
        jupyter
        ipykernel

        numpy
        scipy
        pandas
        matplotlib
        scikit-learn

        torch
      ]);

      # Starts the kernel server the slides connect to.
      kernelServer = pkgs.writeShellScriptBin "kernel-server" ''
        exec ${python}/bin/jupyter server \
          --no-browser \
          --ip=127.0.0.1 \
          --port=8888 \
          --ServerApp.token="''${SLIDES_TOKEN:-slides-secret}" \
          --ServerApp.allow_origin='*' \
          --ServerApp.disable_check_xsrf=True \
          --ServerApp.root_dir="$PWD"
      '';
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          python
          kernelServer
          pkgs.quarto
          pkgs.chromium
        ];

        shellHook = ''
          export JUPYTER_PATH=${python}/share/jupyter
          echo "Quarto $(quarto --version) | $(python --version)"
          echo "Run 'kernel-server' in one terminal, 'quarto preview slides.qmd' in another."
        '';
      };
    };
}

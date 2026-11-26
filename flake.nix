{
  description = "Development environment for billiards management";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          # Go
          go
          gopls
          golangci-lint
          delve

          # Flutter
          flutter

          # Docker
          docker
          docker-compose

          # Base de datos (migraciones con goose)
          postgresql
          goose
          sqlc
        ];

        shellHook = ''echo "Entorno de desarrollo activo"'';
      };
    };
}

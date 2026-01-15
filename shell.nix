{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    neovim
    luajitPackages.busted
  ];

  shellHook = ''
    echo "nvim-codestral development environment"
    echo "Run 'busted' to execute tests"
  '';
}

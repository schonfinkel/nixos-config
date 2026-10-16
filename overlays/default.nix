{
  pkgs,
  inputs,
  system,
  ...
}:

{
  nixpkgs.overlays = [
    inputs.emacs.overlay
    inputs.nix-vscode-extensions.overlays.default
    # Adds a `pkgs.llm-agents.<name>` scope of daily-updated AI coding agent
    # packages (claude-code, codex, cursor-agent, opencode, ...). Nothing from
    # nixpkgs is shadowed; home/llms.nix references the scope explicitly.
    inputs.llm-agents.overlays.shared-nixpkgs
  ];

  # Trust the binary caches used by the packages above. This takes effect
  # system-wide after the next switch; flake.nix carries the same values for
  # builds run with --accept-flake-config before then.
  nix.settings = {
    # `root` is included by NixOS already.
    trusted-users = [ "mbenevides" ];
    substituters = [
      "https://noctalia.cachix.org"
      "https://cache.numtide.com"
    ];
    trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };
}

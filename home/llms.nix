{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.homeModules.llms;

  # Agent CLIs from the llm-agents.nix overlay (overlays/default.nix wires
  # inputs.llm-agents.overlays.shared-nixpkgs, which adds this scope).
  agents = pkgs.llm-agents;

  types = lib.types;

  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;

  # Decrypted agenix secrets live here (modules/agenix.nix declares them for
  # whichever Home Manager user turns on enableWorkProfile). Only *paths* are
  # ever interpolated into store objects; values are read at runtime.
  agenixPath = name: "/run/agenix/${name}";

  secretHeaderType = types.submodule {
    options = {
      secret = mkOption {
        type = types.str;
        description = "Agenix secret name holding the raw header value.";
      };
      prefix = mkOption {
        type = types.str;
        default = "";
        example = "Basic ";
        description = "Scheme prepended to the secret at runtime (e.g. \"Basic \").";
      };
    };
  };

  mcpServerType = types.submodule {
    options = {
      url = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Static endpoint URL for a remote (HTTP) server. Not secret.";
      };
      urlSecret = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Agenix secret name holding the endpoint URL of a remote server.";
      };
      headers = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Static HTTP headers (no secrets).";
      };
      secretHeaders = mkOption {
        type = types.attrsOf secretHeaderType;
        default = { };
        description = "HTTP headers whose values are read from agenix at runtime.";
      };
      command = mkOption {
        type = types.nullOr (types.either types.str types.package);
        default = null;
        description = "Executable of a local (stdio) server.";
      };
      args = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Arguments for a local (stdio) server.";
      };
      env = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Environment variables for a local (stdio) server.";
      };
    };
  };

  isRemote = s: s.url != null || s.urlSecret != null;
  hasSecrets = s: s.urlSecret != null || s.secretHeaders != { };

  # Every client but the personal Claude profile sees the union of both sets.
  allServers = cfg.personalMcpServers // cfg.mcpServers;
  secretServers = lib.filterAttrs (_: s: hasSecrets s) allServers;
  safeServers = lib.filterAttrs (_: s: !hasSecrets s) allServers;

  # LLMS_<SERVER>_<HEADER>, used for the env vars codexw exports and codex's
  # env_http_headers consumes.
  envName =
    server: header:
    "LLMS_"
    + lib.toUpper (builtins.replaceStrings [ "-" "." " " ] [ "_" "_" "_" ] "${server}_${header}");
  shellName = server: builtins.replaceStrings [ "-" "." " " ] [ "_" "_" "_" ] server;

  json = pkgs.formats.json { };

  # Render the shared Claude Code / Cursor JSON shape. Secret leaves are null
  # placeholders, filled at runtime by jq (see jqSecretFill).
  renderMcpServers = servers: {
    mcpServers = lib.mapAttrs (
      _name: s:
      if isRemote s then
        {
          type = "http";
        }
        // (lib.optionalAttrs (s.urlSecret != null) { url = null; })
        // (lib.optionalAttrs (s.url != null) { url = s.url; })
        // (lib.optionalAttrs (s.headers != { } || s.secretHeaders != { }) {
          headers = s.headers // (lib.mapAttrs (_: _: null) s.secretHeaders);
        })
      else
        {
          type = "stdio";
          command = "${s.command}";
        }
        // (lib.optionalAttrs (s.args != [ ]) { args = s.args; })
        // (lib.optionalAttrs (s.env != { }) { env = s.env; })
    ) servers;
  };

  renderOpencode = servers: {
    "$schema" = "https://opencode.ai/config.json";
    mcp = lib.mapAttrs (
      _name: s:
      if isRemote s then
        {
          type = "remote";
        }
        // (lib.optionalAttrs (s.urlSecret != null) { url = null; })
        // (lib.optionalAttrs (s.url != null) { url = s.url; })
        // (lib.optionalAttrs (s.headers != { } || s.secretHeaders != { }) {
          headers = s.headers // (lib.mapAttrs (_: _: null) s.secretHeaders);
        })
        # Basic-auth servers must not trigger OpenCode's OAuth flow.
        // (lib.optionalAttrs (s.secretHeaders != { }) { oauth = false; })
      else
        {
          type = "local";
          command = [ "${s.command}" ] ++ s.args;
          enabled = true;
        }
        // (lib.optionalAttrs (s.env != { }) { environment = s.env; })
    ) servers;
  };

  # jq program + --rawfile arguments replacing the null placeholders above
  # with runtime secret values. Only /run/agenix *paths* end up in the store.
  jqSecretFill =
    rootAttr: servers:
    let
      perServer =
        name: s:
        (lib.optional (s.urlSecret != null) {
          path = "." + rootAttr + "[\"" + name + "\"].url";
          file = agenixPath s.urlSecret;
          prefix = "";
        })
        ++ (lib.mapAttrsToList (h: sc: {
          path = "." + rootAttr + "[\"" + name + "\"].headers.\"" + h + "\"";
          file = agenixPath sc.secret;
          inherit (sc) prefix;
        }) s.secretHeaders);
      rawSteps = lib.concatLists (lib.mapAttrsToList perServer servers);
      steps = lib.imap0 (i: s: s // { index = i; }) rawSteps;
    in
    {
      program =
        if steps == [ ] then
          "."
        else
          lib.concatStringsSep " | " (
            map (s: "${s.path} = (${builtins.toJSON s.prefix} + $raw${toString s.index})") steps
          );
      args = lib.concatLists (
        map (s: [
          "--rawfile"
          "raw${toString s.index}"
          s.file
        ]) steps
      );
      nonEmpty = steps != [ ];
    };

  # A tiny store script rendering one template to stdout with secrets filled.
  mkRenderer =
    name: template: fill:
    pkgs.writeShellScript name ''
      exec ${pkgs.jq}/bin/jq ${lib.concatStringsSep " " (map lib.escapeShellArg fill.args)} ${lib.escapeShellArg fill.program} ${template}
    '';

  personalTemplate = json.generate "claude-mcp-personal.json" (
    renderMcpServers cfg.personalMcpServers
  );
  workTemplate = json.generate "claude-mcp-work.json" (renderMcpServers allServers);
  cursorTemplate = json.generate "cursor-mcp.json" (renderMcpServers allServers);
  opencodeTemplate = json.generate "opencode-mcp.json" (renderOpencode allServers);

  claudePersonalRenderer = mkRenderer "llms-claude-personal" personalTemplate (
    jqSecretFill "mcpServers" cfg.personalMcpServers
  );
  claudeWorkRenderer = mkRenderer "llms-claude-work" workTemplate (
    jqSecretFill "mcpServers" allServers
  );
  cursorRenderer = mkRenderer "llms-cursor" cursorTemplate (jqSecretFill "mcpServers" allServers);
  opencodeRenderer = mkRenderer "llms-opencode" opencodeTemplate (jqSecretFill "mcp" allServers);

  # `cc` replaces the old ccp/ccw wrappers. The active profile comes from
  # CLAUDE_CONFIG_DIR (set per project via the direnv `claude_profile` helper
  # below); it defaults to the personal profile. Work MCPs load only under
  # the work profile; personal MCPs (secret-free) load everywhere.
  cc = pkgs.writeShellApplication {
    name = "cc";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      profile="''${CLAUDE_CONFIG_DIR:-${cfg.profiles.personal}}"
      renderer="${claudePersonalRenderer}"
      if [ "$profile" = "${cfg.profiles.work}" ]; then
        renderer="${claudeWorkRenderer}"
      fi
      export CLAUDE_CONFIG_DIR="$profile"

      mcp_config="$(mktemp "''${XDG_RUNTIME_DIR:-/tmp}/llms-mcp.XXXXXX")"
      if ! "$renderer" > "$mcp_config" 2>/dev/null; then
        rm -f "$mcp_config"
        echo "cc: could not render MCP config (agenix secrets unreadable?); starting without MCPs" >&2
        exec ${agents.claude-code}/bin/claude "$@"
      fi
      chmod 600 "$mcp_config"

      if jq -e '.mcpServers | length > 0' "$mcp_config" > /dev/null 2>&1; then
        exec ${agents.claude-code}/bin/claude --mcp-config "$mcp_config" "$@"
      fi
      rm -f "$mcp_config"
      exec ${agents.claude-code}/bin/claude "$@"
    '';
  };

  # Codex keeps its non-secret servers in ~/.codex/config.toml (store
  # symlink). Servers with secrets are injected per invocation: the URL via
  # `codex -c` and header values via env_http_headers, whose values codex
  # reads from the exported environment. Nothing secret hits the store.
  codexConfigToml =
    if safeServers == { } then
      null
    else
      (pkgs.formats.toml { }).generate "codex-config.toml" {
        mcp_servers = lib.mapAttrs (
          name: s:
          if isRemote s then
            { url = s.url; } // (lib.optionalAttrs (s.headers != { }) { http_headers = s.headers; })
          else
            {
              command = "${s.command}";
            }
            // (lib.optionalAttrs (s.args != [ ]) { args = s.args; })
            // (lib.optionalAttrs (s.env != { }) { env = s.env; })
        ) safeServers;
      };

  # TOML fragments for one secret server, assembled into a single
  # `mcp_servers.<name> = { ... }` inline table passed via `codex -c`.
  # The fragments carry literal \" escapes because they end up inside a
  # double-quoted bash string in codexw below.
  tomlEscape = v: builtins.replaceStrings [ "\\" "\"" ] [ "\\\\" "\\\"" ] v;

  codexSecretTable =
    name: s:
    lib.concatStringsSep ", " (
      (lib.optional (s.urlSecret != null) ''url = \"$llms_${shellName name}_url\"'')
      ++ (lib.optional (s.secretHeaders != { }) (
        "env_http_headers = { "
        + lib.concatStringsSep ", " (
          lib.mapAttrsToList (h: _: ''${h} = \"${envName name h}\"'') s.secretHeaders
        )
        + " }"
      ))
      ++ (lib.optional (s.headers != { }) (
        "http_headers = { "
        + lib.concatStringsSep ", " (lib.mapAttrsToList (h: v: ''${h} = \"${tomlEscape v}\"'') s.headers)
        + " }"
      ))
    );

  codexw = pkgs.writeShellApplication {
    name = "codexw";
    text =
      lib.concatStringsSep "\n" (
        lib.concatLists (
          lib.mapAttrsToList (
            name: s:
            (lib.optional (s.urlSecret != null) ''
              llms_${shellName name}_url="$(cat ${agenixPath s.urlSecret})"
            '')
            ++ (lib.mapAttrsToList (h: sc: ''
              export ${envName name h}="${sc.prefix}$(cat ${agenixPath sc.secret})"
            '') s.secretHeaders)
          ) secretServers
        )
      )
      + ''

        extra=()
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (name: s: ''
            extra+=( -c "mcp_servers.${name} = { ${codexSecretTable name s} }" )
          '') secretServers
        )}
        exec ${agents.codex}/bin/codex "''${extra[@]}" "$@"
      '';
  };

  # Cursor cannot follow symlinks for ~/.cursor/mcp.json and OpenCode needs
  # the secret URL inline, so both files are materialised as real files (0600)
  # by an activation script reading /run/agenix at switch time. Rotation of a
  # secret therefore requires re-running the switch.
  mcpActivation = ''
    render() { # $1 renderer, $2 target
      local renderer="$1" target="$2" tmp
      tmp="$(mktemp)"
      if "$renderer" > "$tmp" 2>/dev/null; then
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 600 "$tmp" "$target"
      else
        echo "llms: skipped $target (agenix secrets not readable yet?)" >&2
      fi
      rm -f "$tmp"
    }
  '';
in
{
  options.homeModules.llms = {
    enable = mkEnableOption "Enable AI coding agents (llm-agents.nix) with declarative MCP servers.";

    clients = {
      claude = mkOption {
        type = types.bool;
        default = true;
        description = "Install Claude Code and the `cc` profile-aware wrapper.";
      };
      codex = mkOption {
        type = types.bool;
        default = true;
        description = "Install Codex CLI, its declarative config.toml and the `codexw` wrapper.";
      };
      cursor = mkOption {
        type = types.bool;
        default = true;
        description = "Install Cursor Agent and manage ~/.cursor/mcp.json.";
      };
      opencode = mkOption {
        type = types.bool;
        default = true;
        description = "Install OpenCode and manage ~/.config/opencode/opencode.json.";
      };
    };

    profiles = {
      personal = mkOption {
        type = types.str;
        default = "${config.home.homeDirectory}/.claude/personal";
        description = "CLAUDE_CONFIG_DIR default (personal subscription state).";
      };
      work = mkOption {
        type = types.str;
        default = "${config.home.homeDirectory}/.claude/work";
        description = "CLAUDE_CONFIG_DIR for the work subscription; loads the work MCP set.";
      };
    };

    # Servers needing agenix secrets require hostModules.agenix on the host
    # plus the matching secret declarations in modules/agenix.nix.
    mcpServers = mkOption {
      type = types.attrsOf mcpServerType;
      default = { };
      description = "Work MCP servers: loaded by codex/cursor/opencode and by `cc` under the work profile.";
    };

    personalMcpServers = mkOption {
      type = types.attrsOf mcpServerType;
      default = { };
      description = "Secret-free MCP servers loaded by every client on every profile.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages =
        (lib.optionals cfg.clients.claude [
          agents.claude-code
          cc
        ])
        ++ (lib.optionals cfg.clients.codex (
          [ agents.codex ] ++ (lib.optional (secretServers != { }) codexw)
        ))
        ++ (lib.optionals cfg.clients.cursor [ agents.cursor-agent ])
        ++ (lib.optionals cfg.clients.opencode [ agents.opencode ]);

      # Per-project profile switching for Claude Code subscriptions. Add
      # `claude_profile work;` (or personal) to a repository's .envrc. Goes
      # through `stdlib` so Home Manager's generated direnvrc (which also
      # wires nix-direnv) keeps working.
      programs.direnv.stdlib = ''
        claude_profile() {
          case "$1" in
            personal) export CLAUDE_CONFIG_DIR="${cfg.profiles.personal}" ;;
            work) export CLAUDE_CONFIG_DIR="${cfg.profiles.work}" ;;
            *) echo "claude_profile: expected 'personal' or 'work', got '$1'" >&2 ;;
          esac
        }
      '';

      assertions =
        let
          serverAssertions =
            prefix: servers:
            lib.concatLists (
              lib.mapAttrsToList (name: s: [
                {
                  assertion = (s.url != null) != (s.urlSecret != null) || s.command != null;
                  message = ''homeModules.llms.${prefix}."${name}": set exactly one of url / urlSecret, or command'';
                }
                {
                  assertion = s.command == null || (s.url == null && s.urlSecret == null);
                  message = ''homeModules.llms.${prefix}."${name}": command cannot be combined with url/urlSecret'';
                }
              ]) servers
            );
        in
        (serverAssertions "mcpServers" cfg.mcpServers)
        ++ (serverAssertions "personalMcpServers" cfg.personalMcpServers);
    }

    (mkIf (cfg.clients.codex && safeServers != { }) {
      home.file.".codex/config.toml".source = codexConfigToml;
    })

    {
      # Cursor (symlink-intolerant) and OpenCode (needs secret URL inline)
      # get real files rendered during Home Manager activation. Only touched
      # when at least one server is configured, so hosts with llms enabled
      # but an empty MCP set keep their files untouched.
      home.activation.llmsMcpConfigs = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        mcpActivation
        + (lib.optionalString (cfg.clients.cursor && allServers != { }) ''
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/.cursor"
          render "${cursorRenderer}" "${config.home.homeDirectory}/.cursor/mcp.json"
        '')
        + (lib.optionalString (cfg.clients.opencode && allServers != { }) ''
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/.config/opencode"
          render "${opencodeRenderer}" "${config.home.homeDirectory}/.config/opencode/opencode.json"
        '')
      );
    }
  ]);
}

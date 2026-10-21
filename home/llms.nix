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

  aiMemoryServer = {
    url = "${lib.removeSuffix "/" cfg.aiMemory.serverUrl}/mcp";
    urlSecret = null;
    headers = { };
    secretHeaders = { };
    command = null;
    args = [ ];
    env = { };
  };

  personalServers =
    (lib.optionalAttrs cfg.aiMemory.enable { ai-memory = aiMemoryServer; }) // cfg.personalMcpServers;

  isRemote = s: s.url != null || s.urlSecret != null;
  hasSecrets = s: s.urlSecret != null || s.secretHeaders != { };

  # Every client but the personal Claude profile sees the union of both sets.
  allServers = personalServers // cfg.mcpServers;
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

  renderHttpServer =
    type: s:
    {
      inherit type;
    }
    // (lib.optionalAttrs (s.urlSecret != null) { url = null; })
    // (lib.optionalAttrs (s.url != null) { url = s.url; })
    // (lib.optionalAttrs (s.headers != { } || s.secretHeaders != { }) {
      headers = s.headers // (lib.mapAttrs (_: _: null) s.secretHeaders);
    });

  renderStdioServer =
    s:
    {
      command = "${s.command}";
    }
    // (lib.optionalAttrs (s.args != [ ]) { args = s.args; })
    // (lib.optionalAttrs (s.env != { }) { env = s.env; });

  # Render the shared Claude Code / Cursor JSON shape. Secret leaves are null
  # placeholders, filled at runtime by jq (see jqSecretFill).
  renderMcpServers = servers: {
    mcpServers = lib.mapAttrs (
      _name: s:
      if isRemote s then renderHttpServer "http" s else { type = "stdio"; } // renderStdioServer s
    ) servers;
  };

  renderOpencode = servers: {
    "$schema" = "https://opencode.ai/config.json";
    mcp = lib.mapAttrs (
      _name: s:
      if isRemote s then
        renderHttpServer "remote" s
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
            map (
              s: ''${s.path} = (${builtins.toJSON s.prefix} + ($raw${toString s.index} | sub("[\\r\\n]+$"; "")))''
            ) steps
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

  mkJsonRenderer =
    {
      scriptName,
      templateName,
      rootAttr,
      servers,
      render,
    }:
    mkRenderer scriptName (json.generate templateName (render servers)) (jqSecretFill rootAttr servers);

  claudePersonalRenderer = mkJsonRenderer {
    scriptName = "llms-claude-personal";
    templateName = "claude-mcp-personal.json";
    rootAttr = "mcpServers";
    servers = personalServers;
    render = renderMcpServers;
  };
  claudeWorkRenderer = mkJsonRenderer {
    scriptName = "llms-claude-work";
    templateName = "claude-mcp-work.json";
    rootAttr = "mcpServers";
    servers = allServers;
    render = renderMcpServers;
  };
  cursorRenderer = mkJsonRenderer {
    scriptName = "llms-cursor";
    templateName = "cursor-mcp.json";
    rootAttr = "mcpServers";
    servers = allServers;
    render = renderMcpServers;
  };
  opencodeRenderer = mkJsonRenderer {
    scriptName = "llms-opencode";
    templateName = "opencode-mcp.json";
    rootAttr = "mcp";
    servers = allServers;
    render = renderOpencode;
  };

  claudeRenderers = {
    personal = claudePersonalRenderer;
    work = claudeWorkRenderer;
  };

  # Renders Claude's MCP config for the given profiles (default: all) to a
  # stable per-profile path in the runtime dir, printing each path written.
  # The path must be stable: Claude Code background jobs store their launch
  # flags (including --mcp-config) and respawn with them later, outside
  # `ccp`, so a per-launch temp file breaks them once it is gone. Writes are
  # atomic so a respawning session never reads a partial file; on failure the
  # previous file is kept and the script exits non-zero.
  claudeMcp = pkgs.writeShellApplication {
    name = "llms-claude-mcp";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      dir="''${XDG_RUNTIME_DIR:-/tmp}/llms-mcp"
      mkdir -p "$dir"
      chmod 700 "$dir"

      render() { # $1 profile, $2 renderer
        local target="$dir/claude-$1.json" tmp
        tmp="$(mktemp "$dir/.claude-$1.XXXXXX")"
        if "$2" > "$tmp" 2>/dev/null; then
          chmod 600 "$tmp"
          mv -f "$tmp" "$target"
          echo "$target"
        else
          rm -f "$tmp"
          echo "llms-claude-mcp: could not render $target (agenix secrets unreadable?)" >&2
          return 1
        fi
      }

      [ "$#" -gt 0 ] || set -- ${lib.concatStringsSep " " (lib.attrNames claudeRenderers)}
      status=0
      for profile in "$@"; do
        case "$profile" in
          ${lib.concatStrings (
            lib.mapAttrsToList (name: renderer: ''
              ${name}) render ${name} ${renderer} || status=1 ;;
            '') claudeRenderers
          )}
          *)
            echo "llms-claude-mcp: unknown profile '$profile'" >&2
            status=2
            ;;
        esac
      done
      exit "$status"
    '';
  };

  # `ccp` is the custom-Claude-profile wrapper. The active profile comes from
  # CLAUDE_CONFIG_DIR (set per project via the direnv `claude_profile` helper
  # below); it defaults to the personal profile. Work MCPs load only under
  # the work profile; personal MCPs (secret-free) load everywhere.
  ccp = pkgs.writeShellApplication {
    name = "ccp";
    runtimeInputs = [
      pkgs.jq
      claudeMcp
      agents.claude-code
    ];
    text = ''
      profile="''${CLAUDE_CONFIG_DIR:-${cfg.profiles.personal}}"
      name=personal
      if [ "$profile" = "${cfg.profiles.work}" ]; then
        name=work
      fi
      export CLAUDE_CONFIG_DIR="$profile"

      # Re-rendered on every launch so rotated secrets are picked up.
      if ! mcp_config="$(llms-claude-mcp "$name")"; then
        echo "ccp: could not render MCP config; starting without MCPs" >&2
        exec claude "$@"
      fi

      if jq -e '.mcpServers | length > 0' "$mcp_config" > /dev/null 2>&1; then
        exec claude --mcp-config "$mcp_config" "$@"
      fi
      exec claude "$@"
    '';
  };

  # Codex keeps its non-secret servers in ~/.codex/config.toml. Codex also
  # writes its own state there (project trust, model, TUI flags), so the file
  # stays a real file and activation only replaces its `mcp_servers` table
  # (see codexActivation). Servers with secrets are injected per invocation: the URL via
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
            renderStdioServer s
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
              ${envName name h}="${sc.prefix}$(cat ${agenixPath sc.secret})"
              export ${envName name h}
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

  # Merges the declarative `mcp_servers` table into ~/.codex/config.toml,
  # keeping everything Codex wrote itself. Earlier generations symlinked the
  # file into the store; that link is replaced, seeding from config.toml.bkp
  # (the pre-symlink copy) when present.
  codexActivation =
    let
      codexDir = "${config.home.homeDirectory}/.codex";
      toml2json = "${pkgs.remarshal}/bin/toml2json";
      json2toml = "${pkgs.remarshal}/bin/json2toml";
      jq = lib.getExe pkgs.jq;
    in
    ''
      codex_config="${codexDir}/config.toml"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${codexDir}"
      if [ -L "$codex_config" ]; then
        $DRY_RUN_CMD rm -f "$codex_config"
      fi
      if [ ! -e "$codex_config" ] && [ -f "${codexDir}/config.toml.bkp" ]; then
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 600 "${codexDir}/config.toml.bkp" "$codex_config"
      fi
      tmp="$(mktemp)"
      if { if [ -f "$codex_config" ]; then ${toml2json} "$codex_config"; else echo '{}'; fi; } \
          | ${jq} --argjson managed "$(${toml2json} ${codexConfigToml})" \
            '.mcp_servers = $managed.mcp_servers' \
          | ${json2toml} > "$tmp" 2>/dev/null; then
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 600 "$tmp" "$codex_config"
      else
        echo "llms: skipped $codex_config (could not merge existing TOML)" >&2
      fi
      rm -f "$tmp"
    '';

  aiMemoryActivation =
    let
      aiMemory = lib.getExe cfg.aiMemory.package;
      enabledAgentClients = lib.filter (client: cfg.clients.${client}) [
        "codex"
        "cursor"
        "opencode"
      ];
      path = lib.makeBinPath (
        [ cfg.aiMemory.package ] ++ lib.optionals cfg.clients.opencode [ agents.opencode ]
      );
      hookArgs = lib.concatStringsSep " " [
        "--apply"
        "--capture-mode"
        (lib.escapeShellArg cfg.aiMemory.captureMode)
        "--project-strategy"
        "repo-root"
        "--server-url"
        (lib.escapeShellArg cfg.aiMemory.serverUrl)
      ];
      installHooks = agent: ''
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/env PATH=${lib.escapeShellArg path} ${aiMemory} install-hooks --agent ${agent} ${hookArgs}
      '';
      installClaude = profile: ''
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/env PATH=${lib.escapeShellArg path} CLAUDE_CONFIG_DIR=${lib.escapeShellArg profile} ${aiMemory} install-hooks --agent claude-code ${hookArgs}
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/env CLAUDE_CONFIG_DIR=${lib.escapeShellArg profile} ${aiMemory} install-skills --scope global --agent claude-code
      '';
    in
    (lib.optionalString cfg.clients.claude (
      installClaude cfg.profiles.personal + installClaude cfg.profiles.work
    ))
    + (lib.concatMapStrings installHooks enabledAgentClients)
    + (lib.optionalString (enabledAgentClients != [ ]) ''
      $DRY_RUN_CMD ${aiMemory} install-skills --scope global --agent agents
    '');
in
{
  options.homeModules.llms = {
    enable = mkEnableOption "Enable AI coding agents (llm-agents.nix) with declarative MCP servers.";

    clients = {
      claude = mkOption {
        type = types.bool;
        default = true;
        description = "Install Claude Code and the `ccp` profile-aware wrapper.";
      };
      codex = mkOption {
        type = types.bool;
        default = true;
        description = "Install Codex CLI, merge MCP servers into its config.toml and add the `codexw` wrapper.";
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

    aiMemory = {
      enable = mkEnableOption "shared, local memory and lifecycle capture for enabled AI clients";

      package = mkOption {
        type = types.package;
        default = inputs.ai-memory.packages.${pkgs.stdenv.hostPlatform.system}.default;
        defaultText = lib.literalExpression "inputs.ai-memory.packages.\${pkgs.system}.default";
        description = "ai-memory package used by lifecycle hooks and activation installers.";
      };

      serverUrl = mkOption {
        type = types.str;
        default = "http://127.0.0.1:49374";
        description = "Base URL of the ai-memory server (without the /mcp suffix).";
      };

      captureMode = mkOption {
        type = types.enum [
          "allowlist"
          "denylist"
        ];
        default = "allowlist";
        description = "Whether repositories require a .ai-memory.toml marker before hooks capture them.";
      };
    };

    # Servers needing agenix secrets require hostModules.agenix on the host
    # plus the matching secret declarations in modules/agenix.nix.
    mcpServers = mkOption {
      type = types.attrsOf mcpServerType;
      default = { };
      description = "Work MCP servers: loaded by codex/cursor/opencode and by `ccp` under the work profile.";
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
          ccp
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

    {
      # Cursor (symlink-intolerant) and OpenCode (needs secret URL inline)
      # get real files rendered during Home Manager activation. Only touched
      # when at least one server is configured, so hosts with llms enabled
      # but an empty MCP set keep their files untouched.
      home.activation.llmsMcpConfigs = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        mcpActivation
        + (lib.optionalString (cfg.clients.codex && safeServers != { }) codexActivation)
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

    # The runtime dir is wiped on logout/reboot; re-render Claude's MCP
    # configs at login so background jobs respawned before any `ccp` launch
    # still find their --mcp-config file.
    (mkIf cfg.clients.claude {
      systemd.user.services.llms-claude-mcp = {
        Unit.Description = "Render Claude Code MCP configs into the runtime dir";
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = lib.getExe claudeMcp;
        };
        Install.WantedBy = [ "default.target" ];
      };
    })

    (mkIf cfg.aiMemory.enable {
      home.activation.llmsAiMemory = lib.hm.dag.entryAfter [ "llmsMcpConfigs" ] aiMemoryActivation;
    })
  ]);
}

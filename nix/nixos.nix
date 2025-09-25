{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.services.wl-clicker-rs;
  inherit (lib) types;
in
{
  options.services.wl-clicker-rs = {
    enable = lib.mkEnableOption "wl-clicker-rs";
    package = lib.mkPackageOption pkgs "wl-clicker-rs" { };
    group = lib.mkOption {
      type = types.str;
      default = "wl-clicker";
      description = ''
        Group which users must be in to use {command}`wl-clicker`.
      '';
    };
    settings = lib.mkOption {
      type = types.attrs;
      default = { };
      description = "Configuration for wl-clicker-rs";
    };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = [ cfg.package ];
      etc."wl-clicker-rs/default.nix" = lib.mkIf (cfg.settings != { }) {
        text = lib.generators.toPretty { } cfg.settings;
      };
    };

    systemd.user.services.wl-clicker-rs = {
      description = "Wayland autoclicker (socket access only)";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package}";
        Restart = "on-failure";

        # hardening

        # allow access to uinput
        DeviceAllow = [ "/dev/uinput" ];
        DevicePolicy = "closed";

        # Sandbox hardening
        RestrictAddressFamilies = [ "AF_UNIX" ];
        CapabilityBoundingSet = "";
        IPAddressDeny = "any";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateNetwork = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
          "~@resources"
        ];
        UMask = "0077";
      };
    };

    users.groups."${cfg.group}" = { };
  };
}

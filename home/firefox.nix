{
  config,
  lib,
  ...
}:

let
  cfg = config.homeModules.firefox;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.homeModules.firefox = {
    enable = mkEnableOption "Enable the Firefox browser";
  };

  config = mkIf cfg.enable {
    stylix.targets.firefox.profileNames = [
      "personal"
      "work"
    ];

    programs.firefox = {
      enable = true;
      configPath = ".config/mozilla/firefox";
      languagePacks = [ "pt-BR" ];

      policies = {
        AIControls.Default = {
          Value = "blocked";
          Locked = true;
        };
        DisableFirefoxStudies = true;
        DisableTelemetry = true;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Category = "strict";
          Cryptomining = true;
          Fingerprinting = true;
          EmailTracking = true;
          SuspectedFingerprinting = true;
          BaselineExceptions = false;
          ConvenienceExceptions = false;
        };
        ExtensionSettings = {
          "*".installation_mode = "blocked";
          "uBlock0@raymondhill.net" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          };
          "{d634138d-c276-4fc8-924b-40a0ea21d284}" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/1password-x-password-manager/latest.xpi";
          };
          "@testpilot-containers" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/latest.xpi";
          };
        };
        FirefoxHome = {
          Search = false;
          TopSites = true;
          SponsoredTopSites = false;
          Highlights = false;
          Stories = false;
          SponsoredStories = false;
        };
        FirefoxSuggest = {
          WebSuggestions = false;
          SponsoredSuggestions = false;
          ImproveSuggest = false;
          Locked = true;
        };
        HttpsOnlyMode = "force_enabled";
        OfferToSaveLogins = false;
        PasswordManagerEnabled = false;
        RequestedLocales = [ "en-US" ];
        UserMessaging = {
          ExtensionRecommendations = false;
          FeatureRecommendations = false;
          UrlbarInterventions = false;
          SkipOnboarding = true;
          MoreFromMozilla = false;
          FirefoxLabs = false;
          Locked = true;
        };
      };

      profiles = {
        personal = {
          id = 0;
          isDefault = true;
          storeId = "9c7ec49f";
        };
        work = {
          id = 1;
          isDefault = false;
          storeId = "8ae87879";
        };
      };
    };
  };
}

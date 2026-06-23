# Employer-specific secrets from private-config
# These secrets use sopsFile override to pull from the private repository
{
  inputs,
  ...
}:
{
  sops.secrets."confluence-main-base-url" = {
    owner = "diego";
    group = "users";
    mode = "0400";
    sopsFile = inputs.private-config.secretFiles.confluenceMain;
  };
  sops.secrets."confluence-main-email" = {
    owner = "diego";
    group = "users";
    mode = "0400";
    sopsFile = inputs.private-config.secretFiles.confluenceMain;
  };
  sops.secrets."confluence-main-api-key" = {
    owner = "diego";
    group = "users";
    mode = "0400";
    sopsFile = inputs.private-config.secretFiles.confluenceMain;
  };
}

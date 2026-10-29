{ ... }:
{
  flake.modules.nixos.network-cloudflare-warp =
{ ... }:

{
  # Cloudflare One client (warp-svc + warp-cli). Enrollment is interactive
  # (browser SSO), so it is not declared here; see the Work HOWTOs.
  services.cloudflare-warp = {
    enable = true;
    openFirewall = true;
  };

}
  ;
}

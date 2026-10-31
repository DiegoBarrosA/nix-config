{ config, ... }:
{
  flake.modules.homeManager.ai =
{ ... }:
{
  imports = with config.flake.modules.homeManager; [
    ai-mcp
    ai-opencode
    ai-ai-tools

  ];
};
}

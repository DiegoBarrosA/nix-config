{ ... }:
{
  # Stylix generates `prompt =` (empty value) which is a parse error in fuzzel.
  # Set an explicit value to override the broken Stylix template output.
  programs.fuzzel.settings.main.prompt = "❯  ";
}

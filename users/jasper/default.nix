{ hmUsers, ... }:
{
  home-manager.users = { inherit (hmUsers) jasper; };

  users.users.nixos = {
    password = "jasper";
    description = "default";
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
}

{ hmUsers, ... }:
{
  home-manager.users = { inherit (hmUsers) jasper; };

  users.users.jasper = {
    password = "jasper";
    description = "default";
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
}

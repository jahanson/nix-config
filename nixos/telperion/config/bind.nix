{config, ...}: 
''
include "${config.sops.secrets."bind/rndc-keys/externaldns".path}";

zone "jahanson.tech." {
  type master;
  file "${config.sops.secrets."bind/zones/jahanson.tech".path}";
  journal "${config.services.bind.directory}/db.jahanson.tech.jnl";
  allow-transfer {
    key "externaldns";
  };
  update-policy {
    grant externaldns zonesub ANY;
  };
};
''
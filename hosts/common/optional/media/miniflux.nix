{
  config,
  lib,
  pkgs,
  ...
}:
let
  port = 8086;

  minifluxCss = ''
    :root {
      --body-background: #212121;
      --body-color: #EEFFFF;
      --title-color: #EEFFFF;
      --link-color: #82AAFF;
      --link-hover-color: #C792EA;
      --header-background: #303030;
      --header-color: #EEFFFF;
      --header-link-color: #EEFFFF;
      --header-link-hover-color: #82AAFF;
      --entry-background: #212121;
      --entry-header-color: #EEFFFF;
      --entry-content-color: #EEFFFF;
      --category-background: #303030;
      --category-color: #82AAFF;
      --button-primary-background: #82AAFF;
      --modal-background: #303030;
    }
    body { background: #212121; color: #EEFFFF; font-family: "Nunito", "Inter", system-ui, sans-serif; }
    .header nav li a { color: #B2CCD6; }
    .header nav li a:hover, .header nav li a.active { color: #82AAFF; }
    .items .item { background: #262626; border: 1px solid #353535; border-radius: 8px; margin-bottom: 8px; }
    .item.current-item { border-color: #82AAFF; box-shadow: 0 0 0 1px #82AAFF; }
    .item-title a { color: #EEFFFF; }
    .item-meta, .item-meta a { color: #7E8A94; }
    a.page-link, .pagination a { color: #82AAFF; }
    .category { background: #303030; color: #82AAFF; border-radius: 12px; }
    button, .button { border-radius: 6px; }
    .button-primary { background: #82AAFF; border-color: #82AAFF; color: #212121; }
    .entry-content a { color: #82AAFF; }
    ::-webkit-scrollbar { width: 10px; }
    ::-webkit-scrollbar-thumb { background: #4A4A4A; border-radius: 6px; }
    ::-webkit-scrollbar-track { background: #212121; }
  '';
  cssFile = pkgs.writeText "miniflux-material-darker.css" minifluxCss;

  opml = pkgs.writeText "miniflux-feeds.opml" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <opml version="2.0">
      <head><title>Dev News</title></head>
      <body>
        <outline text="Dev" title="Dev">
          <outline type="rss" text="Hacker News" title="Hacker News" xmlUrl="https://hnrss.org/frontpage" htmlUrl="https://news.ycombinator.com/"/>
          <outline type="rss" text="Lobsters" title="Lobsters" xmlUrl="https://lobste.rs/rss" htmlUrl="https://lobste.rs/"/>
          <outline type="rss" text="DEV.to" title="DEV.to" xmlUrl="https://dev.to/feed" htmlUrl="https://dev.to/"/>
          <outline type="rss" text="freeCodeCamp" title="freeCodeCamp" xmlUrl="https://www.freecodecamp.org/news/rss/" htmlUrl="https://www.freecodecamp.org/news/"/>
        </outline>
      </body>
    </opml>
  '';
in
{

  sops.secrets."miniflux-admin" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  services.miniflux = {
    enable = true;
    createDatabaseLocally = true;
    adminCredentialsFile = config.sops.secrets."miniflux-admin".path;
    config = {
      LISTEN_ADDR = "127.0.0.1:${toString port}";
      BASE_URL = "https://rss.minerales.network";
      CREATE_ADMIN = 1;

      POLLING_FREQUENCY = 60;
      CLEANUP_ARCHIVE_READ_DAYS = 30;
    };
  };

  services.nginx.virtualHosts."rss.minerales.network" = {
    forceSSL = true;
    useACMEHost = "minerales.network";
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
      extraConfig = ''
        proxy_hide_header X-Frame-Options;
        add_header Content-Security-Policy "frame-ancestors 'self' https://homeassistant.minerales.network" always;
      '';
    };
  };

  systemd.services.miniflux-setup = {
    description = "Seed Miniflux feeds + material-darker theme";
    after = [ "miniflux.service" ];
    requires = [ "miniflux.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.curl pkgs.jq pkgs.coreutils ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      EnvironmentFile = config.sops.secrets."miniflux-admin".path;
    };
    script = ''
      set -euo pipefail
      base="http://127.0.0.1:${toString port}"
      marker="/var/lib/miniflux/.setup-done"
      mkdir -p /var/lib/miniflux

      for i in $(seq 1 60); do
        if curl -sf -o /dev/null "$base/healthcheck"; then break; fi
        sleep 2
      done

      auth=( -u "$ADMIN_USERNAME:$ADMIN_PASSWORD" )

      css=$(jq -Rs . < ${cssFile})
      curl -sf "$base/v1/me" "''${auth[@]}" > /tmp/miniflux-me.json || true
      uid=$(jq -r '.id // 1' /tmp/miniflux-me.json 2>/dev/null || echo 1)
      curl -sf -X PUT "$base/v1/users/$uid" "''${auth[@]}" \
        -H 'Content-Type: application/json' \
        -d "{\"stylesheet\": $css, \"theme\": \"dark_serif\"}" > /dev/null || true

      if [ ! -f "$marker" ]; then
        curl -sf -X POST "$base/v1/import" "''${auth[@]}" \
          --data-binary @${opml} > /dev/null || true
        touch "$marker"
        echo "Miniflux feeds imported."
      else
        echo "Feeds already imported; skipping."
      fi
      echo "Miniflux setup complete."
    '';
  };
}

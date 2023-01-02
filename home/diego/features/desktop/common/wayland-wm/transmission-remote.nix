{ pkgs, ... }: {
  home.packages = with pkgs; [ transmission-remote-gtk ];
  xdg.configFile."transmission-remote-gtk/config.json".text = ''
    {
      "profiles" : [
        {
          "profile-name" : "Default",
          "hostname" : "localhost",
          "port" : 9091,
          "rpc-url-path" : "/transmission/rpc",
          "username" : "",
          "password" : "",
          "auto-connect" : true,
          "ssl" : false,
          "ssl-validate" : false,
          "timeout" : 40,
          "retries" : 3,
          "update-active-only" : false,
          "activeonly-fullsync-enabled" : false,
          "activeonly-fullsync-every" : 2,
          "update-interval" : 3,
          "min-update-interval" : 3,
          "session-update-interval" : 60,
          "custom-headers" : [],
          "exec-commands" : [],
          "destinations" : []
        }
      ],
      "profile-id" : 0,
      "tree-views" : {
        "TrgTorrentTreeView" : {
          "sort-col" : -1,
          "sort-type" : 0
        },
        "TrgTrackersTreeView" : {
          "sort-col" : -2,
          "sort-type" : 0,
          "widths" : [
            105,
            185,
            116,
            179,
            184,
            185,
            154,
            164
          ],
          "columns" : [
            "tier",
            "announce-url",
            "last-announce-peer-count",
            "seeder-count",
            "leecher-count",
            "last-announce-time",
            "last-result",
            "scrape-url"
          ]
        },
        "TrgFilesTreeView" : {
          "sort-col" : -2,
          "sort-type" : 0,
          "widths" : [
            246,
            232,
            265,
            275,
            254
          ],
          "columns" : [
            "name",
            "size",
            "progress",
            "wanted",
            "priority"
          ]
        },
        "TrgPeersTreeView" : {
          "sort-col" : -2,
          "sort-type" : 0,
          "widths" : [
            145,
            164,
            224,
            203,
            194,
            168,
            174
          ],
          "columns" : [
            "ip",
            "host",
            "down-speed",
            "up-speed",
            "progress",
            "flags",
            "client"
          ]
        }
      },
      "window-height" : 1076,
      "window-width" : 2489,
      "notebook-paned-pos" : 300,
      "states-paned-pos" : 120,
      "start-paused" : false,
      "add-options-dialog" : true,
      "delete-local-torrent" : false,
      "show-state-selector" : true,
      "filter-dirs" : true,
      "filter-trackers" : true,
      "directories-first" : true,
      "show-notebook" : false,
      "system-tray" : false,
      "system-tray-minimise" : false,
      "add-notify" : true,
      "complete-notify" : true,
      "rss" : []
    }


  '';
}

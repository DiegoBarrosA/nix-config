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
            257,
            337,
            268,
            331,
            336,
            337,
            306,
            313
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
            488,
            474,
            507,
            517,
            499
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
            318,
            337,
            397,
            376,
            367,
            341,
            349
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
        },
        "TrgFilesTreeView-dialog" : {
          "sort-col" : -2,
          "sort-type" : 0,
          "widths" : [
            661,
            86,
            78,
            88,
            67
          ],
          "columns" : [
            "name",
            "size",
            "progress",
            "wanted",
            "priority"
          ]
        },
        "TrgPeersTreeView-dialog" : {
          "sort-col" : -2,
          "sort-type" : 0,
          "widths" : [
            143,
            49,
            109,
            88,
            79,
            53,
            147
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
        },
        "TrgTrackersTreeView-dialog" : {
          "sort-col" : -2,
          "sort-type" : 0,
          "widths" : [
            42,
            331,
            53,
            116,
            121,
            162,
            211,
            309
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
        }
      },
      "window-height" : 1041,
      "window-width" : 2560,
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
      "rss" : [],
      "dialog-width" : 700,
      "dialog-height" : 648
    }
  '';
}

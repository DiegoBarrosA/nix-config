{ pkgs, config, ... }:
let inherit (config.colorscheme) colors;
in {
  programs.firefox = {
    profiles."messenger" = {
      isDefault = false;
      id = 1;
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "layers.acceleration.force-enabled" = true;
        "gfx.webrender.all" = true;
        "svg.context-properties.content.enabled" = true;
        "toolkit.tabbox.switchByScrolling" = true;
        "ui.key.menuAccessKeyFocuses" = false;
        "layout.spellcheckDefault" = 2;
        "browser.urlbar.quickactions.enabled" = true;
        "mousewheel.with_control.action" = 5;
        "browser.sessionstore.resume_from_crash" = false;
        "extensions.unifiedExtensions.enabled" = false;
      };
      bookmarks = [{
        name = "WhatsApp";
        keyword = "wasap";
        url = "https://web.whatsapp.com/";
      }

        ];
      userChrome = ''
                   @media (prefers-color-scheme: dark) { :root {


                       --window-colour:                     #${colors.base00};
                       --secondary-colour:                  #${colors.base02};
                       --inverted-colour:                   #${colors.base05};

                       /* Containter Tab Colours */
                       --uc-identity-colour-blue:            #${colors.base0D};
                       --uc-identity-colour-turquoise:       #${colors.base0C};
                       --uc-identity-colour-green:           #${colors.base0B};
                       --uc-identity-colour-yellow:          #${colors.base0A};
                       --uc-identity-colour-orange:          #${colors.base09};
                       --uc-identity-colour-red:             #${colors.base08};
                       --uc-identity-colour-pink:            #${colors.base0D};
                       --uc-identity-colour-purple:          #${colors.base0E};

                       --uc-identity-colour-blue-muted:      #7ED6DF99;
                       --uc-identity-colour-turquoise-muted: #55E6C199;
                       --uc-identity-colour-green-muted:     #B8E99499;
                       --uc-identity-colour-yellow-muted:    #F7D794CC;
                       --uc-identity-colour-orange-muted:    #F19066FF;
                       --uc-identity-colour-red-muted:       #FC5C65FF;
                       --uc-identity-colour-pink-muted:      #F78FB399;
                       --uc-identity-colour-purple-muted:    #786FA6FF;

                   }}
                    @media (prefers-color-scheme: light) { :root {

                       --window-colour:                     #F9f9f9;
                       --secondary-colour:                  #ebebeb;
                       --inverted-colour:                   #121212;

                       /* Containter Tab Colours */
                            --uc-identity-colour-blue:            #${colors.base0D};
                       --uc-identity-colour-turquoise:       #${colors.base0C};
                       --uc-identity-colour-green:           #${colors.base0B};
                       --uc-identity-colour-yellow:          #${colors.base0A};
                       --uc-identity-colour-orange:          #${colors.base09};
                       --uc-identity-colour-red:             #${colors.base08};
                       --uc-identity-colour-pink:            #${colors.base0D};
                       --uc-identity-colour-purple:          #${colors.base0E};

                       --uc-identity-colour-blue-muted:      #1D65F5FF;
                       --uc-identity-colour-turquoise-muted: #209FB5FF;
                       --uc-identity-colour-green-muted:     #40A02BFF;
                       --uc-identity-colour-yellow-muted:    #E49320FF;
                       --uc-identity-colour-orange-muted:    #FE640BFF;
                       --uc-identity-colour-red-muted:       #FC5C65FF;
                       --uc-identity-colour-pink-muted:      #EC83D0FF;
                       --uc-identity-colour-purple-muted:    #822FEEFF;

                   }}



               :root {

                   /* URL colour in URL bar suggestions */
                   --urlbar-popup-url-color: var(--uc-identity-colour-purple) !important;


                   /*---+---+---+---+---+---+---+
                    | V | I | S | U | A | L | S |
                    +---+---+---+---+---+---+---*/

                   /* global border radius */
                   --uc-border-radius: 10px;


                   /* dynamic tab width settings */
                   --uc-active-tab-width:   clamp(100px, 20vw, 300px);
                   --uc-inactive-tab-width: clamp( 50px, 15vw, 200px);

                   /* if active always shows the tab close button */
                   --show-tab-close-button: none; /* DEFAULT: -moz-inline-box; */

                   /* if active only shows the tab close button on hover*/
                   --show-tab-close-button-hover: none; /* DEFAULT: -moz-inline-box; */

                   /* adds left and right margin to the container-tabs indicator */
                   --container-tabs-indicator-margin: 10px;

               }

                   /*---+---+---+---+---+---+---+
                    | B | U | T | T | O | N | S |
                    +---+---+---+---+---+---+---*/

                    #back-button,
                    #forward-button { display: none !important; }

                    /* bookmark icon */
                    #star-button{ display: none !important; }

                    /* zoom indicator */
                    #urlbar-zoom-button { display: none !important; }

                    /* Make button small as Possible, hidden out of sight */
                    #PanelUI-button { margin-top: -5px; margin-bottom: 44px; }

                    #PanelUI-menu-button {

                       padding: 0px !important;
                       max-height: 1px;

                       list-style-image: none !important;

                    }

                    #PanelUI-menu-button .toolbarbutton-icon { width: 1px !important; }
                    #PanelUI-menu-button .toolbarbutton-badge-stack { padding: 0px !important; }

                    #reader-mode-button{ display: none !important; }

                    /* tracking protection shield icon */
                    #tracking-protection-icon-container { display: none !important; }

                    /* #identity-box { display: none !important } /* hides encryption AND permission items */
                    #identity-permission-box { display: none !important; } /* only hides permission items */

                    /* e.g. playing indicator (secondary - not icon) */
                    .tab-secondary-label { display: none !important; }

                    #pageActionButton { display: none !important; }
                    #page-action-buttons { display: none !important; }

                    #urlbar-go-button { display: none !important; }





               /*=============================================================================================*/


               /*---+---+---+---+---+---+
                | L | A | Y | O | U | T |
                +---+---+---+---+---+---*/

               /* No need to change anything below this comment.
                * Just tweak it if you want to tweak the overall layout. c: */

               :root {
                   --uc-theme-colour:                          var(--window-colour,    var(--toolbar-bgcolor));
                   --uc-hover-colour:                          var(--secondary-colour, rgba(0, 0, 0, 0.2));
                   --uc-inverted-colour:                       var(--inverted-colour,  var(--toolbar-color));

                   --button-bgcolor:                           var(--uc-theme-colour)    !important;
                   --button-hover-bgcolor:                     var(--uc-hover-colour)    !important;
                   --button-active-bgcolor:                    var(--uc-hover-colour)    !important;

                   --toolbarbutton-border-radius:              var(--uc-border-radius)   !important;

                   --tab-border-radius:                        var(--uc-border-radius)   !important;
                   --lwt-text-color:                           var(--uc-inverted-colour) !important;
                   --lwt-tab-text:                             var(--uc-inverted-colour) !important;

                   --arrowpanel-border-radius:                 var(--uc-border-radius)   !important;

                   --tab-block-margin: 2px !important;

               }





               window,
               #main-window,
               #toolbar-menubar,
               #TabsToolbar,
               #PersonalToolbar,
               #navigator-toolbox,
               #sidebar-box
               {
                   -moz-appearance: none !important;
                   border: none !important;
                   box-shadow: none !important;
                   background: var(--uc-theme-colour) !important;
               }



               /* grey out ccons inside the toolbar to make it
                * more aligned with the Black & White colour look */
               #PersonalToolbar toolbarbutton:not(:hover),
               #bookmarks-toolbar-button:not(:hover) { filter: grayscale(1) !important; }


               /* remove window control buttons */
               .titlebar-buttonbox-container { display: none !important; }


               /* remove "padding" left and right from tabs */
               .titlebar-spacer { display: none !important; }





               /* remove gap after pinned tabs */
               #tabbrowser-tabs[haspinnedtabs]:not([positionpinnedtabs])
                   > #tabbrowser-arrowscrollbox
                   > .tabbrowser-tab[first-visible-unpinned-tab] { margin-inline-start: 0 !important; }


               /* remove tab shadow */
               .tabbrowser-tab
                   >.tab-stack
                   > .tab-background { box-shadow: none !important;  }


               /* tab background */
               .tabbrowser-tab
                   > .tab-stack
                   > .tab-background { background: var(--uc-theme-colour) !important; }


               /* active tab background */
               .tabbrowser-tab[selected]
                   > .tab-stack
                   > .tab-background { background: var(--uc-hover-colour) !important; }


               /* multi tab selection */
               #tabbrowser-tabs:not([noshadowfortests]) .tabbrowser-tab:is([visuallyselected=true], [multiselected]) > .tab-stack > .tab-background:-moz-lwtheme { background: var(--uc-hover-colour) !important; }


               /* tab close button options */
               .tabbrowser-tab:not([pinned]) .tab-close-button { display: var(--show-tab-close-button) !important; }
               .tabbrowser-tab:not([pinned]):hover .tab-close-button { display: var(--show-tab-close-button-hover) !important }


               /* adaptive tab width */
               .tabbrowser-tab[selected][fadein]:not([pinned]) { max-width: var(--uc-active-tab-width) !important; }
               .tabbrowser-tab[fadein]:not([selected]):not([pinned]) { max-width: var(--uc-inactive-tab-width) !important; }


               /* container tabs indicator */
               .tabbrowser-tab[usercontextid]
                   > .tab-stack
                   > .tab-background
                   > .tab-context-line {

                       margin: -1px var(--container-tabs-indicator-margin) 0 var(--container-tabs-indicator-margin) !important;
                       height: 1px !important;

                       border-radius: var(--tab-border-radius) !important;
                       box-shadow: 0 1px 10px 1px var(--uc-identity-gradient-colour) !important;

               }


               /* show favicon when media is playing but tab is hovered */
               .tab-icon-image:not([pinned]) { opacity: 1 !important; }


               /* Makes the speaker icon to always appear if the tab is playing (not only on hover) */
               .tab-icon-overlay:not([crashed]),
               .tab-icon-overlay[pinned][crashed][selected] {

                 top: 5px !important;
                 z-index: 1 !important;

                 padding: 1.5px !important;
                 inset-inline-end: -8px !important;
                 width: 16px !important; height: 16px !important;

                 border-radius: 10px !important;

               }


               /* style and position speaker icon */
               .tab-icon-overlay:not([sharing], [crashed]):is([soundplaying], [muted], [activemedia-blocked]) {

                 stroke: transparent !important;
                 background: transparent !important;
                 opacity: 1 !important; fill-opacity: 0.8 !important;

                 color: currentColor !important;

                 stroke: var(--uc-theme-colour) !important;
                 background-color: var(--uc-theme-colour) !important;

               }


               /* change the colours of the speaker icon on active tab to match tab colours */
               .tabbrowser-tab[selected] .tab-icon-overlay:not([sharing], [crashed]):is([soundplaying], [muted], [activemedia-blocked]) {

                 stroke: var(--uc-hover-colour) !important;
                 background-color: var(--uc-hover-colour) !important;

               }


               .tab-icon-overlay:not([pinned], [sharing], [crashed]):is([soundplaying], [muted], [activemedia-blocked]) { margin-inline-end: 9.5px !important; }


               .tabbrowser-tab:not([image]) .tab-icon-overlay:not([pinned], [sharing], [crashed]) {

                 top: 0 !important;

                 padding: 0 !important;
                 margin-inline-end: 5.5px !important;
                 inset-inline-end: 0 !important;

               }


               .tab-icon-overlay:not([crashed])[soundplaying]:hover,
               .tab-icon-overlay:not([crashed])[muted]:hover,
               .tab-icon-overlay:not([crashed])[activemedia-blocked]:hover {

                   color: currentColor !important;
                   stroke: var(--uc-inverted-colour) !important;
                   background-color: var(--uc-inverted-colour) !important;
                   fill-opacity: 0.95 !important;

               }


               .tabbrowser-tab[selected] .tab-icon-overlay:not([crashed])[soundplaying]:hover,
               .tabbrowser-tab[selected] .tab-icon-overlay:not([crashed])[muted]:hover,
               .tabbrowser-tab[selected] .tab-icon-overlay:not([crashed])[activemedia-blocked]:hover {

                   color: currentColor !important;
                   stroke: var(--uc-inverted-colour) !important;
                   background-color: var(--uc-inverted-colour) !important;
                   fill-opacity: 0.95 !important;

               }


               /* speaker icon colour fix */
               #TabsToolbar .tab-icon-overlay:not([crashed])[soundplaying],
               #TabsToolbar .tab-icon-overlay:not([crashed])[muted],
               #TabsToolbar .tab-icon-overlay:not([crashed])[activemedia-blocked] { color: var(--uc-inverted-colour) !important; }


               /* speaker icon colour fix on hover */
               #TabsToolbar .tab-icon-overlay:not([crashed])[soundplaying]:hover,
               #TabsToolbar .tab-icon-overlay:not([crashed])[muted]:hover,
               #TabsToolbar .tab-icon-overlay:not([crashed])[activemedia-blocked]:hover { color: var(--uc-theme-colour) !important; }





               #statuspanel {

                   position: absolute !important;
                   bottom: 12px !important; left: 12px !important;

               }


               #statuspanel #statuspanel-label {

                   border: none !important;
                   border-radius: var(--uc-border-radius) !important;
                   background: var(--uc-theme-colour) !important;

               }
        /* move entire nav bar  */
                   #nav-bar { display:none; }




              


      '';
      userContent = ''
                        @namespace url("http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul");
                        @namespace html url("http://www.w3.org/1999/xhtml");
                        @-moz-document url-prefix("about:addons"),
                          url-prefix("about:preferences"),
                          url-prefix("about:config"),
                          url-prefix("chrome://browser/content/"),
                          url-prefix("chrome://mozapps/content/"),
                          url-prefix("chrome://pippki/content/"),
                          url-prefix("chrome://mozapps/content/extensions/aboutaddons.html"){
                            :root,
                            html|html{
                              --in-content-page-color: rgb(210,210,210) !important;
                              --in-content-text-color: rgb(210,210,210) !important;
                              --in-content-page-background: #${colors.base00} !important;
                --in-content-primary-button-background:  #${colors.base0D} !important;
                              --in-content-box-background: rgba(255,255,255,0.1) !important;
                              --in-content-deemphasized-text: var(--in-content-text-color) !important;
                              scrollbar-color: var(--in-content-text-color) var(--in-content-page-background) !important;
                              color:var(--in-content-text-color) !important;
                            }
                          menulist > menupopup{ background-color: var(--in-content-page-background) !important; }
                          .updateSettingCrossUserWarningContainer,
                          .info-panel,
                          .extension-controlled,
                          .message-bar,
                          html|message-bar,
                          .alert,
                          treecol{
                            background-color: var(--in-content-box-background) !important;
                            color: var(--in-content-text-color) !important;
                          }
                          .menulist-dropmarker,
                          .checkbox-icon{
                            -moz-context-properties: fill;
                            fill : CurrentColor !important;
                          }
                          /* make panel background blurry if the background is translucent. Requires pref layout.css.backdrop-filter.enabled  */
                          html|panel-list{ backdrop-filter: blur(28px) }
                        }

                        /* Get addons page */
                        /* New addons manager doesn't use this anymore */
                        @-moz-document url-prefix("https://discovery.addons.mozilla.org/"){
                          html|*{ color: inherit !important; }
                          html|html,html|body{
                            background-color: rgb(46,54,69) !important;
                            color: rgb(210,210,210) !important;
                          }
                          html|div.addon,html|div.Notice{ background-color: rgba(255,255,255,0.1) !important; }
                        }
            @namespace url("http://www.w3.org/1999/xhtml");

        @-moz-document url("about:home"),url("about:blank"),url("about:newtab"),url("about:privatebrowsing"){
          body{background-color: #${colors.base00} !important;}
        }
        @-moz-document url("about:privatebrowsing"){
          .search-handoff-button{ background-color: rgba(100,100,100,0.1) !important; }
          .fake-textbox{ color: rgb(200,200,200) !important }
        }

      '';
    };
  };
}

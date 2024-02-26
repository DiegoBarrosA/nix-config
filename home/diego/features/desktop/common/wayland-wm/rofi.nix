{ config, lib, pkgs, ... }:

let inherit (config.colorscheme) colors;
in {
  home.packages = with pkgs; [ wofi ];
  xdg.configFile."wofi/style.css".text = ''
    * {
        font-family:  'Jost*';
        font-size: 20px;
        font-weight: 400;
    }


    #window {
        margin: 0px;
        border: none;
        border-color: rgb(129, 126, 127);
        border-radius: 10px;
        background-color: #${colors.base00};
        color:  #${colors.base05};
    }

    #input {
        margin: 25px;
        background-color: #${colors.base01};
        color: #${colors.base05};
        border-radius: 10px;
        border: none;

        font-size: 40px;
    }

    #scroll {
        margin-bottom: 25px;
    }

    #entry {
        margin: 0px 25px;
    }

    #entry:selected {
        background-color: #${colors.base0D};
        border-radius: 10px;
        border: none;
        outline: none;
    }

    #entry > box {
        margin-left: 15px;
    }

    #entry image {
        padding-right: 10px;
    }

  '';
}

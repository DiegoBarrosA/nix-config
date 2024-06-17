{ pkgs, ... }: {
  imports = [ ./lsp/markdown.nix ];
  programs.helix = {
    enable = true;
    extraPackages = with pkgs; [
      python311Packages.python-lsp-server
      markdown-oxide
      nil
      vscode-langservers-extracted
      rust-analyzer
      ltex-ls
    ];
    settings = {
      theme = "material_darker";
      editor = {
        soft-wrap.enable = true;
        line-number = "relative";
        lsp.display-messages = true;
        true-color = true;
        file-picker.hidden = false;
      };
      keys.normal = {
        space.space = "file_picker";
        space.w = ":w";
        space.q = ":q";
        space.W = [ ":toggle soft-wrap.enable" ":redraw" ];
      };

    };
    languages = with pkgs; {
      language-server = {
        efm-lsp-prettier = {
          command = "${efm-langserver}/bin/efm-langserver";
          config = {
            documentFormatting = true;
            languages = lib.genAttrs [
              "typescript"
              "javascript"
              "typescriptreact"
              "javascriptreact"
              "vue"
              "json"
              "markdown"
            ] (_: [{
              formatCommand =
                "${nodePackages.prettier}/bin/prettier --stdin-filepath \${INPUT}";
              formatStdin = true;
            }]);
          };
        };
        eslint = {
          command = "vscode-eslint-language-server";
          args = [ "--stdio" ];
          config = {
            validate = "on";
            packageManager = "yarn";
            useESLintClass = false;
            codeActionOnSave.mode = "all";
            format = true;
            quiet = false;
            onIgnoredFiles = "off";
            rulesCustomizations = [ ];
            run = "onType";
            nodePath = "";
            workingDirectory.mode = "auto";
            experimental = { };
            problems.shortenToSingleLine = false;
            codeAction = {
              disableRuleComment = {
                enable = true;
                location = "separateLine";
              };
              showDocumentation.enable = true;
            };
          };
        };

        typescript-language-server = {
          command =
            "${nodePackages.typescript-language-server}/bin/typescript-language-server";
          args = [
            "--stdio"
            "--tsserver-path=${nodePackages.typescript}/lib/node_modules/typescript/lib"
          ];
          config.documentFormatting = false;
        };
        nil = {
          command = "${pkgs.nil}/bin/nil";
          config.nil = {
            formatting.command = [ "${nixfmt}/bin/nixfmt" ];
            nix.flake.autoEvalInputs = true;
          };
        };
        # lexical = {
        #   command = "${inputs.lexical.packages.${pkgs.system}.default}/bin/lexical";
        #   config.lexical = {
        #     # formatting.command = [ "${nixpkgs-fmt}/bin/nixpkgs-fmt" ];
        #   };
        # };
        ltex-ls.command = "ltex-ls";
        rust-analyzer = {
          config.rust-analyzer = {
            cargo.loadOutDirsFromCheck = true;
            checkOnSave.command = "clippy";
            procMacro.enable = true;
            lens = {
              references = true;
              methodReferences = true;
            };
            completion.autoimport.enable = true;
            experimental.procAttrMacros = true;
          };
        };
        omnisharp = {
          command = "omnisharp";
          args = [ "-l" "Error" "--languageserver" "-z" ];
        };
      };
      language = let
        jsTsWebLanguageServers = [
          {
            name = "typescript-language-server";
            except-features = [ "format" ];
          }
          "eslint"
          {
            name = "efm-lsp-prettier";
            only-features = [ "format" ];
          }
        ];
      in [
        {
          name = "bash";
          auto-format = true;
          file-types = [ "sh" "bash" ];
          formatter = {
            command = "${pkgs.shfmt}/bin/shfmt";
            # Indent with 2 spaces, simplify the code, indent switch cases, add space after redirection
            args = [ "-i" "4" "-s" "-ci" "-sr" ];
          };
        }
        # { name = "ruby"; file-types = [ "rb" "rake" "rakefile" "irb" "gemfile" "gemspec" "Rakefile" "Gemfile" "Fastfile" "Matchfile" "Pluginfile" "Appfile" ]; }
        {
          name = "rust";
          auto-format = false;
          file-types = [ "lalrpop" "rs" ];
          language-servers = [ "rust-analyzer" ];
        }

        # {
        #   name = "rust";
        #   language-server = { command = "${pkgs.rust-analyzer}/bin/rust-analyzer"; };
        #   config.checkOnSave = {
        #     command = "clippy";
        #   };
        # }

        {
          name = "c-sharp";
          language-servers = [ "omnisharp" ];
        }
        {
          name = "typescript";
          language-servers = jsTsWebLanguageServers;
        }
        {
          name = "javascript";
          language-servers = jsTsWebLanguageServers;
        }
        {
          name = "jsx";
          language-servers = jsTsWebLanguageServers;
        }
        {
          name = "tsx";
          language-servers = jsTsWebLanguageServers;
        }
        {
          name = "vue";
          language-servers = [
            {
              name = "vuels";
              except-features = [ "format" ];
            }
            { name = "efm-lsp-prettier"; }
            "eslint"
          ];
        }
        {
          name = "sql";
          formatter.command = "pg_format";
        }
        {
          name = "nix";
          language-servers = [ "nil" ];
          auto-format = true;
        }
        {
          name = "elixir";
          formatter.command = "${pkgs.elixir}/bin/mix format";
        }

        # { name = "elixir"; language-servers = [ "lexical" ]; }
        # { name = "heex"; language-servers = [ "lexical" ]; }
        {
          name = "json";
          language-servers = [
            {
              name = "vscode-json-language-server";
              except-features = [ "format" ];
            }
            "efm-lsp-prettier"
          ];
        }
        {
          name = "markdown";
          language-servers = [
            {
              name = "markdown-oxide";
              except-features = [ "format" ];
            }
            #"ltex-ls"
            "efm-lsp-prettier"
          ];

          auto-format = true;
        }

        {
          name = "nu";
          language-servers = [ { name = "nu"; } "nu --lsp" ];

          auto-format = true;
        }

        {
          name = "xml";
          # auto-format = true;
          file-types = [ "xml" ];
          formatter = {
            command = "${pkgs.yq-go}/bin/yq";
            args =
              [ "--input-format" "xml" "--output-format" "xml" "--indent" "2" ];
          };
        }
        # {
        #   name = "markdown";
        #   language-server = {
        #     command = "${pkgs.ltex-ls}/bin/ltex-ls";
        #   };
        #   file-types = [ "md" "txt" ];
        #   scope = "source.markdown";
        #   roots = [ ];
        # }
      ];
    };

  };
}

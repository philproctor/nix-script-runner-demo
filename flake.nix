{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = pkgs.lib;
        nixFormatter = pkgs.nixpkgs-fmt;

        # The list of dependencies we need for all generated scripts and the `nix develop` environment
        # Install terraform, terragrunt, and azure tools
        scriptDeps = with pkgs; [
          nixFormatter
          jq
          git
          curl
          kubectl
        ];

        # Build an environment with all the dependencies defined above
        scriptEnv = pkgs.buildEnv {
          name = "script-env";
          paths = scriptDeps;
        };

        # Load and filter all scripts from the `scripts/` directory into a list of all script files
        isScriptFn = name: type: type == "regular";
        scriptDir = ./. + "/scripts"; # this syntax is how to handle relative paths
        scriptDirScripts = builtins.attrNames (lib.filterAttrs isScriptFn (builtins.readDir scriptDir));

        scriptContents =
          let
            # headers here, defined outside the list so they can refer to each other
            stdShHeader = ''
              #!${pkgs.stdenv.shell}
              set -Eeou pipefail
              export PATH="$PATH:${scriptEnv}/bin"
            '';
            tfShHeader = ''
              ${stdShHeader}
              echo 'Running the extra tasks for .tf.sh'
            '';

            # Define metadata for each file suffix and the headers/exec command to attach to them
            scriptSuffixes = [
              {
                suffix = ".std.sh";
                header = stdShHeader;
                command = "exec";
              }
              {
                suffix = ".tf.sh";
                header = tfShHeader;
                command = "exec";
              }
            ];

            # Here we walk the definitions of `scriptSuffixes` and collect them into mappings of `command-name -> script-wrapper-contents`
            scriptMappings = builtins.map
              # for each script suffix we...
              (typeAttrs:
                let
                  # Find all scripts in the directory with our expected suffix
                  scriptsFound = builtins.filter (name: lib.hasSuffix typeAttrs.suffix name) scriptDirScripts;
                  # Map those found scripts to command names such that `format.std.sh` becomes `format`
                  scriptNames = builtins.map (name: builtins.replaceStrings [ typeAttrs.suffix ] [ "" ] name) scriptsFound;
                  # Create a list of maps where the command is set to "name" and the path to the script is set to "value", e.g. [{"name":"format","value":"./scripts/format.std.sh", ...}]
                  scriptAttrLists = builtins.map (name: { name = name; value = scriptDir + "/${name}${typeAttrs.suffix}"; }) scriptNames;
                  # Convert that list of maps into a single mapping where command name is the key, path is the value. e.g. {"format":"./scripts/format.std.sh", ...}
                  scriptAttrs = builtins.listToAttrs scriptAttrLists;
                  # Finally, instead of JUST the path, add the full formatting of the wrapper script (including the header and exec command) to the values
                  # {"format": "<all contents of wrapper script>", ...}
                  scriptContents = builtins.mapAttrs
                    (name: value: ''
                      ${typeAttrs.header}
                      ${typeAttrs.command} ${value}
                    '')
                    scriptAttrs;
                in
                scriptContents)
              scriptSuffixes;
          in
          # For our final result, combine the list we got from our foreach (map) into a single mapping instead of a list of mappings
          lib.attrsets.zipAttrs scriptMappings;

        # Finally, map each script into an "app" of the same name so they can be executed as a flake
        scripts = builtins.mapAttrs
          (name: value: flake-utils.lib.mkApp {
            drv = pkgs.writeScriptBin name value;
          })
          scriptContents;
      in
      {
        apps = {
          default = scripts.test;
        } // scripts;

        devShell = pkgs.mkShell {
          packages = scriptDeps;
        };

        formatter = nixFormatter;
      });
}

# Nix Script Runner Demo

[The Blog Article](https://theviking.tech/devops/nix-scripting/)

This repository is a demo of how [Nix](https://nixos.org/) can be used to create a repository of shared scripts with proper
package locking. This provides a number of benefits over simple script sharing:

- All dependencies are packaged along with each script
- All dependencies are locked at exact versions
- The only prerequisite to running scripts is `sh` and `nix`

## Example Usage

If you haven't installed Nix, you'll get this:

```bash
➤ ./run format
It does not appear that you have nix installed!
Follow the instructions here to install the nix package manager: https://nixos.org/download
```

So, do as the message says and [install Nix!](https://nixos.org/download)
Now you can try again:

```bash
➤ ./run format
0 / 1 have been reformatted
```

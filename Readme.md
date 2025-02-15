# Home Manager Nix configuration

It uses [nix-darwin](https://github.com/LnL7/nix-darwin) and [home-manager](https://github.com/nix-community/home-manager) to set up and manage the user's home environment.

This Readme is currently MacOS-centric.
However, the configuration itself has been tried on Ubuntu and NixOS and it turns out to be working (not using `darwin-configuration.nix`, obviously, but using the whole `Home Manager` config.).

## Installation

### Automated installation

Currently MacOS-specific

```bash
$ bash -i <(curl -fsSL https://raw.githubusercontent.com/AlexeyRaga/home.nix/main/install.sh)
```

At the end of the successful installation the installer will ask to tune the configuration
in your `~/.nixpkgs`, re-enter the shell and switch into the new configuration.

Before switching, consider to populate your secrets:

```bash
~/.nixpkgs/home/secrets/default.nix
~/.nixpkgs/home/work/secrets/default.nix
```
Edit both files. The first one represents "global" secrets, and the second one is for work-related secrets.

Now issuing the `switch` command should have your system set up:

```bash
$ darwin-rebuild switch
```

### Manual installation

0. Install [Nix](https://nixos.org/download.html)
   ```bash
    $ sh <(curl -L https://nixos.org/nix/install) --daemon
   ```

1. Install [nix-darwin](https://github.com/LnL7/nix-darwin)
   ```
    $ nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
    $ ./result/bin/darwin-installer
   ```
   Keep `darwin-configuration.nix` default (we are going to replace it later),
   but `darwin-rebuild switch` command should be now working (reload your shell).

3. Add `home-manager` channel:
   ```bash
    $ nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    $ nix-channel --update
   ```

4. (Optionaly, MacOS only) Install [Homebrew](https://brew.sh/)
   ```
   $ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

4. Clone this repository as your local `~/.nixpkgs` </br>
    You should have `~/.nixpkgs/darwin-configuration.nix` from this repository, replacing the default one.

5. Set up your secrets:
   ```bash
    $ cp ~/.nixpkgs/home/secrets/default.nix.example ~/.nixpkgs/home/secrets/default.nix
    $ cp ~/.nixpkgs/home/work/secrets/default.nix.example ~/.nixpkgs/home/work/secrets/default.nix
   ```
   Edit both files. The first one represents "global" secrets, and the second one is for work-related secrets.

6. Switch the profile:
   ```bash
    $ darwin-rebuild switch
   ```

At this point everything should be installed and the environment should be ready to rock.
Restart the shell if you haven't paid attention to the prompt :)

## Updating the configuration

Make changes to the configuration files and run `darwin-rebuild switch` to update the configuration.

## Note on integration with Homebrew

If `Homebrew` is installed, this configuration will manage `Homebrew` packages via [darwin/apps.nix](./darwin/apps.nix) file.
Use [darwin/apps.nix](./darwin/apps.nix) to specify which packages should be installed via `brew` and Nix will handle the rest.


## Modules overview

A short overview of modules and what they can download

### Git

`git.nix` module installs and enables `Git and creates a global configuration (username/email/github user name).

It also allows configuring "workspaces": folders that should have their own alterations of git configuration.
For example, email addresses that are used for git commits can be different for private and work-related projects.

Example:

```nix
  tools.git = {
    enable = true;
    userName = "Donald Duck";
    userEmail = "donald.duck@gmail.com";
    githubUser = secrets.github.userName;

    workspaces = {
      "src/work" = {
        user = { email = "donald.duck@bigbank.com"; };
        core = { autocrlf = true; };
      };
      "src/charity" {
        user = { email = "donald.duck@charity-works.net"; };
      };
    };
  };
```

### SecureEnv

`SecureEnv` allows to store secrets securely populating them from password managers (currently only `1Password`) with an ability to export
these secrets as environment variables and ssh keys in ssh-agent.

The reason for not exporting them from password managers directly is that they only keeps a session open for a short period of time,
which means that users will be asked to re-authenticate often.

Instead, secrets are copied to `Keychain` (on MacOS) or `Keyring` (on Linux) and then used to source env variables.
This way secrets are never stored on disk unencrypted but can still be made conveniently available to the user as environment variables.

Example:

```nix
  secureEnv.onePassword = {
    enable = true;
    sessionVariables = {
      GITHUB_TOKEN = {
        vault = "Private";
        item = "Github";
        field = "token";
      };
    };
    sshKeys = {
      # the IDs may be found from `op list items`
      test_ec2_keypair = {
        vault = "Dev - Shared DevOps";
        item = "wrmpodmfm2k6rijjj5dimhrnwq";
        field = "notes";
      };
      staging_pem = {
        vault = "Dev - Shared DevOps";
        item = "uhpvoujfk2wgu7kpqrdc2heaby";
        field = "notes";
      };
      loadtest01_pem = {
        vault = "Dev - Shared DevOps";
        item = "nztr4zuyig4jhac47tfgbo6vn4";
        field = "notes";
      };
    };
  };

```

**NOTE**: `Secret Store` module will _not_ remove any passwords from `Keychain`/`Keyring`. It will only сopy passwords and update existing ones.

### .NET

`dotnet.nix` module makes .NET SDK available for the machine. It

It also allows configuring extra Nuget sources, which is useful in setups with private nuget repositories.

Example:

```nix
  tools.dotnet = {
    enable = true;
    nugetSources = {
      bigBankGithub = {
        url = "https://nuget.pkg.github.com/BigBank/index.json";
        userName = secrets.github.userName;
        password = secrets.github.token;
      };
    };
  };
```

### AWS

AWS can be configured via `tools.aws` module.

AWS can have statically defined profiles, and SAML profiles (using Google as ID Provider) such as:

```nix
  tools.aws = {
    enable = true;

    profiles = {
      default = {
        accessKeyId = "AKIAIOSFODNN7EXAMPLE";
        secretAccessKey = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY";
      };
    };

    googleStsProfile = {
      name = "default";
      spId = "1111111111111";
      idpId = "A11a1aa1a";
      accounts = {
        test = {
          accountId = "123456789012";
          roles = [ "admin" "read-only" ];
        };
        prod = {
          accountId = "210987654321";
          roles = [ "admin" "read-only" "terraform" ];
        };
      };
    };
  };
```

When `tools.aws.googleStsProfile` is defined, `aws-switch` command becomes available and it allows to switch between accounts in the configured profile via CLI:

```bash
$ aws-switch test admin
```

`aws-switch` has `Zsh` completion module, so `<TAB>` should help with the command line parameters.

let
  secrets = import ./secrets;
  epNugetSource = {
    url = "https://nuget.pkg.github.com/EducationPerfect/index.json";
    userName = secrets.github.userEmail;
    password = secrets.github.token;
  };

in
{
  imports = [
    ./aws.nix
  ];

  home = {
    sessionVariables = {
      EP_NUGET_SOURCE_URL = epNugetSource.url;
      EP_NUGET_SOURCE_USER = epNugetSource.userName;
      EP_NUGET_SOURCE_PASS = epNugetSource.password;
      EP_SERVER_SOURCE_DIR = "/Users/matthewoffen/Documents/dev/server";
      LOCALSTACK_API_KEY = secrets.localstack.apikey;
      EP_NPM_TOKEN = secrets.ep.npm_token;
      AWS_PAGER="";
    };
  };

  tools.git = {
    workspaces."src/ep" = {
      user = { email = secrets.github.userEmail; };
      core = { autocrlf = true; };
    };
  };
}

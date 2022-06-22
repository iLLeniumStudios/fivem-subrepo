
# fivem-subrepo

A bash script that builds up a subrepo based private Git repo and private forks from a txAdmin Recipe

## Supported Operating Systems

- Linux (Ubuntu / CentOS / Fedora / Arch)

- Windows (WSL / WSL2)

## Pre-requisites
- jq
- yq
- git
- gh
- subrepo
- unzip

For Ubuntu, you can install them using the following commands:

```bash
# Install jq and git
sudo apt install -y git jq unzip
# Install yq
pip3 install yq
# Add python binaries to PATH
echo "export PATH=\$PATH:/home/$USER/.local/bin" >> ~/.bashrc
# Download gh tarball
wget https://github.com/cli/cli/releases/download/v2.12.1/gh_2.12.1_linux_amd64.tar.gz
# Extract tarball
tar -xvf gh_2.12.1_linux_amd64.tar.gz
# Move gh binary to /usr/local/bin
sudo mv gh_2.12.1_linux_amd64/bin/gh /usr/local/bin/
# Mark gh as executable
sudo chmod +x /usr/local/bin/gh
# Cleanup
rm -rf gh_2.12.1_linux_amd64*
# Clone subrepo repository
git clone https://github.com/daotl/git-subrepo $HOME/.subrepo
# Source subrepo in .bashrc
echo "source \$HOME/.subrepo/.rc" >> ~/.bashrc
```

## Create a new Organization
This step is optional but I recommend that you create an entirely new organization under your Github Account and use it. 

**WARNING:** I won't be responsible if anything goes wrong with any of your existing repositories or forks that you have in your account if you intend to use your personal account. Use at your own risk

You can create a new Organization by following these steps:
- Go to https://github.com in your browser
- Click on the `+` sign next to your profile picture at the top right of the page
- Click on `New organization`
- Choose the `Free` plan by clicking on `Create a free organization`
- Type a unique name for your organization and provide your email
- Keep `My personal account` selected for the question `This organization belongs to:`
- Verify your account, check the `I hereby accept...` checkmark and click `Next`
- Click on `Skip this step` on the next screen and click `Submit` on the following screen
- Keep your Organization Name with you. It will be needed in the upcoming steps

## Configure git
If this is the first time for you using the `git` CLI then you will need to setup your username and email with git. To do that, run the following commands after replacing `<username>` with your git username and `<email>` with your git email address:

```bash
git config --global user.name "<username>"
git config --global user.email "<email>"
```

## Configure gh
`gh` is used to create and configure github repositories. In order to set it up, you will need to generate a Personal Access Token. Follow these instructions to generate one:
- Go to https://github.com in your browser
- Click on your profile picture at the top right of the page and then click `Settings`
- In the left sidebar, click `Developer settings`
- In the left sidebar, clieck `Personal access tokens`
- Click `Generate new token`
- Give your token a descriptive name
- Set the expiration to `No expiration`
- Select the following scopes:
	- repo
	- admin:org
	- delete_repo
- Click `Generate token`
- Copy the token
- Now open up the terminal and run the following command after replacing `<token>` with your token

```bash
echo "<token>" | gh auth login --with-token
gh auth status
export MY_GIT_TOKEN=<token>
git config --global url."https://api:$MY_GIT_TOKEN@github.com/".insteadOf "https://github.com/"
```

- If you see all ticks on the terminal output, you are good to go

## Create a new FiveM Server Resources Repo

### Clone this repo

- Run the following command under any directory in the terminal:

```bash
git clone https://github.com/iLLeniumStudios/fivem-subrepo
```

- Go into the directory by running `cd fivem-subrepo`

### Setup env.sh

Set the variable values in `env.sh` according to your needs
| Variable | Description |
|--|--|
| ORG_NAME | Name of the organization that you created by following the above guide |
| REPO_NAME | Name of your main repository that will have your resources folder, server.cfg etc |
| REPO_PATH | Absolute location where you want to clone your main repository and resource repositories |
| RECIPE_PATH | Absolute path to the recipe file. If you want to use qb-core recipe then don't change the default path |  

### Start Repo creation

- Run the following command and let it do its magic:
```bash
./fivem-subrepo.sh create
```

- Once that is done, you should have all the repos as subrepos of the repo that you just created
- Now go to `recipes/qbcore.yaml` and change all instances of `#skip: true` to `skip: true`
- This is needed to avoid a few steps that aren't needed after the initial creation
- And you're done now

## Pull changes from all remote repositories

Now that you've set everything up, you can now pull the latest changes from all the qb-core repositories whenever you need. To do so, follow these instructions:

- Change current directory to the `fivem-subrepo` folder
- Run the following command:

```bash
./fivem-subrepo.sh pull
```
- Wait until the command exits. Once finished, all the changes should be merged into your repo

## Committing changes to the main resources repo

Pushing changes is a bit different when you have subrepo's configured. This is how you will need to commit:

- Add all your files to git history

```bash
git add .
```

- Create a new commit

```bash
git commit -m "Commit message"
```

- Now you have 2 options to choose from (only follow 1):
	- Let subrepo figure out which changes to go which repo and push automatically (Will be slow)
		- To do that, just run `git subrepo push --all` from the root of your main repo
	- Explicitly push a specific resource change (Instant)
		- Figure out what file you edited. For example you edited the `resources/[qb]/qb-core/config.lua`
		- This means you need to push changes to `qb-core` resource
		- Run the following command to do that: `git subrepo push resources/[qb]/qb-core`

## Adding a new resource

You can add as many resources as you can as long as they're in individual git repos and their scripts are at the root of the repo. To add a new repo, you can do the following:

- Make sure that you don't have uncommitted changes, if you do, commit and push all of them
- Add the following lines at the end of `recipes/qbcore.yaml` file:

```yaml
- action: download_github
  dest: ./resources/[qb]/<resource-name>
  ref: <resource-branch>
  src: <resource-url>
```

- Change `<resource-name>` to the name of the resource that you're adding
- Change `<resource-url>` to the git URL of the resource that you're adding
- Change `<resource-branch>` to the branch of the git repo that you're adding
- Save the file
- Run the following command:

```bash
./fivem-subrepo.sh create
```

- And you're done

## Removing a resource

- Get the path of the resource that you want to remove from `recipes/qbcore.yaml`
- Delete the full block for that resource from the file. It should look like this:

```yaml
- action: download_github
  dest: ./resources/[qb]/qb-loading
  ref: main
  src: qb-loading
```

- Go to your main repo directory using the terminal (Example: `cd <my-repo-path>`)
- Run the following commands after replacing `<resource-name>`:

```bash
rm -rf ./resources/[qb]/<resource-name>
git add .
git commit -m "Remove <resource-name>"
git push origin main
git remote remove <resource-name>
```

- And you're done

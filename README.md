# fivem-subtree
A bash script that builds up a subtree based Git repo from a txAdmin Recipe

## Supporting Operating Systems

- Linux (Ubuntu / CentOS / Fedora / Arch)
- Windows (WSL / WSL2)

## Pre-requisites

- jq
- yq
- git

For Ubuntu, you can install them using the following commands:

```bash
sudo apt install -y git jq
pip3 install yq
echo "export PATH=\$PATH:/home/$USER/.local/bin" >> ~/.bashrc
```

## Creating the resource repo

### Clone this repo

- Run the following command under any directory in the terminal:

```bash
git clone https://github.com/iLLeniumStudios/fivem-subtree
```

- Go into the directory by running `cd fivem-subtree`

### Creating a new repo

- Create a new private / public Github Repository
- Make sure to check `Add Readme` so that a default `main` branch gets created
- Copy the URL of the repository (Example: https://github.com/iLLeniumStudios/my-roleplay-server)
- Paste the URL in `env.sh` file under `mainRepoURL` export string
- Choose an **absolute** path for where you want the repository to be cloned
- Add that path in `env.sh` file under `mainRepoPath` export string (Example: /home/myuser/my-roleplay-server)


### Start the subtree creation process

- Run the following command and let it do its magic:

```bash
./create_repo.sh
```

- Once that is done, you should have all the repos as subtrees of the repo that you just created
- Now go to `recipes/qbcore.yaml` and change all instances of `#skip: true` to `skip: true`
- This is needed to avoid a few steps that aren't needed after the initial creation
- And you're done now

## Pull from remote repositories

Now that you've set everything up, you can now pull the latest changes from all the qb-core repositories whenever you need. To do so, follow these instructions:

- Change current directory to the `fivem-subtree` folder
- Run the following command:

```bash
./pull_repo.sh
```

- Wait until the command exits. Once finished, all the changes should be merged into your repo

## Adding new resource subtree

You can add as many resources as you can as long as they're in individual git repos and their scripts are at the root of the repo. To add a new repo, you can do the following:

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
./create_repo.sh
```

- And you're done

## Removing a resource subtree

- Get the path of the resource that you want to remove from `recipes/qbcore.yaml`
- Delete the full block for that resource from the file. It should look like this:

```yaml
  - action: download_github
    dest: ./resources/[qb]/qb-loading
    ref: main
    src: qb-loading
```

- Go to your main repo directory using the terminal (Example: `cd <my-repo-path>`)
- Run the following commands:

```bash
rm -rf ./resources/[qb]/qb-loading
git add .
git commit -m "Remove qb-loading"
git push origin main
git remote remove qb-loading
```

- And you're done

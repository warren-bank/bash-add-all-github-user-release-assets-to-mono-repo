### Usage

1. update: [_general configuration_](./bin/configuration.sh)
2. update: _private configuration_
   - copy [`configuration-private.sh.template`](./bin/configuration-private.sh.template) to `configuration-private.sh`
   - optionally, edit this file to supply a [Github personal access token](./bin/configuration-private.md)
   - note: this file will be ignored by `git`
3. update: [repo blacklist](./bin/repo_blacklist.js)
4. run: [bash script](./bin/add_all_github_user_release_assets_to_mono_repo.sh)
   - would strongly suggest that:
     * stdout and stderr be piped to a log file:
       ```bash
         cd bin
         ./add_all_github_user_release_assets_to_mono_repo.sh >log.txt 2>&1
       ```
     * update [_general configuration_](./bin/configuration.sh) to only perform download during a first pass:
       ```text
         export reuse_json_repo_data_if_already_exist=1
         export reuse_text_repo_names_if_already_exists=1

         export reuse_json_releases_data_if_already_exist=1
         export reuse_script_to_download_all_release_file_assets=1

         export include_releases_source_zipball=1
         export include_releases_source_tarball=0

         export perform_download=1
         export use_utc_timestamp_in_commit_message=1
         export commit_each_repo_individually=1

         export perform_git_clone=0
         export perform_git_commit=0
         export perform_git_push=0
       ```
     * check the log file for any download errors
       - remove any partial files
       - repeat, until all downloads have successfully completed
         * note: `wget` commands are configured to skip downloads when the file is already on disk
     * update [_general configuration_](./bin/configuration.sh) to only perform git commit and push during a last pass:
       ```text
         export reuse_json_repo_data_if_already_exist=1
         export reuse_text_repo_names_if_already_exists=1

         export reuse_json_releases_data_if_already_exist=1
         export reuse_script_to_download_all_release_file_assets=1

         export include_releases_source_zipball=1
         export include_releases_source_tarball=0

         export perform_download=0
         export use_utc_timestamp_in_commit_message=1
         export commit_each_repo_individually=1

         export perform_git_clone=0
         export perform_git_commit=1
         export perform_git_push=1
       ```
     * before executing this last pass,<br>add any missing remotes:
       ```bash
         github_user_name='warren-bank'

         cd "bin/${github_user_name}-releases"

         git remote add origin   "git@github.com:${github_user_name}/${github_user_name}-releases.git"
         git remote add gitlab   "git@gitlab.com:${github_user_name}/${github_user_name}-releases.git"
         git remote add codeberg "git@codeberg.org:${github_user_name}/${github_user_name}-releases.git"
       ```

### What it does..

1. downloads data about all public github repos belonging to the specified user
2. filters this repo data to ignore:
   - disabled repos
   - repos in the blacklist
3. maps the filtered repo data to a list of repo names
   - saved to a text file containing the name of one repo per line
4. for each repo name in this text file:
   - downloads data about all releases in repo
5. for each asset in each release in repo:
   - appends a `wget` command to dynamically generated bash script
6. clones, updates, or initializes a git repo
7. executes the dynamically generated bash script to download all _missing_ file assets
8. commits updates to the local git repo
9. pushes the new commit to all remotes
   - __IMPORTANT__:
     * GitHub has a [2 GB push limit](https://docs.github.com/en/get-started/using-git/troubleshooting-the-2-gb-push-limit)
     * the `commit_each_repo_individually` config option is helpful to work around this limit
       - when combined with `perform_git_commit` and `perform_git_push`,<br>the directory for each repo that has downloaded new release assets is individually committed and pushed to remotes
       - this methodology pushes incremental updates to GitHub, rather than including all new release assets in a single push

#### Legal

* copyright: [Warren Bank](https://github.com/warren-bank)
* license: [GPL-2.0](https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt)

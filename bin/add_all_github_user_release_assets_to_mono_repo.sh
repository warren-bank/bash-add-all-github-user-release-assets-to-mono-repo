#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# -------------------------------------------------------------------- configuration:

source "${DIR}/configuration.sh"

if [ -n "$github_personal_access_token" ];then
  GITHUB_AUTH_HEADER="Authorization: Bearer ${github_personal_access_token}"
else
  GITHUB_AUTH_HEADER=''
fi

# -------------------------------------------------------------------- select working directory:

if [ -n "$working_directory" -a -d "$working_directory" ];then
  cd "$working_directory"
fi

# -------------------------------------------------------------------- initialize output data directory:

data_dir="${mono_repo_name}-data"

if [ ! -d "$data_dir" ];then
  mkdir "$data_dir"
fi

# -------------------------------------------------------------------- generate list of github repo names:

repo_blacklist='repo_blacklist.js'

repo_data="${data_dir}/repo_data.json"
repo_names="${data_dir}/repo_names.txt"

download_repo_data() {
  # https://docs.github.com/en/rest/repos
  # https://docs.github.com/en/rest/repos/repos#list-repositories-for-a-user
  api_url="https://api.github.com/users/${github_user_name}/repos?type=owner&sort=full_name&direction=asc&per_page=100&page="

  if [ -f "$repo_data" -a $reuse_json_repo_data_if_already_exist -ne 1 ];then
    rm -f "$repo_data"
  fi
  if [ ! -f "$repo_data" ];then
    echo '[' >"$repo_data"
    for i in {1..30000}
    do
      data=$(curl --insecure --silent -H "$GITHUB_AUTH_HEADER" "${api_url}${i}")
      if [[ "$data" =~ "{" ]];then
        if [ $i -gt 1 ];then
          echo ',' >>"$repo_data"
        fi
        echo "$data" >>"$repo_data"
      else
        break
      fi
    done
    echo ']' >>"$repo_data"
  fi
}

generate_repo_names() {
  if [ -f "$repo_names" -a $reuse_text_repo_names_if_already_exists -ne 1 ];then
    rm -f "$repo_names"
  fi
  if [ ! -f "$repo_names" ];then
    node -e "const repo_data = require('./${repo_data}'); const repo_blacklist = require('./${repo_blacklist}'); const repo_names = []; for (let repo_group of repo_data) { for (let repo of repo_group) { if (!repo.disabled && !repo_blacklist.includes(repo.name)) { repo_names.push(repo.name); } } } console.log(repo_names.join('\n'));" >"$repo_names"
  fi
}

if [ ! -f "$repo_names" -o $reuse_text_repo_names_if_already_exists -ne 1 ];then
  download_repo_data
  generate_repo_names
fi

# -------------------------------------------------------------------- generate script to download all release file assets:

repos_dir="${data_dir}/repos"

script_to_download_all_release_file_assets="${data_dir}/download_all_release_file_assets.sh"

download_releases_data() {
  if [ ! -d "$repos_dir" ];then
    mkdir "$repos_dir"
  fi

  while read repo_name; do
    if [ -n "$repo_name" ];then
      releases_data="${repos_dir}/${repo_name}.json"
      if [ -f "$releases_data" -a $reuse_json_releases_data_if_already_exist -ne 1 ];then
        rm -f "$releases_data"
      fi
      if [ ! -f "$releases_data" ];then
        # https://docs.github.com/en/rest/releases
        # https://docs.github.com/en/rest/releases/releases
        api_url="https://api.github.com/repos/${github_user_name}/${repo_name}/releases?per_page=100&page="

        echo '[' >"$releases_data"
        for i in {1..30000}
        do
          data=$(curl --insecure --silent -H "$GITHUB_AUTH_HEADER" -H 'Accept: application/vnd.github+json' "${api_url}${i}")
          if [[ "$data" =~ "{" ]];then
            if [ $i -gt 1 ];then
              echo ',' >>"$releases_data"
            fi
            echo "$data" >>"$releases_data"
          else
            break
          fi
        done
        echo ']' >>"$releases_data"
      fi
    fi
  done <"$repo_names"
}

generate_download_script() {
  if [ -f "$script_to_download_all_release_file_assets" -a $reuse_script_to_download_all_release_file_assets -ne 1 ];then
    rm -f "$script_to_download_all_release_file_assets"
  fi
  if [ ! -f "$script_to_download_all_release_file_assets" ];then
    echo '#!/usr/bin/env bash' >"$script_to_download_all_release_file_assets"

    while read repo_name; do
      if [ -n "$repo_name" ];then
        releases_data="${repos_dir}/${repo_name}.json"

        node -e "const releases_data = require('./${releases_data}'); const include_source = ${include_releases_source_zipball} || ${include_releases_source_tarball}; if (releases_data && Array.isArray(releases_data) && releases_data.length) { const repo_dir = '${mono_repo_name}/${repo_name}'; console.log(''); console.log('mkdir -p \"' + repo_dir + '\"'); for (let releases_group of releases_data) { for (let release of releases_group) {if (release && (typeof release === 'object') && release.tag_name && Array.isArray(release.assets) && release.assets.length) {const tag_name = release.tag_name; const tag_dir = repo_dir + '/' + tag_name; const source_dir = tag_dir + '/source'; console.log('mkdir -p \"' + tag_dir + '\"'); for (let asset of release.assets) { const file_name = asset.name; const file_url = asset.browser_download_url; console.log('wget --no-check-certificate -nc -nv -O \"' + tag_dir + '/' + file_name + '\" \"' + file_url + '\"'); } if (include_source) { console.log('mkdir -p \"' + source_dir + '\"'); if (${include_releases_source_zipball}) { const file_name = '${repo_name}-' + tag_name.replaceAll('/', '-') + '.zip'; const file_url = release.zipball_url; console.log('wget --no-check-certificate -nc -nv -O \"' + source_dir + '/' + file_name + '\" \"' + file_url + '\"'); } if (${include_releases_source_tarball}) { const file_name = '${repo_name}-' + tag_name.replaceAll('/', '-') + '.tar.gz'; const file_url = release.tarball_url; console.log('wget --no-check-certificate -nc -nv -O \"' + source_dir + '/' + file_name + '\" \"' + file_url + '\"'); }}}}}}" >>"$script_to_download_all_release_file_assets"
      fi
    done <"$repo_names"
  fi
}

if [ ! -f "$script_to_download_all_release_file_assets" -o $reuse_script_to_download_all_release_file_assets -ne 1 ];then
  download_releases_data
  generate_download_script
fi

# -------------------------------------------------------------------- create or update local repo:

if [ -d "$mono_repo_name" ];then
  cd "$mono_repo_name"
  if [ -d '.git' ];then
    if [ -f ".git/refs/heads/${branch_name}" ];then
      git checkout "$branch_name"
      if [ $? -eq 0 ];then
        git remote get-url 'origin' >/dev/null 2>&1
        if [ $? -eq 0 ];then
          git pull origin "$branch_name"
        fi
      fi
    fi
  else
    git init
    git checkout --orphan "$branch_name"
  fi
  cd ..
else
  if [ $perform_git_clone -eq 1 ];then
    git clone "git@github.com:${github_user_name}/${mono_repo_name}.git"
  fi
  if [ ! -d "$mono_repo_name" ];then
    mkdir "$mono_repo_name"
    cd "$mono_repo_name"
    git init
    git checkout --orphan "$branch_name"
    cd ..
  fi
fi

# -------------------------------------------------------------------- update local repo working tree:

if [ $perform_download -eq 1 ];then
  source "$script_to_download_all_release_file_assets"
fi

# -------------------------------------------------------------------- function: commit local repo working tree to index:

exec_git_commit() {
  repo_name="$1"

  if [ $perform_git_commit -eq 1 ];then
    if [ $use_utc_timestamp_in_commit_message -eq 1 ];then
      commit_msg=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
    else
      commit_msg=$(date +"%Y-%m-%d %H:%M:%S")
    fi

    if [ -n "$repo_name" ];then
      commit_msg="${commit_msg} - ${repo_name}"

      git add --all "$repo_name"
    else
      git add --all .
    fi

    git commit -uno -m "$commit_msg"
  fi
}

# -------------------------------------------------------------------- function: push updates to remote repos:

exec_git_push() {
  repo_name="$1"

  if [ $perform_git_push -eq 1 ];then
    local_sha=$(git rev-parse HEAD)

    for remote_name in $(git remote);do
      remote_sha=$(git rev-parse "${remote_name}/${branch_name}")

      if [ "$local_sha" == "$remote_sha" ];then
        continue
      fi

      retries=-1

      while [ $max_push_retries_before_exit -lt 0 -o $retries -lt $max_push_retries_before_exit ];do
        git push "$remote_name" "$branch_name"

        if [ $? -eq 0 ];then
          # sanity check
          remote_sha=$(git rev-parse "${remote_name}/${branch_name}")

          if [ "$local_sha" == "$remote_sha" ];then
            break
          fi
        fi

        retries=$((retries + 1))
        sleep $seconds_delay_between_push_retries
      done

      if [ $max_push_retries_before_exit -ge 0 -a $retries -eq $max_push_retries_before_exit ];then
        if [ -n "$repo_name" ];then
          echo "Network error: unable to push '/${repo_name}' to '${remote_name}' remote."
        else
          echo "Network error: unable to push to '${remote_name}' remote."
        fi

        return 1
      fi
    done
  fi
}

# -------------------------------------------------------------------- call functions: commit and push

cd "$mono_repo_name"

if [ -n "$bytes_to_push_per_post_chunk_over_ssh" ];then
  git config ssh.postBuffer "$bytes_to_push_per_post_chunk_over_ssh"
fi
if [ -n "$bytes_to_push_per_post_chunk_over_http" ];then
  git config http.postBuffer "$bytes_to_push_per_post_chunk_over_http"
fi

if [ $commit_each_repo_individually -eq 1 ];then
  while read repo_name; do
    if [ -n "$repo_name" ];then
      exec_git_commit "$repo_name"
      exec_git_push   "$repo_name"

      if [ ! $? -eq 0 ];then
        exit 1
      fi
    fi
  done <"../${repo_names}"
else
  exec_git_commit
  exec_git_push
fi

# --------------------------------------------------------------------

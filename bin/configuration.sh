#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# -------------------------------------------------------------------- configuration:

# use empty string to not change directory, and use the current working directory
export working_directory="$DIR"

export github_user_name='warren-bank'

export mono_repo_name="${github_user_name}-releases"
export branch_name='master'

export reuse_json_repo_data_if_already_exist=1
export reuse_text_repo_names_if_already_exists=1

export reuse_json_releases_data_if_already_exist=1
export reuse_script_to_download_all_release_file_assets=1

export include_releases_source_zipball=1
export include_releases_source_tarball=0

export perform_download=1
export use_utc_timestamp_in_commit_message=1
export commit_each_repo_individually=1

export bytes_to_push_per_post_chunk_over_ssh='52428800'  # 50 MiB. (1 MiB is the default.)
export bytes_to_push_per_post_chunk_over_http='52428800' # 50 MiB. (1 MiB is the default.)
export max_push_retries_before_exit=-1 # use any negative number for infinite retries. (I'm looking at you, gitlab.)
export seconds_delay_between_push_retries=5

export perform_git_clone=0
export perform_git_commit=0
export perform_git_push=0

# -------------------------------------------------------------------- private configuration:

if [ -f "${DIR}/configuration-private.sh" ];then
  source "${DIR}/configuration-private.sh"
fi

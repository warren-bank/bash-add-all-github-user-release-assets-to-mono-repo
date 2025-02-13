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

# -------------------------------------------------------------------- large-file-storage:

export PATH_7zip='/c/PortableApps/7-Zip/16.02/App/7-Zip64'

export split_files_larger_than='100' # units: MB
export size_of_split_chunks='50'     # units: MB

export delete_original_files_after_split=1
export delete_split_chunks_after_merge=1

export perform_lfs_split=1
export perform_lfs_merge=0

# -------------------------------------------------------------------- private configuration:

if [ -f "${DIR}/configuration-private.sh" ];then
  source "${DIR}/configuration-private.sh"
fi

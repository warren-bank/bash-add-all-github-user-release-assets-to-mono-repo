#!/usr/bin/env bash

if [ -n "$PATH_7zip" ];then
  PATH="${PATH_7zip}:${PATH}"
fi

find "$mono_repo_name" -path "${mono_repo_name}/.git" -prune -o -type f -size "+${split_files_larger_than}M" -print0 | while IFS= read -r -d $'\0' file;do
  7z a -tzip "-v${size_of_split_chunks}m" "${file}.zip" "$file"

  if [ $delete_original_files_after_split -eq 1 ];then
    rm -f "$file"
  fi
done

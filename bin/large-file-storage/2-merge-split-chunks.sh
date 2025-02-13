#!/usr/bin/env bash

if [ -n "$PATH_7zip" ];then
  PATH="${PATH_7zip}:${PATH}"
fi

find "$mono_repo_name" -path "${mono_repo_name}/.git" -prune -o -type f -name *.zip.001 -print0 | while IFS= read -r -d $'\0' file;do
  output_dir=$(dirname "$file")
  7z e -aoa "-o${output_dir}" "$file"
done

if [ $delete_split_chunks_after_merge -eq 1 ];then
  find "$mono_repo_name" -path "${mono_repo_name}/.git" -prune -o -type f -regextype 'posix-extended' -regex ".*\.zip\.[0-9]{3}$" -print0 | while IFS= read -r -d $'\0' file;do
    rm -f "$file"
  done
fi

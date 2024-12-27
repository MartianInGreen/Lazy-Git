lazy-git(){
  local cwd=$(pwd)

  # Stage modifications to already tracked files
  git add -u

  # Get untracked files
  untracked_files=("${(f)$(git ls-files --others --exclude-standard)}")

  if [ ${#untracked_files[@]} -gt 0 ]; then
    echo "Untracked files:"
    for i in {1..${#untracked_files[@]}}; do
      echo "$i. '${untracked_files[$i]}'"
    done

    # Ask user which files they want to add
    echo -n "Enter the numbers of files you want to add (separated by spaces), or 'all' to add all: "
    read -A file_numbers

    if [[ ${file_numbers[1]} == "all" ]]; then
      git add .
    else
      for num in $file_numbers; do
        if [[ $num =~ ^[0-9]+$ ]] && [ $num -ge 1 ] && [ $num -le ${#untracked_files[@]} ]; then
          git add "${untracked_files[$num]}"
        else
          echo "Invalid number: $num. Skipping."
        fi
      done
    fi
  fi
  
  # Show the diff to the user
  echo "Changes to be committed:"
  git diff --cached --color --compact-summary

  # Summarize changes and get suggested commit message
  summary=$(git diff --cached | sgpt --model gpt-4o-mini "Please summarize these changes into 3-4 lines and suggest a git commit message at the end.\nThe git commit message should be below 40 charachters and be written out as follows:\n**Suggested commit message:**\n_The git message suggestion_\n\n Git diff:\n")

  # Extract the last line as the suggested commit message
  suggested_message=$(echo "$summary" | tail -n 1)
  summary_without_last_line=$(echo "$summary" | head -n -2)

  # Display summary and ask user for commit message
  echo "$summary"
  echo -n "Enter a commit message (press Enter to use suggested message): "
  read commit_message

  if [ -z "$commit_message" ]; then
    commit_message=$(echo -e "$suggested_message\n$summary_without_last_line")
  fi

  git commit -m "$commit_message"
  git push
  echo "Pushed to GitHub."
}
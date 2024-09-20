# TODO: Add error handling.
function nixpkgs-pr --argument-names pull_request --description 'Track the status of a nixpkgs pull request'
  set -l branches staging-next master nixos-unstable-small nixpkgs-unstable nixos-unstable

  set -l merge_commit (curl -s "https://api.github.com/repos/nixos/nixpkgs/pulls/$pull_request" | jq -r '.merge_commit_sha, .html_url, .title')
  set -l statuses (curl --silent --parallel 'https://api.github.com/repos/nixos/nixpkgs/compare/'$branches"...$merge_commit[1]" | jq -r 'if .status == "ahead" or .status == "identical" then "❌" else "✅" end')

  echo "Nixpkgs pull request status for $(hyperlink $merge_commit[2] $merge_commit[3]):"

  for i in (seq (count $branches))
    echo "  $statuses[$i] $branches[$i]"
  end
end

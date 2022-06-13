function gwip --wraps='git add -A; git ls-files --deleted -z | xargs -0 git rm; git commit -m "wip"' --description 'alias gwip=git add -A; git ls-files --deleted -z | xargs -0 git rm; git commit -m "wip"'
  git add -A; git ls-files --deleted -z | xargs -0 git rm; git commit -m "wip" $argv; 
end

GITHUB_PROJECT_NAME=githubProject
GITLAB_PROJECT_NAME=gitlabProject
GITHUB_BACKBASE=https://$GITHUB_USER:$GITHUB_TOKEN@github_repo/owner/$GITHUB_PROJECT_NAME
GITLAB_BACKBASE=https://$GITLAB_USER:$GITLAB_TOKEN@gitlab_repo/group/$GITLAB_PROJECT_NAME.git


## functions ##

reupload_project() {
	github_branch=$1
  gitlab_branch=$2
	
	export http_proxy=$GITHUB_PROXY
	export https_proxy=$GITHUB_PROXY

	# Clone GitHub branches
	git clone -b $github_branch $GITHUB_BACKBASE

	# Repoint to Gitlab repo then push the branch
	unset http_proxy
	unset https_proxy
    
	cd $GITHUB_PROJECT_NAME
	git branch
	git remote add gitlab $GITLAB_BACKBASE
	git push -u gitlab $github_branch
    
  git checkout -b $gitlab_branch $github_branch
	git push -u gitlab $gitlab_branch
}

reupload_project $GITHUB_BRANCH $GITLAB_BRANCH

exit

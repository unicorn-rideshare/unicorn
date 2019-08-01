#!/bin/bash
# Script for Continuous Integration
# Example Jenkins usage: 
#       /bin/bash -c \
#           "AWS_ACCESS_KEY_ID=xyz \
#           AWS_SECRET_ACCESS_KEY=abc \
#           AWS_DEFAULT_REGION=us-east-1 \
#           AWS_DEFAULT_OUTPUT=json \
#           ECR_REPOSITORY_NAME=unicorn/rails \
#           ECS_TASK_DEFINITION_FAMILY=unicorn \
#           ECS_CLUSTER=production \
#           ECS_SERVICE_NAME=unicorn \
#           '$WORKSPACE/scripts/ci-process.sh'"
set -o errexit # set -e
set -o nounset # set -u
set -o pipefail
trap die ERR
die() 
{
    echo "Failed at line $BASH_LINENO"; exit 1
}
echo Executing $0 $*

preparation() 
{
    echo '....Running the full continuous integration process....'
    scriptDir=`dirname $0`
    echo "scriptDir is $scriptDir"
    pushd "${scriptDir}/.." &>/dev/null
    echo 'Working Directory =' `pwd`
}

finalization() 
{
    popd &>/dev/null
    echo '....CI process completed....'
}

setup_rails() 
{
    PATH="$PATH:/usr/share/rvm/bin:$HOME/.rvm/bin"
    if hash gpg 2>/dev/null 
    then
        echo 'Using' `gpg --version`
    else
        echo 'Installing gpg'
        sudo apt-get update
        sudu apt-get -y install gpg
    fi
    echo 'Installing rvm (if needed)' # Otherwise, `hash rvm` triggers rvm, which then fails without Ruby being installed. 
    gpg --keyserver hkp://keys.gnupg.net \
        --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
    curl -sSL https://get.rvm.io | bash
    PRVD_RUBY_VERSION=$(cat .ruby-version)
    rvm install $PRVD_RUBY_VERSION
    pushd ~ &>/dev/null
    popd &>/dev/null
    source $(rvm all do rvm env --path)
    if hash ruby 2>/dev/null
    then
        echo 'Using' `ruby --version`
    else
        echo 'Ensuring Ruby is on the PATH'
        PATH="$PATH:$HOME/.rvm/rubies/ruby-$PRVD_RUBY_VERSION/bin"
    fi
    if hash bundle 2>/dev/null
    then
        echo 'Using' `bundle --version`
    else 
        echo 'Installing bundler (and related)'
        sudo apt-get update
        sudo apt-get -y install libpq-dev # reguired by the pg gem on ubuntu
        bundler_version=`ruby -e 'puts $<.read[/BUNDLED WITH\n   (\S+)$/, 1] || "<1.10"' Gemfile.lock`
        gem install bundler --conservative --no-document -v $bundler_version
    fi
    # sudo apt-get update
    # sudo apt-get install libssl1.0.0=1.0.2n-1ubuntu5.1 # For Docker error: "The following packages have unmet dependencies: libcurl4-openssl-dev : Conflicts: libssl1.0-dev but 1.0.2n-1ubuntu5.1 is to be installed ... Unable to correct problems, you have held broken packages."
    # TODO: add these back to the Gemfile once we can install them: 
    #       gem 'capybara', '~> 2.4'
    #       gem 'capybara-webkit', '~> 1.5'
    # TODO: Later on, also install: (rvm??), Postgres, redis, nats, nginx, etc, for pre-deployment integration testing...?
}

setup_deployment_tools() 
{
    if hash python 2>/dev/null
    then
        echo 'Using: ' 
        python --version
    else
        echo 'Installing python'
        sudo apt-get update
        sudo apt-get -y install python2.7
    fi
    if hash pip 2>/dev/null
    then
        echo 'Using' `pip --version`
    else
        echo 'Installing python'
        sudo apt-get update
        sudo apt-get -y install python-pip
    fi
    if hash aws 2>/dev/null
    then
        echo 'Using AWS CLI: ' 
        aws --version
    else
        echo 'Installing AWS CLI'
        pip install awscli --upgrade --user
    fi
    if hash docker 2>/dev/null
    then
        echo 'Using docker' `docker -v`
    else
        echo 'Installing docker'
        sudo apt-get update
        sudo apt-get install -y apt-transport-https \
                                ca-certificates \
                                software-properties-common
        sudo apt-get install -y docker
    fi
    if hash jq 2>/dev/null
    then
        echo 'Using' `jq --version`
    else
        echo 'Installing jq'
        sudo apt-get update
        sudo apt-get -y install jq
    fi
    export PATH=~/.local/bin:$PATH
}

bootstrap_environment() 
{
    echo '....Setting up environment....'
    setup_rails
    setup_deployment_tools
    echo "PATH is: '$PATH'"
    echo '....Environment setup complete....'
}

get_build_info()
{
    echo '....Getting build values....'
    revNumber=$(echo `git rev-list HEAD | wc -l`) # the echo trims leading whitespace
    gitHash=`git rev-parse --short HEAD`
    gitBranch=`git rev-parse --abbrev-ref HEAD`
    buildDate=$(date '+%m.%d.%y')
    buildTime=$(date '+%H.%M.%S')
    echo "$(echo `git status` | grep "nothing to commit" > /dev/null 2>&1; if [ "$?" -ne "0" ]; then echo 'Local git status is dirty'; fi )";
    buildRef=${gitBranch}-${gitHash}-${buildDate}-${buildTime}
    echo 'Build Ref =' $buildRef
}

build_docker()
{
    echo '....Docker Build....'
    sudo docker build -t unicorn/rails .
    echo '....Docker Tag....'
    sudo docker tag unicorn/rails:latest "085843810865.dkr.ecr.us-east-1.amazonaws.com/unicorn/rails:${buildRef}"
    echo '....Docker Push....'
    $(aws ecr get-login --no-include-email --region us-east-1)
    sudo docker push "085843810865.dkr.ecr.us-east-1.amazonaws.com/unicorn/rails:${buildRef}"
}

perform_deployment()
{
    if [[ -z "${ECR_REPOSITORY_NAME}" || -z "${ECS_CLUSTER}" || -z "${ECS_TASK_DEFINITION_FAMILY}" || -z "${ECS_SERVICE_NAME}" ]]
    then
        echo '....[PRVD] Skipping container deployment....'
    else
        DEFINITION_FILE=ecs-task-definition.json
        MUNGED_FILE=ecs-task-definition-UPDATED.json
        echo '....list-images....'
        ECR_IMAGE_DIGEST=$(aws ecr list-images --repository-name "${ECR_REPOSITORY_NAME}" | jq '.imageIds[0].imageDigest')
        echo '....describe-images....'
        ECR_IMAGE=$(aws ecr describe-images --repository-name "${ECR_REPOSITORY_NAME}" --image-ids imageDigest="${ECR_IMAGE_DIGEST}" | jq '.')
        echo '....describe-task-definition....'
        ECS_TASK_DEFINITION=$(aws ecs describe-task-definition --task-definition "${ECS_TASK_DEFINITION_FAMILY}" | jq '.taskDefinition | del(.taskDefinitionArn) | del(.revision) | del(.status) | del(.compatibilities) | del(.requiresAttributes)')
        echo '....file manipulation....'
        echo $ECS_TASK_DEFINITION > $DEFINITION_FILE
        sed -E "s/unicorn:[a-zA-Z0-9\.-]+/unicorn:${buildRef}/g" "./${DEFINITION_FILE}" > "./${MUNGED_FILE}"
        echo '....register-task-definition....'
        ECS_TASK_DEFINITION_ID=$(aws ecs register-task-definition --family "${ECS_TASK_DEFINITION_FAMILY}" --cli-input-json "file://${MUNGED_FILE}" | jq '.taskDefinition.taskDefinitionArn' | sed -E 's/.*\/(.*)"$/\1/')
        echo '....update-service....'
        aws ecs update-service --cluster "${ECS_CLUSTER}" --service "${ECS_SERVICE_NAME}" --task-definition "${ECS_TASK_DEFINITION_ID}"
    fi
}

preparation
echo '....[PRVD] Setting Up....'
bootstrap_environment
get_build_info
echo '....[PRVD] Building....'
bundle install
bundle exec rake bower:install
bundle exec rake assets:precompile
echo '....[PRVD] Docker....'
build_docker
echo '....[PRVD] AWS Deployment....'
perform_deployment
finalization

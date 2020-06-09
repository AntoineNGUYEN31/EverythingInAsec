# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
init_DevOps(){
  url=`hostname -I|cut -d' ' -f1`

  # Docker preparation for Artifactory http
  sudo echo "{ "insecure-registries":["devops:8082"] }" >/etc/docker/daemon.json
  sudo service docker restart

  # Artifactory
  # https://www.jfrog.com/confluence/display/JFROG/Installing+Artifactory
  export JFROG_HOME=/opt/jfrog
  sudo mkdir -p $JFROG_HOME/artifactory/var/etc/
  sudo chown -R user $JFROG_HOME
  cd $JFROG_HOME/artifactory/var/etc/
  touch ./system.yaml
  cd $JFROG_HOME
  chown -R 1030:1030 $JFROG_HOME/artifactory/var
  #docker pull docker.bintray.io/jfrog/artifactory-jcr
  #docker pull docker.bintray.io/jfrog/artifactory-cpp-ce
  #docker pull docker.bintray.io/jfrog/artifactory-oss
  #docker pull docker.bintray.io/jfrog/artifactory-pro
  docker run --name artifactory -v $JFROG_HOME/artifactory/var/:/var/opt/jfrog/artifactory -d -p 8081:8081 -p 8082:8082 docker.bintray.io/jfrog/artifactory-jcr
  echo "URL to Artifactory: http://"$url":8082/ui/"

  #Jenkins
  docker run --name jenkins -v /opt/jenkins:/var/jenkins_home -d -p 8080:8080 -p 50000:50000 jenkins/jenkins:lts
  cat /opt/jenkins/secrets/initialAdminPassword

  #Sonarqube
  #https://hub.docker.com/_/sonarqube/
  docker run --name sonarqube -d -v /opt/sonarqube/conf:/opt/sonarqube/conf -v /opt/sonarqube/data:/opt/sonarqube/data -v /opt/sonarqube/logs:/opt/sonarqube/logs -v /opt/sonarqube/extensions:/opt/sonarqube/extensions -p 9000:9000 sonarqube:7.9-community
}
start_DevOps(){
  url=`hostname -I|cut -d' ' -f1`
  #sudo minikube start
  #sudo minikube dashboard

  #create persistence volume for storage
  #docker volume create DB_JENKINS

  # Artifactory

  # README
  # https://www.jfrog.com/confluence/display/JFROG/Installing+Artifactory
  export JFROG_HOME=/opt/jfrog
  docker start artifactory
  # to access from browser
  echo "URL to Artifactory: http://"$url":8082/ui/"
  echo "Authentication: admin/admin123456"
  echo "docker login 192.168.1.55:8082"
  echo "docker tag hello-world:latest 192.168.1.55:8082/devops-docker-image/hello-world:latest"
  echo "docker push 192.168.1.55:8082/devops-docker-image/hello-world:latest"

  # Jenkins
  docker start jenkins
  echo "URL to Jenkins: http://"$url":8080"

  # Sonarqube
  docker start sonarqube
  echo "URL to Jenkins: http://"$url":9000"

  echo "*******************************"
  echo "*   DevOps Eco-system is ON   *"
  echo "*******************************"
}
stop_DevOps(){
  docker stop artifactory
  docker stop jenkins
  docker stop sonarqube
  echo "*******************************"
  echo "*   DevOps Eco-system is OFF  *"
  echo "*******************************"
}
export JFROG_HOME=/opt/jfrog
export PATH=/opt/cmake/bin:/opt/anaconda3/envs/devops/bin:/opt/java/jdk-11.0.4/bin:/opt/sonar-scanner/sonar-scanner-4.0.0.1744-linux/bin:$PATH
alias kubectl=microk8s.kubectl

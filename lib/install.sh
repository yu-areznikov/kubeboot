#!/usr/bin/env bash

set -e

echo -e "${G}Hi! This is Kubeboot speaking! I will install some packages for you. Stick around!${NONE}"

fun_asdf_install() {
  local plugin_name=$1
  local plugin_version=$2
  local plugin_source=$3

  if [[ $(asdf plugin-list | grep -w "${plugin_name}" | wc -l) -eq 0 ]]; then
  asdf plugin-add "${plugin_name}" "${plugin_source}"
  fi
  if [[ $(asdf list-all "${plugin_name}" | grep -w "${plugin_version}" | wc -l) -eq 0 ]]; then
  echo "There is no ${plugin_version} version for ${plugin_name}!"
  exit 1;
  fi
  asdf install "${plugin_name}" "${plugin_version}" # Idempotent
  asdf global "${plugin_name}" "${plugin_version}"
}

fun_brew_install() {
  local formula_name=$1
  local formula_source=$2

  if [ ! -z "${formula_source}" ]; then
    brew tap "${formula_source}"
  fi

  brew install "${formula_name}"
}


for component in "${PROPOSE_ASDF_INSTALL[@]}"
do
  if [[ "${component}" == "ASDF" ]]; then
    rm -rf $HOME/.asdf
    git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf --branch v0.4.0

    case "${_os}" in
      Linux*)     filepath="$HOME/.bashrc";;
      Mac*)       filepath="$HOME/.bash_profile";;
      *)
    esac
    touch "${filepath}"
  
    if [[ $(cat ${filepath} | fgrep '. $HOME/.asdf/asdf.sh' | wc -l) -eq "0" ]]; then
      echo -e '\n. $HOME/.asdf/asdf.sh' >> ${filepath}
    fi
    chmod +x "$HOME/.asdf/asdf.sh"
    . "$HOME/.asdf/asdf.sh"
  
    if [[ $(cat ${filepath} | fgrep '. $HOME/.asdf/completions/asdf.bash' | wc -l) -eq "0" ]]; then
      echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ${filepath}
    fi
    chmod +x "$HOME/.asdf/completions/asdf.bash"
  fi
  
  if [[ "${component}" == "Helm" ]]; then
    fun_asdf_install helm "${HELM_VERSION}" https://github.com/Antiarchitect/asdf-helm.git
  fi
  
  if [[ "${component}" == "MiniKube" ]]; then
    fun_asdf_install minikube "${MINIKUBE_VERSION}"
  fi
  
  if [[ "${component}" == "kubectl" ]]; then
    fun_asdf_install kubectl "${KUBECTL_VERSION}"
  fi
done

for component in "${PROPOSE_BREW_INSTALL[@]}"
do
  if [[ "${component}" == "HyperKit" ]]; then
    fun_brew_install hyperkit "markeissler/hyperkit"
  fi

  if [[ "${component}" == "unison-fsmonitor" ]]; then
    fun_brew_install "eugenmayer/dockersync/unox" "eugenmayer/dockersync"
  fi
done

set +e

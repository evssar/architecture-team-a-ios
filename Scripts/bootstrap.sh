#!/bin/sh

#git archive --remote=http://bittracker.org/someproject.git HEAD:<path/to/directory/or/file> <filename> | tar -x

# Parameters

NEW_APP_NAME="$1"
PROJECT_GIT_REPO="$2"

if [ -z "${NEW_APP_NAME}" ]; then 
    NEW_APP_NAME="NewAppName"
fi

### ENVIRONMENTS ###

TEMPLATE_PROJECT_GIT_REPO_PATH="https://github.com/Heads-and-Hands/template-project-ios.git"
TEMPLATE_PROGECT_TEMPLATE_SUBPATH="branches/master"
TEMPLATE_PROJECT_DIRECTORY="$(echo ${TEMPLATE_PROGECT_TEMPLATE_SUBPATH} | awk -F '/' '{print $NF}')"

XCODE_TEMPLATES_PATH="/Applications/Xcode.app/Contents/Developer/Library/Xcode/Templates/File Templates"
XCODE_TEMPLATES_GIT_REPO_PATH="https://github.com/Heads-and-Hands/architecture-team-a-ios.git"
XCODE_TEMPLATES_REMOTE_SUBPATH="branches/develop/HHTemplates"
XCODE_TEMPLATES_REMOTE_NAME="$(echo ${XCODE_TEMPLATES_REMOTE_SUBPATH} | awk -F '/' '{print $NF}')"

NEW_APP_NAME="$(echo ${NEW_APP_NAME} | awk '{print tolower($0)}')"

### FASTLANE ENVIRONMENTS ###

PRODUCE_USERNAME="handh.ci@gmail.com"
PRODUCE_APP_IDENTIFIRE="ru.handh.${NEW_APP_NAME}"
MATCH_FILE_URL="git@github.com:Heads-and-Hands/certs-ios.git"

echo "### CHECK DEPENDENCIES ###"

installation_pormpt() {
    RETVAL='False'
    local DEPENDENCY="$1"
    if ! [ -z "${DEPENDENCY}" ]; then
        while true; do 
            read -p "Do you want to install ${DEPENDENCY}? [Yes, No]: " yn
            case $yn in
                [Yy]* ) RETVAL='True'; brew install "${DEPENDENCY}"; break;;
                [Nn]* ) break;;
            esac
        done
    fi
}

check_dependency() {
    RETVAL="True"
    local DEPENDENCY="$1"
    local DEPENDENCY_NAME="$2"
    local IS_BREW_DEPENDENCY="$3"

    if [ -z "${IS_BREW_DEPENDENCY}" ]; then 
        local IS_BREW_DEPENDENCY=False
    fi

    if [ -z "${DEPENDENCY_NAME}" ]; then 
        local DEPENDENCY_NAME="${DEPENDENCY}"
    fi
    
    if ! [ -x "$(command -v ${DEPENDENCY})" ]; then
        RETVAL="False"
        echo "Error: the next dependency requred, but not installed: ${DEPENDENCY_NAME}."
        if $IS_BREW_DEPENDENCY; then
            echo "Use 'brew install ${DEPENDENCY_NAME}' to install."
            installation_pormpt "${DEPENDENCY_NAME}"
        fi
    fi

    if [ "${RETVAL}" == 'True' ]; then 
        echo "Find ${DEPENDENCY_NAME}"
    fi
}

check_dependency brew
if [ "${RETVAL}" != "True" ]; then
     exit 1
else
    echo "Update brew"
    brew update
fi

check_dependency svn subversion True
if [ "${RETVAL}" != "True" ]; then
     exit 1
else
    echo "Update subversion"
    brew upgrade subversion
fi

check_dependency mint mint True
if [ "${RETVAL}" != "True" ]; then
    exit 1
else
    echo "Update mint"
    brew upgrade mint
fi

check_dependency ack ack True
if [ "${RETVAL}" != "True" ]; then
    exit 1
else
    echo "Update ack"
    brew upgrade ack
fi

check_dependency rename rename True
if [ "${RETVAL}" != "True" ]; then
    exit 1
else
    echo "Update rename"
    brew upgrade rename
fi

check_dependency swiftgen swiftgen True
if [ "${RETVAL}" != "True" ]; then
    exit 1
else
    echo "Update swiftgen"
    brew upgrade swiftgen
fi

check_dependency swiftlint swiftlint True
if [ "${RETVAL}" != "True" ]; then
    exit 1
else
    echo "Update swiftgen"
    brew upgrade swiftlint
fi

check_dependency git
if [ "${RETVAL}" != "True" ]; then
    exit 1
fi

check_dependency carthage carthage True
if [ "${RETVAL}" != "True" ]; then
    exit 1
else
    echo "Update carthate"
    brew upgrade carthage
fi

check_dependency git-flow git-flow True
if [ "${RETVAL}" != "True" ]; then
    exit 1
else
    echo "Update git-flow"
    brew upgrade git-flow
fi

echo "### FETCH REMOTE REPOSITORY TEMPLATE ###"

echo "Remove porject directory if exists: ${NEW_APP_NAME}"
rm -rf "${NEW_APP_NAME}"

echo "Clone remote project template ${TEMPLATE_PROJECT_GIT_REPO_PATH}/${TEMPLATE_PROGECT_TEMPLATE_SUBPATH}"
OUTPUT="$(svn ls ${TEMPLATE_PROJECT_GIT_REPO_PATH}/${TEMPLATE_PROGECT_TEMPLATE_SUBPATH})"
echo ${OUTPUT}
if [ ! -z "${OUTPUT}" ]; then
    svn export "${TEMPLATE_PROJECT_GIT_REPO_PATH}/${TEMPLATE_PROGECT_TEMPLATE_SUBPATH}"
fi

echo "Rename ${TEMPLATE_PROJECT_DIRECTORY} to ${NEW_APP_NAME}"
mv "${TEMPLATE_PROJECT_DIRECTORY}" "${NEW_APP_NAME}"
cd "${NEW_APP_NAME}"

echo "Remove 'git' if exists"
rm -rf git

while read fname; do
    RESULT="$(echo "$fname" | awk -F'/' '{print $NF}' | awk -F'.' '{ s = ""; for (i = 1; i < NF; i++) s = s $i "."; print s }')"
    PROJECT_TEMPLATE_NAME="$(echo "${RESULT}" | awk '{print substr($0, 1, length($0)-1)}')"
    echo "INSIDE ${PROJECT_TEMPLATE_NAME}" 
done < <(find . -name "*.xcodeproj")

echo "OUTSIDE ${PROJECT_TEMPLATE_NAME}"

if [ -z "${PROJECT_TEMPLATE_NAME}" ]; then
    echo "Error: Project file does not found"
    exit 1
fi

echo "### RENAME PROJECT TEMPLATES FILES ###"

echo "Rename project template files"
echo "${PROJECT_TEMPLATE_NAME}"
OUTPUT="$(find . -name "${PROJECT_TEMPLATE_NAME}*")"
echo "${OUTPUT}"

while [ ! -z "${OUTPUT}" ]; do
    find . -name "${PROJECT_TEMPLATE_NAME}*" -print0 | xargs -0 rename --subst-all "${PROJECT_TEMPLATE_NAME}" "${NEW_APP_NAME}"
    OUTPUT="$(find . -name "${PROJECT_TEMPLATE_NAME}*")"
    echo "$(OUTPUT)"
done

echo "Rename project template files content"
OUTPUT="$(ack --literal ${PROJECT_TEMPLATE_NAME})"
echo "${OUTPUT}"

while [ ! -z "${OUTPUT}" ]; do
    ack --literal --files-with-matches "${PROJECT_TEMPLATE_NAME}" --print0 | xargs -0 sed -i '' "s/${PROJECT_TEMPLATE_NAME}/${NEW_APP_NAME}/g"
    OUTPUT="$(ack --literal ${PROJECT_TEMPLATE_NAME})"
done

CAPITALIZED_NEW_APP_NAME="$(echo ${NEW_APP_NAME} | awk '{print toupper(substr($1,1,1)) substr($1,2)}')"
CAPITALIZED_PROJECT_TEMPLATE_NAME="$(echo ${PROJECT_TEMPLATE_NAME} | awk '{print toupper(substr($1,1,1)) substr($1,2)}')"

OUTPUT="$(ack --literal ${CAPITALIZED_PROJECT_TEMPLATE_NAME})"
echo "${OUTPUT}"

while [ ! -z "${OUTPUT}" ]; do
    ack --literal --files-with-matches "${CAPITALIZED_PROJECT_TEMPLATE_NAME}" --print0 | xargs -0 sed -i '' "s/${CAPITALIZED_PROJECT_TEMPLATE_NAME}/${CAPITALIZED_NEW_APP_NAME}/g"
    OUTPUT="$(ack --literal ${CAPITALIZED_PROJECT_TEMPLATE_NAME})"
done

echo "### UPDATE BUNDLE ###"

check_dependency bundler
if [ "${RETVAL}" != "True" ]; then
    echo "Use 'gem install bundler' to install"
    exit 1
fi

bundler update

echo "### SWIFTLINT CONFIGURATION ###"

if which mint >/dev/null; then
    mint run realm/swiftlint
    VERSION="$(swiftlint version)"
    echo "realm/swiftlint@${VERSION}" > Mintfile
fi

echo "### FASTLANE CONFIGURATION ###"

fastlane produce

fastlane match development

fastlane match appstore

echo "### GIT CONFIGURATION ###"

git init

git add .

git commit -S -m "Initial commit"

if which git-flow >/dev/null; then
    git-flow init
fi

if ! [ -z "${PROJECT_GIT_REPO}" ]; then
    git remote add origin "${PROJECT_GIT_REPO}"

    git push --set-upstream origin master
    git push --set-upstream origin develop
fi

cd ..

echo "### FETCH XCODE TEMPLATES ###"

rm -rf "${XCODE_TEMPLATES_REMOTE_NAME}"

echo "Clone remote project template ${XCODE_TEMPLATES_GIT_REPO_PATH}/${XCODE_TEMPLATES_REMOTE_SUBPATH}"
OUTPUT="$(svn ls ${XCODE_TEMPLATES_GIT_REPO_PATH}/${XCODE_TEMPLATES_REMOTE_SUBPATH})"
echo ${OUTPUT}
if [ ! -z "${OUTPUT}" ]; then
    svn export "${XCODE_TEMPLATES_GIT_REPO_PATH}/${XCODE_TEMPLATES_REMOTE_SUBPATH}"
fi

while true; do 
    read -p "Do you want to copy remote XCode templates to XCodte templates directory (needs root privileges)? [Yes, No]: " yn
    case $yn in
        [Yy]* ) sudo cp -rf "${XCODE_TEMPLATES_REMOTE_NAME}" "${XCODE_TEMPLATES_PATH}/"; break;;
        [Nn]* ) break;;
    esac
done
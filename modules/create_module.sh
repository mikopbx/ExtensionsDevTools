#!/bin/sh
export LC_CTYPE=C;
if [ "${1}x" != "x" ]; then
	dstClass="$1";
else
	dstClass='ModuleMyNewModPBX';
fi;

echo "$dstClass" | grep -i '^Module' > /dev/null;
resultTest="${?}";
if [ "$resultTest" != "0" ]; then
	dstClass="Module${dstClass}";
fi;

simpleDstClass=$(echo "$dstClass" | sed "s/Module//g");
modDir="$(pwd)/ModuleTemplate";

if [ ! -d "$modDir" ]; then
	rm -rf "$modDir";
	git clone --single-branch --branch develop https://github.com/mikopbx/ModuleTemplate.git
	rm -rf "${modDir}"/.git*;
	rm -rf "${modDir}"/.idea;
	rm -rf "${modDir}"/README*;
	needRemoveSrcDir=1;
fi;
	
srcClass=$(basename "$modDir");

to_lower_case(){
	result=$(echo "$1" | tr '[:upper:]' '[:lower:]');
}
camel_to_dash_style(){
	result=$(echo "$1" | sed 's|\([A-Z][^A-Z]\)| \1|g' | xargs);
	result=$(echo "$result" | tr ' ' '-');
	to_lower_case "$result";
	echo "$result";
}
camel_to_underline_style(){
	result=$(echo "$1" | sed 's|\([A-Z][^A-Z]\)| \1|g' | xargs);
	result=$(echo "$result" | tr ' ' '_');
	to_lower_case "$result";
	echo "$result";
}

srcShotPrefix='mod_tpl_';
dstShotPrefix=$(camel_to_underline_style $dstClass);

srcReq='module-template';
dstReq=$(camel_to_dash_style $dstClass);

# For composer.json "name": "mikopbx/moduletemplate" (Issue #2)
srcComposerName='moduletemplate';
to_lower_case "$dstClass";
dstComposerName="$result";

replace() {
	fileName="$1";
	dstFile=$(echo "$fileName" | sed "s/${srcClass}/${dstClass}/g" | sed "s/${srcReq}/${dstReq}/g" | sed  "s/${srcShotPrefix}/${dstShotPrefix}/g")

  echo "$fileName" | grep "\.php$" > /dev/null;
  isPHP="$?"
  if [ "$isPHP" = "0" ]; then
    oldClassName=$(basename "$fileName" | sed "s/\.php//g");
    newClassName=$(echo "$oldClassName" | sed "s/Template/$simpleDstClass/g");
    if [ "$oldClassName" != "$newClassName" ]; then
      # Тут описываем соответствие-масив, значения для замены в пост обработке.
      wordCounter=$((wordCounter+1));
      dstFile="$(dirname "$dstFile")/${newClassName}.php";
      # Сохарнием переменные для пост обработки.
      eval oldClassName$wordCounter="$oldClassName";
      eval newClassName$wordCounter="$newClassName";

      varName=$(echo "$fileName" | tr '/' 's'| tr '.' 's');
      eval dstFile"$varName"="$dstFile"
    fi;
	fi;

	rm -rf "$dstFile";
	mkdir -p "$(dirname "${dstFile}")";
	sed "s/${srcClass}/${dstClass}/g" < "$fileName" | sed "s/${srcReq}/${dstReq}/g" | sed "s/${srcShotPrefix}/${dstShotPrefix}/g" | sed "s/${srcComposerName}/${dstComposerName}/g" > "$dstFile";
}



replacePartTwo() {
	fileName="$1";
	countVars="$2"

  varName=$(echo "$fileName" | tr '/' 's'| tr '.' 's');
	dstFile=$(eval echo \$dstFile"$varName");
  if [ "$dstFile" = "" ]; then
    return;
  fi;
	echo "Dst $dstFile...";
	while [ "$countVars" != 0 ] ; do
    oldClassName=$(eval echo \$oldClassName"$countVars");
    newClassName=$(eval echo \$newClassName"$countVars");
    if [ "$oldClassName" != '' ]; then
      echo "  -- Replace $oldClassName To $newClassName"
      cp "$dstFile" "${dstFile}.tmp";
      sed "s/${oldClassName}/${newClassName}/g" < "${dstFile}.tmp" > "$dstFile"
      rm "${dstFile}.tmp";
    fi;
    countVars=$((countVars-1));
  done
}

files=$(find "$modDir" -type f)
wordCounter=1;

for fileName in $files
do
	replace "$fileName";
done

for fileName in $files
do
	echo "$fileName" | grep "\.php$" > /dev/null;
  isPHP="$?"
  if [ "$isPHP" = "0" ]; then
    replacePartTwo "$fileName" "$wordCounter";
  fi;
done

if [ "${needRemoveSrcDir}x" != "x" ]; then
	rm -rf "$modDir";
fi;

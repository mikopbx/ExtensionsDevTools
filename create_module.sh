#!/bin/sh

if [ "${1}x" != "x" ]; then
	dst_slass="$1";
else
	dst_slass='ModuleMyNewModPBX';
fi;

echo $dst_slass | grep -i '^Module' > /dev/null
test=$(echo $dst_slass | grep -i '^Module')
if [ "${?}" != "0" ]; then
	dst_slass="Module${dst_slass}";
fi;

mod_dir="$(pwd)/ModuleTemplate";

if [ ! -d $mod_dir ]; then
	rm -rf $mod_dir;
	git clone --single-branch --branch develop https://github.com/mikopbx/ModuleTemplate.git
	rm -rf ${mod_dir}/.git*;
	rm -rf ${mod_dir}/.idea;
	rm -rf ${mod_dir}/README*;
	need_remove_src_dir=1;
fi;
	
src_class=$(basename $mod_dir);

to_lower_case(){
	result=$(echo "$1" | tr '[:upper:]' '[:lower:]');
}
camel_to_dash_style(){
	result=$(echo "$1" | sed 's|\([A-Z][^A-Z]\)| \1|g' | xargs);
	result=$(echo "$result" | tr ' ' '-');
	to_lower_case $result;
	echo $result;	
}
camel_to_underline_style(){
	result=$(echo "$1" | sed 's|\([A-Z][^A-Z]\)| \1|g' | xargs);
	result=$(echo "$result" | tr ' ' '_');
	to_lower_case $result;
	echo $result;
}

src_shot='mod_tpl_';
dst_shot=$(camel_to_underline_style $dst_slass);

src_req='module-template';
dst_req=$(camel_to_dash_style $dst_slass);

replace() {
	fname=$1;
	dst_file=$(echo $fname | sed "s/${src_class}/${dst_slass}/g" | sed "s/${src_req}/${dst_req}/g" | sed  "s/${src_shot}/${dst_shot}/g")
	rm -rf $dst_file;
	mkdir -p $(dirname "${dst_file}");
	cat $fname | sed "s/${src_class}/${dst_slass}/g" | sed "s/${src_req}/${dst_req}/g" | sed  "s/${src_shot}/${dst_shot}/g" > $dst_file;
}

files=$(find $mod_dir -type f)

for fname in $files
do
	replace $fname;	
done

dst_lib_dir="$(pwd)/$dst_slass/Lib";
res_file=$(echo "${dst_slass}" | sed 's/Module//');
mv "$dst_lib_dir/TemplateConf.php" "${dst_lib_dir}/${res_file}Conf.php"
mv "$dst_lib_dir/TemplateMain.php" "${dst_lib_dir}/${res_file}Main.php"
mv "$dst_lib_dir/WorkerTemplateAMI.php" "${dst_lib_dir}/Worker${res_file}AMI.php"
mv "$dst_lib_dir/WorkerTemplateMain.php" "${dst_lib_dir}/Worker${res_file}Main.php"

if [ "${need_remove_src_dir}x" != "x" ]; then
	rm -rf $mod_dir;
fi;

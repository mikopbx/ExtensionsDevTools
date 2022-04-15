Скрипт **create_module.sh** позволяет создать новый модуль с заданным именем. 
Зависимости:
 - git

Используются утилиты:
 - echo 
 - sed 
 - tr 
 - xargs 
 - find 
 - dirname 
 - rm 
 - mkdir

Перед использованием скрипта перейдите в рабочий каталог:

`work_dir='/path/to/dir';
mkdir -p $work_dir;
cd $work_dir;`

Если на ПК нет предустановленного git, то просто разместите в рабочий каталог файлы из репозитория [ModuleTemplate](https://github.com/mikopbx/ModuleTemplate.git "ModuleTemplate")

Использование:

`create_module.sh 'ModuleMyNewModPBX'`
Первым параметром передается имя будущего модуля. **ВАЖНО**: имя должно начинаться с "**Module**". 


###ENGLISH:
___

The script **create_module.sh** lets you create a new module with an individual name based on the source of the [ModuleTemplate](https://github.com/mikopbx/ModuleTemplate.git "ModuleTemplate").

####Required:
- git (mod_replace.py is using gitpython - you can install it with `pip install gitpython`)

####OS functions used:
- echo
- sed
- tr
- xargs
- find
- dirname
- rm
- mkdir

Before using the script, go to the working directory:

`work_dir='/path/to/dir';
mkdir -p $work_dir;
cd $work_dir;`

If there is no pre-installed GIT on the PC, just place the files from the repository into the working directory [ModuleTemplate](https://github.com/mikopbx/ModuleTemplate.git "ModuleTemplate")

Use the script:

`create_module.sh 'ModuleMyNewModPBX'`
The first parameter is passed to the name of the future module. **IMPORTANT**: The name must begin with "**Module**". 
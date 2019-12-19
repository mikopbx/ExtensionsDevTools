Скрипт create_module.sh позволяет создать новый модуль с заданным именем. 
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

work_dir='/path/to/dir';
mkdir -p $work_dir;
cd $work_dir;

Если на ПК нет предустановленного git, то просто разместите в рабочий каталог файлы из репозитория https://github.com/mikopbx/ModuleTemplate.git

Использование:

create_module.sh 'ModuleMyNewModPBX'
Первым параметром передается имя будущего модуля. ВАЖНО: имя должно начинаться с "Module". 
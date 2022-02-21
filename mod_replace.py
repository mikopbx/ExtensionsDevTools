import os
import re
import shutil
import stat

from git import Repo
from sys import argv

START_WORD = 'Module'
DIR_NAME = 'ModuleMyNewModPBX'

NAME_TO_CHANGE = 'Template'
NAME_TO_CHANGE_IN_DASH_STYLE = 'module-template'
NAME_TO_CHANGE_IN_UNDERLINE_STYLE_SHORT = 'mod_tpl'
NAME_TO_CHANGE_IN_UNDERLINE_STYLE = 'module_template'

GITHUB_URL = "https://github.com/mikopbx/ModuleTemplate.git"
DELETE_FILE_1 = 'README.md'
DELETE_FILE_2 = '.gitignore'
DELETE_DIR = '.git'


def name_to_dash_style(replacement_name):
    dash_style_name = re.sub(r'([A-Z])', r' \1', replacement_name).split()
    file_name_to_dash_style = ""
    for word in dash_style_name:
        file_name_to_dash_style = file_name_to_dash_style + word.lower() + '-'
    return file_name_to_dash_style


def name_to_underline_style(replacement_name):
    underline_style_name = re.sub(r'([A-Z])', r' \1', replacement_name).split()
    file_name_to_underline_style = ""
    for word in underline_style_name:
        file_name_to_underline_style = file_name_to_underline_style + word.lower() + '_'
    return file_name_to_underline_style


def func_rename(file_name, str_to_replace, replacement_name):
    old_name = file_name
    new_name = file_name.replace(str_to_replace, replacement_name)
    os.rename(old_name, new_name)


def func_change_file(file_name, str_to_replace, replacement_name):
    file_to_change = ''
    with open(file_name, "rt") as file:
        file_to_change = file.read()
    with open(file_name, "wt") as file:
        file_to_change = file_to_change.replace(str_to_replace, replacement_name)
        file.write(file_to_change)


def onerror(func, path, exc_info):
    if not os.access(path, os.W_OK):
        os.chmod(path, stat.S_IWUSR)
        func(path)
    else:
        raise


script, input_name = argv

if input_name != '':
    if input_name[:6] == START_WORD:
        dir_name = input_name
    else:
        exit()
else:
    dir_name = DIR_NAME

if os.path.isdir(dir_name):
    shutil.rmtree(dir_name)

os.mkdir(dir_name)
os.chdir(dir_name)
Repo.clone_from(GITHUB_URL, os.getcwd())
os.remove(DELETE_FILE_1)
os.remove(DELETE_FILE_2)
shutil.rmtree(DELETE_DIR, onerror=onerror)
os.chdir(os.path.dirname(os.getcwd()))

FileRename = dir_name[6:]
TextInDashStyle = name_to_dash_style(dir_name)
TextInUnderlineStyle = name_to_underline_style(dir_name)

filelist = []
for root, dirs, files in os.walk(dir_name):
    for file in files:
        filelist.append(os.path.join(root, file))

for name in filelist:
    if name.find(DELETE_DIR) == -1:
        func_change_file(name, NAME_TO_CHANGE, FileRename)
        func_change_file(name, NAME_TO_CHANGE_IN_DASH_STYLE, TextInDashStyle[:-1])
        func_change_file(name, NAME_TO_CHANGE_IN_UNDERLINE_STYLE_SHORT, TextInUnderlineStyle[:-1])
        func_change_file(name, NAME_TO_CHANGE_IN_UNDERLINE_STYLE, TextInUnderlineStyle[:-1])

    if not name.find(NAME_TO_CHANGE) == -1:
        func_rename(name, NAME_TO_CHANGE, FileRename)
    elif not name.find(NAME_TO_CHANGE_IN_DASH_STYLE) == -1:
        func_rename(name, NAME_TO_CHANGE_IN_DASH_STYLE, TextInDashStyle[:-1])

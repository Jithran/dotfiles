# include all sh files in the .bashrc.d folder. 
# This method ensures we don't need to touch the .bashrc file as it includes this one.
# All Aliases are places in the ~/.bashrc.d/10-aliases.sh file 

for f in ~/.bashrc.d/*.sh; do [ -r "$f" ] && . "$f"; done

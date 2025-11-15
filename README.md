# BashFM - a cli file navigator written in bash

# Preview

<center>

https://github.com/user-attachments/assets/6bd0a286-66b5-4a3a-b0e5-2fc45643bde4

</center>

# Features
- Implemented a fast interactive TUI with smooth scroll.
- supports media preview and file preview
- Can search through files in the pwd
- Can toggle hidden files

# Dependencies

- ffmpeg & chafa
```bash
sudo apt install ffmpeg
sudo apt install chafa
```
- Or build from source
  - https://github.com/FFmpeg/FFmpeg
  - https://github.com/hpjansson/chafa

# Default keybindings
- `/` : Enter the search mode
- `Enter` : To confirm search text
- `Esc` : To exit search mode
- `.` : Toggle hidden files
- `h` & `←` : Navigate to the previous Directory
- `j` & `↓` : Down
- `k` & `↑` : Up
- `l` & `→` : Open the selected File or Directory

# Installation
- clone the project
```bash
git clone https://github.com/Aarnya-Jain/bashfm.git
```
- get into the project directory
```bash
cd bashfm
```
- Run the installation script
```bash
./install.sh
```
- Use bashfm after installation
```bash
bashfm
```
**( Note : Keep the bashfm folder to cleanly remove the project )**

# Uninstalling
- get into the bashfm folder and run the uninstall script
```bash
./uninstall.sh
```
- ( In case the folder is deleted : manually delete the files from )
```bash
/usr/local/bin/bashfm
.config/bashfm
```

# Ps -
- This is a minimal file manager that I built to learn bash .
- Though not full fledged , could be used ..
- Feel free to contribute and suggest changes : ]
- Do Give a star if you like it .

Output complexity_trap.mp4
Require nvim

Set FontSize 16
Set Width 1200
Set Height 800

Hide
Type "rm -f .*.swp" Enter
Type "cp scene1_naive.kt Solution.kt" Enter
Type "nvim -n -u setup_nvim.lua" Enter
Sleep 1s
Type ":DojoStart sliding_window" Enter
Sleep 1s
Type "11G"
Show

Sleep 1s
Type ":DojoValidate" Enter
Sleep 5s

Type "k" Sleep 500ms
Type "k" Sleep 500ms
Type "d4k"
Sleep 1.5s

Type "O"
Type@75ms "        // Jump the pointer instantly in O(1)" Enter
Type@75ms "        left = maxOf(left, map.getOrDefault(char, -1) + 1)" Escape

Sleep 1s
Type ":DojoValidate" Enter

Sleep 4s

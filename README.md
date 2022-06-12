# CombustionRotate

This addon is meant to help mages to setup combustion rotation and give them real time feedback about it.

It also allow non-mage raid leaders to easily manage, report and watch the combustion rotation live. 

This addon will work even if you are the only one using it in your raid. (With some combat log range limitation, see bellow)

![Screenshot](docs/screenshots/screenshot.png "screenshot") ![Screenshot](docs/screenshots/drag.gif "drag and drop gif")  ![Screenshot](docs/screenshots/rotation.gif "rotation gif")

## Usage
 
Use `/comb` for options

You must be in a raid for mages to get registered and displayed by the addon.

First step is to setup your combustion rotation using drag & drop on mages, if others mages use the addon too, changes will be synced. 
You may use the trumpet button to report the rotation in raid chat so others players without the addon can know what you planned. 
Please note the backup group is hidden if empty but you can still drag mages into it.

You can now just pull the boss and trigger combustion, CombustionRotate will track the rotation and use a purple color on the next mage that should trigger combustion. CombustionRotate will play sounds when the previous mage started combustion and you are the next, as well as when you have to trigger your combustion CD.

**Warning** : if all of your mages does not use the addon, make sure someone with the addon stay within 45m range of mages without the addon or you won't be able to register their combustion. MC and AQ40 encounters might lead to range issues. However, I didn't had any complain about this yet  :) 

You can use the reset button in the top bar to reset the rotation status

You may add the `/comb backup` command to a macro that you can use when you are unable to start combustion and you need some help,
It will whisper all backup mages the fail message.

The `/comb check` command allows you to list CombustionRotate versions used by others players

# Powershell Configurations
This repository contains my PowerShell custom configurations/themes and profile settings for future references. 

This was inspired from the great <a href="https://www.hanselman.com/blog/my-ultimate-powershell-prompt-with-oh-my-posh-and-the-windows-terminal" target="_blank">Scott Hanselman</a>



## HOW TO USE

Fire up PowerShell!

Clone this Repo

```
git clone https://github.com/rishigohil/powershell-configurations.git
```


Get <a href="https://ohmyposh.dev/" target="_blank">OH MY POSH</a> for this customization (They have got impressive themes!)
```
winget install JanDeDobbeleer.OhMyPosh
# restart shell to reload PATH
```

Get the profile from this repo and place it in a secured folder and edit your PowerShell PROFILE and add following line in it.

```
oh-my-posh --init --shell pwsh --config C:/personal/utils/pwsh/ohmyposhv3-2.json | Invoke-Expression
```

Restart your powershell or reload your profile

```
. $PROFILE
```


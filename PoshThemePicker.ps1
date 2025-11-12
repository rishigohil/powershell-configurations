# ============================================
# Oh My Posh Interactive Theme Picker
# ============================================
# Add this to your PowerShell profile to enable theme switching
#
# Usage:
#   Select-PoshTheme           # Opens interactive picker
#   Select-PoshTheme -Preview  # Preview each theme before selecting
#   theme                      # Short alias
# ============================================

function Select-PoshTheme {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ThemeFolder = "C:\Personal\utils\powershell-configurations\themes",
        
        [Parameter()]
        [switch]$Preview,
        
        [Parameter()]
        [switch]$IncludeBuiltIn
    )
    
    # Collect themes from your custom folder
    $customThemes = @()
    if (Test-Path $ThemeFolder) {
        $customThemes = Get-ChildItem -Path $ThemeFolder -Filter "*.json" | 
            Select-Object @{Name='Name';Expression={$_.BaseName}}, 
                         @{Name='Path';Expression={$_.FullName}},
                         @{Name='Source';Expression={'Custom'}}
    }
    
    # Optionally include built-in themes
    $builtInThemes = @()
    if ($IncludeBuiltIn -and $env:POSH_THEMES_PATH) {
        $builtInThemes = Get-ChildItem -Path $env:POSH_THEMES_PATH -Filter "*.omp.json" | 
            Select-Object @{Name='Name';Expression={$_.BaseName}}, 
                         @{Name='Path';Expression={$_.FullName}},
                         @{Name='Source';Expression={'Built-in'}}
    }
    
    # Combine all themes
    $allThemes = $customThemes + $builtInThemes
    
    if ($allThemes.Count -eq 0) {
        Write-Host "No themes found!" -ForegroundColor Red
        Write-Host "Theme folder: $ThemeFolder" -ForegroundColor Yellow
        Write-Host "Use -IncludeBuiltIn to see built-in themes" -ForegroundColor Yellow
        return
    }
    
    # Display menu
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     Oh My Posh Theme Selector 🎨      ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $allThemes.Count; $i++) {
        $theme = $allThemes[$i]
        $number = $i + 1
        $sourceColor = if ($theme.Source -eq 'Custom') { 'Green' } else { 'DarkGray' }
        
        Write-Host "  [$number] " -NoNewline -ForegroundColor Yellow
        Write-Host $theme.Name -NoNewline -ForegroundColor White
        Write-Host " ($($theme.Source))" -ForegroundColor $sourceColor
    }
    
    Write-Host "`n  [0] " -NoNewline -ForegroundColor Yellow
    Write-Host "Cancel" -ForegroundColor Red
    Write-Host ""
    
    # Get user selection
    do {
        $selection = Read-Host "Select a theme number"
        $selectionNum = $null
        $validInput = [int]::TryParse($selection, [ref]$selectionNum)
    } while (-not $validInput -or $selectionNum -lt 0 -or $selectionNum -gt $allThemes.Count)
    
    # Cancel if 0
    if ($selectionNum -eq 0) {
        Write-Host "Theme selection cancelled." -ForegroundColor Yellow
        return
    }
    
    # Get selected theme
    $selectedTheme = $allThemes[$selectionNum - 1]
    
    # Preview mode
    if ($Preview) {
        Write-Host "`nPreviewing: " -NoNewline
        Write-Host $selectedTheme.Name -ForegroundColor Cyan
        Write-Host "Press any key to apply, or Ctrl+C to cancel..." -ForegroundColor Yellow
        oh-my-posh init pwsh --config $selectedTheme.Path | Invoke-Expression
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
    
    # Apply the theme
    oh-my-posh init pwsh --config $selectedTheme.Path | Invoke-Expression
    
    Write-Host "`n✓ Theme applied: " -NoNewline -ForegroundColor Green
    Write-Host $selectedTheme.Name -ForegroundColor Cyan
    Write-Host "  Path: $($selectedTheme.Path)" -ForegroundColor DarkGray
    
    # Ask if user wants to make it permanent
    Write-Host "`nMake this your default theme? (y/n): " -NoNewline -ForegroundColor Yellow
    $makeDefault = Read-Host
    
    if ($makeDefault -eq 'y' -or $makeDefault -eq 'Y') {
        Set-PoshThemeAsDefault -ThemePath $selectedTheme.Path
    }
}

function Set-PoshThemeAsDefault {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ThemePath
    )
    
    $profileContent = Get-Content $PROFILE -Raw
    
    # Find and replace the oh-my-posh init line
    $pattern = 'oh-my-posh init pwsh --config ".*?" \| Invoke-Expression'
    $replacement = "oh-my-posh init pwsh --config `"$ThemePath`" | Invoke-Expression"
    
    if ($profileContent -match $pattern) {
        $newContent = $profileContent -replace $pattern, $replacement
        Set-Content -Path $PROFILE -Value $newContent
        Write-Host "✓ Profile updated! Theme will load on next PowerShell start." -ForegroundColor Green
    } else {
        Write-Host "⚠ Could not find oh-my-posh init line in profile." -ForegroundColor Yellow
        Write-Host "Add this line manually to your profile:" -ForegroundColor Yellow
        Write-Host $replacement -ForegroundColor Cyan
    }
}

function Get-CurrentPoshTheme {
    $profileContent = Get-Content $PROFILE -Raw
    if ($profileContent -match 'oh-my-posh init pwsh --config "([^"]+)"') {
        $themePath = $matches[1]
        $themeName = [System.IO.Path]::GetFileNameWithoutExtension($themePath)
        
        Write-Host "Current theme: " -NoNewline
        Write-Host $themeName -ForegroundColor Cyan
        Write-Host "Path: $themePath" -ForegroundColor DarkGray
    } else {
        Write-Host "Could not detect current theme from profile." -ForegroundColor Yellow
    }
}

function Copy-PoshThemeToFolder {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ThemeName,
        
        [Parameter()]
        [string]$DestinationFolder = "C:\Personal\utils\powershell-configurations\themes"
    )
    
    # Ensure destination folder exists
    if (-not (Test-Path $DestinationFolder)) {
        New-Item -ItemType Directory -Path $DestinationFolder -Force | Out-Null
        Write-Host "✓ Created theme folder: $DestinationFolder" -ForegroundColor Green
    }
    
    # Find theme in built-in themes
    $sourceTheme = Get-ChildItem -Path $env:POSH_THEMES_PATH -Filter "$ThemeName.omp.json" -ErrorAction SilentlyContinue
    
    if ($sourceTheme) {
        $destPath = Join-Path $DestinationFolder "$ThemeName.json"
        Copy-Item -Path $sourceTheme.FullName -Destination $destPath
        Write-Host "✓ Copied theme to: $destPath" -ForegroundColor Green
    } else {
        Write-Host "✗ Theme not found: $ThemeName" -ForegroundColor Red
        Write-Host "Available built-in themes:" -ForegroundColor Yellow
        Get-ChildItem -Path $env:POSH_THEMES_PATH -Filter "*.omp.json" | 
            Select-Object -First 10 BaseName | 
            ForEach-Object { Write-Host "  - $($_.BaseName)" -ForegroundColor Gray }
    }
}

# Aliases for convenience
Set-Alias -Name theme -Value Select-PoshTheme
Set-Alias -Name poshtheme -Value Select-PoshTheme
Set-Alias -Name current-theme -Value Get-CurrentPoshTheme
Set-Alias -Name copy-theme -Value Copy-PoshThemeToFolder

# ============================================
# Quick Setup Instructions:
# ============================================
# 
# 1. Create your themes folder:
#    New-Item -ItemType Directory -Path "C:\Personal\utils\powershell-configurations\themes" -Force
#
# 2. Copy your current theme there:
#    Copy-Item "C:\Personal\utils\powershell-configurations\ohmyposhv3-v2.json" `
#              "C:\Personal\utils\powershell-configurations\themes\my-theme.json"
#
# 3. Copy some built-in themes you like:
#    copy-theme "atomic"
#    copy-theme "jandedobbeleer"
#    copy-theme "powerlevel10k_rainbow"
#
# 4. Add to your profile (add this line near the top):
#    . "C:\Path\To\PoshThemePicker.ps1"
#
# 5. Use it:
#    theme                    # Opens picker
#    theme -IncludeBuiltIn    # Shows built-in themes too
#    theme -Preview           # Preview before applying
#    current-theme            # See what theme you're using
#
# ============================================

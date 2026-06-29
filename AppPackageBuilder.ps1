#requires -Version 5.1

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

function Show-Error {
    param([string]$Message)
    [System.Windows.MessageBox]::Show($Message, 'Erro', 'OK', 'Error') | Out-Null
}

function Show-Info {
    param([string]$Message)
    [System.Windows.MessageBox]::Show($Message, 'Gerador de pacotes', 'OK', 'Information') | Out-Null
}

function Get-MsiProperty {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Property
    )

    $installer = $null
    $database = $null
    $view = $null
    $record = $null
    try {
        $installer = New-Object -ComObject WindowsInstaller.Installer
        $database = $installer.GetType().InvokeMember(
            'OpenDatabase', 'InvokeMethod', $null, $installer, @($Path, 0)
        )
        $query = "SELECT ``Value`` FROM ``Property`` WHERE ``Property``='$($Property.Replace("'", "''"))'"
        $view = $database.GetType().InvokeMember('OpenView', 'InvokeMethod', $null, $database, @($query))
        $view.GetType().InvokeMember('Execute', 'InvokeMethod', $null, $view, $null) | Out-Null
        $record = $view.GetType().InvokeMember('Fetch', 'InvokeMethod', $null, $view, $null)
        if ($null -eq $record) { return '' }
        return [string]$record.GetType().InvokeMember('StringData', 'GetProperty', $null, $record, @(1))
    }
    finally {
        foreach ($item in @($record, $view, $database, $installer)) {
            if ($null -ne $item -and [Runtime.InteropServices.Marshal]::IsComObject($item)) {
                [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($item)
            }
        }
    }
}

function Get-InstallerMetadata {
    param([Parameter(Mandatory)][string]$Path)

    $extension = [IO.Path]::GetExtension($Path).ToLowerInvariant()
    if ($extension -eq '.msi') {
        return [pscustomobject]@{
            Type = 'MSI'
            Manufacturer = Get-MsiProperty $Path 'Manufacturer'
            ProductName = Get-MsiProperty $Path 'ProductName'
            ProductVersion = Get-MsiProperty $Path 'ProductVersion'
            ProductCode = Get-MsiProperty $Path 'ProductCode'
        }
    }
    if ($extension -eq '.exe') {
        $versionInfo = (Get-Item -LiteralPath $Path).VersionInfo
        return [pscustomobject]@{
            Type = 'EXE'
            Manufacturer = [string]$versionInfo.CompanyName
            ProductName = [string]$versionInfo.ProductName
            ProductVersion = [string]$versionInfo.ProductVersion
            ProductCode = ''
        }
    }
    throw 'Selecione um instalador MSI ou EXE.'
}

function ConvertTo-PackageToken {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) { return '' }
    $normalized = $Value.Normalize([Text.NormalizationForm]::FormD)
    $withoutMarks = -join ($normalized.ToCharArray() | Where-Object {
        [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne
            [Globalization.UnicodeCategory]::NonSpacingMark
    })
    $parts = [regex]::Matches($withoutMarks, '[A-Za-z0-9]+') | ForEach-Object { $_.Value }
    return -join ($parts | ForEach-Object {
        if ($_.Length -eq 1) { $_.ToUpperInvariant() }
        else { $_.Substring(0, 1).ToUpperInvariant() + $_.Substring(1) }
    })
}

function Get-SuggestedApplicationName {
    param([string]$ProductName, [string]$Version)

    $result = $ProductName.Trim()
    $versions = New-Object System.Collections.Generic.List[string]
    if (-not [string]::IsNullOrWhiteSpace($Version)) {
        $versions.Add($Version)
        $segments = [System.Collections.Generic.List[string]]@($Version -split '\.')
        while ($segments.Count -gt 1 -and $segments[$segments.Count - 1] -match '^0+$') {
            $segments.RemoveAt($segments.Count - 1)
            $trimmed = $segments -join '.'
            if ($trimmed) { $versions.Add($trimmed) }
        }
    }
    foreach ($candidate in ($versions | Sort-Object Length -Descending)) {
        $result = [regex]::Replace($result, '\s+' + [regex]::Escape($candidate) + '(?=\s|$)', '', 'IgnoreCase')
    }
    $result = [regex]::Replace($result, '\s*\((?:x64|x86|64-bit|32-bit)[^)]*\)\s*$', '', 'IgnoreCase')
    $result = [regex]::Replace($result, '\s+', ' ').Trim()
    if ([string]::IsNullOrWhiteSpace($result)) { return $ProductName.Trim() }
    return $result
}

function ConvertTo-PSDoubleQuotedValue {
    param([string]$Value)
    if ($null -eq $Value) { return '' }
    return $Value.Replace('`', '``').Replace('$', '`$').Replace('"', '`"')
}

function Set-AppVariable {
    param([string]$Content, [string]$Name, [string]$Value)
    $escaped = ConvertTo-PSDoubleQuotedValue $Value
    $pattern = "(?m)^\s*\`$$([regex]::Escape($Name))\s*=\s*.*$"
    $replacement = '$' + $Name + ' = "' + $escaped + '"'
    return [regex]::Replace($Content, $pattern, { param($match) $replacement }, 1)
}

function Set-CommentValue {
    param([string]$Content, [string]$Label, [string]$Value)
    $pattern = "(?m)^(#\s*" + [regex]::Escape($Label) + "\s*:).*$"
    return [regex]::Replace($Content, $pattern, {
        param($match)
        $match.Groups[1].Value + ' ' + $Value
    }, 1)
}

function Set-ScriptBody {
    param([string]$Content, [string]$Body)
    $pattern = '(?s)(# Script START \(Code Here\)\r?\n#-+\r?\n).*?(\r?\n#-+\r?\n# Script END)'
    if (-not [regex]::IsMatch($Content, $pattern)) {
        throw 'Os marcadores START/END não foram encontrados no template.'
    }
    return [regex]::Replace($Content, $pattern, {
        param($match)
        $match.Groups[1].Value + "`r`n" + $Body.Trim() + "`r`n" + $match.Groups[2].Value
    }, 1)
}

function Add-DebugMode {
    param([string]$Content)
    if ($Content -match '(?m)^\$Global:DebugMode\s*=') { return $Content }
    return [regex]::Replace($Content, '(?m)^(\$Global:Computer_info\s*=.*)$', {
        param($match)
        $match.Groups[1].Value + "`r`n" + '$Global:DebugMode = $true'
    }, 1)
}

function New-ProcessCommands {
    param([string]$Processes)
    $items = $Processes -split '[,;\r\n]+' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    if (@($items).Count -eq 0) { return '# Nenhum processo informado.' }
    return ($items | ForEach-Object {
        'FN_Close_Process -ProcessName "' + (ConvertTo-PSDoubleQuotedValue $_) + '"'
    }) -join "`r`n"
}

function New-RegistryRemovalBlock {
    param(
        [bool]$RemoveAllVersions,
        [string]$DisplayNamePattern,
        [string]$ProductCode,
        [string]$ExitVariable
    )

    if ($RemoveAllVersions) {
        $safePattern = ConvertTo-PSDoubleQuotedValue $DisplayNamePattern
        return @"
`$Installed = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall |
    Get-ItemProperty |
    Where-Object { `$_.DisplayName -like "$safePattern*" -and `$_.UninstallString -match 'MsiExec' }

foreach (`$app in `$Installed) {
    FN_Update_LogFile -Message "Removing detected version: `$(`$app.DisplayName)"
    `$$ExitVariable = FN_MSI_Installer -Action UnInstall -ProductCode `$app.PSChildName
    FN_Update_LogFile -Message "Uninstall ExitCode: `$$ExitVariable"
}
"@
    }

    $safeCode = ConvertTo-PSDoubleQuotedValue $ProductCode
    return @"
`$ProductCode = "$safeCode"
FN_Update_LogFile -Message "Removing selected ProductCode: `$ProductCode"
`$$ExitVariable = FN_MSI_Installer -Action UnInstall -ProductCode `$ProductCode
FN_Update_LogFile -Message "Uninstall ExitCode: `$$ExitVariable"
"@
}

function New-ExeUninstallBlock {
    param(
        [string]$UninstallPath,
        [string]$UninstallArguments,
        [string]$ExitVariable
    )

    $safePath = ConvertTo-PSDoubleQuotedValue $UninstallPath
    $safeArguments = ConvertTo-PSDoubleQuotedValue $UninstallArguments
    return @"
`$UninstallerPath = "$safePath"
if (Test-Path -LiteralPath `$UninstallerPath) {
    FN_Update_LogFile -Message "Running EXE uninstaller: `$UninstallerPath"
    `$$ExitVariable = FN_Run_EXE_File -EXEFilePath `$UninstallerPath -Arguments "$safeArguments" -Wait All
} else {
    FN_Update_LogFile -Message "EXE uninstaller not found; nothing to remove: `$UninstallerPath"
    `$$ExitVariable = 0
}
"@
}

function New-Package {
    param([hashtable]$Data)

    $templatePath = Join-Path $PSScriptRoot 'DWP - Application Template'
    if (-not (Test-Path -LiteralPath $templatePath -PathType Container)) {
        throw "Template não encontrado: $templatePath"
    }

    if ($Data.CompanyToken -notmatch '^[A-Za-z0-9]+$' -or $Data.AppToken -notmatch '^[A-Za-z0-9]+$') {
        throw 'Os nomes usados na pasta devem conter apenas letras e números, sem espaços.'
    }

    $folderName = '{0}_{1}_{2}_{3}_{4}' -f $Data.CompanyToken, $Data.AppToken,
        $Data.Version, $Data.System, $Data.Language
    $invalidChars = [IO.Path]::GetInvalidFileNameChars()
    if ($folderName.IndexOfAny($invalidChars) -ge 0) {
        throw 'O nome final da pasta contém caracteres inválidos.'
    }

    $appPath = Join-Path $Data.OutputRoot $folderName
    if (Test-Path -LiteralPath $appPath) {
        throw "A pasta de destino já existe. Nada foi sobrescrito:`n$appPath"
    }

    Copy-Item -LiteralPath $templatePath -Destination $appPath -Recurse
    try {
        $progPath = Join-Path $appPath 'Prog'
        New-Item -ItemType Directory -Path $progPath -Force | Out-Null
        Copy-Item -LiteralPath $Data.InstallerPath -Destination (Join-Path $progPath ([IO.Path]::GetFileName($Data.InstallerPath)))

        $installPath = Join-Path $appPath 'Install.ps1'
        $uninstallPath = Join-Path $appPath 'Uninstall.ps1'
        $install = Get-Content -LiteralPath $installPath -Raw
        $uninstall = Get-Content -LiteralPath $uninstallPath -Raw

        $values = [ordered]@{
            APP_Company = $Data.CompanyToken
            APP_Name = $Data.AppName
            APP_Version = $Data.Version
            APP_System = $Data.System
            APP_Language = $Data.Language
            APP_InternalVersion = $Data.InternalVersion
        }
        foreach ($entry in $values.GetEnumerator()) {
            $install = Set-AppVariable $install $entry.Key $entry.Value
        }

        $detectionFile = if ([string]::IsNullOrWhiteSpace($Data.DetectionPath)) {
            ''
        } else {
            '"' + $Data.DetectionPath + '"'
        }
        $install = Set-CommentValue $install 'File' $detectionFile
        $install = Set-CommentValue $install 'Version' $Data.DetectionVersion
        $registryDetection = if ($Data.InstallerType -eq 'MSI') {
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($Data.ProductCode)"
        } else { '' }
        $install = Set-CommentValue $install 'Registry' $registryDetection
        $install = Set-CommentValue $install 'Install for system' 'x'
        $install = Set-CommentValue $install 'Install for user' ''
        $install = Set-CommentValue $install 'Whether or not a user is logged on' 'x'
        $install = Set-CommentValue $install 'Hidden' 'x'
        $install = Add-DebugMode $install
        $uninstall = Add-DebugMode $uninstall

        $processCommands = New-ProcessCommands $Data.Processes
        if ($Data.InstallerType -eq 'MSI') {
            $preRemoval = New-RegistryRemovalBlock $Data.RemoveAllVersions $Data.DisplayPattern $Data.ProductCode 'UninstallExit'
            $uninstallRemoval = New-RegistryRemovalBlock $Data.RemoveAllVersions $Data.DisplayPattern $Data.ProductCode 'ExitCode'
        } else {
            $preRemoval = New-ExeUninstallBlock $Data.UninstallPath $Data.UninstallArguments 'UninstallExit'
            $uninstallRemoval = New-ExeUninstallBlock $Data.UninstallPath $Data.UninstallArguments 'ExitCode'
        }
        $installerName = ConvertTo-PSDoubleQuotedValue ([IO.Path]::GetFileName($Data.InstallerPath))
        $arguments = ConvertTo-PSDoubleQuotedValue $Data.InstallArguments

        if ($Data.InstallerType -eq 'MSI') {
            $installCommand = @"
`$MSI = "$installerName"
FN_Update_LogFile -Message "Installing `$MSI"
`$ExitCode = FN_MSI_Installer -Action Install -MSIFilePath "`$(`$Util_Info.Path_Prog)\`$MSI" -Additional_Arguments "$arguments"
"@
        } else {
            $installCommand = @"
`$EXE = "$installerName"
FN_Update_LogFile -Message "Installing `$EXE"
`$ExitCode = FN_Run_EXE_File -EXEFilePath "`$(`$Util_Info.Path_Prog)\`$EXE" -Arguments "$arguments" -Wait All
"@
        }

        $installBody = @"
`$ExitCode = 0
FN_Update_LogFile -Message "Starting Install process"
FN_Update_LogFile -Message "Running pre-uninstall step"

# Fechar processos
$processCommands
Start-Sleep -Seconds 5

$preRemoval
Start-Sleep -Seconds 5

$installCommand
FN_Update_LogFile -Message "Install process finished"
"@

        $uninstallBody = @"
`$ExitCode = 0
FN_Update_LogFile -Message "Starting Uninstall process"

# Fechar processos
$processCommands
Start-Sleep -Seconds 5

$uninstallRemoval
FN_Update_LogFile -Message "Uninstall process finished"
"@

        $install = Set-ScriptBody $install $installBody
        $uninstall = Set-ScriptBody $uninstall $uninstallBody
        Set-Content -LiteralPath $installPath -Value $install -Encoding UTF8
        Set-Content -LiteralPath $uninstallPath -Value $uninstall -Encoding UTF8

        $manifest = [ordered]@{
            GeneratedAt = (Get-Date).ToString('s')
            SourceInstaller = [IO.Path]::GetFileName($Data.InstallerPath)
            InstallerType = $Data.InstallerType
            Manufacturer = $Data.Manufacturer
            ProductName = $Data.AppName
            ProductVersion = $Data.Version
            ProductCode = $Data.ProductCode
            PackageFolder = $folderName
            RemoveAllVersions = $Data.RemoveAllVersions
            InstallArguments = $Data.InstallArguments
            UninstallPath = $Data.UninstallPath
            UninstallArguments = $Data.UninstallArguments
        } | ConvertTo-Json
        Set-Content -LiteralPath (Join-Path $appPath 'PackageInfo.json') -Value $manifest -Encoding UTF8
        return $appPath
    }
    catch {
        if (Test-Path -LiteralPath $appPath) {
            Remove-Item -LiteralPath $appPath -Recurse -Force
        }
        throw
    }
}

if ($env:PACKAGE_BUILDER_NO_UI -eq '1') { return }

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Gerador de pacotes SCCM / Intune" Height="900" Width="940"
        WindowStartupLocation="CenterScreen" MinHeight="700" MinWidth="820">
  <Grid Margin="18">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>
    <StackPanel Grid.Row="0" Margin="0,0,0,12">
      <TextBlock Text="Gerador de pacotes SCCM / Intune" FontSize="24" FontWeight="SemiBold"/>
      <TextBlock Text="Selecione um MSI ou EXE, revise os dados e gere uma cópia preenchida do template." Foreground="#555"/>
    </StackPanel>
    <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
      <Grid>
        <Grid.ColumnDefinitions><ColumnDefinition Width="190"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <TextBlock Grid.Row="0" Grid.ColumnSpan="3" Text="Fonte" FontSize="17" FontWeight="SemiBold" Margin="0,4,0,8"/>
        <Label Grid.Row="1" Content="Instalador MSI ou EXE *"/><TextBox x:Name="InstallerPath" Grid.Row="1" Grid.Column="1" Margin="4" IsReadOnly="True"/><Button x:Name="BrowseInstaller" Grid.Row="1" Grid.Column="2" Content="Selecionar..." Padding="14,5" Margin="4"/>
        <Label Grid.Row="2" Content="Pasta de saída *"/><TextBox x:Name="OutputRoot" Grid.Row="2" Grid.Column="1" Margin="4"/><Button x:Name="BrowseOutput" Grid.Row="2" Grid.Column="2" Content="Selecionar..." Padding="14,5" Margin="4"/>

        <TextBlock Grid.Row="3" Grid.ColumnSpan="3" Text="Identificação" FontSize="17" FontWeight="SemiBold" Margin="0,14,0,8"/>
        <Label Grid.Row="4" Content="Fabricante"/><TextBox x:Name="Manufacturer" Grid.Row="4" Grid.Column="1" Margin="4" Grid.ColumnSpan="2"/>
        <Label Grid.Row="5" Content="Fabricante na pasta *"/><TextBox x:Name="CompanyToken" Grid.Row="5" Grid.Column="1" Margin="4" Grid.ColumnSpan="2"/>
        <Label Grid.Row="6" Content="Nome do aplicativo *"/><TextBox x:Name="AppName" Grid.Row="6" Grid.Column="1" Margin="4" Grid.ColumnSpan="2"/>
        <Label Grid.Row="7" Content="Nome na pasta *"/><TextBox x:Name="AppToken" Grid.Row="7" Grid.Column="1" Margin="4" Grid.ColumnSpan="2"/>
        <Label Grid.Row="8" Content="Versão *"/><TextBox x:Name="Version" Grid.Row="8" Grid.Column="1" Margin="4" Grid.ColumnSpan="2"/>
        <Label Grid.Row="9" Content="Sistema / Idioma"/><StackPanel Grid.Row="9" Grid.Column="1" Grid.ColumnSpan="2" Orientation="Horizontal"><TextBox x:Name="SystemCode" Width="100" Margin="4"/><TextBox x:Name="Language" Width="100" Margin="4"/><Label Content="Versão interna"/><TextBox x:Name="InternalVersion" Width="100" Margin="4"/></StackPanel>
        <Label Grid.Row="10" Content="Tipo / ProductCode"/><StackPanel Grid.Row="10" Grid.Column="1" Grid.ColumnSpan="2" Orientation="Horizontal"><TextBox x:Name="InstallerType" Width="70" Margin="4" IsReadOnly="True"/><TextBox x:Name="ProductCode" Width="520" Margin="4" IsReadOnly="True"/></StackPanel>

        <TextBlock Grid.Row="11" Grid.ColumnSpan="3" Text="Instalação e detecção" FontSize="17" FontWeight="SemiBold" Margin="0,14,0,8"/>
        <Label x:Name="InstallArgumentsLabel" Grid.Row="12" Content="Argumentos MSI"/><TextBox x:Name="InstallArguments" Grid.Row="12" Grid.Column="1" Margin="4" Grid.ColumnSpan="2"/>
        <Label Grid.Row="13" Content="Desinstalador EXE"/><TextBox x:Name="UninstallPath" Grid.Row="13" Grid.Column="1" Margin="4" Grid.ColumnSpan="2" ToolTip="Obrigatório para EXE. Caminho completo do desinstalador após a instalação."/>
        <Label Grid.Row="14" Content="Argumentos de desinstalação"/><TextBox x:Name="UninstallArguments" Grid.Row="14" Grid.Column="1" Margin="4" Grid.ColumnSpan="2"/>
        <Label Grid.Row="15" Content="Executável de detecção"/><TextBox x:Name="DetectionPath" Grid.Row="15" Grid.Column="1" Margin="4" Grid.ColumnSpan="2" ToolTip="Obrigatório para EXE. Opcional para MSI, que pode usar o ProductCode."/>
        <Label Grid.Row="16" Content="Versão de detecção"/><TextBox x:Name="DetectionVersion" Grid.Row="16" Grid.Column="1" Margin="4" Grid.ColumnSpan="2" ToolTip="Obrigatório para EXE. Versão do executável instalado."/>
        <Label Grid.Row="17" Content="Processos a fechar"/><TextBox x:Name="Processes" Grid.Row="17" Grid.Column="1" Margin="4" Grid.ColumnSpan="2" ToolTip="Separe os nomes por vírgula"/>
        <Label Grid.Row="18" Content="Padrão DisplayName"/><TextBox x:Name="DisplayPattern" Grid.Row="18" Grid.Column="1" Margin="4" Grid.ColumnSpan="2"/>
        <CheckBox x:Name="RemoveAllVersions" Grid.Row="19" Grid.Column="1" Grid.ColumnSpan="2" Margin="5,10" Content="Remover todas as versões MSI anteriores encontradas pelo DisplayName" IsChecked="True"/>
      </Grid>
    </ScrollViewer>
    <DockPanel Grid.Row="2" Margin="0,14,0,0">
      <TextBlock x:Name="FolderPreview" VerticalAlignment="Center" Foreground="#444" TextWrapping="Wrap"/>
      <Button x:Name="Generate" Content="Gerar pacote" Padding="24,9" FontWeight="SemiBold" DockPanel.Dock="Right"/>
    </DockPanel>
  </Grid>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)
$names = 'InstallerPath','InstallerType','OutputRoot','Manufacturer','CompanyToken','AppName','AppToken','Version','SystemCode',
    'Language','InternalVersion','ProductCode','InstallArguments','InstallArgumentsLabel','UninstallPath',
    'UninstallArguments','DetectionPath','DetectionVersion','Processes','DisplayPattern','RemoveAllVersions',
    'BrowseInstaller','BrowseOutput','Generate','FolderPreview'
$ui = @{}
foreach ($name in $names) { $ui[$name] = $window.FindName($name) }

$ui.OutputRoot.Text = $PSScriptRoot
$ui.SystemCode.Text = '01'
$ui.Language.Text = 'ML'
$ui.InternalVersion.Text = '01.00'

$updatePreview = {
    $folder = '{0}_{1}_{2}_{3}_{4}' -f $ui.CompanyToken.Text, $ui.AppToken.Text,
        $ui.Version.Text, $ui.SystemCode.Text, $ui.Language.Text
    $ui.FolderPreview.Text = "Pasta: $folder"
}
foreach ($field in @('CompanyToken','AppToken','Version','SystemCode','Language')) {
    $ui[$field].Add_TextChanged($updatePreview)
}

$ui.BrowseOutput.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = 'Selecione a pasta onde o pacote será criado'
    $dialog.SelectedPath = $ui.OutputRoot.Text
    if ($dialog.ShowDialog() -eq 'OK') { $ui.OutputRoot.Text = $dialog.SelectedPath }
})

$ui.BrowseInstaller.Add_Click({
    $dialog = New-Object Microsoft.Win32.OpenFileDialog
    $dialog.Filter = 'Instaladores (*.msi;*.exe)|*.msi;*.exe|Windows Installer (*.msi)|*.msi|Executáveis (*.exe)|*.exe'
    if ($dialog.ShowDialog()) {
        try {
            $metadata = Get-InstallerMetadata $dialog.FileName
            $suggestedName = Get-SuggestedApplicationName $metadata.ProductName $metadata.ProductVersion
            $appToken = ConvertTo-PackageToken $suggestedName
            $defaultInstallPath = "C:\Applics\$appToken"
            $ui.InstallerPath.Text = $dialog.FileName
            $ui.InstallerType.Text = $metadata.Type
            $ui.Manufacturer.Text = $metadata.Manufacturer
            $ui.CompanyToken.Text = ConvertTo-PackageToken $metadata.Manufacturer
            $ui.AppName.Text = $suggestedName
            $ui.AppToken.Text = $appToken
            $ui.Version.Text = $metadata.ProductVersion
            $ui.ProductCode.Text = $metadata.ProductCode
            $ui.DetectionVersion.Text = $metadata.ProductVersion
            $ui.DisplayPattern.Text = $suggestedName
            $ui.Processes.Text = ''
            $ui.UninstallPath.Text = ''
            $ui.UninstallArguments.Text = ''
            $ui.DetectionPath.Text = ''

            if ($metadata.Type -eq 'MSI') {
                $ui.InstallArgumentsLabel.Content = 'Argumentos MSI'
                $ui.InstallArguments.Text = 'INSTALLDIR="' + $defaultInstallPath + '"'
                $ui.RemoveAllVersions.IsEnabled = $true
                $ui.RemoveAllVersions.IsChecked = $true
            } else {
                $ui.InstallArgumentsLabel.Content = 'Argumentos EXE'
                $ui.InstallArguments.Text = ''
                $ui.RemoveAllVersions.IsChecked = $false
                $ui.RemoveAllVersions.IsEnabled = $false
                if ($suggestedName -match '^7-Zip$') {
                    $ui.InstallArguments.Text = "/S /D=$defaultInstallPath"
                    $ui.UninstallPath.Text = "$defaultInstallPath\Uninstall.exe"
                    $ui.UninstallArguments.Text = '/S'
                    $ui.DetectionPath.Text = "$defaultInstallPath\7z.exe"
                    $ui.Processes.Text = '7zFM, 7z'
                } else {
                    Show-Info 'EXE selecionado. Informe os argumentos silenciosos, o desinstalador e o executável de detecção antes de gerar.'
                }
            }

            if ([string]::IsNullOrWhiteSpace($metadata.ProductVersion)) {
                Show-Info 'O instalador não informa a versão. Preencha a versão antes de gerar.'
                $ui.Version.Focus()
            }
        }
        catch { Show-Error "Não foi possível ler o instalador.`n`n$($_.Exception.Message)" }
    }
})

$ui.Generate.Add_Click({
    $required = [ordered]@{
        'Instalador' = $ui.InstallerPath.Text; 'Pasta de saída' = $ui.OutputRoot.Text
        'Fabricante na pasta' = $ui.CompanyToken.Text; 'Nome do aplicativo' = $ui.AppName.Text
        'Nome na pasta' = $ui.AppToken.Text; 'Versão' = $ui.Version.Text
        'Sistema' = $ui.SystemCode.Text; 'Idioma' = $ui.Language.Text
        'Versão interna' = $ui.InternalVersion.Text
    }
    if ($ui.InstallerType.Text -eq 'MSI') {
        $required['ProductCode'] = $ui.ProductCode.Text
        $required['Padrão DisplayName'] = $ui.DisplayPattern.Text
    } elseif ($ui.InstallerType.Text -eq 'EXE') {
        $required['Desinstalador EXE'] = $ui.UninstallPath.Text
        $required['Executável de detecção'] = $ui.DetectionPath.Text
        $required['Versão de detecção'] = $ui.DetectionVersion.Text
    } else {
        Show-Error 'Selecione um instalador MSI ou EXE.'
        return
    }
    $missing = @($required.GetEnumerator() | Where-Object { [string]::IsNullOrWhiteSpace([string]$_.Value) } | ForEach-Object { $_.Key })
    if ($missing.Count -gt 0) { Show-Error ("Preencha os campos obrigatórios:`n- " + ($missing -join "`n- ")); return }
    if (-not (Test-Path -LiteralPath $ui.InstallerPath.Text -PathType Leaf)) { Show-Error 'O instalador não existe.'; return }
    if (-not (Test-Path -LiteralPath $ui.OutputRoot.Text -PathType Container)) { Show-Error 'A pasta de saída não existe.'; return }

    $choice = [System.Windows.MessageBox]::Show(
        "O pacote será criado em uma nova pasta. O template original não será alterado.`n`n$($ui.FolderPreview.Text)`n`nContinuar?",
        'Confirmar geração', 'YesNo', 'Question'
    )
    if ($choice -ne 'Yes') { return }

    try {
        $ui.Generate.IsEnabled = $false
        $data = @{
            InstallerPath = $ui.InstallerPath.Text; InstallerType = $ui.InstallerType.Text
            OutputRoot = $ui.OutputRoot.Text
            Manufacturer = $ui.Manufacturer.Text; CompanyToken = $ui.CompanyToken.Text
            AppName = $ui.AppName.Text; AppToken = $ui.AppToken.Text; Version = $ui.Version.Text
            System = $ui.SystemCode.Text; Language = $ui.Language.Text; InternalVersion = $ui.InternalVersion.Text
            ProductCode = $ui.ProductCode.Text; InstallArguments = $ui.InstallArguments.Text
            UninstallPath = $ui.UninstallPath.Text; UninstallArguments = $ui.UninstallArguments.Text
            DetectionPath = $ui.DetectionPath.Text; DetectionVersion = $ui.DetectionVersion.Text
            Processes = $ui.Processes.Text; DisplayPattern = $ui.DisplayPattern.Text
            RemoveAllVersions = [bool]$ui.RemoveAllVersions.IsChecked
        }
        $created = New-Package $data
        Show-Info "Pacote criado com sucesso:`n$created"
        Start-Process explorer.exe -ArgumentList ('"' + $created + '"')
    }
    catch { Show-Error $_.Exception.Message }
    finally { $ui.Generate.IsEnabled = $true }
})

$window.ShowDialog() | Out-Null

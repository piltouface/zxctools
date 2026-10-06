# boSS Tools - WPF-лаунчер (розовая матовая тема)
# Kind='Script'   - качает .ps1 в papa\scripts и запускает файл в окне powershell (-File)
# Kind='Inline'   - локальная команда: сохраняется в papa\scripts и запускается оттуда же
# Kind='Download' - качает файлы по прямым ссылкам в $ToolsRoot и открывает папку
# Kind='Link'     - просто открывает ссылку в браузере
#
# Свои инструменты добавлять в массив $Tools, вкладки - в $Categories

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Restart-ScriptElevatedSta {
    param([string]$Path, [switch]$AsAdmin)
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) { return $false }
    $start = New-Object System.Diagnostics.ProcessStartInfo
    $start.FileName = 'powershell.exe'
    $start.Arguments = '-NoProfile -STA -ExecutionPolicy Bypass -File "' + $Path.Replace('"', '\"') + '"'
    $start.UseShellExecute = $true
    if ($AsAdmin) { $start.Verb = 'runas' }
    try { [System.Diagnostics.Process]::Start($start) | Out-Null; return $true }
    catch { return $false }
}

$script:EntryPath = if ($PSCommandPath) { $PSCommandPath } else { $MyInvocation.MyCommand.Path }

if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    if (Restart-ScriptElevatedSta -Path $script:EntryPath) { exit }
    Write-Error 'Запусти так: powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\installer.ps1'
    exit 1
}

if (-not (Test-IsAdministrator)) {
    if ($script:EntryPath -and (Restart-ScriptElevatedSta -Path $script:EntryPath -AsAdmin)) { exit }
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# всё качается на рабочий стол в папку papa
# GetFolderPath понимает перенесённый рабочий стол (OneDrive), $env:USERPROFILE - нет
$DesktopRoot = [Environment]::GetFolderPath('Desktop')
if ([string]::IsNullOrWhiteSpace($DesktopRoot) -or -not (Test-Path -LiteralPath $DesktopRoot)) {
    $DesktopRoot = Join-Path $env:USERPROFILE 'Desktop'
}
$ToolsRoot = Join-Path $DesktopRoot 'papa'
if (-not (Test-Path -LiteralPath $ToolsRoot)) { New-Item -Path $ToolsRoot -ItemType Directory -Force | Out-Null }

# ---------- XAML ----------

[xml]$xamlDoc = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:shell="clr-namespace:System.Windows.Shell;assembly=PresentationFramework"
        Title="boSS Tools" Height="640" Width="960"
        WindowStartupLocation="CenterScreen"
        AllowsTransparency="False">
    <shell:WindowChrome.WindowChrome>
        <shell:WindowChrome CaptionHeight="0" ResizeBorderThickness="5" GlassFrameThickness="0" UseAeroCaptionButtons="False"/>
    </shell:WindowChrome.WindowChrome>
    <Window.Resources>
        <!-- цвета -->
        <SolidColorBrush x:Key="BrushBg"            Color="#2d1a22"/>
        <SolidColorBrush x:Key="BrushPanel"         Color="#3a2030"/>
        <SolidColorBrush x:Key="BrushBorder"        Color="#52304a"/>
        <SolidColorBrush x:Key="BrushAccent"        Color="#c85a82"/>
        <SolidColorBrush x:Key="BrushAccentDark"    Color="#9a3a60"/>
        <SolidColorBrush x:Key="BrushBadge"         Color="#b04870"/>
        <SolidColorBrush x:Key="BrushText"          Color="#f0e4ec"/>
        <SolidColorBrush x:Key="BrushMuted"         Color="#8a6878"/>
        <SolidColorBrush x:Key="BrushSecondaryText" Color="#d4b8c8"/>
        <SolidColorBrush x:Key="BrushScrollThumb"   Color="#c85a82"/>
        <SolidColorBrush x:Key="BrushScrollTrack"   Color="#3a2030"/>

        <!-- кнопка основная -->
        <Style x:Key="PrimaryButton" TargetType="Button">
            <Setter Property="Foreground" Value="{StaticResource BrushText}"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="14,7"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd" CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <Border.Background>
                                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                    <GradientStop Color="#c85a82" Offset="0"/>
                                    <GradientStop Color="#9a3a60" Offset="1"/>
                                </LinearGradientBrush>
                            </Border.Background>
                            <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Opacity" Value="0.85"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Bd" Property="Opacity" Value="0.7"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- кнопка вторичная -->
        <Style x:Key="SecondaryButton" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="{StaticResource BrushSecondaryText}"/>
            <Setter Property="BorderBrush" Value="{StaticResource BrushBorder}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="14,7"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#3a2030"/>
                                <Setter TargetName="Bd" Property="BorderBrush" Value="#c85a82"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- скроллбар розовый -->
        <Style x:Key="PinkScrollBarThumb" TargetType="Thumb">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Thumb">
                        <Border x:Name="Bd" CornerRadius="4" Margin="2">
                            <Border.Background>
                                <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                    <GradientStop Color="#c85a82" Offset="0"/>
                                    <GradientStop Color="#9a3a60" Offset="1"/>
                                </LinearGradientBrush>
                            </Border.Background>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Opacity" Value="0.8"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="PinkScrollBarButton" TargetType="RepeatButton">
            <Setter Property="Height" Value="0"/>
            <Setter Property="Width" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="RepeatButton">
                        <Border Background="Transparent"/>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="PinkScrollBar" TargetType="ScrollBar">
            <Setter Property="Width" Value="8"/>
            <Setter Property="Background" Value="{StaticResource BrushScrollTrack}"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                        <Grid Background="{TemplateBinding Background}">
                            <Track x:Name="PART_Track" IsDirectionReversed="True">
                                <Track.DecreaseRepeatButton>
                                    <RepeatButton Style="{StaticResource PinkScrollBarButton}" Command="ScrollBar.PageUpCommand"/>
                                </Track.DecreaseRepeatButton>
                                <Track.Thumb>
                                    <Thumb Style="{StaticResource PinkScrollBarThumb}"/>
                                </Track.Thumb>
                                <Track.IncreaseRepeatButton>
                                    <RepeatButton Style="{StaticResource PinkScrollBarButton}" Command="ScrollBar.PageDownCommand"/>
                                </Track.IncreaseRepeatButton>
                            </Track>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="ScrollViewer">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollViewer">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <ScrollContentPresenter Grid.Column="0"/>
                            <ScrollBar Grid.Column="1"
                                       Style="{StaticResource PinkScrollBar}"
                                       x:Name="PART_VerticalScrollBar"
                                       Orientation="Vertical"
                                       Value="{TemplateBinding VerticalOffset}"
                                       Maximum="{TemplateBinding ScrollableHeight}"
                                       ViewportSize="{TemplateBinding ViewportHeight}"
                                       Visibility="{TemplateBinding ComputedVerticalScrollBarVisibility}"/>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="CloseButton" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="{StaticResource BrushMuted}"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Width" Value="32"/>
            <Setter Property="Height" Value="32"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="4">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#55303040"/>
                                <Setter Property="Foreground" Value="White"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <!-- градиентный фон окна -->
    <Window.Background>
        <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#2d1a22" Offset="0"/>
            <GradientStop Color="#321e28" Offset="0.5"/>
            <GradientStop Color="#28181e" Offset="1"/>
        </LinearGradientBrush>
    </Window.Background>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <!-- кастомный тёмный заголовок вместо белой системной полосы -->
        <Grid Grid.Row="0" x:Name="TitleBar" Height="36" Background="#1a1018">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock Text="boSS Tools" Foreground="{StaticResource BrushMuted}"
                       FontSize="12" VerticalAlignment="Center" Margin="14,0,0,0"/>
            <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,4,0">
                <Button x:Name="BtnMinimize" Content="&#x2013;" Style="{StaticResource CloseButton}"/>
                <Button x:Name="BtnClose"    Content="&#x2715;" Style="{StaticResource CloseButton}"/>
            </StackPanel>
        </Grid>

        <!-- основной контент -->
        <Grid Grid.Row="1" Margin="16,10,16,16">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Grid Grid.Row="0" Margin="0,0,0,14">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                <!-- иконка Y — точно как на скрине: скруглённый квадрат, вертикальный градиент розовый->малиновый, буква Y -->
                <Border CornerRadius="14" Width="44" Height="44">
                    <Border.Background>
                        <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                            <GradientStop Color="#c85a82" Offset="0"/>
                            <GradientStop Color="#b04870" Offset="0.5"/>
                            <GradientStop Color="#8a3258" Offset="1"/>
                        </LinearGradientBrush>
                    </Border.Background>
                    <Border.Effect>
                        <DropShadowEffect Color="#c85a82" BlurRadius="10" ShadowDepth="0" Opacity="0.4"/>
                    </Border.Effect>
                    <TextBlock Text="Y" Foreground="White" FontWeight="Bold" FontSize="22"
                               FontFamily="Segoe UI" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                </Border>
                <StackPanel Margin="12,0,0,0" VerticalAlignment="Center">
                    <TextBlock Text="boSS Tools" Foreground="{StaticResource BrushText}" FontWeight="Bold" FontSize="15"/>
                    <TextBlock Text="I LOVE BYPASS" Foreground="{StaticResource BrushMuted}" FontSize="11"/>
                </StackPanel>
            </StackPanel>
                <StackPanel Grid.Column="1" Orientation="Horizontal">
                    <Button x:Name="BtnFolder"  Content="papa"    Style="{StaticResource SecondaryButton}" Margin="0,0,8,0"/>
                    <Button x:Name="BtnRefresh" Content="Обновить" Style="{StaticResource SecondaryButton}"/>
                </StackPanel>
        </Grid>

        <Grid Grid.Row="1" Margin="0,0,0,14">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <Border Background="{StaticResource BrushPanel}" BorderBrush="{StaticResource BrushBorder}"
                    BorderThickness="1" CornerRadius="6">
                <Grid>
                    <TextBlock x:Name="TxtPlaceholder" Text="Поиск по названию и описанию"
                               Foreground="{StaticResource BrushMuted}" FontSize="13"
                               HorizontalAlignment="Center" VerticalAlignment="Center"
                               IsHitTestVisible="False"/>
                    <TextBox x:Name="TxtFilter" Background="Transparent"
                             Foreground="{StaticResource BrushText}"
                             BorderThickness="0" Padding="10,0"
                             Height="36"
                             VerticalContentAlignment="Center"
                             HorizontalContentAlignment="Center"
                             TextAlignment="Center"
                             CaretBrush="{StaticResource BrushAccent}">
                        <TextBox.Style>
                            <Style TargetType="TextBox">
                                <Setter Property="Template">
                                    <Setter.Value>
                                        <ControlTemplate TargetType="TextBox">
                                            <Border Background="Transparent" BorderThickness="0">
                                                <ScrollViewer x:Name="PART_ContentHost" Margin="0"/>
                                            </Border>
                                        </ControlTemplate>
                                    </Setter.Value>
                                </Setter>
                            </Style>
                        </TextBox.Style>
                    </TextBox>
                </Grid>
            </Border>
            <Button Grid.Column="1" x:Name="BtnClearFilter" Content="Очистить" Style="{StaticResource SecondaryButton}" Margin="8,0,0,0"/>
            <Button Grid.Column="2" x:Name="BtnDownloadAll" Content="Скачать всю категорию" Style="{StaticResource PrimaryButton}" Margin="8,0,0,0"/>
        </Grid>

        <Grid Grid.Row="2">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="180"/>
                <ColumnDefinition Width="14"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <StackPanel Grid.Column="0" x:Name="CategoryList"/>

            <Border Grid.Column="2" BorderBrush="{StaticResource BrushBorder}" BorderThickness="1" CornerRadius="6">
                <Border.Background>
                    <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                        <GradientStop Color="#2d1a22" Offset="0"/>
                        <GradientStop Color="#2a1820" Offset="1"/>
                    </LinearGradientBrush>
                </Border.Background>
                <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="0">
                        <StackPanel x:Name="ToolList" Margin="12,12,12,12"/>
                </ScrollViewer>
            </Border>
        </Grid>

        <TextBlock Grid.Row="3" x:Name="StatusText" Foreground="{StaticResource BrushMuted}" Margin="0,6,0,0" FontSize="11"/>
    </Grid>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xamlDoc
$Window = [Windows.Markup.XamlReader]::Load($reader)

$BtnFolder       = $Window.FindName('BtnFolder')
$BtnRefresh      = $Window.FindName('BtnRefresh')
$TxtFilter       = $Window.FindName('TxtFilter')
$TxtPlaceholder  = $Window.FindName('TxtPlaceholder')
$BtnClearFilter  = $Window.FindName('BtnClearFilter')
$BtnDownloadAll  = $Window.FindName('BtnDownloadAll')
$CategoryList    = $Window.FindName('CategoryList')
$ToolList        = $Window.FindName('ToolList')
$StatusText      = $Window.FindName('StatusText')
$TitleBar        = $Window.FindName('TitleBar')
$BtnMinimize     = $Window.FindName('BtnMinimize')
$BtnClose        = $Window.FindName('BtnClose')

# ---------- логика запуска ----------

# Скрипты и команды запускаются как обычный `powershell -File <файл.ps1>`.
# Раньше было iex(irm URL) + base64 -EncodedCommand через cmd /k: в журналы
# (4104, 4688, Sysmon) попадали нечитаемая base64-строка и код чужого скрипта
# как "анонимный блок из строки", что выглядит как обфускация и забивает логи.
# Теперь командная строка короткая и читаемая, а у каждого запуска есть файл
# в papa\scripts - его можно открыть, сверить хеш и показать проверяемому.

# имя файла из названия инструмента: только буквы, цифры, '-', '_' и '.'
function Get-SafeFileName {
    param([string]$Name)
    $safe = ($Name -replace '[^\w\.\-]+', '_').Trim('_')
    if ([string]::IsNullOrWhiteSpace($safe)) { $safe = 'tool' }
    return $safe
}

# папка для скачанных скриптов и локальных команд (та же, что у категории scripts)
function Get-ScriptFolder {
    $dir = Join-Path $ToolsRoot 'scripts'
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    return $dir
}

# окно powershell, которое остаётся открытым после выполнения (-NoExit).
# Лаунчер и так работает от админа, поэтому повторный UAC нужен, только если это не так
function Start-ToolWindow {
    param([string]$ScriptPath)
    $params = @{
        FilePath     = 'powershell.exe'
        ArgumentList = ('-NoProfile -ExecutionPolicy Bypass -NoExit -File "{0}"' -f $ScriptPath)
    }
    if (-not (Test-IsAdministrator)) { $params.Verb = 'RunAs' }
    Start-Process @params
}

# качает скрипт в papa\scripts и запускает с диска. Возвращает короткий SHA256 для статусбара
function Invoke-RemoteScript {
    param([string]$Name, [string]$Url)
    $path = Join-Path (Get-ScriptFolder) ((Get-SafeFileName $Name) + '.ps1')
    $client = New-Object System.Net.WebClient
    try {
        $client.Headers.Add('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)')
        $bytes = $client.DownloadData($Url)
    } finally { $client.Dispose() }
    $text = [Text.Encoding]::UTF8.GetString($bytes).TrimStart([char]0xFEFF)
    if ([string]::IsNullOrWhiteSpace($text)) { throw 'сервер вернул пустой файл' }
    # UTF-8 с BOM: иначе PowerShell 5.1 читает кириллицу в скрипте как ANSI
    [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($true)))
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { $hash = -join ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) } finally { $sha.Dispose() }
    Start-ToolWindow -ScriptPath $path
    return $hash.Substring(0, 12)
}

# локальная команда: кладётся в читаемый .ps1 и запускается из него
function Invoke-InlineCommand {
    param([string]$Name, [string]$Command)
    $path = Join-Path (Get-ScriptFolder) ((Get-SafeFileName $Name) + '.ps1')
    [System.IO.File]::WriteAllText($path, $Command, (New-Object System.Text.UTF8Encoding($true)))
    Start-ToolWindow -ScriptPath $path
}

# пишет в строку состояния и сразу перерисовывает окно, чтобы оно не выглядело зависшим
function Set-Status {
    param([string]$Text, [switch]$Error)
    $StatusText.Text = $Text
    $StatusText.Foreground = if ($Error) { $Window.FindResource('BrushAccent') } else { $Window.FindResource('BrushMuted') }
    $Window.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Render) | Out-Null
}

# папка, куда падает инструмент
function Get-ToolFolder {
    param($Tool)
    $dest = Join-Path $ToolsRoot $Tool.Category
    if (-not (Test-Path -LiteralPath $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
    return $dest
}

# имя файла из ссылки, без хвоста ?query
function Get-LinkFileName {
    param([string]$Url)
    $name = [System.IO.Path]::GetFileName(([uri]$Url).LocalPath)
    if ([string]::IsNullOrWhiteSpace($name)) { $name = 'download.bin' }
    return $name
}

# качает один файл: WebClient быстрее Invoke-WebRequest, User-Agent нужен NirSoft и паре зеркал
function Get-RemoteFile {
    param([string]$Url, [string]$Path)
    $client = New-Object System.Net.WebClient
    try {
        $client.Headers.Add('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)')
        $client.DownloadFile($Url, $Path)
    } finally { $client.Dispose() }
}

# скачан ли уже инструмент
function Test-ToolDownloaded {
    param($Tool)
    if ($Tool.Kind -ne 'Download') { return $false }
    $dest = Join-Path $ToolsRoot $Tool.Category
    foreach ($link in $Tool.Links) {
        if (-not (Test-Path -LiteralPath (Join-Path $dest (Get-LinkFileName $link)))) { return $false }
    }
    return $true
}

# качает все ссылки инструмента, zip сразу распаковывает рядом. Возвращает $true при успехе.
function Invoke-ToolDownload {
    param($Tool, [switch]$Quiet)
    $dest = Get-ToolFolder -Tool $Tool
    $failed = @()
    foreach ($link in $Tool.Links) {
        $fileName = Get-LinkFileName $link
        $target = Join-Path $dest $fileName
        Set-Status "Качаю: $($Tool.Name) - $fileName"
        try {
            Get-RemoteFile -Url $link -Path $target
            if ($fileName -like '*.zip') {
                $unpack = Join-Path $dest ([System.IO.Path]::GetFileNameWithoutExtension($fileName))
                try {
                    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
                    if (Test-Path -LiteralPath $unpack) { Remove-Item -LiteralPath $unpack -Recurse -Force -ErrorAction SilentlyContinue }
                    [System.IO.Compression.ZipFile]::ExtractToDirectory($target, $unpack)
                } catch { }
            }
        } catch {
            $failed += "$fileName ($($_.Exception.Message))"
        }
    }
    if ($failed.Count -gt 0) {
        Set-Status "Не скачалось - $($Tool.Name): $($failed -join '; ')" -Error
        return $false
    }
    if (-not $Quiet) {
        Start-Process explorer.exe $dest
        Set-Status "Готово: $($Tool.Name) -> $dest"
    }
    return $true
}

# качает всю текущую категорию одной кнопкой
# единственное место, где решается "что сейчас на экране".
# и список карточек, и кнопка "скачать всё" берут набор отсюда - иначе качается не то, что видишь
function Get-VisibleTools {
    param([string]$CategoryKey, [string]$Filter)
    if ([string]::IsNullOrWhiteSpace($Filter)) {
        return @($Tools | Where-Object { $_.Category -eq $CategoryKey })
    }
    # с текстом в поиске категория игнорируется - ищем везде, по названию и описанию
    return @($Tools | Where-Object { $_.Name -like "*$Filter*" -or $_.Description -like "*$Filter*" })
}

function Invoke-CategoryDownload {
    param([string]$CategoryKey, [string]$Filter)
    $items = @(Get-VisibleTools -CategoryKey $CategoryKey -Filter $Filter | Where-Object { $_.Kind -eq 'Download' })
    if ($items.Count -eq 0) { Set-Status 'Качать нечего - на экране только ссылки и скрипты'; return }
    $BtnDownloadAll.IsEnabled = $false
    $ok = 0; $bad = 0
    foreach ($tool in $items) {
        if (Invoke-ToolDownload -Tool $tool -Quiet) { $ok++ } else { $bad++; Start-Sleep -Milliseconds 800 }
    }
    $BtnDownloadAll.IsEnabled = $true
    # при поиске по всем категориям файлы падают в разные папки - открываем корень
    $folder = if ([string]::IsNullOrWhiteSpace($Filter)) { Join-Path $ToolsRoot $CategoryKey } else { $ToolsRoot }
    if (Test-Path -LiteralPath $folder) { Start-Process explorer.exe $folder }
    Update-ToolList -CategoryKey $CategoryKey -Filter $Filter -KeepStatus
    Set-Status "Скачано $ok, ошибок $bad" -Error:($bad -gt 0)
}

# ---------- данные ----------

$Categories = @(
    @{ Key = 'ytools';        Label = 'Y Tools' }
    @{ Key = 'orbdiff';       Label = 'OrbDiff' }
    @{ Key = 'spokwn';        Label = 'Spokwn' }
    @{ Key = 'tonynoh';       Label = 'Tonynoh' }
    @{ Key = 'redlotus';      Label = 'RedLotus' }
    @{ Key = 'detectac';      Label = 'DetectAC' }
    @{ Key = 'vortex';        Label = 'Vortex' }
    @{ Key = 'scripts';       Label = 'Scripts' }
    @{ Key = 'nirsoft';       Label = 'NirSoft' }
    @{ Key = 'ericzimmerman'; Label = 'EricZimmerman' }
    @{ Key = 'others';        Label = 'Others' }
    @{ Key = 'dependencies';  Label = 'Dependencies' }
)

$Tools = @(
    # ---------- Y Tools ----------
    # github.com/sweetvata, всё что начинается на Y-
    @{ Name='Y-Check';    Description='Проверка всех .jar файлов';        Category='ytools'; Kind='Download'; Links=@('https://github.com/sweetvata/Y-Check/releases/download/v2.2/Y-check.exe') }
    @{ Name='Y-AmCache';  Description='Парсер AmCache';                   Category='ytools'; Kind='Download'; Links=@('https://github.com/sweetvata/Y-AmCache/releases/download/v.1.0.0/Y-AmCache.exe') }
    @{ Name='Y-Jdamp';    Description='Дампер';                           Category='ytools'; Kind='Download'; Links=@('https://github.com/sweetvata/Y-Jdamp/releases/download/v1.0.0/Y-Jdamp.exe') }
    @{ Name='Y-Alts';     Description='Чекер альт-аккаунтов';             Category='ytools'; Kind='Download'; Links=@('https://github.com/sweetvata/Y-Alts/releases/download/v1.0/Y-Alts.exe') }
    # Y-BOssTools (InjGen++) убран 11.08.2026: файл удалён из репозитория
    # sweetvata/Y-BOssTools коммитом f004ba3, релизов там нет, качать нечего

    # ---------- OrbDiff ----------
    @{ Name='Prefetch View++';     Description='Парсит prefetch, вытаскивает инфу о файлах'; Category='orbdiff'; Kind='Download'; Links=@('https://github.com/Orbdiff/PrefetchView/releases/download/v1.6.7/pv++.exe') }
    @{ Name='BAM Reveal';          Description='Парсит артефакт BAM';                        Category='orbdiff'; Kind='Download'; Links=@('https://github.com/Orbdiff/BAMReveal/releases/latest/download/BAMReveal.exe') }
    @{ Name='Amcache Parser';      Description='Amcache с YARA и сигнатурами';               Category='orbdiff'; Kind='Download'; Links=@('https://github.com/Orbdiff/AmcacheParser/releases/latest/download/AmcacheParser.exe') }
    @{ Name='Journal Parser';      Description='Парсит записи USN Journal NTFS';             Category='orbdiff'; Kind='Download'; Links=@('https://github.com/Orbdiff/JournalParser/releases/latest/download/JournalParser.exe') }
    @{ Name='Check Deleted USN';   Description='Сверяет таймстампы USN с временем загрузки'; Category='orbdiff'; Kind='Download'; Links=@('https://github.com/Orbdiff/CheckDeletedUSN/releases/latest/download/CheckDeletedUSN.exe') }
    @{ Name='Fileless';            Description='Детект fileless через eventlog и memdump';   Category='orbdiff'; Kind='Download'; Links=@('https://github.com/Orbdiff/Fileless/releases/latest/download/fileless.exe') }
    @{ Name='JAR Parser';          Description='JAR prefetch, строки DcomLaunch и прочее';   Category='orbdiff'; Kind='Download'; Links=@('https://github.com/Orbdiff/JARParser/releases/latest/download/JARParser.exe') }
    @{ Name='PF Trace';            Description='Анализ prefetch rundll32 и regsvr32';        Category='orbdiff'; Kind='Download'; Links=@('https://github.com/Orbdiff/PFTrace/releases/latest/download/PFTrace.exe') }
    @{ Name='InjGen';              Description='Детект инжектов JNI и JVMTI в память';       Category='orbdiff'; Kind='Download'; Links=@('https://github.com/Orbdiff/InjGen/releases/latest/download/InjGen.exe') }
    @{ Name='DPS Analyzer';        Description='Анализ памяти DPS';                          Category='orbdiff'; Kind='Download'; Links=@('https://github.com/Orbdiff/DPS-Analyzer/releases/latest/download/dpsanalyzer.exe') }
    @{ Name='USB Detector';        Description='История подключений USB';                    Category='orbdiff'; Kind='Download'; Links=@('https://github.com/Orbdiff/USBDetector/releases/latest/download/USBDetector.exe') }
    @{ Name='User Assist View';    Description='Парсер артефакта UserAssist';                Category='orbdiff'; Kind='Download'; Links=@('https://github.com/Orbdiff/UserAssistView/releases/latest/download/UserAssistView.exe') }
    @{ Name='Strings Parser';      Description='Строки с YARA и сигнатурами';                Category='orbdiff'; Kind='Download'; Links=@('https://github.com/Orbdiff/StringsParser/releases/download/v1.2/stringsparser1.2b.exe') }
    @{ Name='Bam Check Restart';   Description='Определяет дату создания BAM';               Category='orbdiff'; Kind='Download'; Links=@('https://github.com/Orbdiff/BAM-CheckRestart/releases/download/v2.0.2/BAMCheckRestart.exe') }

    # ---------- Spokwn ----------
    @{ Name='Activities Cache Execution'; Description='Запуски файлов по activitiescache.db'; Category='spokwn'; Kind='Download'; Links=@('https://github.com/spokwn/ActivitiesCache-execution/releases/download/v0.6.5/ActivitiesCacheParser.exe') }
    @{ Name='BAM Parser';                 Description='Парсит артефакт BAM';                  Category='spokwn'; Kind='Download'; Links=@('https://github.com/spokwn/BAM-parser/releases/download/v1.2.9/BAMParser.exe') }
    @{ Name='Bam Deleted Keys';           Description='Удалённые ключи BAM сверкой с кустами';Category='spokwn'; Kind='Download'; Links=@('https://github.com/spokwn/BamDeletedKeys/releases/download/v1.0/BamDeletedKeys.exe') }
    @{ Name='Journal Trace';              Description='Парсит записи журнала NTFS';           Category='spokwn'; Kind='Download'; Links=@('https://github.com/spokwn/JournalTrace/releases/download/1.2/JournalTrace.exe') }
    @{ Name='Pca Svc Executed';           Description='Форк service-execution от zack-srcs';  Category='spokwn'; Kind='Download'; Links=@('https://github.com/spokwn/pcasvc-executed/releases/download/v0.8.7/PcaSvcExecuted.exe') }
    @{ Name='Espouken Tool';              Description='Комбайн из кучи инструментов';         Category='spokwn'; Kind='Download'; Links=@('https://github.com/spokwn/Tool/releases/download/v1.1.3/espouken.exe') }
    @{ Name='Process Parser';             Description='Парсит процессы через xxstrings';      Category='spokwn'; Kind='Download'; Links=@('https://github.com/spokwn/process-parser/releases/download/v0.5.5/ProcessParser.exe') }
    @{ Name='Paths Parser';               Description='Разбирает инфу о путях в .txt';        Category='spokwn'; Kind='Download'; Links=@('https://github.com/spokwn/PathsParser/releases/download/v1.2/PathsParser.exe') }
    @{ Name='Kernel Live Dump Tool';      Description='Снимает живые дампы памяти ядра';      Category='spokwn'; Kind='Link';     Url='https://github.com/spokwn/KernelLiveDumpTool/releases/latest' }
    @{ Name='Prefetch Parser';            Description='Парсит файлы prefetch';                Category='spokwn'; Kind='Link';     Url='https://github.com/spokwn/prefetch-parser/releases/latest' }

    # ---------- Tonynoh ----------
    @{ Name='Meow Resolver';        Description='Детект и резолв кривых байпасов';      Category='tonynoh'; Kind='Download'; Links=@('https://github.com/MeowTonynoh/MeowResolver/releases/download/v.1.1/MeowResolver.exe') }
    @{ Name='Meow Doomsday Fucker'; Description='Поиск Doomsday';                       Category='tonynoh'; Kind='Download'; Links=@('https://github.com/MeowTonynoh/MeowDoomsdayFucker/releases/download/V.1.5/MeowDoomsdayFucker.exe') }
    @{ Name='Meow Client Fucker';   Description='Сканер клиентов';                      Category='tonynoh'; Kind='Download'; Links=@('https://github.com/MeowTonynoh/MeowClientFucker/releases/download/v1.0/MeowClientFucker.exe') }
    @{ Name='Meow Imports Checker'; Description='Проверка импортов файлов';             Category='tonynoh'; Kind='Download'; Links=@('https://github.com/MeowTonynoh/MeowImportsChecker/releases/download/MeowImportsChecker/MeowImportsChecker.exe') }
    @{ Name='Meow Novoware Fucker'; Description='Детект артефактов Novoware';           Category='tonynoh'; Kind='Link';     Url='https://github.com/MeowTonynoh/MeowNovowareFucker/releases/latest' }

    # ---------- RedLotus ----------
    # у всех троих релиз без прямой ссылки на файл, поэтому Link, а не Download
    @{ Name='RL ModAnalyzer';   Description='Анализ модов на признаки читов';        Category='redlotus'; Kind='Link'; Url='https://github.com/ItzIceHere/RedLotus-Mod-Analyzer/releases/latest' }
    @{ Name='RL TaskSentinel';  Description='Слежение за задачами планировщика';      Category='redlotus'; Kind='Link'; Url='https://github.com/ItzIceHere/RedLotus-Task-Sentinel/releases/latest' }
    @{ Name='RL AltChecker';    Description='Проверка на альт-аккаунты';              Category='redlotus'; Kind='Link'; Url='https://github.com/ItzIceHere/RedLotusAltChecker/releases/latest' }

    # ---------- DetectAC ----------
    @{ Name='Amcache Parser++';         Description='Amcache с YARA и VirusTotal';                Category='detectac'; Kind='Download'; Links=@('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/AmcacheParser++.exe') }
    @{ Name='Autoruns++';               Description='Автозагрузка с USN и проверкой подписей';    Category='detectac'; Kind='Download'; Links=@('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/Autoruns++.exe') }
    @{ Name='Bam Parser++';             Description='BAM с YARA и детектом подмены';              Category='detectac'; Kind='Download'; Links=@('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/BamParser++.exe') }
    @{ Name='Browser Downloads View++'; Description='Загрузки браузеров с подсветкой правок USN'; Category='detectac'; Kind='Download'; Links=@('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/BrowserDownloadsView++.exe') }
    @{ Name='Browsing History View++';  Description='История браузеров с флагами доменов и VT';    Category='detectac'; Kind='Download'; Links=@('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/BrowsingHistoryView++.exe') }
    @{ Name='Crashed File Viewer++';    Description='Артефакты падений Windows с подсветкой USN';  Category='detectac'; Kind='Download'; Links=@('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/CrashedFileViewer++.exe') }
    @{ Name='Journal Trace++';          Description='USN Journal с детектом байпасов';             Category='detectac'; Kind='Download'; Links=@('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/JournalTrace++.exe') }
    @{ Name='Kernel Live Dump++';       Description='Дамп памяти ядра и юзермода с поиском строк'; Category='detectac'; Kind='Download'; Links=@('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/KernelLiveDump++.exe') }
    @{ Name='MFT Explorer++';           Description='Просмотр $MFT с подозрительными ADS';         Category='detectac'; Kind='Download'; Links=@('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/MFTExplorer++.exe') }
    @{ Name='Paths Parser++';           Description='Разбор путей с YARA и просмотром USN';        Category='detectac'; Kind='Download'; Links=@('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/PathsParser++.exe') }
    @{ Name='PowerShell Parser++';      Description='Артефакты истории PowerShell и байпасы';      Category='detectac'; Kind='Download'; Links=@('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/PowerShellParser++.exe') }
    @{ Name='Saved Files Viewer++';     Description='Все сохранённые на диск файлы по таймстампам';Category='detectac'; Kind='Download'; Links=@('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/SavedFilesViewer++.exe') }
    @{ Name='SRUM Explorer++';          Description='Пути и службы из SRUM с YARA и USN';          Category='detectac'; Kind='Download'; Links=@('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/SRUMExplorer++.exe') }
    @{ Name='String Explorer++';        Description='Строки exe, энтропия, VirusTotal';            Category='detectac'; Kind='Download'; Links=@('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/StringExplorer++.exe') }
    @{ Name='USB Deview++';             Description='Логи USB со сверкой по DeviceHunt';           Category='detectac'; Kind='Download'; Links=@('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/USBDeview++.exe') }
    @{ Name='Win Prefetch View++';      Description='Prefetch с детектом байпасов и YARA';         Category='detectac'; Kind='Download'; Links=@('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/WinPrefetchView++.exe') }

    # ---------- Vortex ----------
    # dot-sys, он же автор PC-Check. Сайт: vortexforensic.com
    @{ Name='Vortex Prefetch';   Description='Парсер prefetch Win10/11 с глубоким разбором';        Category='vortex'; Kind='Download'; Links=@('https://github.com/dot-sys/VortexPrefetch/releases/download/v1.1/VortexPrefetch.exe') }
    @{ Name='Vortex MFT Plus';   Description='NTFS: MFT, USN Journal, $LogFile, $I30 и $ObjId';     Category='vortex'; Kind='Download'; Links=@('https://github.com/dot-sys/VortexMFTPlus/releases/download/v1.0/VortexMFTPlus.exe') }
    @{ Name='Vortex AmCache';    Description='Живой парсер и анализатор куста AmCache';             Category='vortex'; Kind='Download'; Links=@('https://github.com/dot-sys/VortexAmCache/releases/download/v1.0/VortexAmCache.exe') }
    @{ Name='Vortex PCA';        Description='Разбор локального PCA в Win11 с метаданными';         Category='vortex'; Kind='Download'; Links=@('https://github.com/dot-sys/VortexPCA/releases/download/v1.0/VortexPCA.exe') }
    @{ Name='Vortex FAT';        Description='Парсер FAT16/32 и exFAT, поиск удалённых файлов';     Category='vortex'; Kind='Download'; Links=@('https://github.com/dot-sys/VortexFAT/releases/download/v1.2/VortexFAT.exe') }
    @{ Name='Vortex Viewer';     Description='Триаж живой системы: журнал, таймлайн, строки памяти'; Category='vortex'; Kind='Download'; Links=@('https://github.com/dot-sys/VortexViewer/releases/download/v1.2/VortexViewer.exe') }
    # веб-инструмент, релизов нет - открывается в браузере
    @{ Name='Vortex CSRSS Tool'; Description='Визуализация сырых строк CSRSS, работает в браузере';  Category='vortex'; Kind='Link';     Url='https://vortexforensic.com/webtools/CSRSSTool.html' }

    # ---------- Scripts: свои ----------
    @{ Name='SS Starter';           Description='Свой стартер из MyPowerShellScripts-ssing'; Category='scripts'; Kind='Script'; Url='https://raw.githubusercontent.com/piespeas/MyPowerShellScripts-ssing/refs/heads/main/ss_starter.ps1' }
    @{ Name='RedLotus BAM';         Description='Разбор BAM от PureIntent';                 Category='scripts'; Kind='Script'; Url='https://raw.githubusercontent.com/PureIntent/ScreenShare/main/RedLotusBam.ps1' }
    @{ Name='Y-ClipBoard';          Description='Просмотр истории буфера обмена';           Category='scripts'; Kind='Script'; Url='https://github.com/sweetvata/Y-ClipBoard/releases/download/Y-ClipBoard_1.0/Y-ClipBoard.ps1' }
    @{ Name='Y-SysInfo';            Description='Сбор информации о системе';                Category='scripts'; Kind='Script'; Url='https://raw.githubusercontent.com/sweetvata/Y-sysinfo/main/check.ps1' }
    # сам складывает выгрузку в Рабочий стол\papa - совпадает с $ToolsRoot
    @{ Name='Y-PSOperational';      Description='Разбор событий 4104 из журнала PowerShell/Operational'; Category='scripts'; Kind='Script'; Url='https://raw.githubusercontent.com/sweetvata/Y-PSOperational/main/hunt-ps4104.ps1' }
    @{ Name='LOLBAS Bypass Killer'; Description='Детект LOLBAS-байпасов';                   Category='scripts'; Kind='Script'; Url='https://raw.githubusercontent.com/allahbypasses/main/refs/heads/main/lolbasbypasskillerminecraft2016.ps1' }
    # ВНИМАНИЕ: PC-Check качает себя в C:\Temp и добавляет C:\Temp\Dump в исключения Defender
    @{ Name='PC-Check';             Description='PC-Check от dot-sys, качается в C:\Temp и запускается'; Category='scripts'; Kind='Inline'; Command='New-Item -Path "C:\Temp" -ItemType Directory -Force | Out-Null; Set-Location "C:\temp"; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/dot-sys/PC-Check/master/PCCheck.ps1" -OutFile "PC-Check.ps1"; Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force; Add-MpPreference -ExclusionPath ''C:\Temp\Dump'' | Out-Null; .\PC-Check.ps1' }
    # PCCheckv2 без меню - повторяет то, что делает пункт "Full Check" в Menu.ps1:
    # качает те же 7 файлов и запускает PCCheck.ps1 напрямую.
    # Полный или быстрый режим PCCheck выбирает сам по наличию QuickMFT.ps1 на диске -
    # качаем MFT.ps1 и не качаем QuickMFT.ps1, значит полный.
    # Read-Host подменяется на заглушку с 'Y': PCCheck спрашивает согласие в начале
    # и "открыть отчёт?" в конце, оба ответа нужны утвердительные.
    # ValueFromRemainingArguments обязателен - первый вопрос зовётся с двумя
    # позиционными аргументами, обычный param($p) на этом падает.
    # Menu.ps1 намеренно не качаем: последней строкой PCCheck.ps1 вызывает его обратно,
    # а с подменённым Read-Host меню зациклится на "Invalid option".
    # ВНИМАНИЕ: добавляет весь C:\Temp в исключения Defender и на время работы ставит
    # ExecutionPolicy машины в RemoteSigned (PCCheck сам запускает powershell -File без
    # Bypass, без этого его дочерние скрипты не стартуют). Исключение PCCheck снимает сам
    # в конце, политика возвращается на прежнюю в finally.
    @{ Name='PC-Check v2 (авто)';   Description='PCCheckv2 от dot-sys, полный дамп без меню; трогает Defender и ExecutionPolicy'; Category='scripts'; Kind='Inline'; Command='$ErrorActionPreference=''SilentlyContinue''; New-Item -Path ''C:\Temp\Scripts'',''C:\Temp\Dump'' -ItemType Directory -Force | Out-Null; Get-ChildItem ''C:\Temp\Dump'' | Remove-Item -Recurse -Force; Get-ChildItem ''C:\Temp\Scripts'' -File | Remove-Item -Force; $b=''https://raw.githubusercontent.com/dot-sys/PCCheckv2/main/''; foreach($f in ''PCCheck.ps1'',''MFT.ps1'',''Registry.ps1'',''SystemLogs.ps1'',''ProcDump.ps1'',''Localhost.ps1'',''Viewer.html''){ Invoke-WebRequest -Uri ($b+$f) -OutFile (''C:\Temp\Scripts\''+$f) }; Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force; $oldEP=Get-ExecutionPolicy -Scope LocalMachine; Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy RemoteSigned -Force; Add-MpPreference -ExclusionPath ''C:\Temp'' | Out-Null; function global:Read-Host { param([Parameter(ValueFromRemainingArguments=$true)]$a) ''Y'' }; try { & ''C:\Temp\Scripts\PCCheck.ps1'' } finally { Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy $oldEP -Force }' }
    @{ Name='CSRSS Signature Check';Description='Проверка подписей CSRSS от dot-sys';  Category='scripts'; Kind='Script'; Url='https://raw.githubusercontent.com/dot-sys/CSRSS-Signature-Check/main/csrss.ps1' }
    @{ Name='Recording Check';      Description='Следы программ записи экрана';        Category='scripts'; Kind='Script'; Url='https://raw.githubusercontent.com/dot-sys/Recording-Check/main/Recording-Check.ps1' }
    @{ Name='Метрики интерфейсов';  Description='IPv4-интерфейсы по метрике - ищем хотспот'; Category='scripts'; Kind='Inline'; Command='Get-NetIPInterface | Where-Object {$_.AddressFamily -eq ''IPv4'' -and $_.InterfaceMetric -ne ''0''} | Sort-Object -Property InterfaceMetric | Format-Table -Property InterfaceIndex, InterfaceAlias, AddressFamily, InterfaceMetric -AutoSize' }
    @{ Name='Netsh интерфейсы';     Description='netsh interface ipv4 show interfaces';      Category='scripts'; Kind='Inline'; Command='netsh interface ipv4 show interfaces' }

    # ---------- Scripts ----------
    @{ Name='Running Processes';           Description='Список запущенных процессов';           Category='scripts'; Kind='Inline'; Command='Get-Process | Sort-Object CPU -Descending | Format-Table Name,ID,CPU,WorkingSet -AutoSize' }
    @{ Name='Services Checker';            Description='NiccBlahh ServiceChecker';              Category='scripts'; Kind='Script'; Url='https://raw.githubusercontent.com/NiccBlahh/ServiceChecker/refs/heads/main/ServiceChecker.ps1' }
    @{ Name='Zeezy Services';              Description='Проверка служб от zeezyexe';            Category='scripts'; Kind='Script'; Url='https://raw.githubusercontent.com/zeezyexe/services-checker/refs/heads/main/zeezyservices.psl' }
    @{ Name='Doomsday Finder';             Description='DoomsDayDetector от zedoonvm1';         Category='scripts'; Kind='Script'; Url='https://raw.githubusercontent.com/zedoonvm1/powershell-scripts/refs/heads/main/DoomsDayDetector.ps1' }
    @{ Name='All In One';                  Description='Комбайн для скриншера от Enr1c0o';      Category='scripts'; Kind='Script'; Url='https://raw.githubusercontent.com/Enr1c0o/Powershell-Scripts/refs/heads/main/All-in-one.ps1' }
    # Mod Analyzer от p1aegg убран: modanalyzer.ps1 удалён из репозитория (404), остался только ClassLoaderDump.ps1
    @{ Name='JAR Parser (script)';         Description='Разбор JAR-файлов';                     Category='scripts'; Kind='Script'; Url='https://raw.githubusercontent.com/l4rpsucks/Scripts/refs/heads/main/JARParser.ps1' }
    @{ Name='Fileless Bypass Detection';   Description='Детект fileless-байпасов';              Category='scripts'; Kind='Script'; Url='https://raw.githubusercontent.com/l4rpsucks/Scripts/refs/heads/main/FilelessBypassDetection.ps1' }
    @{ Name='Macro Scanner';               Description='Поиск макросов мышиного софта';         Category='scripts'; Kind='Script'; Url='https://raw.githubusercontent.com/zeezyexe/macro-scanner/refs/heads/main/catchmacro.ps1' }
    @{ Name='ClassLoader Dump';            Description='Дамп данных ClassLoader';               Category='scripts'; Kind='Script'; Url='https://raw.githubusercontent.com/p1aegg/powershell/refs/heads/main/ClassLoaderDump.ps1' }
    @{ Name='Meow Mod Analyzer';           Description='Анализ модов от MeowTonynoh';           Category='scripts'; Kind='Script'; Url='https://raw.githubusercontent.com/MeowTonynoh/MeowModAnalyzer/main/MeowModAnalyzer.ps1' }
    @{ Name='Prefetch Integrity Analyzer'; Description='Целостность prefetch (RedLotus)';       Category='scripts'; Kind='Script'; Url='https://raw.githubusercontent.com/bacanoicua/Screenshare/main/RedLotusPrefetchIntegrityAnalyzer.ps1' }
    @{ Name='Lily Services';               Description='Проверка служб от PraiseLily';          Category='scripts'; Kind='Script'; Url='https://raw.githubusercontent.com/Lafferrr/SSTools/refs/heads/main/LilysServices.ps1' }
    @{ Name='Lily Services Enabler';       Description='Включение служб';                       Category='scripts'; Kind='Script'; Url='https://raw.githubusercontent.com/Lafferrr/SSTools/refs/heads/main/LilysServicesEnabler.ps1' }
    @{ Name='DQRKIS Fucker';               Description='Проверка артефактов DQRKIS';            Category='scripts'; Kind='Script'; Url='https://raw.githubusercontent.com/cheesecatlol/DQRKIS-FUCKER/refs/heads/main/DqrkisFucker.ps1' }
    @{ Name='MacroDetector';               Description='Следы макросов и кликеров';             Category='scripts'; Kind='Script'; Url='https://raw.githubusercontent.com/NiccBlahh/MacroDetector/refs/heads/main/MacroDetector.ps1' }

    # ---------- NirSoft ----------
    @{ Name='Full Event Log View';     Description='Просмотр журналов событий Windows'; Category='nirsoft'; Kind='Download'; Links=@('https://www.nirsoft.net/utils/fulleventlogview-x64.zip') }
    @{ Name='Network Usage View';      Description='Использование сети';                Category='nirsoft'; Kind='Download'; Links=@('https://www.nirsoft.net/utils/networkusageview-x64.zip') }
    @{ Name='Browser Downloads View';  Description='История загрузок браузеров';        Category='nirsoft'; Kind='Download'; Links=@('https://www.nirsoft.net/utils/browserdownloadsview-x64.zip') }
    @{ Name='Alternate Stream View';   Description='Просмотр ADS в NTFS';               Category='nirsoft'; Kind='Download'; Links=@('https://www.nirsoft.net/utils/alternatestreamview-x64.zip') }
    @{ Name='USB Deview';             Description='Управление USB-устройствами';        Category='nirsoft'; Kind='Download'; Links=@('https://www.nirsoft.net/utils/usbdeview-x64.zip') }
    @{ Name='Open Save Files View';    Description='История диалогов открытия и сохранения'; Category='nirsoft'; Kind='Download'; Links=@('https://www.nirsoft.net/utils/opensavefilesview-x64.zip') }
    @{ Name='Executed Programs List';  Description='Список запускавшихся программ';     Category='nirsoft'; Kind='Download'; Links=@('https://www.nirsoft.net/utils/executedprogramslist.zip') }
    @{ Name='Task Scheduler View';     Description='Просмотр задач планировщика';       Category='nirsoft'; Kind='Download'; Links=@('https://www.nirsoft.net/utils/taskschedulerview-x64.zip') }
    @{ Name='Jump Lists View';         Description='Просмотр Jump Lists';               Category='nirsoft'; Kind='Download'; Links=@('https://www.nirsoft.net/utils/jumplistsview.zip') }
    @{ Name='Win Prefetch View';       Description='Просмотр файлов prefetch';          Category='nirsoft'; Kind='Download'; Links=@('https://www.nirsoft.net/utils/winprefetchview-x64.zip') }
    @{ Name='Reg Scanner';             Description='Продвинутый поиск по реестру';      Category='nirsoft'; Kind='Download'; Links=@('https://www.nirsoft.net/utils/regscanner-x64.zip') }
    @{ Name='ShellBags View';          Description='Просмотр записей ShellBags';        Category='nirsoft'; Kind='Download'; Links=@('https://www.nirsoft.net/utils/shellbagsview.zip') }
    @{ Name='Computer Activity View';  Description='Таймлайн активности на компьютере'; Category='nirsoft'; Kind='Link';     Url='https://www.nirsoft.net/utils/computer_activity_view.html' }

    # ---------- EricZimmerman ----------
    @{ Name='Amcache Parser (EZ)';      Description='Парсит Amcache.hve';               Category='ericzimmerman'; Kind='Download'; Links=@('https://download.ericzimmermanstools.com/net9/AmcacheParser.zip') }
    @{ Name='bstrings';                 Description='Извлечение строк';                 Category='ericzimmerman'; Kind='Download'; Links=@('https://download.ericzimmermanstools.com/net9/bstrings.zip') }
    @{ Name='EvtxECmd';                 Description='Парсер журналов событий';          Category='ericzimmerman'; Kind='Download'; Links=@('https://download.ericzimmermanstools.com/net9/EvtxECmd.zip') }
    @{ Name='Jump List Explorer';       Description='Просмотр Jump List';               Category='ericzimmerman'; Kind='Download'; Links=@('https://download.ericzimmermanstools.com/net9/JumpListExplorer.zip') }
    @{ Name='JLECmd';                   Description='Разбор Jump List из консоли';      Category='ericzimmerman'; Kind='Download'; Links=@('https://download.ericzimmermanstools.com/net9/JLECmd.zip') }
    @{ Name='MFTECmd';                  Description='Парсер $MFT';                      Category='ericzimmerman'; Kind='Download'; Links=@('https://download.ericzimmermanstools.com/net9/MFTECmd.zip') }
    @{ Name='PECmd';                    Description='Парсер prefetch';                  Category='ericzimmerman'; Kind='Download'; Links=@('https://download.ericzimmermanstools.com/net9/PECmd.zip') }
    @{ Name='Recent File Cache Parser'; Description='Разбор RecentFileCache.bcf';       Category='ericzimmerman'; Kind='Download'; Links=@('https://download.ericzimmermanstools.com/net9/RecentFileCacheParser.zip') }
    @{ Name='Registry Explorer';        Description='Просмотр реестра';                 Category='ericzimmerman'; Kind='Download'; Links=@('https://download.ericzimmermanstools.com/net9/RegistryExplorer.zip') }
    @{ Name='ShellBags Explorer';       Description='Просмотр ShellBags';               Category='ericzimmerman'; Kind='Download'; Links=@('https://download.ericzimmermanstools.com/net9/ShellBagsExplorer.zip') }
    @{ Name='SrumECmd';                 Description='Парсер SRUM';                      Category='ericzimmerman'; Kind='Download'; Links=@('https://download.ericzimmermanstools.com/net9/SrumECmd.zip') }
    @{ Name='Timeline Explorer';        Description='Просмотр таймлайнов';              Category='ericzimmerman'; Kind='Download'; Links=@('https://download.ericzimmermanstools.com/net9/TimelineExplorer.zip') }

    # ---------- Others ----------
    @{ Name='Jarabel';                Description='Находит .jar файлы на компьютере';      Category='others'; Kind='Download'; Links=@('https://github.com/nay-cat/Jarabel/releases/download/light/Jarabel.Light.exe') }
    @{ Name='Luyten';                 Description='Java-декомпилятор с GUI для Procyon';   Category='others'; Kind='Download'; Links=@('https://github.com/deathmarine/Luyten/releases/download/v0.5.4_Rebuilt_with_Latest_depenencies/luyten-0.5.4.exe') }
    @{ Name='VM Aware';               Description='Детект виртуальных машин';              Category='others'; Kind='Download'; Links=@('https://github.com/NotRequiem/VMAware/releases/download/v2.8.0/vmaware.exe') }
    @{ Name='NTFS Parser';            Description='Форензик-инструмент для NTFS';          Category='others'; Kind='Download'; Links=@('https://github.com/thewhiteninja/ntfstool/releases/download/v1.7/ntfstool.x64.exe') }
    @{ Name='Hayabusa';               Description='Быстрый генератор форензик-таймлайна';  Category='others'; Kind='Download'; Links=@('https://github.com/Yamato-Security/hayabusa/releases/download/v3.10.0/hayabusa-3.10.0-all-platforms.zip') }
    @{ Name='Everything 1.5';         Description='Мгновенный поиск файлов по имени, ветка 1.5'; Category='others'; Kind='Download'; Links=@('https://www.voidtools.com/Everything-1.5.0.1418b.x64-Setup.exe') }
    @{ Name='HxD';                    Description='Hex-редактор';                          Category='others'; Kind='Download'; Links=@('https://mh-nexus.de/downloads/HxDSetup.zip') }
    @{ Name='DIE Engine';             Description='Определяет тип файла, пакер, компилятор';Category='others'; Kind='Link';    Url='https://github.com/horsicq/DIE-engine/releases' }
    @{ Name='Velociraptor';           Description='DFIR и threat hunting на эндпоинтах';   Category='others'; Kind='Link';     Url='https://github.com/Velocidex/velociraptor/releases/latest' }
    @{ Name='P1AE Javaw';             Description='Сканер javaw';                          Category='others'; Kind='Download'; Links=@('https://github.com/p1aegg/javaw/releases/download/v1.9/P1AE.Javaw.exe') }
    @{ Name='Macro Scanner (Lafferr)';Description='Сканер макросов от Lafferr';            Category='others'; Kind='Download'; Links=@('https://github.com/Lafferrr/MacroScanner/releases/download/MAW/MacroScanner.exe') }
    @{ Name='String Checker';         Description='Проверка строк от Lafferr';             Category='others'; Kind='Download'; Links=@('https://github.com/Lafferrr/SSTools/raw/refs/heads/main/SSTools/Strings/LaffersStringsChecker.exe') }
    @{ Name='Java Library Analyzer';  Description='Анализ библиотек Java от Lafferr';      Category='others'; Kind='Download'; Links=@('https://github.com/Lafferrr/SSTools/raw/refs/heads/main/SSTools/JavaLibraryAnalyzer/JavaLibraryAnalyzer.exe','https://github.com/Lafferrr/SSTools/raw/refs/heads/main/SSTools/JavaLibraryAnalyzer/library_baseline.bin','https://github.com/Lafferrr/SSTools/raw/refs/heads/main/SSTools/JavaLibraryAnalyzer/natives_baseline.bin') }
    @{ Name='PJ Cheat Scanner Lite';  Description='Проверка строк';                        Category='others'; Kind='Download'; Links=@('https://github.com/gorbgallin/Pj-sCheatScannerLite/releases/download/1.1/PjCheatScannerLite.exe','https://github.com/gorbgallin/Pj-sCheatScannerLite/releases/download/1.1/cheat_strings.txt') }
    @{ Name='System Informer';        Description='Просмотр процессов и прочего';          Category='others'; Kind='Download'; Links=@('https://github.com/winsiderss/si-builds/releases/download/4.0.26115.206/systeminformer-build-canary-setup.exe') }

    # ---------- Dependencies ----------
    @{ Name='NET 8.0';   Description='Рантайм .NET 8.0';           Category='dependencies'; Kind='Link';     Url='https://dotnet.microsoft.com/en-us/download/dotnet/8.0' }
    @{ Name='NET 9.0';   Description='Рантайм .NET 9.0';           Category='dependencies'; Kind='Download'; Links=@('https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/9.0.11/windowsdesktop-runtime-9.0.11-win-x64.exe') }
    @{ Name='NET 10.0';  Description='Рантайм .NET 10.0';          Category='dependencies'; Kind='Download'; Links=@('https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/10.0.10/windowsdesktop-runtime-10.0.10-win-x64.exe') }
    @{ Name='VSRedist';  Description='Visual C++ Redistributable'; Category='dependencies'; Kind='Download'; Links=@('https://aka.ms/vc14/vc_redist.x64.exe') }
)

# ---------- отрисовка списка инструментов ----------

# цвет и подпись бейджа по типу действия.
# Script отдельным цветом не для красоты: он выполняет чужой код с гитхаба от админа,
# это должно быть видно до нажатия, а не после
$KindBadge = @{
    'Download' = @{ Text = 'СКАЧАТЬ'; Color = '#c85a82' }
    'Script'   = @{ Text = 'СКРИПТ';  Color = '#c8703a' }
    'Inline'   = @{ Text = 'КОМАНДА'; Color = '#8a5a9a' }
    'Link'     = @{ Text = 'ССЫЛКА';  Color = '#5a8a9a' }
}

function New-KindBadge {
    param([string]$Kind)
    $spec = $KindBadge[$Kind]
    if (-not $spec) { $spec = @{ Text = $Kind.ToUpper(); Color = '#8a6878' } }
    $b = New-Object System.Windows.Controls.Border
    $b.CornerRadius = '3'
    $b.Padding = '5,1,5,1'
    $b.Margin = '0,0,6,0'
    $b.VerticalAlignment = 'Center'
    $bg = New-Object System.Windows.Media.SolidColorBrush
    $bg.Color = [System.Windows.Media.ColorConverter]::ConvertFromString($spec.Color)
    $b.Background = $bg
    $t = New-Object System.Windows.Controls.TextBlock
    $t.Text = $spec.Text
    $t.FontSize = 9
    $t.FontWeight = 'Bold'
    $t.Foreground = [System.Windows.Media.Brushes]::White
    $b.Child = $t
    return $b
}

function Update-ToolList {
    # KeepStatus - когда список перерисовывают после скачивания: там в статусе
    # уже лежат итоги ("скачано 7, ошибок 0"), и затирать их счётчиком не надо
    param([string]$CategoryKey, [string]$Filter, [switch]$KeepStatus)
    $ToolList.Children.Clear()

    $searching = -not [string]::IsNullOrWhiteSpace($Filter)
    $items = Get-VisibleTools -CategoryKey $CategoryKey -Filter $Filter
    if (-not $items) {
        $tb = New-Object System.Windows.Controls.TextBlock
        $tb.Text = 'Ничего не найдено'
        $tb.Foreground = $Window.FindResource('BrushMuted')
        $ToolList.Children.Add($tb) | Out-Null
        return
    }
    foreach ($tool in $items) {
        $card = New-Object System.Windows.Controls.Border
        $card.BorderBrush = $Window.FindResource('BrushBorder')
        $card.BorderThickness = '1'
        $card.CornerRadius = '6'
        $card.Padding = '12,10,12,10'
        $card.Margin = '0,0,0,12'
        # фон карточки чуть темнее панели чтобы не сливались
        $cardBg = New-Object System.Windows.Media.SolidColorBrush
        $cardBg.Color = [System.Windows.Media.ColorConverter]::ConvertFromString('#3a2030')
        $card.Background = $cardBg

        $grid = New-Object System.Windows.Controls.Grid
        $col1 = New-Object System.Windows.Controls.ColumnDefinition
        $col1.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        $col2 = New-Object System.Windows.Controls.ColumnDefinition
        $col2.Width = [System.Windows.GridLength]::Auto
        $grid.ColumnDefinitions.Add($col1)
        $grid.ColumnDefinitions.Add($col2)

        # подсветка карточки под курсором
        $card.Add_MouseEnter({ param($s, $e) $s.BorderBrush = $Window.FindResource('BrushAccent') })
        $card.Add_MouseLeave({ param($s, $e) $s.BorderBrush = $Window.FindResource('BrushBorder') })

        $textStack = New-Object System.Windows.Controls.StackPanel
        $textStack.VerticalAlignment = 'Center'
        $downloaded = Test-ToolDownloaded -Tool $tool

        # строка с бейджем типа, именем и - только в результатах поиска - категорией
        $titleRow = New-Object System.Windows.Controls.StackPanel
        $titleRow.Orientation = 'Horizontal'
        $titleRow.Children.Add((New-KindBadge -Kind $tool.Kind)) | Out-Null
        $nameBlock = New-Object System.Windows.Controls.TextBlock
        $nameBlock.Text = $tool.Name
        $nameBlock.Foreground = $Window.FindResource('BrushText')
        $nameBlock.FontWeight = 'SemiBold'
        $nameBlock.VerticalAlignment = 'Center'
        $titleRow.Children.Add($nameBlock) | Out-Null
        if ($downloaded) {
            $tick = New-Object System.Windows.Controls.TextBlock
            $tick.Text = ' ✓'
            $tick.FontWeight = 'Bold'
            $tick.VerticalAlignment = 'Center'
            $tick.Foreground = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.ColorConverter]::ConvertFromString('#6ec87a'))
            $titleRow.Children.Add($tick) | Out-Null
        }
        if ($searching) {
            $catLabel = ($Categories | Where-Object { $_.Key -eq $tool.Category }).Label
            $catBlock = New-Object System.Windows.Controls.TextBlock
            $catBlock.Text = "  ·  $catLabel"
            $catBlock.FontSize = 11
            $catBlock.VerticalAlignment = 'Center'
            $catBlock.Foreground = $Window.FindResource('BrushMuted')
            $titleRow.Children.Add($catBlock) | Out-Null
        }

        $descBlock = New-Object System.Windows.Controls.TextBlock
        $descBlock.Text = $tool.Description
        $descBlock.Foreground = $Window.FindResource('BrushMuted')
        $descBlock.FontSize = 12
        $descBlock.TextWrapping = 'Wrap'
        $descBlock.Margin = '0,2,0,0'
        $textStack.Children.Add($titleRow) | Out-Null
        $textStack.Children.Add($descBlock) | Out-Null
        [System.Windows.Controls.Grid]::SetColumn($textStack, 0)
        $grid.Children.Add($textStack) | Out-Null

        $actionBtn = New-Object System.Windows.Controls.Button
        $actionBtn.Style = $Window.FindResource('PrimaryButton')
        $actionBtn.Content = switch ($tool.Kind) {
            'Script'   { 'Запустить' }
            'Inline'   { 'Запустить' }
            'Download' { if ($downloaded) { 'Перекачать' } else { 'Скачать' } }
            'Link'     { 'Открыть' }
            default    { 'Открыть' }
        }
        $actionBtn.Tag = $tool
        $actionBtn.Add_Click({
            param($s, $e)
            $t = $s.Tag
            switch ($t.Kind) {
                'Script'   {
                    $s.IsEnabled = $false
                    Set-Status "Качаю скрипт: $($t.Name)"
                    try {
                        $sum = Invoke-RemoteScript -Name $t.Name -Url $t.Url
                        Set-Status "Запущено: $($t.Name) - papa\scripts, sha256 $sum..."
                    } catch {
                        Set-Status "Не запустилось - $($t.Name): $($_.Exception.Message)" -Error
                    }
                    $s.IsEnabled = $true
                }
                'Inline'   {
                    try {
                        Invoke-InlineCommand -Name $t.Name -Command $t.Command
                        Set-Status "Запущено: $($t.Name)"
                    } catch {
                        Set-Status "Не запустилось - $($t.Name): $($_.Exception.Message)" -Error
                    }
                }
                'Download' {
                    $s.IsEnabled = $false
                    Invoke-ToolDownload -Tool $t | Out-Null
                    $s.IsEnabled = $true
                    Update-ToolList -CategoryKey $script:SelectedCategory -Filter $TxtFilter.Text -KeepStatus
                }
                'Link'     { Start-Process $t.Url; Set-Status "Открыто: $($t.Name)" }
            }
        })
        $actionBtn.VerticalAlignment = 'Center'
        $actionBtn.Margin = '12,0,0,0'
        [System.Windows.Controls.Grid]::SetColumn($actionBtn, 1)
        $grid.Children.Add($actionBtn) | Out-Null

        $card.Child = $grid
        $ToolList.Children.Add($card) | Out-Null
    }

    if ($KeepStatus) { return }
    $shown = @($items).Count
    if ($searching) { Set-Status "Найдено $shown из $($Tools.Count) - поиск идёт по всем категориям" }
    else { Set-Status "Показано $shown - всего в лаунчере $($Tools.Count)" }
}

# ---------- вкладки категорий ----------

$script:SelectedCategory = $Categories[0].Key

function Set-CategoryButtonStyles {
    foreach ($child in $CategoryList.Children) {
        if ($child.Tag -eq $script:SelectedCategory) {
            $child.Style = $Window.FindResource('PrimaryButton')
        } else {
            $child.Style = $Window.FindResource('SecondaryButton')
        }
    }
}

foreach ($cat in $Categories) {
    $btn = New-Object System.Windows.Controls.Button
    # счётчик прямо во вкладке: с 12 категориями иначе не видно, где пусто, а где 28 штук
    $count = @($Tools | Where-Object { $_.Category -eq $cat.Key }).Count
    $inner = New-Object System.Windows.Controls.Grid
    $c1 = New-Object System.Windows.Controls.ColumnDefinition
    $c1.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $c2 = New-Object System.Windows.Controls.ColumnDefinition
    $c2.Width = [System.Windows.GridLength]::Auto
    $inner.ColumnDefinitions.Add($c1)
    $inner.ColumnDefinitions.Add($c2)
    $lbl = New-Object System.Windows.Controls.TextBlock
    $lbl.Text = $cat.Label
    $num = New-Object System.Windows.Controls.TextBlock
    $num.Text = "$count"
    $num.FontSize = 11
    $num.Opacity = 0.65
    $num.VerticalAlignment = 'Center'
    [System.Windows.Controls.Grid]::SetColumn($num, 1)
    $inner.Children.Add($lbl) | Out-Null
    $inner.Children.Add($num) | Out-Null
    $btn.Content = $inner
    $btn.Tag = $cat.Key
    $btn.HorizontalContentAlignment = 'Stretch'
    $btn.Margin = '0,0,0,6'
    $btn.Style = if ($cat.Key -eq $script:SelectedCategory) { $Window.FindResource('PrimaryButton') } else { $Window.FindResource('SecondaryButton') }
    $btn.Add_Click({
        param($s, $e)
        $script:SelectedCategory = $s.Tag
        Set-CategoryButtonStyles
        Update-ToolList -CategoryKey $script:SelectedCategory -Filter $TxtFilter.Text
    })
    $CategoryList.Children.Add($btn) | Out-Null
}

$TxtFilter.Add_TextChanged({
    $hasText = $TxtFilter.Text.Length -gt 0
    $TxtPlaceholder.Visibility = if ($hasText) { 'Collapsed' } else { 'Visible' }
    Update-ToolList -CategoryKey $script:SelectedCategory -Filter $TxtFilter.Text
})
$BtnClearFilter.Add_Click({ $TxtFilter.Text = '' })
$BtnRefresh.Add_Click({ Update-ToolList -CategoryKey $script:SelectedCategory -Filter $TxtFilter.Text; Set-Status 'Обновлено' })
$BtnFolder.Add_Click({ Start-Process explorer.exe $ToolsRoot })
$BtnDownloadAll.Add_Click({ Invoke-CategoryDownload -CategoryKey $script:SelectedCategory -Filter $TxtFilter.Text })

# кастомный заголовок: перетаскивание, минимизация, закрытие
$TitleBar.Add_MouseLeftButtonDown({ $Window.DragMove() })
$BtnMinimize.Add_Click({ $Window.WindowState = 'Minimized' })
$BtnClose.Add_Click({ $Window.Close() })
Update-ToolList -CategoryKey $script:SelectedCategory -Filter ''

$Window.ShowDialog() | Out-Null

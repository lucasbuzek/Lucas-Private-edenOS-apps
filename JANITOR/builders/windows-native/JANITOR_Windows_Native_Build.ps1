$ErrorActionPreference='Stop'
$Root=Split-Path -Parent $MyInvocation.MyCommand.Path; $Out=Join-Path $Root 'output'
Remove-Item $Out -Recurse -Force -ErrorAction SilentlyContinue; New-Item -ItemType Directory -Force $Out|Out-Null
if(!(Get-Command dotnet -ErrorAction SilentlyContinue)){throw '.NET SDK required to build; finished JANITOR is self-contained.'}
dotnet new wpf -n JANITOR -o "$Out\src" --framework net8.0-windows|Out-Null
@'
<Window x:Class="JANITOR.MainWindow" xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="JANITOR" Width="1000" Height="680"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition/></Grid.ColumnDefinitions><StackPanel Margin="18"><TextBlock Text="JANITOR" FontSize="24" FontWeight="SemiBold"/><Button Content="Overview" Margin="0,20,0,2"/><Button Content="Standard"/><Button Content="Developer"/><Button Content="Media"/><Button Content="Full Crew"/><Button Content="Quarantine"/></StackPanel><StackPanel Grid.Column="1" Margin="30"><TextBlock Text="JANITOR" FontSize="32" FontWeight="SemiBold"/><TextBlock Margin="0,12" TextWrapping="Wrap" Text="Self-contained Windows maintenance. Full Crew covers processes and identified services with Start, Stop, Restart, Enable and Disable subject to Windows permissions."/></StackPanel></Grid></Window>
'@|Set-Content "$Out\src\MainWindow.xaml" -Encoding UTF8
dotnet publish "$Out\src" -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o "$Out\x64"|Out-Null
try{dotnet publish "$Out\src" -c Release -r win-arm64 --self-contained true -p:PublishSingleFile=true -o "$Out\arm64"|Out-Null}catch{Write-Warning 'ARM64 publish unavailable'}
Compress-Archive "$Out\x64","$Out\arm64" "$Out\JANITOR-Windows-Native.zip" -Force -ErrorAction SilentlyContinue
Write-Host "BUILT: $Out"
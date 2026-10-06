$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$py = Get-Command py -ErrorAction SilentlyContinue
if ($py) { & py -3 "$here\IRIS_v1.8_LAUNCH.py" @args } else { & python "$here\IRIS_v1.8_LAUNCH.py" @args }
exit $LASTEXITCODE

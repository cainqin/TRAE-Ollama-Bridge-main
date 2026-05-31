$ErrorActionPreference = 'Stop'
$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$caCertFile = Join-Path $projectDir "certs\local-ca.pem"
$hostsPath = "C:\Windows\System32\drivers\etc\hosts"
$connectPort = 3001

Write-Host "=== 步骤 1: 安装 CA 证书到系统受信任根 ==="
certutil -addstore -f "Root" $caCertFile
Write-Host "CA 证书安装完成"

Write-Host "=== 步骤 2: 配置 hosts 文件 ==="
$line = "127.0.0.1 api.openai.com"
$content = Get-Content -Raw $hostsPath
if (-not $content.Contains($line)) {
    attrib -R $hostsPath
    Add-Content -Path $hostsPath -Value ("`r`n" + $line)
    Write-Host "hosts 已更新"
} else {
    Write-Host "hosts 已存在，跳过"
}

Write-Host "=== 步骤 3: 配置端口转发 443 -> $connectPort ==="
netsh interface portproxy delete v4tov4 listenport=443 listenaddress=0.0.0.0
netsh interface portproxy add v4tov4 listenport=443 listenaddress=0.0.0.0 connectport=$connectPort connectaddress=127.0.0.1
Write-Host "端口转发已配置"

Write-Host "=== 步骤 4: 开放防火墙 443 端口 ==="
netsh advfirewall firewall add rule name="TRAE-Bridge-HTTPS" dir=in action=allow protocol=TCP localport=443
Write-Host "防火墙已开放"

Write-Host ""
Write-Host "=== 验证 ==="
Write-Host "1. hosts:" 
Select-String "api.openai.com" $hostsPath | ForEach-Object { "   $_" }

Write-Host "2. 端口转发:"
netsh interface portproxy show v4tov4

Write-Host "=== 全部完成 ==="
pause

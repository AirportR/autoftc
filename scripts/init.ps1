# 获取当前系统的 CPU 架构
$cpu_arch = (Get-WmiObject Win32_Processor).Architecture

# 根据架构值判断是 amd64、arm64 还是其他架构
switch ($cpu_arch) {
    0 { $summary = "x86"; break }
    9 { $summary = "amd64"; break }
    12 { $summary = "arm64"; break }
    default { $summary = "unknown"; break }
}

# 输出结果
Write-Host "The current system's CPU architecture is $summary."
Write-Host "当前系统CPU架构: $summary."
if ($summary -eq "unknown") {
    Write-Host "当然系统CPU架构不支持自动脚本，程序已退出。"
    exit
}

#检查是否有系统代理
$internet_setting = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
if ($internet_setting.ProxyEnable -eq 1) {
    $env:HTTP_PROXY = "http://$($internet_setting.ProxyServer)"
    $env:HTTPS_PROXY = "http://$($internet_setting.ProxyServer)"
    Write-Output "Proxy Enabled.系统代理已启用: $($internet_setting.ProxyServer)"
} else{
    Write-Output "Proxy Disabled.系统代理已禁用"
}

# 下载python
$python_url = "https://www.python.org/ftp/python/3.11.6/python-3.11.6-embed-$summary.zip"
$python_resource_name = "python-3.11.6-embed-$summary.zip"
$python_archive_dir = "python-3.11.6-embed-$summary"
Write-Host "已确定系统架构，即将下载python: $python_url"
if ($internet_setting.ProxyEnable -eq 1){
    Invoke-WebRequest -Uri $python_url -OutFile $python_resource_name -Proxy "http://$($internet_setting.ProxyServer)"
}
else
{
    Invoke-WebRequest -Uri $python_url -OutFile $python_resource_name
}

#解压文件
Expand-Archive $python_resource_name -Force

#安装pip包管理工具
Write-Host "正在安装pip包管理工具..."
Add-Content -Path "$python_archive_dir\python311._pth" -Value 'import site'
if ($internet_setting.ProxyEnable -eq 1){
    Invoke-WebRequest -Uri https://bootstrap.pypa.io/get-pip.py -OutFile get-pip.py -Proxy "http://$($internet_setting.ProxyServer)"
}
else
{
    Invoke-WebRequest -Uri https://bootstrap.pypa.io/get-pip.py -OutFile get-pip.py
}
$python_executable_path = ".\$python_archive_dir\python.exe"
$python_executable_path = Resolve-Path -Path $python_executable_path
$install_pip_param = "get-pip.py"
& $python_executable_path $install_pip_param

#删除缓存
Remove-Item -Path $python_resource_name
Remove-Item -Path get-pip.py
Remove-Variable install_pip_cmd
Remove-Variable install_pip_param
Remove-Variable python_resource_name


$pip_executable_path = "$python_archive_dir\Scripts\pip.exe"
& $pip_executable_path list
& $pip_executable_path -V

#下载源代码
Write-Host "正在下载FullTclash源代码..."
$owner = "AirportR"
$repo = "FullTclash"

$apiUrl = "https://api.github.com/repos/$owner/$repo/releases/latest"
if ($internet_setting.ProxyEnable -eq 1){
    $release = Invoke-RestMethod -Uri $apiUrl -Proxy "http://$($internet_setting.ProxyServer)"
}
else
{
    $release = Invoke-RestMethod -Uri $apiUrl
}
$tagName = $release.tag_name
$downloadUrl = "https://github.com/AirportR/FullTclash/archive/refs/tags/$tagName.zip"

Write-Output "Latest release: $tagName"
Write-Output "Download URL: $downloadUrl"
if ($internet_setting.ProxyEnable -eq 1){
    Invoke-WebRequest -Uri $downloadUrl -OutFile "FullTclash-$tagName.zip" -Proxy "http://$($internet_setting.ProxyServer)"
}
else
{
    Invoke-WebRequest -Uri $downloadUrl -OutFile "FullTclash-$tagName.zip"
}
Expand-Archive "FullTclash-$tagName.zip" -Force

$ftc_dir = "FullTclash-$tagName"
$ftc_dir = Resolve-Path -Path $ftc_dir
$source = "$ftc_dir\$ftc_dir"
$destination = "$ftc_dir\"

#移动文件夹
Get-ChildItem $source | Move-Item -Destination $destination
#将FullTclash项目目录加入到环境变量

Add-Content -Path "$python_archive_dir\python311._pth" -Value $ftc_dir
#删除缓存
Remove-Item -Path "FullTclash-$tagName.zip"
Remove-Item -Path $source
Remove-Variable source
Remove-Variable destination
#安装第三方模块
Write-Host "正在安装FullTclash所需的第三方依赖..."
& $pip_executable_path install -r $ftc_dir\requirements.txt
Write-Host "FullTclash运行环境已安装完毕，剩余的启动流程将由python环境接管"

Set-Location $ftc_dir
& $python_executable_path $ftc_dir\main.py -h



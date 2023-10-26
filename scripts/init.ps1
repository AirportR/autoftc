# ��ȡ��ǰϵͳ�� CPU �ܹ�
$cpu_arch = (Get-WmiObject Win32_Processor).Architecture

# ���ݼܹ�ֵ�ж��� amd64��arm64 ���������ܹ�
switch ($cpu_arch) {
    0 { $summary = "x86"; break }
    9 { $summary = "amd64"; break }
    12 { $summary = "arm64"; break }
    default { $summary = "unknown"; break }
}

# ������
Write-Host "The current system's CPU architecture is $summary."
Write-Host "��ǰϵͳCPU�ܹ�: $summary."
if ($summary -eq "unknown") {
    Write-Host "��ȻϵͳCPU�ܹ���֧���Զ��ű����������˳���"
    exit
}

#����Ƿ���ϵͳ����
$internet_setting = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
if ($internet_setting.ProxyEnable -eq 1) {
    $env:HTTP_PROXY = "http://$($internet_setting.ProxyServer)"
    $env:HTTPS_PROXY = "http://$($internet_setting.ProxyServer)"
    Write-Output "Proxy Enabled.ϵͳ����������: $($internet_setting.ProxyServer)"
} else{
    Write-Output "Proxy Disabled.ϵͳ�����ѽ���"
}

# ����python
$python_url = "https://www.python.org/ftp/python/3.11.6/python-3.11.6-embed-$summary.zip"
$python_resource_name = "python-3.11.6-embed-$summary.zip"
$python_archive_dir = "python-3.11.6-embed-$summary"
Write-Host "��ȷ��ϵͳ�ܹ�����������python: $python_url"
if ($internet_setting.ProxyEnable -eq 1){
    Invoke-WebRequest -Uri $python_url -OutFile $python_resource_name -Proxy "http://$($internet_setting.ProxyServer)"
}
else
{
    Invoke-WebRequest -Uri $python_url -OutFile $python_resource_name
}

#��ѹ�ļ�
Expand-Archive $python_resource_name -Force

#��װpip��������
Write-Host "���ڰ�װpip��������..."
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

#ɾ������
Remove-Item -Path $python_resource_name
Remove-Item -Path get-pip.py
Remove-Variable install_pip_cmd
Remove-Variable install_pip_param
Remove-Variable python_resource_name


$pip_executable_path = "$python_archive_dir\Scripts\pip.exe"
& $pip_executable_path list
& $pip_executable_path -V

#����Դ����
Write-Host "��������FullTclashԴ����..."
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

#�ƶ��ļ���
Get-ChildItem $source | Move-Item -Destination $destination
#��FullTclash��ĿĿ¼���뵽��������

Add-Content -Path "$python_archive_dir\python311._pth" -Value $ftc_dir
#ɾ������
Remove-Item -Path "FullTclash-$tagName.zip"
Remove-Item -Path $source
Remove-Variable source
Remove-Variable destination
#��װ������ģ��
Write-Host "���ڰ�װFullTclash����ĵ���������..."
& $pip_executable_path install -r $ftc_dir\requirements.txt
Write-Host "FullTclash���л����Ѱ�װ��ϣ�ʣ����������̽���python�����ӹ�"

Set-Location $ftc_dir
& $python_executable_path $ftc_dir\main.py -h



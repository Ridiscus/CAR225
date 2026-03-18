 = Get-ChildItem -Path "c:\Users\THEWAYNE\Documents\CAR225Mobile\lib\features\driver" -Recurse -Filter *.dart
$mapping = @{
    'Ã©' = 'é'
    'Ã¨' = 'è'
    'Ã¢' = 'â'
    'Ãª' = 'ê'
    'Ã®' = 'î'
    'Ã´' = 'ô'
    'Ã»' = 'û'
    'Ã§' = 'ç'
    'Ã‰' = 'É'
    'ÃŠ' = 'Ê'
}

foreach ($file in $files) {
    if ($file.Extension -eq '.dart') {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        $original = $content
        $mapping.GetEnumerator() | ForEach-Object {
            $content = $content.Replace($_.Name, $_.Value)
        }
        
        $content = $content.Replace('Ã ', 'à')
        $content = $content.Replace('Ã¯', 'ï')
        $content = $content.Replace('Ã', 'à')
        
        if ($original -cne $content) {
            Write-Host "Replaced in $($file.Name)"
            Set-Content -Path $file.FullName -Value $content -Encoding UTF8
        }
    }
}

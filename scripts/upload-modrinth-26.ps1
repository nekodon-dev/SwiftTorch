param(
    [string] $JarDir = (Join-Path $PSScriptRoot "..\build\libs"),
    [string] $TokenFile = (Join-Path $env:APPDATA "SilentLanding\modrinth-token.sec"),
    [switch] $DryRun,
    [switch] $SubmitForReview
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Net.Http

$ApiBase = "https://api.modrinth.com/v2"
$ProjectId = "swifttorch"
$ProjectSlug = "swifttorch"
$UserAgent = "swifttorch-release-uploader/1.0"
$RepositoryUrl = "https://github.com/nekodon-dev/SwiftTorch"
$JarFile = "swifttorch-mc26.1.2-1.0.1.jar"
$VersionNumber = "1.0.1"

$ProjectBody = @'
# SwiftTorch

SwiftTorch is a Fabric mod that lets you place torches from your inventory without switching away from your pickaxe.

## Features

- Hold a pickaxe and right-click a block to place a torch from your inventory.
- Keep normal interactions for chests, doors, buttons, and other interactive blocks.
- Hold the sneak key to temporarily disable SwiftTorch.
- Offhand items are not used or consumed when placing a torch.

For more details, see the [README](https://github.com/nekodon-dev/SwiftTorch/blob/main/README.md).

---

# SwiftTorch（日本語）

ツルハシから持ち替えずにインベントリ内の松明を設置できるFabric製MODです。

## 主な機能

- ツルハシを持ってブロックを右クリックすると、インベントリ内の松明を設置します。
- チェスト、ドア、ボタンなどの通常操作を維持します。
- スニーク中はSwiftTorchを一時的に無効化できます。
- 松明設置時にオフハンドのアイテムを使用・消費しません。

さらに詳細は[README](https://github.com/nekodon-dev/SwiftTorch/blob/main/README.md)を参照してください。
'@

function Get-Token {
    if (-not [string]::IsNullOrWhiteSpace($env:MODRINTH_TOKEN)) {
        return $env:MODRINTH_TOKEN
    }

    if (Test-Path -LiteralPath $TokenFile) {
        $secure = Get-Content -LiteralPath $TokenFile | ConvertTo-SecureString
        $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        try {
            return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
        } finally {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
        }
    }

    $secure = Read-Host "Modrinth token" -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

function New-ApiClient($token) {
    $client = [System.Net.Http.HttpClient]::new()
    $client.DefaultRequestHeaders.Add("Authorization", $token)
    $client.DefaultRequestHeaders.UserAgent.ParseAdd($UserAgent)
    return $client
}

function Get-Project($token) {
    try {
        return Invoke-RestMethod -Uri "$ApiBase/project/$ProjectId" -Headers @{
            "User-Agent" = $UserAgent
            "Authorization" = $token
        }
    } catch {
        if ($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -eq 404) {
            return $null
        }
        throw
    }
}

function New-Project($token) {
    $client = New-ApiClient $token
    $multipart = $null
    $iconStream = $null
    try {
        $projectData = @{
            slug = $ProjectSlug
            title = "SwiftTorch"
            description = "Place torches from your inventory without switching away from your pickaxe."
            body = $ProjectBody
            categories = @("utility")
            additional_categories = @()
            status = "draft"
            requested_status = "draft"
            issues_url = "$RepositoryUrl/issues"
            source_url = $RepositoryUrl
            wiki_url = $null
            discord_url = $null
            donation_urls = @()
            client_side = "required"
            server_side = "required"
            license_id = "MIT"
            license_url = "$RepositoryUrl/blob/main/LICENSE"
            project_type = "mod"
            initial_versions = @()
            is_draft = $true
            gallery_items = @()
        }

        $multipart = [System.Net.Http.MultipartFormDataContent]::new()
        $json = $projectData | ConvertTo-Json -Depth 20 -Compress
        $multipart.Add([System.Net.Http.StringContent]::new(
            $json, [System.Text.Encoding]::UTF8, "application/json"), "data")

        $iconPath = Join-Path $PSScriptRoot "..\src\main\resources\assets\swifttorch\icon.png"
        $iconStream = [System.IO.File]::OpenRead($iconPath)
        $iconContent = [System.Net.Http.StreamContent]::new($iconStream)
        $iconContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("image/png")
        $multipart.Add($iconContent, "icon", "icon.png")

        $response = $client.PostAsync("$ApiBase/project", $multipart).GetAwaiter().GetResult()
        $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        if (-not $response.IsSuccessStatusCode) {
            throw "Modrinth project creation failed: HTTP $([int]$response.StatusCode) $($response.ReasonPhrase)`n$body"
        }
        return $body | ConvertFrom-Json
    } finally {
        if ($multipart) { $multipart.Dispose() }
        if ($iconStream) { $iconStream.Dispose() }
        $client.Dispose()
    }
}

function Update-ProjectMetadata($token, $projectId) {
    $client = New-ApiClient $token
    try {
        $projectData = @{
            description = "Place torches from your inventory without switching away from your pickaxe."
            body = $ProjectBody
            categories = @("utility")
            additional_categories = @()
            issues_url = "$RepositoryUrl/issues"
            source_url = $RepositoryUrl
            license_id = "MIT"
            license_url = "$RepositoryUrl/blob/main/LICENSE"
            client_side = "required"
            server_side = "required"
        }
        $json = $projectData | ConvertTo-Json -Depth 20 -Compress
        $content = [System.Net.Http.StringContent]::new(
            $json, [System.Text.Encoding]::UTF8, "application/json")
        $response = $client.PatchAsync("$ApiBase/project/$projectId", $content).GetAwaiter().GetResult()
        $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        if (-not $response.IsSuccessStatusCode) {
            throw "Modrinth project update failed: HTTP $([int]$response.StatusCode) $($response.ReasonPhrase)`n$body"
        }
    } finally {
        $client.Dispose()
    }
}

function New-VersionData($projectId) {
    return @{
        name = "SwiftTorch 26.1.2-1.0.1"
        version_number = $VersionNumber
        changelog = "Fixed offhand items being used or consumed when placing a torch.`n`n松明設置時にオフハンドのアイテムが使用・消費される問題を修正しました。"
        dependencies = @(
            @{
                project_id = "P7dR8mSH"
                dependency_type = "required"
            }
        )
        game_versions = @("26.1.2")
        version_type = "release"
        loaders = @("fabric")
        featured = $true
        status = "listed"
        project_id = $projectId
        file_parts = @("file")
        primary_file = "file"
        environment = "client_and_server"
    }
}

function New-Version($token, $jarPath, $versionData) {
    $client = New-ApiClient $token
    $multipart = $null
    $fileStream = $null
    try {
        $multipart = [System.Net.Http.MultipartFormDataContent]::new()
        $json = $versionData | ConvertTo-Json -Depth 20 -Compress
        $multipart.Add([System.Net.Http.StringContent]::new(
            $json, [System.Text.Encoding]::UTF8, "application/json"), "data")

        $fileStream = [System.IO.File]::OpenRead($jarPath)
        $fileContent = [System.Net.Http.StreamContent]::new($fileStream)
        $fileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("application/java-archive")
        $multipart.Add($fileContent, "file", [System.IO.Path]::GetFileName($jarPath))

        $response = $client.PostAsync("$ApiBase/version", $multipart).GetAwaiter().GetResult()
        $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        if (-not $response.IsSuccessStatusCode) {
            throw "Modrinth upload failed: HTTP $([int]$response.StatusCode) $($response.ReasonPhrase)`n$body"
        }
        return $body | ConvertFrom-Json
    } finally {
        if ($multipart) { $multipart.Dispose() }
        if ($fileStream) { $fileStream.Dispose() }
        $client.Dispose()
    }
}

function Submit-Project($token, $projectId) {
    $client = New-ApiClient $token
    try {
        $json = @{ requested_status = "approved" } | ConvertTo-Json -Compress
        $content = [System.Net.Http.StringContent]::new(
            $json, [System.Text.Encoding]::UTF8, "application/json")
        $response = $client.PatchAsync("$ApiBase/project/$projectId", $content).GetAwaiter().GetResult()
        $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        if (-not $response.IsSuccessStatusCode) {
            throw "Modrinth review submission failed: HTTP $([int]$response.StatusCode) $($response.ReasonPhrase)`n$body"
        }
    } finally {
        $client.Dispose()
    }
}

$jarPath = Join-Path $JarDir $JarFile
if (-not (Test-Path -LiteralPath $jarPath)) {
    throw "JAR not found: $jarPath"
}

if ($DryRun) {
    Write-Host "Dry run: would create '$ProjectSlug' when absent and upload $JarFile as $VersionNumber"
    New-VersionData "PROJECT_ID" | ConvertTo-Json -Depth 20
    exit
}

$token = Get-Token
$project = Get-Project $token
if (-not $project) {
    $project = New-Project $token
    Write-Host "Created project: $($project.id)"
}

Update-ProjectMetadata $token $project.id
Write-Host "Updated project metadata."

$existing = Invoke-RestMethod `
    -Uri "$ApiBase/project/$($project.id)/version" `
    -Headers @{
        "User-Agent" = $UserAgent
        "Authorization" = $token
    }

if (@($existing.version_number) -notcontains $VersionNumber) {
    $created = New-Version $token $jarPath (New-VersionData $project.id)
    Write-Host "Uploaded ${VersionNumber}: $($created.id)"
} else {
    Write-Host "Skip existing version: $VersionNumber"
}

if ($SubmitForReview -and ($project.status -eq "draft" -or $project.status -eq "private")) {
    Submit-Project $token $project.id
    Write-Host "Submitted project for review."
} elseif ($project.status -eq "draft" -or $project.status -eq "private") {
    Write-Host "Project remains a draft. Use -SubmitForReview only after final review."
}

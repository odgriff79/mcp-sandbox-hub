param([string]$Profile = $env:MODEL_PROFILE)
if (-not $Profile) { $Profile = "claude" }
$summary = @{
  profile = $Profile
  ts      = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
}
$summary | ConvertTo-Json -Compress | Write-Host
exit 0

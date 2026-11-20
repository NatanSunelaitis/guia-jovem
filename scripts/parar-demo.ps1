# Para a API e o servidor do app iniciados pelo iniciar-demo.cmd. Não mexe
# no banco nem no build; os logs ficam em .demo/.
$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot
$arquivoPids = Join-Path $raiz '.demo\pids.json'

if (-not (Test-Path $arquivoPids)) {
  Write-Host 'Nenhuma demonstração iniciada pelo iniciar-demo.cmd está registrada.'
  exit 0
}

$pids = Get-Content $arquivoPids -Raw | ConvertFrom-Json
$itens = @(
  @{ nome = 'A API'; parado = 'parada'; id = $pids.api; porta = $pids.portaApi },
  @{ nome = 'O app'; parado = 'parado'; id = $pids.app; porta = $pids.portaApp }
)
foreach ($item in $itens) {
  $processo = Get-Process -Id $item.id -ErrorAction SilentlyContinue
  if ($processo -and $processo.ProcessName -eq 'node') {
    Stop-Process -Id $item.id -Force
    Write-Host "$($item.nome) foi $($item.parado) (porta $($item.porta), PID $($item.id))."
  } else {
    Write-Host "$($item.nome) já não estava rodando."
  }
}
Remove-Item $arquivoPids
